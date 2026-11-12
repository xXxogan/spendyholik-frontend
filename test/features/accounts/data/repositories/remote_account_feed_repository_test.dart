import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/config/app_config.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/network/cached_read.dart';
import 'package:spendyholik/core/network/network_status.dart';
import 'package:spendyholik/core/session/session_currency.dart';
import 'package:spendyholik/core/storage/api_cache.dart';
import 'package:spendyholik/features/accounts/data/api/accounts_api.dart';
import 'package:spendyholik/features/accounts/data/models/feed_dtos.dart';
import 'package:spendyholik/features/accounts/data/models/models.dart';
import 'package:spendyholik/features/accounts/data/repositories/remote_account_feed_repository.dart';
import 'package:spendyholik/features/debts/debts.dart';
import 'package:spendyholik/features/transactions/transactions.dart';
import 'package:talker/talker.dart';

import '../../../../helpers/dio_errors.dart';

class MockAccountsApi extends Mock implements AccountsApi {}

class MockApiCache extends Mock implements ApiCache {}

Map<String, dynamic> _money(int minor) => {
  'minor': minor,
  'currency': 'RUB',
  'formatted': '',
};

/// Форма `FeedItemOut` из схемы API.
Map<String, dynamic> item({
  required String kind,
  String id = 'e1',
  String date = '2026-11-10',
  int amount = 500000,
  String effect = 'in',
  Map<String, dynamic>? transaction,
  Map<String, dynamic>? debt,
  Map<String, dynamic>? goal,
}) => {
  'kind': kind,
  'id': id,
  'date': date,
  'amount': _money(amount),
  'effect': effect,
  'account': {'id': 'a1', 'name': 'Карта', 'color': 'blue'},
  'transaction': transaction,
  'debt': debt,
  'goal': goal,
};

/// Название совпадает с категорией — подставное сервера, в модели должно стать пустым.
final transactionJson = {
  'id': 't1',
  'type': 'expense',
  'amount': _money(120000),
  'title': 'Продукты',
  'subtitle': '',
  'category': {
    'id': 'food',
    'name': 'Продукты',
    'icon': 'cart',
    'color': 'green',
  },
  'account': {'id': 'a1', 'name': 'Карта', 'color': 'blue'},
  'transfer_to_account': null,
  'date': '2026-11-10',
  'time': '14:30:00',
  'note': '',
  'receipt': null,
};

const ivan = {'id': 'd1', 'person_name': 'Иван', 'direction': 'i_owe'};

FeedPageDto page(List<Map<String, dynamic>> items, [String? next]) =>
    FeedPageDto.fromJson({'items': items, 'next_cursor': next});

void main() {
  late MockAccountsApi api;
  late MockApiCache cache;
  late Talker talker;
  late RemoteAccountFeedRepository repository;

  setUp(() {
    api = MockAccountsApi();
    cache = MockApiCache();
    when(() => cache.generation).thenReturn(0);
    when(() => cache.read(any())).thenAnswer((_) async => null);
    when(() => cache.write(any(), any())).thenAnswer((_) async {});
    talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
    repository = RemoteAccountFeedRepository(
      api,
      CachedReader(cache, NetworkStatus(), talker),
      TransactionMapper(SessionCurrency()..value = Currency.rub, talker),
      talker,
    );
  });

  void stubFeed(FeedPageDto result) => when(
    () => api.feed(
      accountId: any(named: 'accountId'),
      cursor: any(named: 'cursor'),
      limit: any(named: 'limit'),
    ),
  ).thenAnswer((_) async => result);

  test('query: счёт, курсор, размер страницы; nextCursor', () async {
    stubFeed(page([], 'c3'));

    final result = await repository.getPage('a1', cursor: 'c2');

    expect(result.nextCursor, 'c3');
    verify(
      () => api.feed(
        accountId: 'a1',
        cursor: 'c2',
        limit: AppConfig.transactionsPageSize,
      ),
    ).called(1);
  });

  test('операция — общим маппингом, с подставным названием', () async {
    stubFeed(
      page([
        item(
          kind: 'transaction',
          id: 't1',
          amount: 120000,
          effect: 'out',
          transaction: transactionJson,
        ),
      ]),
    );

    final entry =
        (await repository.getPage('a1')).items.single as FeedTransaction;

    expect(entry.id, 't1');
    expect(entry.effect, FeedEffect.outgoing);
    expect(entry.amount, 120000);
    expect(entry.date, DateTime(2026, 11, 10));
    expect(entry.transaction.title, '');
    expect(entry.transaction.occurredAt, DateTime(2026, 11, 10, 14, 30));
  });

  test('события долга: открытие и погашение, направление, effect', () async {
    stubFeed(
      page([
        item(kind: 'debt_opening', id: 'd1', debt: ivan),
        item(
          kind: 'debt_payment',
          id: 'p1',
          effect: 'in',
          debt: {'id': 'd2', 'person_name': 'Анна', 'direction': 'owed_to_me'},
        ),
      ]),
    );

    final items = (await repository.getPage('a1')).items;

    final opening = items[0] as FeedDebtEvent;
    expect(opening.opening, isTrue);
    expect(opening.debtId, 'd1');
    expect(opening.personName, 'Иван');
    expect(opening.direction, DebtDirection.iOwe);
    expect(opening.effect, FeedEffect.incoming);
    expect(opening.currency, Currency.rub);
    final payment = items[1] as FeedDebtEvent;
    expect(payment.opening, isFalse);
    expect(payment.id, 'p1');
    expect(payment.debtId, 'd2');
    expect(payment.direction, DebtDirection.owedToMe);
  });

  test('пополнение цели', () async {
    stubFeed(
      page([
        item(
          kind: 'goal_contribution',
          id: 'c1',
          amount: 300000,
          effect: 'out',
          goal: {'id': 'g1', 'name': 'Отпуск'},
        ),
      ]),
    );

    final entry =
        (await repository.getPage('a1')).items.single as FeedGoalContribution;

    expect(entry.goalId, 'g1');
    expect(entry.goalName, 'Отпуск');
    expect(entry.amount, 300000);
    expect(entry.effect, FeedEffect.outgoing);
  });

  test('неизвестный kind и effect transfer — пропуск с warning', () async {
    stubFeed(
      page([
        item(kind: 'cashback'),
        item(
          kind: 'transaction',
          effect: 'transfer',
          transaction: transactionJson,
        ),
        item(kind: 'debt_opening', debt: ivan),
      ]),
    );

    final items = (await repository.getPage('a1')).items;

    expect(items.single, isA<FeedDebtEvent>());
    expect(
      talker.history.where((e) => e.logLevel == LogLevel.warning),
      hasLength(2),
    );
  });

  test('первая страница без сети — из кэша', () async {
    when(
      () => api.feed(
        accountId: any(named: 'accountId'),
        cursor: any(named: 'cursor'),
        limit: any(named: 'limit'),
      ),
    ).thenThrow(networkError());
    when(() => cache.read(any())).thenAnswer(
      (_) async => jsonEncode({
        'items': [item(kind: 'debt_opening', debt: ivan)],
        'next_cursor': null,
      }),
    );

    final result = await repository.getPage('a1');

    expect(result.items.single, isA<FeedDebtEvent>());
    verify(() => cache.read('feed?account_id=a1&limit=50')).called(1);
  });

  test(
    'страница с курсором без сети — NetworkFailure, кэш не читается',
    () async {
      when(
        () => api.feed(
          accountId: any(named: 'accountId'),
          cursor: any(named: 'cursor'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(networkError());

      await expectLater(
        repository.getPage('a1', cursor: 'c2'),
        throwsA(isA<NetworkFailure>()),
      );
      verifyNever(() => cache.read(any()));
    },
  );
}
