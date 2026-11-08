import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/network/cached_read.dart';
import 'package:spendyholik/core/network/network_status.dart';
import 'package:spendyholik/core/session/session_currency.dart';
import 'package:spendyholik/core/storage/api_cache.dart';
import 'package:spendyholik/features/goals/data/api/goals_api.dart';
import 'package:spendyholik/features/goals/data/models/goal_dtos.dart';
import 'package:spendyholik/features/goals/data/models/models.dart';
import 'package:spendyholik/features/goals/data/repositories/remote_goal_repository.dart';
import 'package:talker/talker.dart';

import '../../../../helpers/dio_errors.dart';

class MockGoalsApi extends Mock implements GoalsApi {}

class MockApiCache extends Mock implements ApiCache {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

Map<String, Object?> money(int minor, [String currency = 'RUB']) => {
  'minor': minor,
  'currency': currency,
  'formatted': '',
};

/// Копия примера `GoalOut` из схемы API.
GoalOutDto goal({int saved = 12000000, String currency = 'RUB'}) =>
    GoalOutDto.fromJson({
      'id': 'g1',
      'name': 'Отпуск',
      'target_amount': money(20000000, currency),
      'current_amount': money(saved, currency),
      'account_id': null,
      'deadline': '2027-06-01',
      'icon': 'flag',
      'color': 'goal',
      'progress': 0.6,
    });

void main() {
  late MockGoalsApi api;
  late MockApiCache cache;
  late MockDataChangeBus bus;
  late SessionCurrency session;
  late RemoteGoalRepository repository;

  setUpAll(() {
    registerFallbackValue(<DataTopic>{});
    registerFallbackValue(
      const GoalCreateBody(
        name: '',
        targetAmountMinor: 0,
        currency: '',
        initialAmountMinor: 0,
      ),
    );
    registerFallbackValue(const GoalPatchBody(name: '', targetAmountMinor: 0));
    registerFallbackValue(
      const ContributeBody(accountId: '', amountMinor: 0, date: ''),
    );
  });

  setUp(() {
    api = MockGoalsApi();
    cache = MockApiCache();
    bus = MockDataChangeBus();
    when(() => cache.read(any())).thenAnswer((_) async => null);
    when(() => cache.write(any(), any())).thenAnswer((_) async {});
    session = SessionCurrency()..value = Currency.rub;
    repository = RemoteGoalRepository(
      api,
      CachedReader(cache, NetworkStatus(), Talker()),
      bus,
      session,
      Talker(settings: TalkerSettings(useConsoleLogs: false)),
    );
  });

  test('getGoals: маппинг GoalOut', () async {
    when(() => api.list()).thenAnswer((_) async => [goal(currency: 'USD')]);

    final g = (await repository.getGoals()).single;

    expect(g.target, 20000000);
    expect(g.saved, 12000000);
    expect(g.currency, Currency.usd);
    expect(g.deadline, DateTime(2027, 6));
  });

  test('getGoals без сети — из кэша', () async {
    when(() => api.list()).thenThrow(networkError());
    when(() => cache.read('goals')).thenAnswer(
      (_) async =>
          '[{"id":"g1","name":"Отпуск","target_amount":{"minor":100,"currency":"RUB"},'
          '"current_amount":{"minor":10,"currency":"RUB"},"deadline":null}]',
    );

    expect((await repository.getGoals()).single.saved, 10);
  });

  test('getContributions: новые первыми, счёт из ссылки', () async {
    when(() => api.contributions('g1')).thenAnswer(
      (_) async => [
        ContributionOutDto.fromJson({
          'id': 'c1',
          'goal_id': 'g1',
          'account_id': 'a1',
          'account': {'id': 'a1', 'name': 'Карта', 'color': 'blue'},
          'amount': money(100),
          'date': '2026-10-01',
        }),
        ContributionOutDto.fromJson({
          'id': 'c2',
          'goal_id': 'g1',
          'account_id': null,
          'account': null,
          'amount': money(200),
          'date': '2026-11-01',
        }),
      ],
    );

    final list = await repository.getContributions('g1');

    expect(list.map((c) => c.id), ['c2', 'c1']);
    expect(list.last.from.name, 'Карта');
    expect(list.last.from.color, EntityColor.blue);
    expect(list.first.from.name, '', reason: 'счёт удалён — ссылки нет');
  });

  group('getForecast', () {
    test('дата завершения', () async {
      when(() => api.forecast('g1')).thenAnswer(
        (_) async => ForecastOutDto.fromJson({
          'goal_id': 'g1',
          'remaining': money(100),
          'projected_completion': '2027-03-12',
        }),
      );

      expect(await repository.getForecast('g1'), DateTime(2027, 3, 12));
    });

    test('пополнений нет — null', () async {
      when(() => api.forecast('g1')).thenAnswer(
        (_) async => ForecastOutDto.fromJson({
          'goal_id': 'g1',
          'remaining': money(100),
          'projected_completion': null,
        }),
      );

      expect(await repository.getForecast('g1'), isNull);
    });
  });

  group('запись', () {
    test('create — валюта сессии, начальный взнос со счёта', () async {
      session.value = Currency.usd;
      when(() => api.create(any())).thenAnswer((_) async => goal());

      await repository.create(
        GoalDraft(
          name: 'Отпуск',
          target: 20000000,
          initialContribution: 500000,
          initialAccountId: 'a1',
          deadline: DateTime(2027, 6),
        ),
      );

      final body =
          verify(() => api.create(captureAny())).captured.single
              as GoalCreateBody;
      expect(body.toJson(), {
        'name': 'Отпуск',
        'target_amount_minor': 20000000,
        'currency': 'USD',
        'account_id': 'a1',
        'initial_amount_minor': 500000,
        'deadline': '2027-06-01',
      });
      verify(() => bus.emit({DataTopic.goals, DataTopic.accounts})).called(1);
    });

    test('update — имя, сумма, срок; снятый срок — явный null', () async {
      when(() => api.update(any(), any())).thenAnswer((_) async => goal());

      await repository.update(
        'g1',
        const GoalDraft(name: 'Отпуск', target: 300, initialContribution: 0),
      );

      final body =
          verify(() => api.update('g1', captureAny())).captured.single
              as GoalPatchBody;
      expect(body.toJson(), {
        'name': 'Отпуск',
        'target_amount_minor': 300,
        'deadline': null,
      });
      verify(() => bus.emit({DataTopic.goals})).called(1);
    });

    test('contribute — POST, затем цель заново', () async {
      when(() => api.contribute(any(), any())).thenAnswer(
        (_) async => ContributionOutDto.fromJson({
          'id': 'c1',
          'goal_id': 'g1',
          'account_id': 'a1',
          'account': null,
          'amount': money(3000000),
          'date': '2026-11-08',
        }),
      );
      when(() => api.get('g1')).thenAnswer((_) async => goal(saved: 15000000));

      final updated = await repository.contribute('g1', 3000000, 'a1');

      expect(updated.saved, 15000000);
      final body =
          verify(() => api.contribute('g1', captureAny())).captured.single
              as ContributeBody;
      expect(body.accountId, 'a1');
      expect(body.amountMinor, 3000000);
      expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(body.date), isTrue);
      verify(() => bus.emit({DataTopic.goals, DataTopic.accounts})).called(1);
    });

    test('contribute: insufficient_funds — у суммы, exceedsBalance', () async {
      when(() => api.contribute(any(), any())).thenThrow(
        apiError(409, 'insufficient_funds', {
          'amount_minor': 'insufficient_funds',
        }),
      );

      await expectLater(
        repository.contribute('g1', 6000000, 'a1'),
        throwsA(
          isA<ValidationFailure>()
              .having((f) => f.field, 'field', 'amount')
              .having((f) => f.reason, 'reason', FieldError.exceedsBalance),
        ),
      );
      verifyNever(() => bus.emit(any()));
    });

    test('contribute: счёт в другой валюте — у поля счёта', () async {
      when(() => api.contribute(any(), any())).thenThrow(
        apiError(422, 'validation_error', {'account_id': 'currency_mismatch'}),
      );

      await expectLater(
        repository.contribute('g1', 100, 'usd'),
        throwsA(
          isA<ValidationFailure>()
              .having((f) => f.field, 'field', 'accountId')
              .having((f) => f.reason, 'reason', FieldError.currencyMismatch),
        ),
      );
    });

    test(
      'create: начальный взнос больше цели — у initialContribution',
      () async {
        when(() => api.create(any())).thenThrow(
          apiError(409, 'exceeds_target', {
            'initial_amount_minor': 'exceeds_target',
          }),
        );

        await expectLater(
          repository.create(
            const GoalDraft(
              name: 'x',
              target: 100,
              initialContribution: 200,
              initialAccountId: 'a1',
            ),
          ),
          throwsA(
            isA<ValidationFailure>()
                .having((f) => f.field, 'field', 'initialContribution')
                .having((f) => f.reason, 'reason', FieldError.exceedsTarget),
          ),
        );
      },
    );

    test('delete — emit целей и счетов', () async {
      when(() => api.delete('g1')).thenAnswer((_) async {});

      await repository.delete('g1');

      verify(() => bus.emit({DataTopic.goals, DataTopic.accounts})).called(1);
    });
  });
}
