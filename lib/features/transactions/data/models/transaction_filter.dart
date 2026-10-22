import 'package:spendyholik/core/models/date_period.dart';
import 'package:spendyholik/features/transactions/data/models/transaction_model.dart';

class TransactionFilter {
  const TransactionFilter({
    this.type,
    this.period,
    this.categoryId,
    this.accountId,
    this.limit,
  });

  /// null — все типы.
  final TransactionType? type;
  final DatePeriod? period;

  /// Включая подкатегории.
  final String? categoryId;

  /// Счёт и как источник, и как получатель перевода.
  final String? accountId;
  final int? limit;

  TransactionFilter withType(TransactionType? type) => TransactionFilter(
    type: type,
    period: period,
    categoryId: categoryId,
    accountId: accountId,
    limit: limit,
  );

  @override
  bool operator ==(Object other) =>
      other is TransactionFilter &&
      other.type == type &&
      other.period == period &&
      other.categoryId == categoryId &&
      other.accountId == accountId &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(type, period, categoryId, accountId, limit);
}
