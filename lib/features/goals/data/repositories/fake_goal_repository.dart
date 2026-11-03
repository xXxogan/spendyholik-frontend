import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/fake_backend/fake_backend.dart';
import 'package:spendyholik/features/accounts/accounts.dart';
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

  @override
  Future<GoalModel> create(GoalDraft draft) async {
    final created = await _backend(() {
      final from = draft.initialContribution > 0
          ? _account(draft.initialAccountId!)
          : null;
      if (from != null && draft.initialContribution > from.balance) {
        throw const ValidationFailure(
          'initialContribution',
          FieldError.exceedsBalance,
        );
      }
      final goal = _backend.addGoal(draft);
      if (from != null) {
        _backend.addContribution(goal.id, draft.initialContribution, from);
      }
      return _find(goal.id);
    });
    _bus.emit({DataTopic.goals, DataTopic.accounts});
    return created;
  }

  @override
  Future<GoalModel> update(String id, GoalDraft draft) async {
    final updated = await _backend(() {
      _backend.updateGoal(id, draft);
      return _find(id);
    });
    _bus.emit({DataTopic.goals});
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    await _backend(() => _backend.deleteGoal(id));
    _bus.emit({DataTopic.goals, DataTopic.accounts});
  }

  @override
  Future<GoalModel> contribute(
    String goalId,
    int amount,
    String accountId,
  ) async {
    final updated = await _backend(() {
      _find(goalId);
      final account = _account(accountId);
      if (amount > account.balance) {
        throw const ValidationFailure('amount', FieldError.exceedsBalance);
      }
      _backend.addContribution(goalId, amount, account);
      return _find(goalId);
    });
    _bus.emit({DataTopic.goals, DataTopic.accounts});
    return updated;
  }

  AccountModel _account(String id) => _backend.accounts.firstWhere(
    (a) => a.id == id,
    orElse: () => throw const NotFoundFailure(),
  );

  GoalModel _find(String id) => _backend.goals.firstWhere(
    (goal) => goal.id == id,
    orElse: () => throw const NotFoundFailure(),
  );
}
