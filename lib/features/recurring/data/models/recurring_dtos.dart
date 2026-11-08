import 'package:json_annotation/json_annotation.dart';
import 'package:spendyholik/core/models/money_dto.dart';

part 'recurring_dtos.g.dart';

/// toJson у ответов — для кэша чтения.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class RecurringOutDto {
  const RecurringOutDto({
    required this.id,
    required this.name,
    required this.amount,
    required this.type,
    required this.accountId,
    required this.frequency,
    required this.nextRun,
    required this.isActive,
    this.categoryId,
    this.account,
    this.category,
    this.anchorDate,
  });

  factory RecurringOutDto.fromJson(Map<String, dynamic> json) =>
      _$RecurringOutDtoFromJson(json);

  final String id;
  final String name;
  final MoneyDto amount;

  /// expense | income.
  final String type;
  final String accountId;
  final String? categoryId;
  final RecurringAccountRefDto? account;
  final RecurringCategoryRefDto? category;

  /// weekly | monthly | yearly.
  final String frequency;

  /// yyyy-MM-dd.
  final String? anchorDate;

  /// yyyy-MM-dd.
  final String nextRun;
  final bool isActive;

  Map<String, dynamic> toJson() => _$RecurringOutDtoToJson(this);
}

@JsonSerializable()
class RecurringAccountRefDto {
  const RecurringAccountRefDto({
    required this.id,
    required this.name,
    required this.color,
  });

  factory RecurringAccountRefDto.fromJson(Map<String, dynamic> json) =>
      _$RecurringAccountRefDtoFromJson(json);

  final String id;
  final String name;
  final String color;

  Map<String, dynamic> toJson() => _$RecurringAccountRefDtoToJson(this);
}

@JsonSerializable()
class RecurringCategoryRefDto {
  const RecurringCategoryRefDto({
    required this.id,
    this.name,
    this.icon,
    this.color,
  });

  factory RecurringCategoryRefDto.fromJson(Map<String, dynamic> json) =>
      _$RecurringCategoryRefDtoFromJson(json);

  final String id;
  final String? name;
  final String? icon;
  final String? color;

  Map<String, dynamic> toJson() => _$RecurringCategoryRefDtoToJson(this);
}

/// `next_run` не шлём: сервер считает ближайшую дату сам.
@JsonSerializable(createFactory: false, fieldRename: FieldRename.snake)
class RecurringCreateBody {
  const RecurringCreateBody({
    required this.name,
    required this.amountMinor,
    required this.type,
    required this.accountId,
    required this.frequency,
    required this.categoryId,
    required this.anchorDate,
    this.isActive = true,
  });

  final String name;
  final int amountMinor;
  final String type;
  final String accountId;
  final String frequency;
  final String categoryId;
  final String anchorDate;
  final bool isActive;

  Map<String, dynamic> toJson() => _$RecurringCreateBodyToJson(this);
}

/// Без `type` (в PATCH его нет), `is_active` (пауза — только toggle, иначе
/// правка снимала бы её) и `next_run` (сервер пересчитает).
@JsonSerializable(createFactory: false, fieldRename: FieldRename.snake)
class RecurringPatchBody {
  const RecurringPatchBody({
    required this.name,
    required this.amountMinor,
    required this.accountId,
    required this.categoryId,
    required this.frequency,
    required this.anchorDate,
  });

  final String name;
  final int amountMinor;
  final String accountId;
  final String categoryId;
  final String frequency;
  final String anchorDate;

  Map<String, dynamic> toJson() => _$RecurringPatchBodyToJson(this);
}

@JsonSerializable(createFactory: false, fieldRename: FieldRename.snake)
class RecurringToggleBody {
  const RecurringToggleBody({required this.isActive});

  final bool isActive;

  Map<String, dynamic> toJson() => _$RecurringToggleBodyToJson(this);
}
