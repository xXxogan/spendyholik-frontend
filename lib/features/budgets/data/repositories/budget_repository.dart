import 'package:spendyholik/features/budgets/data/models/models.dart';

/// Все методы бросают только [Failure] из `core/errors`.
abstract interface class BudgetRepository {
  Future<List<BudgetModel>> getBudgets();

  /// [NotFoundFailure], если бюджета нет.
  Future<BudgetModel> getBudget(String id);

  /// `ValidationFailure('categoryId', …)`, если на категорию уже есть бюджет.
  Future<BudgetModel> create(BudgetDraft draft);

  Future<BudgetModel> update(String id, BudgetDraft draft);

  /// Операции категории не трогает. [NotFoundFailure], если бюджета нет.
  Future<void> delete(String id);
}
