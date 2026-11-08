import 'package:spendyholik/features/transactions/data/models/transaction_model.dart';

class TransactionPage {
  const TransactionPage({required this.items, this.nextCursor});

  /// По убыванию [TransactionModel.occurredAt].
  final List<TransactionModel> items;

  /// null — страница последняя.
  final String? nextCursor;
}
