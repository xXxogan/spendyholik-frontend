import 'package:spendyholik/core/models/currency.dart';
import 'package:spendyholik/features/accounts/accounts.dart';

enum DebtDirection { iOwe, owedToMe }

enum DebtEventKind { opened, repayment }

class DebtModel {
  const DebtModel({
    required this.id,
    required this.currency,
    required this.counterparty,
    required this.direction,
    required this.total,
    required this.remaining,
    required this.createdAt,
    this.dueDate,
    this.note,
  });

  final String id;
  final Currency currency;
  final String counterparty;
  final DebtDirection direction;
  final int total;

  /// 0 ≤ remaining ≤ total.
  final int remaining;
  final DateTime? dueDate;
  final String? note;
  final DateTime createdAt;

  bool get isClosed => remaining == 0;

  /// Сравниваются даты без времени: срок «сегодня» ещё не просрочен.
  bool isOverdue(DateTime today) {
    final due = dueDate;
    if (isClosed || due == null) return false;
    return DateTime(
      due.year,
      due.month,
      due.day,
    ).isBefore(DateTime(today.year, today.month, today.day));
  }
}

class DebtEvent {
  const DebtEvent({
    required this.id,
    required this.kind,
    required this.amount,
    required this.date,
    this.account,
  });

  final String id;
  final DebtEventKind kind;
  final int amount;
  final DateTime date;

  /// Только у погашения; открытие долга счёт не трогает.
  final AccountRef? account;
}

class DebtDraft {
  const DebtDraft({
    required this.counterparty,
    required this.direction,
    required this.amount,
    this.dueDate,
    this.note,
    this.accountId,
    this.currency,
    this.openedOn,
  });

  final String counterparty;
  final DebtDirection direction;
  final int amount;
  final DateTime? dueDate;
  final String? note;

  /// Только при создании: счёт, через который прошёл заём, и его дата.
  final String? accountId;
  final DateTime? openedOn;

  /// Валюта счёта: сервер требует её совпадения с валютой долга. null — базовая.
  final Currency? currency;
}
