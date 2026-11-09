import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/network/cached_read.dart';
import 'package:spendyholik/core/network/network_status.dart';
import 'package:spendyholik/core/session/session_currency.dart';
import 'package:spendyholik/core/storage/api_cache.dart';
import 'package:spendyholik/features/debts/data/api/debts_api.dart';
import 'package:spendyholik/features/debts/data/models/debt_dtos.dart';
import 'package:spendyholik/features/debts/data/models/models.dart';
import 'package:spendyholik/features/debts/data/repositories/remote_debt_repository.dart';
import 'package:talker/talker.dart';

import '../../../../helpers/dio_errors.dart';

class MockDebtsApi extends Mock implements DebtsApi {}

class MockApiCache extends Mock implements ApiCache {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

Map<String, Object?> money(int minor, [String currency = 'RUB']) => {
  'minor': minor,
  'currency': currency,
  'formatted': '',
};

DebtOutDto debt({
  String id = 'd1',
  int remaining = 1200000,
  String direction = 'i_owe',
  String note = '',
  String currency = 'RUB',
  String? createdAt = '2026-10-01T10:00:00Z',
}) => DebtOutDto.fromJson({
  'id': id,
  'person_name': 'Иван',
  'direction': direction,
  'amount': money(1200000, currency),
  'remaining': money(remaining, currency),
  'due_date': '2026-12-01',
  'is_closed': remaining == 0,
  'note': note,
  'created_at': createdAt,
});

void main() {
  late MockDebtsApi api;
  late MockApiCache cache;
  late MockDataChangeBus bus;
  late SessionCurrency session;
  late RemoteDebtRepository repository;

  setUpAll(() {
    registerFallbackValue(<DataTopic>{});
    registerFallbackValue(
      const DebtCreateBody(
        personName: '',
        direction: '',
        amountMinor: 0,
        currency: '',
        note: '',
      ),
    );
    registerFallbackValue(
      const DebtPatchBody(personName: '', amountMinor: 0, note: ''),
    );
    registerFallbackValue(
      const RepayBody(accountId: '', amountMinor: 0, date: ''),
    );
  });

  setUp(() {
    api = MockDebtsApi();
    cache = MockApiCache();
    when(() => cache.generation).thenReturn(0);
    bus = MockDataChangeBus();
    when(() => cache.read(any())).thenAnswer((_) async => null);
    when(() => cache.write(any(), any())).thenAnswer((_) async {});
    session = SessionCurrency()..value = Currency.rub;
    repository = RemoteDebtRepository(
      api,
      CachedReader(cache, NetworkStatus(), Talker()),
      bus,
      session,
      Talker(settings: TalkerSettings(useConsoleLogs: false)),
    );
  });

  test('getDebts: маппинг, пустая заметка — null, валюта долга', () async {
    when(
      () => api.list(),
    ).thenAnswer((_) async => [debt(currency: 'USD', direction: 'owed_to_me')]);

    final d = (await repository.getDebts()).single;

    expect(d.counterparty, 'Иван');
    expect(d.direction, DebtDirection.owedToMe);
    expect(d.total, 1200000);
    expect(d.remaining, 1200000);
    expect(d.currency, Currency.usd);
    expect(d.note, isNull);
    expect(d.dueDate, DateTime(2026, 12));
    expect(d.createdAt, DateTime.utc(2026, 10, 1, 10));
  });

  test('getDebts: открытые, затем закрытые', () async {
    when(() => api.list()).thenAnswer(
      (_) async => [
        debt(id: 'closed', remaining: 0, createdAt: '2026-10-05T10:00:00Z'),
        debt(id: 'open'),
      ],
    );

    expect((await repository.getDebts()).map((d) => d.id), ['open', 'closed']);
  });

  test('getDebt: заметка сохраняется', () async {
    when(() => api.get('d1'))
        .thenAnswer((_) async => debt(note: 'до зарплаты'));

    expect((await repository.getDebt('d1')).note, 'до зарплаты');
  });

  test('getDebts без сети — из кэша', () async {
    when(() => api.list()).thenThrow(networkError());
    when(() => cache.read('debts')).thenAnswer(
      (_) async =>
          '[{"id":"d1","person_name":"Иван","direction":"i_owe",'
          '"amount":{"minor":100,"currency":"RUB"},'
          '"remaining":{"minor":40,"currency":"RUB"},"due_date":null,'
          '"is_closed":false,"note":"","created_at":null}]',
    );

    expect((await repository.getDebts()).single.remaining, 40);
  });

  test('getHistory: события, новые первыми, счёт из ссылки', () async {
    when(() => api.history('d1')).thenAnswer(
      (_) async => [
        DebtEventOutDto.fromJson({
          'id': 'e1',
          'kind': 'opened',
          'amount': money(1200000),
          'date': '2026-10-01',
          'account': null,
        }),
        DebtEventOutDto.fromJson({
          'id': 'e2',
          'kind': 'repayment',
          'amount': money(500000),
          'date': '2026-11-01',
          'account': {'id': 'a1', 'name': 'Карта', 'color': 'nope'},
        }),
      ],
    );

    final list = await repository.getHistory('d1');

    expect(list.map((e) => e.id), ['e2', 'e1']);
    expect(list.first.kind, DebtEventKind.repayment);
    expect(list.first.amount, 500000);
    expect(list.first.account?.name, 'Карта');
    expect(list.first.account?.color, EntityColor.gray);
    expect(list.last.kind, DebtEventKind.opened);
    expect(list.last.account, isNull);
  });

  group('запись', () {
    test('create — базовая валюта сессии, пустая заметка ""', () async {
      session.value = Currency.usd;
      when(() => api.create(any())).thenAnswer((_) async => debt());

      await repository.create(
        DebtDraft(
          counterparty: 'Иван',
          direction: DebtDirection.owedToMe,
          amount: 1200000,
          dueDate: DateTime(2026, 12),
        ),
      );

      final body =
          verify(() => api.create(captureAny())).captured.single
              as DebtCreateBody;
      expect(body.toJson(), {
        'person_name': 'Иван',
        'direction': 'owed_to_me',
        'amount_minor': 1200000,
        'currency': 'USD',
        'due_date': '2026-12-01',
        'note': '',
      });
      verify(() => bus.emit({DataTopic.debts})).called(1);
    });

    test('update — без направления, снятый срок null, заметка ""', () async {
      when(() => api.update(any(), any())).thenAnswer((_) async => debt());

      await repository.update(
        'd1',
        const DebtDraft(
          counterparty: 'Иван',
          direction: DebtDirection.iOwe,
          amount: 300,
        ),
      );

      final body =
          verify(() => api.update('d1', captureAny())).captured.single
              as DebtPatchBody;
      expect(body.toJson(), {
        'person_name': 'Иван',
        'amount_minor': 300,
        'due_date': null,
        'note': '',
      });
      verify(() => bus.emit({DataTopic.debts})).called(1);
    });

    test('update: below_repaid — у суммы, belowRepaid', () async {
      when(() => api.update(any(), any())).thenThrow(
        apiError(409, 'below_repaid', {'amount_minor': 'below_repaid'}),
      );

      await expectLater(
        repository.update(
          'd1',
          const DebtDraft(
            counterparty: 'Иван',
            direction: DebtDirection.iOwe,
            amount: 1,
          ),
        ),
        throwsA(
          isA<ValidationFailure>()
              .having((f) => f.field, 'field', 'amount')
              .having((f) => f.reason, 'reason', FieldError.belowRepaid),
        ),
      );
      verifyNever(() => bus.emit(any()));
    });

    test('repay — только POST и шина: перечитывание долга могло бы упасть после списания', () async {
      when(() => api.repay(any(), any())).thenAnswer(
        (_) async =>
            DebtPaymentOutDto.fromJson({'id': 'p1', 'amount': money(500000)}),
      );
      await repository.repay('d1', 500000, 'a1');

      verifyNever(() => api.get(any()));
      final body =
          verify(() => api.repay('d1', captureAny())).captured.single
              as RepayBody;
      expect(body.accountId, 'a1');
      expect(body.amountMinor, 500000);
      expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(body.date), isTrue);
      verify(() => bus.emit({DataTopic.debts, DataTopic.accounts})).called(1);
    });

    test('repay: excessive_repayment — exceedsRemaining у суммы', () async {
      when(() => api.repay(any(), any())).thenThrow(
        apiError(409, 'excessive_repayment', {
          'amount_minor': 'excessive_repayment',
        }),
      );

      await expectLater(
        repository.repay('d1', 9999999, 'a1'),
        throwsA(
          isA<ValidationFailure>()
              .having((f) => f.field, 'field', 'amount')
              .having((f) => f.reason, 'reason', FieldError.exceedsRemaining),
        ),
      );
      verifyNever(() => bus.emit(any()));
    });

    test('repay: insufficient_funds — exceedsBalance', () async {
      when(() => api.repay(any(), any())).thenThrow(
        apiError(409, 'insufficient_funds', {
          'amount_minor': 'insufficient_funds',
        }),
      );

      await expectLater(
        repository.repay('d1', 100, 'a1'),
        throwsA(
          isA<ValidationFailure>().having(
            (f) => f.reason,
            'reason',
            FieldError.exceedsBalance,
          ),
        ),
      );
    });

    test('repay: счёт в другой валюте — у accountId', () async {
      when(() => api.repay(any(), any())).thenThrow(
        apiError(422, 'validation_error', {'account_id': 'currency_mismatch'}),
      );

      await expectLater(
        repository.repay('d1', 100, 'usd'),
        throwsA(
          isA<ValidationFailure>()
              .having((f) => f.field, 'field', 'accountId')
              .having((f) => f.reason, 'reason', FieldError.currencyMismatch),
        ),
      );
    });
  });
}
