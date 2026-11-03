import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/fake_backend/fake_backend.dart';
import 'package:spendyholik/features/debts/data/models/models.dart';
import 'package:spendyholik/features/debts/data/repositories/debt_repository.dart';

@LazySingleton(as: DebtRepository)
class FakeDebtRepository implements DebtRepository {
  FakeDebtRepository(this._backend, this._bus);

  final FakeBackend _backend;
  final DataChangeBus _bus;

  @override
  Future<List<DebtModel>> getDebts() => _backend(() {
    final all = _backend.debts.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return [...all.where((d) => !d.isClosed), ...all.where((d) => d.isClosed)];
  });

  @override
  Future<DebtModel> getDebt(String id) => _backend(() => _find(id));

  @override
  Future<List<DebtEvent>> getHistory(String id) => _backend(() {
    if (!_backend.debts.any((d) => d.id == id)) throw const NotFoundFailure();
    return _backend.debtEventsOf(id);
  });

  // Форма — T-24.
  @override
  Future<DebtModel> create(DebtDraft draft) => throw UnimplementedError();

  @override
  Future<DebtModel> update(String id, DebtDraft draft) =>
      throw UnimplementedError();

  @override
  Future<DebtModel> repay(String id, int amount, String accountId) async {
    final updated = await _backend(() {
      final debt = _find(id);
      final account = _backend.accounts.firstWhere(
        (a) => a.id == accountId,
        orElse: () => throw const NotFoundFailure(),
      );
      if (amount > debt.remaining) {
        throw const ValidationFailure('amount', FieldError.exceedsRemaining);
      }
      if (debt.direction == DebtDirection.iOwe && amount > account.balance) {
        throw const ValidationFailure('amount', FieldError.exceedsBalance);
      }
      _backend.addDebtRepayment(id, amount, account);
      return _find(id);
    });
    _bus.emit({DataTopic.debts, DataTopic.accounts});
    return updated;
  }

  DebtModel _find(String id) => _backend.debts.firstWhere(
    (d) => d.id == id,
    orElse: () => throw const NotFoundFailure(),
  );
}
