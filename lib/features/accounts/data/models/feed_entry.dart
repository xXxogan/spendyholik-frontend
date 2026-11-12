import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/debts/debts.dart';
import 'package:spendyholik/features/transactions/transactions.dart';

/// Как запись меняет баланс счёта, по которому открыта лента.
enum FeedEffect { incoming, outgoing }

sealed class FeedEntry {
  const FeedEntry({
    required this.id,
    required this.date,
    required this.amount,
    required this.currency,
    required this.effect,
  });

  /// Id операции, долга (открытие), погашения или пополнения — уникален
  /// только вместе с видом записи, поэтому для сверки страниц есть [key].
  final String id;

  /// День записи, без времени.
  final DateTime date;
  final int amount;
  final Currency currency;
  final FeedEffect effect;

  String get key;
}

class FeedTransaction extends FeedEntry {
  const FeedTransaction({
    required super.id,
    required super.date,
    required super.amount,
    required super.currency,
    required super.effect,
    required this.transaction,
  });

  final TransactionModel transaction;

  @override
  String get key => 'transaction:$id';
}

class FeedDebtEvent extends FeedEntry {
  const FeedDebtEvent({
    required super.id,
    required super.date,
    required super.amount,
    required super.currency,
    required super.effect,
    required this.debtId,
    required this.personName,
    required this.direction,
    required this.opening,
  });

  final String debtId;
  final String personName;
  final DebtDirection direction;

  /// true — заём получен или выдан, false — погашение.
  final bool opening;

  @override
  String get key => '${opening ? 'debt_opening' : 'debt_payment'}:$id';
}

class FeedGoalContribution extends FeedEntry {
  const FeedGoalContribution({
    required super.id,
    required super.date,
    required super.amount,
    required super.currency,
    required super.effect,
    required this.goalId,
    required this.goalName,
  });

  final String goalId;
  final String goalName;

  @override
  String get key => 'goal_contribution:$id';
}
