import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/network/cached_read.dart';
import 'package:spendyholik/core/network/network_status.dart';
import 'package:spendyholik/core/storage/api_cache.dart';
import 'package:spendyholik/features/budgets/data/api/budgets_api.dart';
import 'package:spendyholik/features/budgets/data/models/budget_dtos.dart';
import 'package:spendyholik/features/budgets/data/models/models.dart';
import 'package:spendyholik/features/budgets/data/repositories/remote_budget_repository.dart';
import 'package:talker/talker.dart';

import '../../../../helpers/dio_errors.dart';

class MockBudgetsApi extends Mock implements BudgetsApi {}

class MockApiCache extends Mock implements ApiCache {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

/// Форма `BudgetOut` из схемы API.
BudgetOutDto budget({
  String id = 'b1',
  String period = 'monthly',
  String? startDate,
  String? endDate,
  String? periodStart = '2026-10-01',
  String? periodEnd = '2026-10-31',
  bool isActive = true,
}) => BudgetOutDto.fromJson({
  'id': id,
  'category': {
    'id': 'food',
    'name': 'Продукты',
    'icon': 'cart',
    'color': 'green',
  },
  'category_id': 'food',
  'amount': {'minor': 500000, 'currency': 'RUB', 'formatted': ''},
  'spent': {'minor': 120000, 'currency': 'RUB', 'formatted': ''},
  'period': period,
  'start_date': startDate,
  'end_date': endDate,
  'period_start': periodStart,
  'period_end': periodEnd,
  'is_active': isActive,
});

void main() {
  late MockBudgetsApi api;
  late MockApiCache cache;
  late MockDataChangeBus bus;
  late RemoteBudgetRepository repository;

  setUpAll(() {
    registerFallbackValue(<DataTopic>{});
    registerFallbackValue(
      const BudgetCreateBody(
        categoryId: '',
        amountMinor: 0,
        period: '',
        isActive: true,
      ),
    );
    registerFallbackValue(
      const BudgetPatchBody(categoryId: '', amountMinor: 0, period: ''),
    );
  });

  setUp(() {
    api = MockBudgetsApi();
    cache = MockApiCache();
    when(() => cache.generation).thenReturn(0);
    bus = MockDataChangeBus();
    when(() => cache.read(any())).thenAnswer((_) async => null);
    when(() => cache.write(any(), any())).thenAnswer((_) async {});
    repository = RemoteBudgetRepository(
      api,
      CachedReader(cache, NetworkStatus(), Talker()),
      bus,
    );
  });

  group('маппинг', () {
    test('monthly: limit, spent, категория, период +1 день', () async {
      when(() => api.list()).thenAnswer((_) async => [budget()]);

      final b = (await repository.getBudgets()).single;

      expect(b.limit, 500000);
      expect(b.spent, 120000);
      expect(b.period, BudgetPeriod.monthly);
      expect(b.category.id, 'food');
      expect(b.category.icon, EntityIcon.cart);
      expect(b.category.color, EntityColor.green);
      expect(
        b.currentPeriod,
        DatePeriod(start: DateTime(2026, 10), end: DateTime(2026, 11)),
      );
    });

    test('weekly: конец недели включительно → +1 день', () async {
      when(() => api.get('b1')).thenAnswer(
        (_) async => budget(
          period: 'weekly',
          periodStart: '2026-10-26',
          periodEnd: '2026-11-01',
        ),
      );

      final b = await repository.getBudget('b1');

      expect(b.period, BudgetPeriod.weekly);
      expect(
        b.currentPeriod,
        DatePeriod(start: DateTime(2026, 10, 26), end: DateTime(2026, 11, 2)),
      );
    });

    test('one_time → once, период по датам', () async {
      when(() => api.get('b1')).thenAnswer(
        (_) async => budget(
          period: 'one_time',
          startDate: '2026-12-01',
          endDate: '2026-12-10',
          periodStart: '2026-12-01',
          periodEnd: '2026-12-10',
        ),
      );

      final b = await repository.getBudget('b1');

      expect(b.period, BudgetPeriod.once);
      expect(
        b.currentPeriod,
        DatePeriod(start: DateTime(2026, 12), end: DateTime(2026, 12, 11)),
      );
    });

    test(
      'period_* null (неактивный разовый) — из start_date/end_date',
      () async {
        when(() => api.get('b1')).thenAnswer(
          (_) async => budget(
            period: 'one_time',
            startDate: '2026-12-01',
            endDate: '2026-12-10',
            periodStart: null,
            periodEnd: null,
            isActive: false,
          ),
        );

        final b = await repository.getBudget('b1');

        expect(
          b.currentPeriod,
          DatePeriod(start: DateTime(2026, 12), end: DateTime(2026, 12, 11)),
        );
      },
    );

    test('неизвестные иконка и цвет — запасные', () async {
      when(() => api.get('b1')).thenAnswer(
        (_) async => BudgetOutDto.fromJson({
          'id': 'b1',
          'category': {'id': 'x', 'name': null, 'icon': 'nope', 'color': null},
          'amount': {'minor': 1, 'currency': 'RUB'},
          'spent': {'minor': 0, 'currency': 'RUB'},
          'period': 'monthly',
          'period_start': '2026-10-01',
          'period_end': '2026-10-31',
          'is_active': true,
        }),
      );

      final b = await repository.getBudget('b1');

      expect(b.category.icon, EntityIcon.other);
      expect(b.category.color, EntityColor.gray);
      expect(b.category.name, '');
    });
  });

  test('getBudget: 404 — NotFoundFailure', () async {
    when(() => api.get('x')).thenThrow(apiError(404, 'not_found'));

    await expectLater(
      repository.getBudget('x'),
      throwsA(isA<NotFoundFailure>()),
    );
  });

  test('список без сети — из кэша', () async {
    when(() => api.list()).thenThrow(networkError());
    when(() => cache.read(any())).thenAnswer(
      (_) async =>
          '[{"id":"b9","category":{"id":"c","name":"К","icon":"cart",'
          '"color":"green"},"amount":{"minor":7,"currency":"RUB"},'
          '"spent":{"minor":1,"currency":"RUB"},"period":"monthly",'
          '"period_start":"2026-10-01","period_end":"2026-10-31",'
          '"is_active":true}]',
    );

    final result = await repository.getBudgets();

    expect(result.single.limit, 7);
    verify(() => cache.read('budgets')).called(1);
  });

  group('запись', () {
    const topics = {DataTopic.budgets};

    test('create monthly: даты null, emit', () async {
      when(() => api.create(any())).thenAnswer((_) async => budget());

      await repository.create(
        const BudgetDraft(
          categoryId: 'food',
          limit: 500000,
          period: BudgetPeriod.monthly,
        ),
      );

      final body =
          verify(() => api.create(captureAny())).captured.single
              as BudgetCreateBody;
      expect(body.toJson(), {
        'category_id': 'food',
        'amount_minor': 500000,
        'period': 'monthly',
        'start_date': null,
        'end_date': null,
        'is_active': true,
      });
      verify(() => bus.emit(topics)).called(1);
    });

    test('create разового: end_date включительно (onceEnd − 1 день)', () async {
      when(() => api.create(any()))
          .thenAnswer((_) async => budget(period: 'one_time'));

      await repository.create(
        BudgetDraft(
          categoryId: 'food',
          limit: 100,
          period: BudgetPeriod.once,
          onceStart: DateTime(2026, 12),
          onceEnd: DateTime(2026, 12, 11),
        ),
      );

      final body =
          verify(() => api.create(captureAny())).captured.single
              as BudgetCreateBody;
      expect(body.toJson()['period'], 'one_time');
      expect(body.toJson()['start_date'], '2026-12-01');
      expect(body.toJson()['end_date'], '2026-12-10');
    });

    test('update: поля со значениями, даты у monthly — явный null', () async {
      when(() => api.update(any(), any())).thenAnswer((_) async => budget());

      await repository.update(
        'b1',
        const BudgetDraft(
          categoryId: 'food',
          limit: 900,
          period: BudgetPeriod.weekly,
        ),
      );

      final body =
          verify(() => api.update('b1', captureAny())).captured.single
              as BudgetPatchBody;
      expect(
        body.toJson(),
        {
          'category_id': 'food',
          'amount_minor': 900,
          'period': 'weekly',
          'start_date': null,
          'end_date': null,
        },
        reason: 'is_active не шлём: выключенный на сервере бюджет не включится от правки',
      );
      verify(() => bus.emit(topics)).called(1);
    });

    test('409 budget_already_exists → categoryId, без emit', () async {
      when(() => api.create(any())).thenThrow(
        apiError(409, 'budget_already_exists', {
          'category_id': 'budget_already_exists',
        }),
      );

      await expectLater(
        repository.create(
          const BudgetDraft(
            categoryId: 'food',
            limit: 1,
            period: BudgetPeriod.monthly,
          ),
        ),
        throwsA(
          isA<ValidationFailure>()
              .having((f) => f.field, 'field', 'categoryId')
              .having((f) => f.reason, 'reason', FieldError.alreadyExists),
        ),
      );
      verifyNever(() => bus.emit(any()));
    });

    test(
      '422 по amount_minor → limit, по датам → period (у формы нет полей дат)',
      () async {
        when(() => api.create(any())).thenThrow(
          apiError(422, 'validation_error', {'amount_minor': 'too_small'}),
        );
        await expectLater(
          repository.create(
            const BudgetDraft(
              categoryId: 'food',
              limit: 0,
              period: BudgetPeriod.monthly,
            ),
          ),
          throwsA(
            isA<ValidationFailure>()
                .having((f) => f.field, 'field', 'limit')
                .having((f) => f.reason, 'reason', FieldError.invalidAmount),
          ),
        );

        when(
          () => api.create(any()),
        ).thenThrow(apiError(422, 'validation_error', {'end_date': 'invalid'}));
        await expectLater(
          repository.create(
            const BudgetDraft(
              categoryId: 'food',
              limit: 1,
              period: BudgetPeriod.monthly,
            ),
          ),
          throwsA(
            isA<ValidationFailure>().having((f) => f.field, 'field', 'period'),
          ),
        );

        when(() => api.create(any())).thenThrow(
          apiError(422, 'validation_error', {'start_date': 'invalid'}),
        );
        await expectLater(
          repository.create(
            const BudgetDraft(
              categoryId: 'food',
              limit: 1,
              period: BudgetPeriod.monthly,
            ),
          ),
          throwsA(
            isA<ValidationFailure>().having((f) => f.field, 'field', 'period'),
          ),
        );
      },
    );

    test('delete — emit', () async {
      when(() => api.delete('b1')).thenAnswer((_) async {});

      await repository.delete('b1');

      verify(() => api.delete('b1')).called(1);
      verify(() => bus.emit(topics)).called(1);
    });

    test('delete: 404 — NotFoundFailure, без emit', () async {
      when(() => api.delete('x')).thenThrow(apiError(404, 'not_found'));

      await expectLater(
        repository.delete('x'),
        throwsA(isA<NotFoundFailure>()),
      );
      verifyNever(() => bus.emit(any()));
    });
  });
}
