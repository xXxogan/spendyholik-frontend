import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/network/cached_read.dart';
import 'package:spendyholik/core/network/network_status.dart';
import 'package:spendyholik/core/session/session_currency.dart';
import 'package:spendyholik/core/storage/api_cache.dart';
import 'package:spendyholik/features/recurring/data/api/recurring_api.dart';
import 'package:spendyholik/features/recurring/data/models/models.dart';
import 'package:spendyholik/features/recurring/data/models/recurring_dtos.dart';
import 'package:spendyholik/features/recurring/data/repositories/remote_recurring_repository.dart';
import 'package:spendyholik/features/transactions/transactions.dart';
import 'package:talker/talker.dart';

import '../../../../helpers/dio_errors.dart';

class MockRecurringApi extends Mock implements RecurringApi {}

class MockApiCache extends Mock implements ApiCache {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

RecurringOutDto recurring({
  String id = 'r1',
  bool isActive = true,
  String nextRun = '2026-11-30',
  String? anchorDate = '2026-01-31',
  String currency = 'RUB',
  bool withCategory = true,
  bool withAccount = true,
  String type = 'expense',
}) => RecurringOutDto.fromJson({
  'id': id,
  'name': 'Интернет',
  'amount': {'minor': 80000, 'currency': currency, 'formatted': ''},
  'type': type,
  'account_id': 'a1',
  'category_id': withCategory ? 'c1' : null,
  'account': withAccount
      ? {'id': 'a1', 'name': 'Карта', 'color': 'blue'}
      : null,
  'category': withCategory
      ? {'id': 'c1', 'name': 'Дом', 'icon': 'cart', 'color': 'green'}
      : null,
  'frequency': 'monthly',
  'anchor_date': anchorDate,
  'next_run': nextRun,
  'is_active': isActive,
});

void main() {
  late MockRecurringApi api;
  late MockApiCache cache;
  late MockDataChangeBus bus;
  late SessionCurrency session;
  late RemoteRecurringRepository repository;

  final draft = RecurringDraft(
    title: 'Интернет',
    type: TransactionType.expense,
    amount: 80000,
    categoryId: 'c1',
    accountId: 'a1',
    frequency: RecurrenceFrequency.monthly,
    anchor: DateTime(2026, 1, 31, 12),
  );

  setUpAll(() {
    registerFallbackValue(<DataTopic>{});
    registerFallbackValue(
      const RecurringCreateBody(
        name: '',
        amountMinor: 0,
        type: '',
        accountId: '',
        frequency: '',
        categoryId: '',
        anchorDate: '',
      ),
    );
    registerFallbackValue(
      const RecurringPatchBody(
        name: '',
        amountMinor: 0,
        accountId: '',
        categoryId: '',
        frequency: '',
        anchorDate: '',
      ),
    );
    registerFallbackValue(const RecurringToggleBody(isActive: true));
  });

  setUp(() {
    api = MockRecurringApi();
    cache = MockApiCache();
    when(() => cache.generation).thenReturn(0);
    bus = MockDataChangeBus();
    when(() => cache.read(any())).thenAnswer((_) async => null);
    when(() => cache.write(any(), any())).thenAnswer((_) async {});
    session = SessionCurrency()..value = Currency.rub;
    repository = RemoteRecurringRepository(
      api,
      CachedReader(cache, NetworkStatus(), Talker()),
      bus,
      session,
      Talker(settings: TalkerSettings(useConsoleLogs: false)),
    );
  });

  test('getAll: маппинг полей, валюта шаблона', () async {
    when(() => api.list())
        .thenAnswer((_) async => [recurring(currency: 'USD')]);

    final r = (await repository.getAll()).single;

    expect(r.title, 'Интернет');
    expect(r.amount, 80000);
    expect(r.currency, Currency.usd);
    expect(r.type, TransactionType.expense);
    expect(r.frequency, RecurrenceFrequency.monthly);
    expect(r.nextDate, DateTime(2026, 11, 30, 12));
    expect(r.anchor, DateTime(2026, 1, 31, 12));
    expect(r.isPaused, isFalse);
    expect(r.account.name, 'Карта');
    expect(r.account.color, EntityColor.blue);
    expect(r.category.name, 'Дом');
    expect(r.category.icon, EntityIcon.cart);
  });

  test('anchor_date null — якорь равен next_run', () async {
    when(() => api.list())
        .thenAnswer((_) async => [recurring(anchorDate: null)]);

    expect(
      (await repository.getAll()).single.anchor,
      DateTime(2026, 11, 30, 12),
    );
  });

  test('is_active false — на паузе; активные по дате, затем паузы', () async {
    when(() => api.list()).thenAnswer(
      (_) async => [
        recurring(id: 'paused', isActive: false, nextRun: '2026-11-01'),
        recurring(id: 'late', nextRun: '2026-12-01'),
        recurring(id: 'soon', nextRun: '2026-11-10'),
      ],
    );

    final all = await repository.getAll();

    expect(all.map((r) => r.id), ['soon', 'late', 'paused']);
    expect(all.last.isPaused, isTrue);
  });

  test('категории и счёта в ответе нет — запасные ссылки по id', () async {
    when(() => api.list()).thenAnswer(
      (_) async => [recurring(withCategory: false, withAccount: false)],
    );

    final r = (await repository.getAll()).single;

    expect(r.category.id, '');
    expect(r.account.id, 'a1');
    expect(r.account.name, '');
    expect(r.account.color, EntityColor.gray);
  });

  test('getAll без сети — из кэша', () async {
    when(() => api.list()).thenThrow(networkError());
    when(() => cache.read('recurring')).thenAnswer(
      (_) async =>
          '[{"id":"r1","name":"Кэш","amount":{"minor":5,"currency":"RUB"},'
          '"type":"income","account_id":"a1","category_id":null,'
          '"account":null,"category":null,"frequency":"weekly",'
          '"anchor_date":null,"next_run":"2026-11-09","is_active":true}]',
    );

    final r = (await repository.getAll()).single;
    expect(r.title, 'Кэш');
    expect(r.type, TransactionType.income);
  });

  group('запись', () {
    test('create: тело с anchor_date, без next_run, emit', () async {
      when(() => api.create(any())).thenAnswer((_) async => recurring());

      await repository.create(draft);

      final body =
          verify(() => api.create(captureAny())).captured.single
              as RecurringCreateBody;
      expect(body.toJson(), {
        'name': 'Интернет',
        'amount_minor': 80000,
        'type': 'expense',
        'account_id': 'a1',
        'frequency': 'monthly',
        'anchor_date': '2026-01-31',
        'category_id': 'c1',
        'is_active': true,
      });
      verify(() => bus.emit({DataTopic.recurring})).called(1);
    });

    test('update: PATCH без type, is_active и next_run', () async {
      when(() => api.update(any(), any())).thenAnswer((_) async => recurring());

      await repository.update('r1', draft);

      final body =
          verify(() => api.update('r1', captureAny())).captured.single
              as RecurringPatchBody;
      expect(body.toJson(), {
        'name': 'Интернет',
        'amount_minor': 80000,
        'account_id': 'a1',
        'category_id': 'c1',
        'frequency': 'monthly',
        'anchor_date': '2026-01-31',
      });
      verify(() => bus.emit({DataTopic.recurring})).called(1);
    });

    test('setPaused(true) — toggle с is_active false', () async {
      when(() => api.toggle(any(), any()))
          .thenAnswer((_) async => recurring(isActive: false));

      final r = await repository.setPaused('r1', true);

      final body =
          verify(() => api.toggle('r1', captureAny())).captured.single
              as RecurringToggleBody;
      expect(body.toJson(), {'is_active': false});
      expect(r.isPaused, isTrue);
      verify(() => bus.emit({DataTopic.recurring})).called(1);
    });

    test('setPaused(false) — is_active true', () async {
      when(() => api.toggle(any(), any())).thenAnswer((_) async => recurring());

      await repository.setPaused('r1', false);

      final body =
          verify(() => api.toggle('r1', captureAny())).captured.single
              as RecurringToggleBody;
      expect(body.isActive, isTrue);
    });

    test('create: 422 name — ValidationFailure(title)', () async {
      when(() => api.create(any()))
          .thenThrow(apiError(422, 'validation_error', {'name': 'required'}));

      await expectLater(
        repository.create(draft),
        throwsA(
          isA<ValidationFailure>()
              .having((f) => f.field, 'field', 'title')
              .having((f) => f.reason, 'reason', FieldError.required),
        ),
      );
      verifyNever(() => bus.emit(any()));
    });

    test('create: 422 amount_minor и account_id — amount, accountId', () async {
      when(() => api.create(any())).thenThrow(
        apiError(422, 'validation_error', {'amount_minor': 'invalid'}),
      );
      await expectLater(
        repository.create(draft),
        throwsA(
          isA<ValidationFailure>().having((f) => f.field, 'field', 'amount'),
        ),
      );

      when(() => api.create(any())).thenThrow(
        apiError(422, 'validation_error', {'account_id': 'required'}),
      );
      await expectLater(
        repository.create(draft),
        throwsA(
          isA<ValidationFailure>().having((f) => f.field, 'field', 'accountId'),
        ),
      );
    });
  });
}
