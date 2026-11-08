import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/accounts/data/models/models.dart';
import 'package:spendyholik/features/accounts/data/repositories/repositories.dart';
import 'package:spendyholik/features/categories/data/models/models.dart';
import 'package:spendyholik/features/categories/data/repositories/repositories.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';
import 'package:spendyholik/features/transactions/presentation/cubit/transaction_filters_cubit.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockAccountRepository extends Mock implements AccountRepository {}

CategoryModel category(String id, CategoryKind kind, {String? parentId}) =>
    CategoryModel(
      id: id,
      name: id,
      kind: kind,
      icon: EntityIcon.other,
      color: EntityColor.gray,
      parentId: parentId,
      transactionCount: 0,
    );

AccountModel account(String id, {bool archived = false}) => AccountModel(
  currency: Currency.rub,
  id: id,
  name: id,
  type: AccountType.debit,
  balance: 0,
  color: EntityColor.blue,
  isArchived: archived,
);

void main() {
  late MockCategoryRepository categories;
  late MockAccountRepository accounts;

  final food = category('food', .expense);
  final delivery = category('delivery', .expense, parentId: 'food');
  final salary = category('salary', .income);
  final between = category('between', .transfer);

  setUp(() {
    categories = MockCategoryRepository();
    accounts = MockAccountRepository();
    when(() => categories.getCategories())
        .thenAnswer((_) async => [food, delivery, salary, between]);
    when(() => accounts.getAccounts()).thenAnswer(
      (_) async => [account('card'), account('old', archived: true)],
    );
  });

  TransactionFiltersCubit build() =>
      TransactionFiltersCubit(categories, accounts);

  Future<TransactionFiltersCubit> ready([
    TransactionFilter current = const TransactionFilter(),
  ]) async {
    final cubit = build();
    await cubit.init(current);
    return cubit;
  }

  test(
    'init: текущий фильтр, период месяца узнаётся, архивные счета скрыты',
    () async {
      final month = DatePeriod.current(.month, DateTime.now());
      final cubit = await ready(
        TransactionFilter(period: month, accountId: 'card'),
      );

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.preset, PeriodPreset.month);
      expect(cubit.state.filter.accountId, 'card');
      expect(cubit.state.accounts.map((a) => a.id), ['card']);
    },
  );

  test('init: нестандартный период — custom', () async {
    final cubit = await ready(
      TransactionFilter(
        period: DatePeriod(
          start: DateTime(2026, 3, 1),
          end: DateTime(2026, 3, 16),
        ),
      ),
    );

    expect(cubit.state.preset, PeriodPreset.custom);
  });

  test('категории: верхний уровень под тип, у переводов нет', () async {
    final cubit = await ready();

    expect(cubit.state.categoryOptions, [food, salary]);
    cubit.setType(.income);
    expect(cubit.state.categoryOptions, [salary]);
    cubit.setType(.transfer);
    expect(cubit.state.categoryOptions, isEmpty);
  });

  test(
    'смена типа сбрасывает категорию чужого типа и оставляет свою',
    () async {
      final cubit = await ready();
      cubit
        ..setCategory('food')
        ..setType(.expense);
      expect(cubit.state.filter.categoryId, 'food');

      cubit.setType(.income);
      expect(cubit.state.filter.categoryId, isNull);
    },
  );

  test('период: пресет даёт текущий период, null — за всё время', () async {
    final cubit = await ready();

    cubit.setPeriod(.week);
    expect(
      cubit.state.filter.period,
      DatePeriod.current(.week, DateTime.now()),
    );
    expect(cubit.state.preset, PeriodPreset.week);

    final custom = DatePeriod(
      start: DateTime(2026, 3, 1),
      end: DateTime(2026, 3, 8),
    );
    cubit.setPeriod(.custom, custom: custom);
    expect(cubit.state.filter.period, custom);

    cubit.setPeriod(null);
    expect(cubit.state.filter.period, isNull);
    expect(cubit.state.preset, isNull);
  });

  test(
    'комбинация: период, категория, счёт, тип собираются в один фильтр',
    () async {
      final cubit = await ready();
      cubit
        ..setPeriod(.month)
        ..setType(.expense)
        ..setCategory('food')
        ..setAccount('card');

      expect(
        cubit.state.filter,
        TransactionFilter(
          type: .expense,
          period: DatePeriod.current(.month, DateTime.now()),
          categoryId: 'food',
          accountId: 'card',
        ),
      );
    },
  );

  test('сброс — фильтр по умолчанию', () async {
    final cubit = await ready(
      const TransactionFilter(type: .income, accountId: 'card'),
    );

    cubit.reset();

    expect(cubit.state.filter, const TransactionFilter());
    expect(cubit.state.preset, isNull);
  });

  blocTest<TransactionFiltersCubit, TransactionFiltersState>(
    'варианты не загрузились — failure',
    setUp: () =>
        when(() => categories.getCategories())
            .thenThrow(const NetworkFailure()),
    build: build,
    act: (cubit) => cubit.init(const TransactionFilter()),
    expect: () => [
      const TransactionFiltersState(
        isLoading: false,
        failure: NetworkFailure(),
      ),
    ],
  );
}
