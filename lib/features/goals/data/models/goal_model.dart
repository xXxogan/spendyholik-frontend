import 'package:spendyholik/features/accounts/accounts.dart';

class GoalModel {
  const GoalModel({
    required this.id,
    required this.name,
    required this.target,
    required this.saved,
    this.deadline,
  });

  final String id;
  final String name;
  final int target;
  final int saved;
  final DateTime? deadline;

  int get remaining => saved >= target ? 0 : target - saved;

  /// Не больше 1, даже если накоплено сверх цели.
  double get progress => saved >= target ? 1 : saved / target;

  bool get isReached => saved >= target;

  GoalModel copyWith({int? saved}) => GoalModel(
    id: id,
    name: name,
    target: target,
    saved: saved ?? this.saved,
    deadline: deadline,
  );
}

class GoalContribution {
  const GoalContribution({
    required this.id,
    required this.amount,
    required this.from,
    required this.date,
  });

  final String id;
  final int amount;
  final AccountRef from;
  final DateTime date;
}

class GoalDraft {
  const GoalDraft({
    required this.name,
    required this.target,
    required this.initialContribution,
    this.initialAccountId,
    this.deadline,
  });

  final String name;
  final int target;
  final int initialContribution;

  /// Обязателен, если [initialContribution] > 0.
  final String? initialAccountId;
  final DateTime? deadline;
}
