import 'package:json_annotation/json_annotation.dart';
import 'package:spendyholik/core/models/money_dto.dart';

part 'account_dtos.g.dart';

/// toJson у ответов — для кэша чтения.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class AccountOutDto {
  const AccountOutDto({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.balance,
    required this.color,
    required this.interestRate,
    required this.isArchived,
    this.last4,
    this.creditLimit,
  });

  factory AccountOutDto.fromJson(Map<String, dynamic> json) =>
      _$AccountOutDtoFromJson(json);

  final String id;
  final String name;
  final String type;
  final String currency;
  final MoneyDto balance;
  final String color;
  final String? last4;
  final MoneyDto? creditLimit;

  /// Десятичная строка: «0», «7.50».
  final String interestRate;
  final bool isArchived;

  Map<String, dynamic> toJson() => _$AccountOutDtoToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BalancePointOutDto {
  const BalancePointOutDto({required this.at, required this.balance});

  factory BalancePointOutDto.fromJson(Map<String, dynamic> json) =>
      _$BalancePointOutDtoFromJson(json);

  final DateTime at;
  final MoneyDto balance;

  Map<String, dynamic> toJson() => _$BalancePointOutDtoToJson(this);
}

/// Бюджеты и доходы/расходы месяца из ответа не читаются: им есть свои экраны.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class DashboardOutDto {
  const DashboardOutDto({
    required this.totalBalance,
    required this.netThisMonth,
  });

  factory DashboardOutDto.fromJson(Map<String, dynamic> json) =>
      _$DashboardOutDtoFromJson(json);

  final MoneyDto totalBalance;
  final MoneyDto netThisMonth;

  Map<String, dynamic> toJson() => _$DashboardOutDtoToJson(this);
}

@JsonSerializable(createFactory: false, fieldRename: FieldRename.snake)
class AccountCreateBody {
  const AccountCreateBody({
    required this.name,
    required this.type,
    required this.currency,
    required this.initialBalanceMinor,
    required this.color,
    required this.interestRate,
    this.last4,
    this.creditLimitMinor,
  });

  final String name;
  final String type;
  final String currency;
  final int initialBalanceMinor;
  final String color;
  final String? last4;
  final int? creditLimitMinor;
  final String interestRate;

  Map<String, dynamic> toJson() => _$AccountCreateBodyToJson(this);
}

/// null в `last4` и `credit_limit_minor` уходит явно: так поле очищается.
@JsonSerializable(createFactory: false, fieldRename: FieldRename.snake)
class AccountPatchBody {
  const AccountPatchBody({
    required this.name,
    required this.type,
    required this.balanceMinor,
    required this.color,
    required this.interestRate,
    this.last4,
    this.creditLimitMinor,
  });

  final String name;
  final String type;
  final int balanceMinor;
  final String color;
  final String? last4;
  final int? creditLimitMinor;
  final String interestRate;

  Map<String, dynamic> toJson() => _$AccountPatchBodyToJson(this);
}
