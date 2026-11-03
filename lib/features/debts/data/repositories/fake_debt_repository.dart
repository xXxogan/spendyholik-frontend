import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/fake_backend/fake_backend.dart';
import 'package:spendyholik/features/debts/data/models/models.dart';
import 'package:spendyholik/features/debts/data/repositories/debt_repository.dart';

@LazySingleton(as: DebtRepository)
class FakeDebtRepository implements DebtRepository {
  FakeDebtRepository(this._backend);

  final FakeBackend _backend;

  @override
  Future<List<DebtModel>> getDebts() => _backend(() {
    final all = _backend.debts.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return [...all.where((d) => !d.isClosed), ...all.where((d) => d.isClosed)];
  });

  @override
  Future<DebtModel> getDebt(String id) => _backend(
    () => _backend.debts.firstWhere(
      (d) => d.id == id,
      orElse: () => throw const NotFoundFailure(),
    ),
  );

  @override
  Future<List<DebtEvent>> getHistory(String id) => _backend(() {
    if (!_backend.debts.any((d) => d.id == id)) throw const NotFoundFailure();
    return _backend.debtEventsOf(id);
  });

  // Погашение — T-23, форма — T-24.
  @override
  Future<DebtModel> create(DebtDraft draft) => throw UnimplementedError();

  @override
  Future<DebtModel> update(String id, DebtDraft draft) =>
      throw UnimplementedError();

  @override
  Future<DebtModel> repay(String id, int amount, String accountId) =>
      throw UnimplementedError();
}
