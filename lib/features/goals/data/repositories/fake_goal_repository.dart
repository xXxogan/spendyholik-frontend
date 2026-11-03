import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/fake_backend/fake_backend.dart';
import 'package:spendyholik/features/goals/data/models/models.dart';
import 'package:spendyholik/features/goals/data/repositories/goal_repository.dart';

@LazySingleton(as: GoalRepository)
class FakeGoalRepository implements GoalRepository {
  FakeGoalRepository(this._backend, this._bus);

  final FakeBackend _backend;
  final DataChangeBus _bus;

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

  // Форма цели — T-19.
  @override
  Future<GoalModel> create(GoalDraft draft) => throw UnimplementedError();

  @override
  Future<GoalModel> update(String id, GoalDraft draft) =>
      throw UnimplementedError();

  @override
  Future<GoalModel> contribute(
    String goalId,
    int amount,
    String accountId,
  ) async {
    final updated = await _backend(() {
      _find(goalId);
      final account = _backend.accounts.firstWhere(
        (a) => a.id == accountId,
        orElse: () => throw const NotFoundFailure(),
      );
      if (amount > account.balance) {
        throw const ValidationFailure('amount', FieldError.exceedsBalance);
      }
      _backend.addContribution(goalId, amount, account);
      return _find(goalId);
    });
    _bus.emit({DataTopic.goals, DataTopic.accounts});
    return updated;
  }

  GoalModel _find(String id) => _backend.goals.firstWhere(
    (goal) => goal.id == id,
    orElse: () => throw const NotFoundFailure(),
  );
}
