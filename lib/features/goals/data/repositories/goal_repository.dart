import 'package:spendyholik/features/goals/data/models/models.dart';

/// Все методы бросают только [Failure] из `core/errors`.
abstract interface class GoalRepository {
  Future<List<GoalModel>> getGoals();

  /// [NotFoundFailure], если цели нет.
  Future<GoalModel> getGoal(String id);

  /// По дате, новые первыми.
  Future<List<GoalContribution>> getContributions(String goalId);

  Future<GoalModel> create(GoalDraft draft);

  Future<GoalModel> update(String id, GoalDraft draft);

  /// `ValidationFailure('amount', exceedsBalance)`, если на счёте меньше [amount].
  Future<GoalModel> contribute(String goalId, int amount, String accountId);
}
