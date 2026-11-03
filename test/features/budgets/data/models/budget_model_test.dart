import 'package:flutter_test/flutter_test.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/budgets/data/models/budget_model.dart';
import 'package:spendyholik/features/categories/categories.dart';

BudgetModel budget({required int spent, int limit = 1000000}) => BudgetModel(
  id: 'b1',
  category: const CategoryRef(
    id: 'cat-groceries',
    name: 'Продукты',
    icon: EntityIcon.cart,
    color: EntityColor.green,
  ),
  limit: limit,
  spent: spent,
  period: BudgetPeriod.monthly,
  currentPeriod: DatePeriod(start: DateTime(2026, 11), end: DateTime(2026, 12)),
);

void main() {
  group('status', () {
    test('79% — ok', () {
      expect(budget(spent: 790000).status, BudgetStatus.ok);
    });

    test('80% — warning', () {
      expect(budget(spent: 800000).status, BudgetStatus.warning);
    });

    test('100% — ещё warning', () {
      expect(budget(spent: 1000000).status, BudgetStatus.warning);
    });

    test('101% — exceeded', () {
      expect(budget(spent: 1010000).status, BudgetStatus.exceeded);
    });
  });

  test('остаток и прогресс: 14 230 из 20 000', () {
    final model = budget(spent: 1423000, limit: 2000000);

    expect(model.remaining, 577000);
    expect(model.progress, closeTo(0.7115, 1e-4));
  });

  test('превышение — остаток отрицательный, прогресс больше 1', () {
    final model = budget(spent: 1200000);

    expect(model.remaining, -200000);
    expect(model.progress, 1.2);
  });
}
