import 'package:spendyholik/features/goals/data/models/models.dart';

/// Все методы бросают только [Failure] из `core/errors`.
abstract interface class GoalRepository {
  Future<List<GoalModel>> getGoals();

  /// [NotFoundFailure], если цели нет.
  Future<GoalModel> getGoal(String id);

  /// По дате, новые первыми.
  Future<List<GoalContribution>> getContributions(String goalId);

  /// Начальный взнос списывается с `initialAccountId`:
  /// `ValidationFailure('initialContribution', exceedsBalance)`, если на счёте меньше.
  Future<GoalModel> create(GoalDraft draft);

  /// Меняет имя, сумму и срок; `initialContribution` при правке не учитывается.
  Future<GoalModel> update(String id, GoalDraft draft);

  /// Пополнения удаляются вместе с целью — деньги возвращаются на счета.
  Future<void> delete(String id);

  /// `ValidationFailure('amount', exceedsBalance)`, если на счёте меньше [amount].
  Future<GoalModel> contribute(String goalId, int amount, String accountId);
}
