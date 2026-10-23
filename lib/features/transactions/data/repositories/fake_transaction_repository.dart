import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/fake_backend/fake_backend.dart';
import 'package:spendyholik/features/accounts/data/models/models.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';
import 'package:spendyholik/features/transactions/data/repositories/transaction_repository.dart';

@LazySingleton(as: TransactionRepository)
class FakeTransactionRepository implements TransactionRepository {
  FakeTransactionRepository(this._backend, this._bus);

  final FakeBackend _backend;
  final DataChangeBus _bus;

  @override
  Future<List<TransactionModel>> getTransactions(TransactionFilter filter) =>
      _backend(() {
        final categoryIds = switch (filter.categoryId) {
          final id? => {
            id,
            for (final category in _backend.categories)
              if (category.parentId == id) category.id,
          },
          null => null,
        };
        final matching = _backend.transactions.where((t) {
          if (filter.type case final type? when t.type != type) {
            return false;
          }
          if (filter.period case final period?
              when !period.contains(t.occurredAt)) {
            return false;
          }
          if (categoryIds != null && !categoryIds.contains(t.category?.id)) {
            return false;
          }
          if (filter.accountId case final id?
              when t.account.id != id && t.toAccount?.id != id) {
            return false;
          }
          return true;
        }).toList()..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

        return switch (filter.limit) {
          final limit? => matching.take(limit).toList(),
          null => matching,
        };
      });

  @override
  Future<TransactionModel> getTransaction(String id) => _backend(
    () => _backend.transactions.firstWhere(
      (t) => t.id == id,
      orElse: () => throw const NotFoundFailure(),
    ),
  );

  @override
  Future<TransactionModel> create(TransactionDraft draft) async {
    final created = await _backend(() {
      final transaction = _fromDraft(
        'tx-${DateTime.now().microsecondsSinceEpoch}',
        draft,
      );
      _backend.addTransaction(transaction);
      return transaction;
    });
    _bus.emit(_changedTopics);
    return created;
  }

  @override
  Future<TransactionModel> update(String id, TransactionDraft draft) async {
    final updated = await _backend(() {
      final transaction = _fromDraft(id, draft);
      _backend.replaceTransaction(transaction);
      return transaction;
    });
    _bus.emit(_changedTopics);
    return updated;
  }

  @override
  Future<void> delete(String id) => _backend(() {
    _backend.deleteTransaction(id);
    _bus.emit(_changedTopics);
  });

  /// Категории — из-за счётчиков операций у них.
  static const _changedTopics = {
    DataTopic.transactions,
    DataTopic.accounts,
    DataTopic.budgets,
    DataTopic.categories,
  };

  TransactionModel _fromDraft(String id, TransactionDraft draft) {
    AccountRef account(String accountId) {
      final a = _backend.accounts.firstWhere(
        (a) => a.id == accountId,
        orElse: () => throw const NotFoundFailure(),
      );
      return AccountRef(id: a.id, name: a.name, color: a.color);
    }

    return TransactionModel(
      id: id,
      type: draft.type,
      amount: draft.amount,
      title: draft.title,
      category: switch (draft.categoryId) {
        final categoryId? =>
          _backend.categories
              .firstWhere(
                (c) => c.id == categoryId,
                orElse: () => throw const NotFoundFailure(),
              )
              .toRef(),
        null => null,
      },
      account: account(draft.accountId),
      toAccount: switch (draft.toAccountId) {
        final toAccountId? => account(toAccountId),
        null => null,
      },
      occurredAt: draft.occurredAt,
      note: draft.note,
    );
  }
}
