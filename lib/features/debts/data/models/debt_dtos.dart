import 'package:json_annotation/json_annotation.dart';
import 'package:spendyholik/core/models/money_dto.dart';

part 'debt_dtos.g.dart';

/// toJson у ответов — для кэша чтения.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class DebtOutDto {
  const DebtOutDto({
    required this.id,
    required this.personName,
    required this.direction,
    required this.amount,
    required this.remaining,
    this.dueDate,
    this.note = '',
    this.createdAt,
  });

  factory DebtOutDto.fromJson(Map<String, dynamic> json) =>
      _$DebtOutDtoFromJson(json);

  final String id;
  final String personName;

  /// i_owe | owed_to_me.
  final String direction;
  final MoneyDto amount;
  final MoneyDto remaining;

  /// yyyy-MM-dd.
  final String? dueDate;
  final String note;
  final String? createdAt;

  Map<String, dynamic> toJson() => _$DebtOutDtoToJson(this);
}

@JsonSerializable()
class DebtAccountRefDto {
  const DebtAccountRefDto({
    required this.id,
    required this.name,
    required this.color,
  });

  factory DebtAccountRefDto.fromJson(Map<String, dynamic> json) =>
      _$DebtAccountRefDtoFromJson(json);

  final String id;
  final String name;
  final String color;

  Map<String, dynamic> toJson() => _$DebtAccountRefDtoToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class DebtEventOutDto {
  const DebtEventOutDto({
    required this.id,
    required this.kind,
    required this.amount,
    required this.date,
    this.account,
  });

  factory DebtEventOutDto.fromJson(Map<String, dynamic> json) =>
      _$DebtEventOutDtoFromJson(json);

  final String id;

  /// opened | repayment.
  final String kind;
  final MoneyDto amount;
  final String date;

  /// null у открытия долга.
  final DebtAccountRefDto? account;

  Map<String, dynamic> toJson() => _$DebtEventOutDtoToJson(this);
}

/// Остальные поля ответа не нужны: после погашения читаем долг заново.
@JsonSerializable(createToJson: false)
class DebtPaymentOutDto {
  const DebtPaymentOutDto({required this.id});

  factory DebtPaymentOutDto.fromJson(Map<String, dynamic> json) =>
      _$DebtPaymentOutDtoFromJson(json);

  final String id;
}

@JsonSerializable(createFactory: false, fieldRename: FieldRename.snake)
class DebtCreateBody {
  const DebtCreateBody({
    required this.personName,
    required this.direction,
    required this.amountMinor,
    required this.currency,
    required this.note,
    this.dueDate,
  });

  final String personName;
  final String direction;
  final int amountMinor;
  final String currency;
  final String? dueDate;

  /// Пустая заметка — "": сервер не принимает null.
  final String note;

  Map<String, dynamic> toJson() => _$DebtCreateBodyToJson(this);
}

/// null в PATCH сервер принимает только для `due_date` (так срок снимается);
/// направление и валюта не меняются.
@JsonSerializable(createFactory: false, fieldRename: FieldRename.snake)
class DebtPatchBody {
  const DebtPatchBody({
    required this.personName,
    required this.amountMinor,
    required this.note,
    this.dueDate,
  });

  final String personName;
  final int amountMinor;
  final String? dueDate;
  final String note;

  Map<String, dynamic> toJson() => _$DebtPatchBodyToJson(this);
}

@JsonSerializable(createFactory: false, fieldRename: FieldRename.snake)
class RepayBody {
  const RepayBody({
    required this.accountId,
    required this.amountMinor,
    required this.date,
  });

  final String accountId;
  final int amountMinor;
  final String date;

  Map<String, dynamic> toJson() => _$RepayBodyToJson(this);
}
