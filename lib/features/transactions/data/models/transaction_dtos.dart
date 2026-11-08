import 'package:json_annotation/json_annotation.dart';
import 'package:spendyholik/core/models/money_dto.dart';

part 'transaction_dtos.g.dart';

/// toJson у ответов — для кэша чтения.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class TransactionPageDto {
  const TransactionPageDto({required this.items, this.nextCursor});

  factory TransactionPageDto.fromJson(Map<String, dynamic> json) =>
      _$TransactionPageDtoFromJson(json);

  final List<TransactionOutDto> items;
  final String? nextCursor;

  Map<String, dynamic> toJson() => _$TransactionPageDtoToJson(this);
}

/// Вложение `receipt` не читается: чеков в приложении нет.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class TransactionOutDto {
  const TransactionOutDto({
    required this.id,
    required this.type,
    required this.amount,
    required this.title,
    required this.account,
    required this.date,
    this.category,
    this.transferToAccount,
    this.time,
    this.note,
  });

  factory TransactionOutDto.fromJson(Map<String, dynamic> json) =>
      _$TransactionOutDtoFromJson(json);

  final String id;
  final String type;
  final MoneyDto amount;
  final String title;
  final CategoryRefDto? category;
  final AccountRefDto account;
  final AccountRefDto? transferToAccount;

  /// yyyy-MM-dd.
  final String date;

  /// HH:mm:ss или null.
  final String? time;
  final String? note;

  Map<String, dynamic> toJson() => _$TransactionOutDtoToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class CategoryRefDto {
  const CategoryRefDto({required this.id, this.name, this.icon, this.color});

  factory CategoryRefDto.fromJson(Map<String, dynamic> json) =>
      _$CategoryRefDtoFromJson(json);

  final String id;
  final String? name;
  final String? icon;
  final String? color;

  Map<String, dynamic> toJson() => _$CategoryRefDtoToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class AccountRefDto {
  const AccountRefDto({
    required this.id,
    required this.name,
    required this.color,
  });

  factory AccountRefDto.fromJson(Map<String, dynamic> json) =>
      _$AccountRefDtoFromJson(json);

  final String id;
  final String name;
  final String color;

  Map<String, dynamic> toJson() => _$AccountRefDtoToJson(this);
}

/// null уходит явно: так сервер очищает `category_id`, `time`,
/// `transfer_to_account_id`. `note` null не принимает — пустая строка.
@JsonSerializable(createFactory: false, fieldRename: FieldRename.snake)
class TransactionCreateBody {
  const TransactionCreateBody({
    required this.accountId,
    required this.type,
    required this.amountMinor,
    required this.date,
    required this.title,
    required this.note,
    this.categoryId,
    this.time,
    this.transferToAccountId,
  });

  final String accountId;
  final String type;
  final int amountMinor;

  /// yyyy-MM-dd.
  final String date;
  final String? categoryId;

  /// HH:mm:ss.
  final String? time;
  final String note;
  final String title;
  final String? transferToAccountId;

  Map<String, dynamic> toJson() => _$TransactionCreateBodyToJson(this);
}

/// Без `type`: сервер не меняет тип существующей операции.
@JsonSerializable(createFactory: false, fieldRename: FieldRename.snake)
class TransactionPatchBody {
  const TransactionPatchBody({
    required this.accountId,
    required this.amountMinor,
    required this.date,
    required this.title,
    required this.note,
    this.categoryId,
    this.time,
    this.transferToAccountId,
  });

  final String accountId;
  final int amountMinor;
  final String date;
  final String? categoryId;
  final String? time;
  final String note;
  final String title;
  final String? transferToAccountId;

  Map<String, dynamic> toJson() => _$TransactionPatchBodyToJson(this);
}
