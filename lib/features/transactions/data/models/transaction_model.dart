import 'package:spendyholik/features/accounts/accounts.dart';
import 'package:spendyholik/features/categories/categories.dart';

enum TransactionType { expense, income, transfer }

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.title,
    required this.account,
    required this.occurredAt,
    this.category,
    this.toAccount,
    this.note,
  });

  final String id;
  final TransactionType type;
  final int amount;
  final String title;
  final CategoryRef? category;
  final AccountRef account;
  final AccountRef? toAccount;
  final DateTime occurredAt;
  final String? note;
}
