import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/network/cached_read.dart';
import 'package:spendyholik/core/network/network_status.dart';
import 'package:spendyholik/core/session/session_currency.dart';
import 'package:spendyholik/core/storage/api_cache.dart';
import 'package:spendyholik/features/accounts/data/api/accounts_api.dart';
import 'package:spendyholik/features/accounts/data/models/account_dtos.dart';
import 'package:spendyholik/features/accounts/data/models/models.dart';
import 'package:spendyholik/features/accounts/data/repositories/remote_account_repository.dart';
import 'package:talker/talker.dart';

import '../../../../helpers/dio_errors.dart';

class MockAccountsApi extends Mock implements AccountsApi {}

class MockApiCache extends Mock implements ApiCache {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

/// Копия примера `AccountOut` из схемы API.
AccountOutDto account({
  String id = 'a1',
  String type = 'debit',
  String currency = 'RUB',
  int balance = 1050000,
  String color = 'blue',
  String? last4 = '4831',
  String interestRate = '0',
  bool archived = false,
  int? creditLimit,
}) => AccountOutDto.fromJson({
  'id': id,
  'name': 'Карта',
  'type': type,
  'currency': currency,
  'balance': {'minor': balance, 'currency': currency, 'formatted': ''},
  'initial_balance': {'minor': 0, 'currency': currency, 'formatted': ''},
  'color': color,
  'last4': last4,
  'credit_limit': creditLimit == null
      ? null
      : {'minor': creditLimit, 'currency': currency, 'formatted': ''},
  'interest_rate': interestRate,
  'is_archived': archived,
});

const draft = AccountDraft(
  name: 'Карта',
  type: AccountType.debit,
  balance: 500000,
  color: EntityColor.blue,
  cardLast4: '4831',
);

void main() {
  late MockAccountsApi api;
  late MockApiCache cache;
  late MockDataChangeBus bus;
  late SessionCurrency session;
  late RemoteAccountRepository repository;

  setUpAll(() {
    registerFallbackValue(<DataTopic>{});
    registerFallbackValue(draftBody);
    registerFallbackValue(patchBody);
  });

  setUp(() {
    api = MockAccountsApi();
    cache = MockApiCache();
    when(() => cache.generation).thenReturn(0);
    bus = MockDataChangeBus();
    when(() => cache.read(any())).thenAnswer((_) async => null);
    when(() => cache.write(any(), any())).thenAnswer((_) async {});
    session = SessionCurrency()..value = Currency.rub;
    repository = RemoteAccountRepository(
      api,
      CachedReader(cache, NetworkStatus(), Talker()),
      bus,
      session,
      Talker(settings: TalkerSettings(useConsoleLogs: false)),
    );
  });

  group('getAccounts', () {
    test('все счета с архивом; маппинг AccountOut', () async {
      when(() => api.list(any())).thenAnswer(
        (_) async => [
          account(),
          account(
            id: 's1',
            type: 'savings',
            interestRate: '7.50',
            color: 'unknown',
            last4: null,
          ),
          account(id: 'c1', type: 'credit', creditLimit: 5000000),
        ],
      );

      final accounts = await repository.getAccounts();

      verify(() => api.list(true)).called(1);
      final card = accounts[0];
      expect(card.balance, 1050000);
      expect(card.cardLast4, '4831');
      expect(card.currency, Currency.rub);
      expect(card.interestRate, isNull, reason: '«0» у не-вклада — нет ставки');
      expect(card.color, EntityColor.blue);
      final savings = accounts[1];
      expect(savings.type, AccountType.savings);
      expect(savings.interestRate, 7.5);
      expect(savings.color, EntityColor.gray, reason: 'неизвестный цвет');
      expect(accounts[2].creditLimit, 5000000);
    });

    test('неизвестная валюта — базовая валюта сессии', () async {
      session.value = Currency.usd;
      when(() => api.list(any()))
          .thenAnswer((_) async => [account(currency: 'XYZ')]);

      expect((await repository.getAccounts()).single.currency, Currency.usd);
    });

    test('нет сети — последний список из кэша', () async {
      when(() => api.list(any())).thenThrow(networkError());
      when(() => cache.read('accounts?include_archived=true')).thenAnswer(
        (_) async =>
            '[{"id":"a1","name":"Карта","type":"cash","currency":"RUB",'
            '"balance":{"minor":100,"currency":"RUB"},"color":"green",'
            '"last4":null,"credit_limit":null,"interest_rate":"0",'
            '"is_archived":false}]',
      );

      final accounts = await repository.getAccounts();
      expect(accounts.single.balance, 100);
    });
  });

  test('getAccount: 404 — NotFoundFailure', () async {
    when(() => api.get('x')).thenThrow(apiError(404, 'not_found'));

    await expectLater(
      repository.getAccount('x'),
      throwsA(isA<NotFoundFailure>()),
    );
  });

  test('getTotalBalance — из dashboard', () async {
    when(() => api.dashboard()).thenAnswer(
      (_) async => DashboardOutDto.fromJson(const {
        'total_balance': {'minor': 9000000, 'currency': 'RUB', 'formatted': ''},
        'income_this_month': {'minor': 0, 'currency': 'RUB', 'formatted': ''},
        'expense_this_month': {'minor': 0, 'currency': 'RUB', 'formatted': ''},
        'net_this_month': {
          'minor': -120000,
          'currency': 'RUB',
          'formatted': '',
        },
        'budgets': <Object>[],
        'excluded_currencies': <Object>[],
      }),
    );

    final total = await repository.getTotalBalance();
    expect(total.total, 9000000);
    expect(total.monthDelta, -120000);
  });

  test('getBalanceHistory — точки с сервера за weeks недель', () async {
    when(() => api.history('a1', 8)).thenAnswer(
      (_) async => [
        BalancePointOutDto.fromJson(const {
          'at': '2026-10-01T00:00:00Z',
          'balance': {'minor': 100, 'currency': 'RUB', 'formatted': ''},
        }),
        BalancePointOutDto.fromJson(const {
          'at': '2026-11-08T10:00:00Z',
          'balance': {'minor': 300, 'currency': 'RUB', 'formatted': ''},
        }),
      ],
    );

    final points = await repository.getBalanceHistory('a1', weeks: 8);
    expect(points.map((p) => p.balance), [100, 300]);
    expect(points.last.at, DateTime.utc(2026, 11, 8, 10));
  });

  group('запись', () {
    test('create — валюта сессии и начальный баланс, emit accounts', () async {
      session.value = Currency.usd;
      when(() => api.create(any())).thenAnswer((_) async => account());

      await repository.create(draft);

      final body =
          verify(() => api.create(captureAny())).captured.single
              as AccountCreateBody;
      expect(body.toJson(), {
        'name': 'Карта',
        'type': 'debit',
        'currency': 'USD',
        'initial_balance_minor': 500000,
        'color': 'blue',
        'last4': '4831',
        'credit_limit_minor': null,
        'interest_rate': '0',
      });
      verify(() => bus.emit({DataTopic.accounts})).called(1);
    });

    test('update — желаемый текущий баланс в balance_minor', () async {
      when(() => api.update(any(), any())).thenAnswer((_) async => account());

      await repository.update('a1', draft);

      final body =
          verify(() => api.update('a1', captureAny())).captured.single
              as AccountPatchBody;
      expect(body.toJson()['balance_minor'], 500000);
      verify(
        () => bus.emit({
          DataTopic.accounts,
          DataTopic.transactions,
          DataTopic.goals,
          DataTopic.debts,
          DataTopic.recurring,
        }),
      ).called(1);
    });

    test('update без смены баланса — balance_minor не шлётся', () async {
      when(() => api.update(any(), any())).thenAnswer((_) async => account());

      await repository.update(
        'a1',
        const AccountDraft(
          name: 'Карта',
          type: AccountType.debit,
          balance: 500000,
          color: EntityColor.blue,
          balanceChanged: false,
        ),
      );

      final body =
          verify(() => api.update('a1', captureAny())).captured.single
              as AccountPatchBody;
      // Иначе правка имени вернула бы баланс к значению на момент открытия формы.
      expect(body.toJson().containsKey('balance_minor'), isFalse);
    });

    test('archive и unarchive — свои эндпоинты, emit accounts', () async {
      when(() => api.archive('a1')).thenAnswer((_) async => account());
      when(() => api.unarchive('a1')).thenAnswer((_) async => account());

      await repository.archive('a1');
      await repository.unarchive('a1');

      verify(() => api.archive('a1')).called(1);
      verify(() => api.unarchive('a1')).called(1);
      verify(() => bus.emit({DataTopic.accounts})).called(2);
    });

    test('422 по last4 — ошибка у поля cardLast4, без emit', () async {
      when(() => api.create(any()))
          .thenThrow(apiError(422, 'validation_error', {'last4': 'invalid'}));

      await expectLater(
        repository.create(draft),
        throwsA(
          isA<ValidationFailure>()
              .having((f) => f.field, 'field', 'cardLast4')
              .having((f) => f.reason, 'reason', FieldError.invalid),
        ),
      );
      verifyNever(() => bus.emit(any()));
    });

    test('запись без сети — NetworkFailure, кэш не трогается', () async {
      when(() => api.create(any())).thenThrow(networkError());

      await expectLater(
        repository.create(draft),
        throwsA(isA<NetworkFailure>()),
      );
      verifyNever(() => cache.read(any()));
    });
  });
}

const draftBody = AccountCreateBody(
  name: '',
  type: '',
  currency: '',
  initialBalanceMinor: 0,
  color: '',
  interestRate: '',
);

const patchBody = AccountPatchBody(
  name: '',
  type: '',
  balanceMinor: 0,
  color: '',
  interestRate: '',
);
