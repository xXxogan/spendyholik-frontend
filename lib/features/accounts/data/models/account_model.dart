import 'package:spendyholik/core/models/currency.dart';
import 'package:spendyholik/core/models/entity_color.dart';

enum AccountType { debit, cash, savings, credit }

class AccountModel {
  const AccountModel({
    required this.id,
    required this.currency,
    required this.name,
    required this.type,
    required this.balance,
    required this.color,
    required this.isArchived,
    this.cardLast4,
    this.interestRate,
    this.creditLimit,
  });

  final String id;
  final Currency currency;
  final String name;
  final AccountType type;
  final int balance;
  final EntityColor color;
  final bool isArchived;
  final String? cardLast4;
  final double? interestRate;
  final int? creditLimit;

  AccountModel copyWith({int? balance, bool? isArchived, Currency? currency}) =>
      AccountModel(
        id: id,
        currency: currency ?? this.currency,
        name: name,
        type: type,
        balance: balance ?? this.balance,
        color: color,
        isArchived: isArchived ?? this.isArchived,
        cardLast4: cardLast4,
        interestRate: interestRate,
        creditLimit: creditLimit,
      );
}

class AccountRef {
  const AccountRef({required this.id, required this.name, required this.color});

  final String id;
  final String name;
  final EntityColor color;
}

class TotalBalance {
  const TotalBalance({required this.total, required this.monthDelta});

  final int total;
  final int monthDelta;
}

class BalancePoint {
  const BalancePoint({required this.at, required this.balance});

  /// Баланс сразу после этого момента.
  final DateTime at;
  final int balance;
}

class AccountDraft {
  const AccountDraft({
    required this.name,
    required this.type,
    required this.balance,
    required this.color,
    this.cardLast4,
    this.interestRate,
    this.creditLimit,
  });

  final String name;
  final AccountType type;

  /// При создании — начальный баланс, при правке — желаемый текущий:
  /// сервер сдвигает начальный, операции не трогает.
  final int balance;
  final EntityColor color;
  final String? cardLast4;
  final double? interestRate;
  final int? creditLimit;
}
