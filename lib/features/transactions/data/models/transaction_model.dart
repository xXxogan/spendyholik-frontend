import 'package:spendyholik/core/models/currency.dart';
import 'package:spendyholik/features/accounts/accounts.dart';
import 'package:spendyholik/features/categories/categories.dart';

enum TransactionType { expense, income, transfer }

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.currency,
    required this.type,
    required this.amount,
    required this.title,
    required this.account,
    required this.occurredAt,
    this.hasTime = true,
    this.category,
    this.toAccount,
    this.note,
  });

  final String id;

  /// Валюта счёта операции.
  final Currency currency;
  final TransactionType type;
  final int amount;
  final String title;
  final CategoryRef? category;
  final AccountRef account;
  final AccountRef? toAccount;
  final DateTime occurredAt;
  final bool hasTime;
  final String? note;
}

class TransactionDraft {
  const TransactionDraft({
    required this.type,
    required this.amount,
    required this.title,
    required this.accountId,
    required this.occurredAt,
    this.hasTime = true,
    this.categoryId,
    this.toAccountId,
    this.note,
  });

  final TransactionType type;
  final int amount;
  final String title;
  final String? categoryId;
  final String accountId;
  final String? toAccountId;
  final DateTime occurredAt;
  final bool hasTime;
  final String? note;
}

class TransactionDayGroup {
  const TransactionDayGroup({required this.day, required this.items});

  /// Начало дня.
  final DateTime day;
  final List<TransactionModel> items;
}
