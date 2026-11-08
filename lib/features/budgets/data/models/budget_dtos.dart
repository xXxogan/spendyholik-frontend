import 'package:json_annotation/json_annotation.dart';
import 'package:spendyholik/core/models/money_dto.dart';

part 'budget_dtos.g.dart';

/// toJson у ответов — для кэша чтения.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class BudgetOutDto {
  const BudgetOutDto({
    required this.id,
    required this.category,
    required this.amount,
    required this.spent,
    required this.period,
    required this.isActive,
    this.startDate,
    this.endDate,
    this.periodStart,
    this.periodEnd,
  });

  factory BudgetOutDto.fromJson(Map<String, dynamic> json) =>
      _$BudgetOutDtoFromJson(json);

  final String id;
  final BudgetCategoryRefDto category;
  final MoneyDto amount;

  /// Категория вместе с подкатегориями за текущий период.
  final MoneyDto spent;

  /// monthly | weekly | one_time.
  final String period;

  /// yyyy-MM-dd; заданы у разового бюджета.
  final String? startDate;
  final String? endDate;

  /// yyyy-MM-dd; `periodEnd` — последний день включительно. null у неактивного.
  final String? periodStart;
  final String? periodEnd;
  final bool isActive;

  Map<String, dynamic> toJson() => _$BudgetOutDtoToJson(this);
}

/// Свой тип, а не `CategoryRefDto` транзакций: фичи не зависят друг от друга.
@JsonSerializable(fieldRename: FieldRename.snake)
class BudgetCategoryRefDto {
  const BudgetCategoryRefDto({
    required this.id,
    this.name,
    this.icon,
    this.color,
  });

  factory BudgetCategoryRefDto.fromJson(Map<String, dynamic> json) =>
      _$BudgetCategoryRefDtoFromJson(json);

  final String id;
  final String? name;
  final String? icon;
  final String? color;

  Map<String, dynamic> toJson() => _$BudgetCategoryRefDtoToJson(this);
}

/// null в датах уходит явно: у месячного и недельного бюджета их нет.
@JsonSerializable(createFactory: false, fieldRename: FieldRename.snake)
class BudgetCreateBody {
  const BudgetCreateBody({
    required this.categoryId,
    required this.amountMinor,
    required this.period,
    required this.isActive,
    this.startDate,
    this.endDate,
  });

  final String categoryId;
  final int amountMinor;
  final String period;
  final String? startDate;
  final String? endDate;
  final bool isActive;

  Map<String, dynamic> toJson() => _$BudgetCreateBodyToJson(this);
}

/// Сервер принимает null в PATCH только для `start_date` и `end_date`;
/// остальные поля всегда со значением. `is_active` не шлём: в UI его нет,
/// а `true` молча включал бы бюджет, выключенный на сервере.
@JsonSerializable(createFactory: false, fieldRename: FieldRename.snake)
class BudgetPatchBody {
  const BudgetPatchBody({
    required this.categoryId,
    required this.amountMinor,
    required this.period,
    this.startDate,
    this.endDate,
  });

  final String categoryId;
  final int amountMinor;
  final String period;
  final String? startDate;
  final String? endDate;

  Map<String, dynamic> toJson() => _$BudgetPatchBodyToJson(this);
}
