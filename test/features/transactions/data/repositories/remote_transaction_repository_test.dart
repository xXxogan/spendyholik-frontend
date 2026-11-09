import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/config/app_config.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/network/cached_read.dart';
import 'package:spendyholik/core/network/network_status.dart';
import 'package:spendyholik/core/session/session_currency.dart';
import 'package:spendyholik/core/storage/api_cache.dart';
import 'package:spendyholik/features/transactions/data/api/transactions_api.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';
import 'package:spendyholik/features/transactions/data/models/transaction_dtos.dart';
import 'package:spendyholik/features/transactions/data/repositories/remote_transaction_repository.dart';
import 'package:talker/talker.dart';

import '../../../../helpers/dio_errors.dart';

class MockTransactionsApi extends Mock implements TransactionsApi {}

class MockApiCache extends Mock implements ApiCache {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

Map<String, dynamic> _money(int minor, [String currency = 'RUB']) => {
  'minor': minor,
  'currency': currency,
  'formatted': '',
};

/// Форма `TransactionOut` из схемы API.
TransactionOutDto tx({
  String id = 't1',
  String type = 'expense',
  String currency = 'RUB',
  String? time = '14:30:00',
  String date = '2026-10-23',
  String note = '',
  Map<String, dynamic>? category = const {
    'id': 'food',
    'name': 'Продукты',
    'icon': 'cart',
    'color': 'green',
  },
  Map<String, dynamic>? transferTo,
  String title = 'Пятёрочка',
}) => TransactionOutDto.fromJson({
  'id': id,
  'type': type,
  'amount': _money(120000, currency),
  'title': title,
  'subtitle': 'Продукты · Карта',
  'category': category,
  'account': {'id': 'a1', 'name': 'Карта', 'color': 'blue'},
  'transfer_to_account': transferTo,
  'date': date,
  'time': time,
  'note': note,
  'receipt': null,
});

TransactionPageDto page(List<TransactionOutDto> items, [String? next]) =>
    TransactionPageDto(items: items, nextCursor: next);

final draft = TransactionDraft(
  type: TransactionType.expense,
  amount: 300000,
  title: 'Обед',
  categoryId: 'food',
  accountId: 'a1',
  occurredAt: DateTime(2026, 10, 23, 9, 5, 7),
  note: 'с коллегами',
);

void main() {
  late MockTransactionsApi api;
  late MockApiCache cache;
  late MockDataChangeBus bus;
  late SessionCurrency session;
  late RemoteTransactionRepository repository;

  setUpAll(() {
    registerFallbackValue(<DataTopic>{});
    registerFallbackValue(
      const TransactionCreateBody(
        accountId: '',
        type: '',
        amountMinor: 0,
        date: '',
        title: '',
        note: '',
      ),
    );
    registerFallbackValue(
      const TransactionPatchBody(
        accountId: '',
        amountMinor: 0,
        date: '',
        title: '',
        note: '',
      ),
    );
  });

  setUp(() {
    api = MockTransactionsApi();
    cache = MockApiCache();
    when(() => cache.generation).thenReturn(0);
    bus = MockDataChangeBus();
    when(() => cache.read(any())).thenAnswer((_) async => null);
    when(() => cache.write(any(), any())).thenAnswer((_) async {});
    session = SessionCurrency()..value = Currency.rub;
    repository = RemoteTransactionRepository(
      api,
      CachedReader(cache, NetworkStatus(), Talker()),
      bus,
      session,
      Talker(settings: TalkerSettings(useConsoleLogs: false)),
    );
  });

  void stubList(TransactionPageDto result) => when(
    () => api.list(
      type: any(named: 'type'),
      accountId: any(named: 'accountId'),
      categoryId: any(named: 'categoryId'),
      dateFrom: any(named: 'dateFrom'),
      dateTo: any(named: 'dateTo'),
      cursor: any(named: 'cursor'),
      limit: any(named: 'limit'),
    ),
  ).thenAnswer((_) async => result);

  group('getPage', () {
    test('фильтр → query; date_to включительно', () async {
      stubList(page([]));

      await repository.getPage(
        TransactionFilter(
          type: TransactionType.expense,
          period: DatePeriod(start: DateTime(2026, 3), end: DateTime(2026, 4)),
          categoryId: 'food',
          accountId: 'a1',
          limit: 20,
        ),
        cursor: 'abc',
      );

      verify(
        () => api.list(
          type: 'expense',
          accountId: 'a1',
          categoryId: 'food',
          dateFrom: '2026-03-01',
          dateTo: '2026-03-31',
          cursor: 'abc',
          limit: 20,
        ),
      ).called(1);
    });

    test('без фильтра — только limit по умолчанию', () async {
      stubList(page([]));

      await repository.getPage(const TransactionFilter());

      verify(() => api.list(limit: AppConfig.transactionsPageSize)).called(1);
    });

    test('маппинг: date + time, валюта, пустая note → «»', () async {
      stubList(page([tx()], 'next'));

      final result = await repository.getPage(const TransactionFilter());

      expect(result.nextCursor, 'next');
      final t = result.items.single;
      expect(t.occurredAt, DateTime(2026, 10, 23, 14, 30));
      expect(t.amount, 120000);
      expect(t.currency, Currency.rub);
      expect(t.note, isNull);
      expect(t.title, 'Пятёрочка');
      expect(t.category?.icon, EntityIcon.cart);
      expect(t.account.color, EntityColor.blue);
      expect(t.toAccount, isNull);
    });

    test('time null → 12:00; неизвестная валюта — валюта сессии', () async {
      session.value = Currency.usd;
      stubList(page([tx(time: null, currency: 'XYZ', note: 'заметка')]));

      final t = (await repository.getPage(const TransactionFilter()))
          .items
          .single;

      expect(t.occurredAt, DateTime(2026, 10, 23, 12));
      expect(t.currency, Currency.usd);
      expect(t.note, 'заметка');
    });

    test(
      'перевод: toAccount, без категории; неизвестные иконка и цвет',
      () async {
        stubList(
          page([
            tx(
              type: 'transfer',
              category: null,
              transferTo: {'id': 'a2', 'name': 'Вклад', 'color': 'nope'},
            ),
            tx(
              category: {
                'id': 'x',
                'name': null,
                'icon': 'nope',
                'color': 'nope',
              },
            ),
          ]),
        );

        final items = (await repository.getPage(const TransactionFilter()))
            .items;

        expect(items[0].type, TransactionType.transfer);
        expect(items[0].category, isNull);
        expect(items[0].toAccount?.id, 'a2');
        expect(items[0].toAccount?.color, EntityColor.gray);
        expect(items[1].category?.icon, EntityIcon.other);
        expect(items[1].category?.color, EntityColor.gray);
      },
    );

    test('первая страница без сети — из кэша', () async {
      when(
        () => api.list(
          type: any(named: 'type'),
          accountId: any(named: 'accountId'),
          categoryId: any(named: 'categoryId'),
          dateFrom: any(named: 'dateFrom'),
          dateTo: any(named: 'dateTo'),
          cursor: any(named: 'cursor'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(networkError());
      when(() => cache.read(any())).thenAnswer((_) async {
        return '{"items":[{"id":"t1","type":"income","amount":'
            '{"minor":5,"currency":"RUB"},"title":"Т","subtitle":"",'
            '"category":null,"account":{"id":"a1","name":"К","color":"blue"},'
            '"transfer_to_account":null,"date":"2026-10-01","time":null,'
            '"note":"","receipt":null}],"next_cursor":null}';
      });

      final result = await repository.getPage(const TransactionFilter());

      expect(result.items.single.amount, 5);
      verify(() => cache.read('transactions?limit=50')).called(1);
    });

    test(
      'страница с курсором без сети — NetworkFailure, кэш не читается',
      () async {
        when(
          () => api.list(
            type: any(named: 'type'),
            accountId: any(named: 'accountId'),
            categoryId: any(named: 'categoryId'),
            dateFrom: any(named: 'dateFrom'),
            dateTo: any(named: 'dateTo'),
            cursor: any(named: 'cursor'),
            limit: any(named: 'limit'),
          ),
        ).thenThrow(networkError());

        await expectLater(
          repository.getPage(const TransactionFilter(), cursor: 'c2'),
          throwsA(isA<NetworkFailure>()),
        );
        verifyNever(() => cache.read(any()));
        verifyNever(() => cache.write(any(), any()));
      },
    );
  });

  test('getTransactions — первая страница целиком', () async {
    stubList(page([tx(), tx(id: 't2')], 'more'));

    final items = await repository.getTransactions(const TransactionFilter());

    expect(items.map((t) => t.id), ['t1', 't2']);
  });

  test('getTransaction: 404 — NotFoundFailure', () async {
    when(() => api.get('x')).thenThrow(apiError(404, 'not_found'));

    await expectLater(
      repository.getTransaction('x'),
      throwsA(isA<NotFoundFailure>()),
    );
  });

  group('запись', () {
    const topics = {
      DataTopic.transactions,
      DataTopic.accounts,
      DataTopic.budgets,
      DataTopic.categories,
    };

    test('create: тело с HH:mm:ss, emit тем', () async {
      when(() => api.create(any())).thenAnswer((_) async => tx());

      await repository.create(draft);

      final body =
          verify(() => api.create(captureAny())).captured.single
              as TransactionCreateBody;
      expect(body.toJson(), {
        'account_id': 'a1',
        'type': 'expense',
        'amount_minor': 300000,
        'date': '2026-10-23',
        'category_id': 'food',
        'time': '09:05:07',
        'note': 'с коллегами',
        'title': 'Обед',
        'transfer_to_account_id': null,
      });
      verify(() => bus.emit(topics)).called(1);
    });

    test('create перевода: transfer_to_account_id, пустая note → «»', () async {
      when(() => api.create(any()))
          .thenAnswer((_) async => tx(type: 'transfer'));

      await repository.create(
        TransactionDraft(
          type: TransactionType.transfer,
          amount: 100,
          title: '',
          accountId: 'a1',
          toAccountId: 'a2',
          occurredAt: DateTime(2026, 10, 23, 18),
        ),
      );

      final body =
          verify(() => api.create(captureAny())).captured.single
              as TransactionCreateBody;
      expect(body.toJson()['transfer_to_account_id'], 'a2');
      expect(body.toJson()['type'], 'transfer');
      expect(body.toJson()['category_id'], isNull);
      // Сервер не принимает null в note (ни при создании, ни в правке).
      expect(body.toJson()['note'], '');
    });

    test('update: убранная заметка уходит пустой строкой, не null', () async {
      when(() => api.update(any(), any())).thenAnswer((_) async => tx());

      await repository.update(
        't1',
        TransactionDraft(
          type: TransactionType.expense,
          amount: 300000,
          title: 'Обед',
          categoryId: 'food',
          accountId: 'a1',
          occurredAt: DateTime(2026, 10, 23, 9, 5, 7),
        ),
      );

      final body =
          verify(() => api.update('t1', captureAny())).captured.single
              as TransactionPatchBody;
      // null в note сервер отклоняет: «note cannot be null».
      expect(body.toJson()['note'], '');
    });

    test('update: тело без type, emit тем', () async {
      when(() => api.update(any(), any())).thenAnswer((_) async => tx());

      await repository.update('t1', draft);

      final body =
          verify(() => api.update('t1', captureAny())).captured.single
              as TransactionPatchBody;
      expect(body.toJson().containsKey('type'), isFalse);
      expect(body.toJson()['amount_minor'], 300000);
      expect(body.toJson()['time'], '09:05:07');
      verify(() => bus.emit(topics)).called(1);
    });

    test('delete — emit тем', () async {
      when(() => api.delete('t1')).thenAnswer((_) async {});

      await repository.delete('t1');

      verify(() => api.delete('t1')).called(1);
      verify(() => bus.emit(topics)).called(1);
    });

    test('422 currency_mismatch → toAccountId, без emit', () async {
      when(() => api.create(any())).thenThrow(
        apiError(422, 'validation_error', {
          'transfer_to_account_id': 'currency_mismatch',
        }),
      );

      await expectLater(
        repository.create(draft),
        throwsA(
          isA<ValidationFailure>()
              .having((f) => f.field, 'field', 'toAccountId')
              .having((f) => f.reason, 'reason', FieldError.currencyMismatch),
        ),
      );
      verifyNever(() => bus.emit(any()));
    });

    test('422 по amount_minor → amount', () async {
      when(() => api.create(any())).thenThrow(
        apiError(422, 'validation_error', {'amount_minor': 'invalid'}),
      );

      await expectLater(
        repository.create(draft),
        throwsA(isA<ValidationFailure>().having((f) => f.field, 'f', 'amount')),
      );
    });
  });

  group('подставное название сервера', () {
    Future<String> titleOf(TransactionOutDto dto) async {
      when(() => api.get('t1')).thenAnswer((_) async => dto);
      return (await repository.getTransaction('t1')).title;
    }

    test('совпадает с именем категории — названия нет', () async {
      expect(await titleOf(tx(title: 'Продукты')), '');
    });

    test('перевод: имя счёта или «Перевод» — названия нет', () async {
      final to = {'id': 'a2', 'name': 'Наличные', 'color': 'green'};
      expect(
        await titleOf(
          tx(type: 'transfer', category: null, transferTo: to, title: 'Карта'),
        ),
        '',
      );
      expect(
        await titleOf(
          tx(
            type: 'transfer',
            category: null,
            transferTo: to,
            title: 'Перевод',
          ),
        ),
        '',
      );
    });

    test('своё название остаётся', () async {
      expect(await titleOf(tx()), 'Пятёрочка');
    });
  });
}
