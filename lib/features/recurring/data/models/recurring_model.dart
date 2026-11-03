import 'package:spendyholik/features/accounts/accounts.dart';
import 'package:spendyholik/features/categories/categories.dart';
import 'package:spendyholik/features/transactions/transactions.dart';

enum RecurrenceFrequency {
  weekly,
  monthly,
  yearly;

  /// Первое выполнение строго после [from]; якорь в будущем — сам якорь.
  /// Monthly с якорем 31-го в коротких месяцах — последний день месяца,
  /// затем снова 31-е; yearly с 29 февраля — 28-е в невисокосные годы.
  DateTime nextAfter(DateTime anchor, DateTime from) {
    for (var k = 0; ; k++) {
      final occurrence = _occurrence(anchor, k);
      if (occurrence.isAfter(from)) return occurrence;
    }
  }

  DateTime _occurrence(DateTime anchor, int k) => switch (this) {
    weekly => DateTime(
      anchor.year,
      anchor.month,
      anchor.day + 7 * k,
      anchor.hour,
      anchor.minute,
    ),
    monthly => _clamped(anchor, anchor.year, anchor.month + k),
    yearly => _clamped(anchor, anchor.year + k, anchor.month),
  };

  static DateTime _clamped(DateTime anchor, int year, int month) {
    // День 0 следующего месяца — последний день этого.
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = anchor.day < lastDay ? anchor.day : lastDay;
    return DateTime(year, month, day, anchor.hour, anchor.minute);
  }
}

class RecurringModel {
  const RecurringModel({
    required this.id,
    required this.title,
    required this.type,
    required this.amount,
    required this.category,
    required this.account,
    required this.frequency,
    required this.anchor,
    required this.nextDate,
    required this.isPaused,
  });

  final String id;
  final String title;

  /// Только expense или income.
  final TransactionType type;
  final int amount;
  final CategoryRef category;
  final AccountRef account;
  final RecurrenceFrequency frequency;

  /// Первое выполнение.
  final DateTime anchor;
  final DateTime nextDate;
  final bool isPaused;
}

class RecurringDraft {
  const RecurringDraft({
    required this.title,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.accountId,
    required this.frequency,
    required this.anchor,
  });

  final String title;
  final TransactionType type;
  final int amount;
  final String categoryId;
  final String accountId;
  final RecurrenceFrequency frequency;
  final DateTime anchor;
}
