import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/fake_backend/fake_backend.dart';
import 'package:spendyholik/features/goals/data/models/models.dart';
import 'package:spendyholik/features/goals/data/repositories/goal_repository.dart';

@LazySingleton(as: GoalRepository)
class FakeGoalRepository implements GoalRepository {
  FakeGoalRepository(this._backend);

  final FakeBackend _backend;

  @override
  Future<List<GoalModel>> getGoals() => _backend(() => _backend.goals);

  @override
  Future<GoalModel> getGoal(String id) => _backend(() => _find(id));

  @override
  Future<List<GoalContribution>> getContributions(String goalId) =>
      _backend(() {
        _find(goalId);
        return _backend.contributionsOf(goalId);
      });

  // Пополнение — T-18, форма цели — T-19: там же шина изменений.
  @override
  Future<GoalModel> create(GoalDraft draft) => throw UnimplementedError();

  @override
  Future<GoalModel> update(String id, GoalDraft draft) =>
      throw UnimplementedError();

  @override
  Future<GoalModel> contribute(String goalId, int amount, String accountId) =>
      throw UnimplementedError();

  GoalModel _find(String id) => _backend.goals.firstWhere(
    (goal) => goal.id == id,
    orElse: () => throw const NotFoundFailure(),
  );
}
