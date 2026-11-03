import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/fake_backend/fake_backend.dart';
import 'package:spendyholik/features/budgets/data/models/models.dart';
import 'package:spendyholik/features/budgets/data/repositories/budget_repository.dart';

@LazySingleton(as: BudgetRepository)
class FakeBudgetRepository implements BudgetRepository {
  FakeBudgetRepository(this._backend, this._bus);

  final FakeBackend _backend;
  final DataChangeBus _bus;

  @override
  Future<List<BudgetModel>> getBudgets() => _backend(() => _backend.budgets);

  @override
  Future<BudgetModel> getBudget(String id) => _backend(() => _find(id));

  @override
  Future<BudgetModel> create(BudgetDraft draft) async {
    final created = await _backend(() {
      _checkCategoryFree(draft.categoryId);
      return _find(_backend.addBudget(draft));
    });
    _bus.emit({DataTopic.budgets});
    return created;
  }

  @override
  Future<BudgetModel> update(String id, BudgetDraft draft) async {
    final updated = await _backend(() {
      _checkCategoryFree(draft.categoryId, except: id);
      _backend.updateBudget(id, draft);
      return _find(id);
    });
    _bus.emit({DataTopic.budgets});
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    await _backend(() => _backend.deleteBudget(id));
    _bus.emit({DataTopic.budgets});
  }

  void _checkCategoryFree(String categoryId, {String? except}) {
    final taken = _backend.budgets.any(
      (b) => b.category.id == categoryId && b.id != except,
    );
    if (taken) {
      throw const ValidationFailure('categoryId', FieldError.alreadyExists);
    }
  }

  BudgetModel _find(String id) => _backend.budgets.firstWhere(
    (budget) => budget.id == id,
    orElse: () => throw const NotFoundFailure(),
  );
}
