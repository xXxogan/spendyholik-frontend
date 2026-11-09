import 'package:json_annotation/json_annotation.dart';
import 'package:spendyholik/core/models/money_dto.dart';

part 'analytics_dtos.g.dart';

/// toJson у ответов — для кэша чтения. Валюты в `excluded_currencies` не показываем.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class SummaryOutDto {
  const SummaryOutDto({required this.income, required this.expense});

  factory SummaryOutDto.fromJson(Map<String, dynamic> json) =>
      _$SummaryOutDtoFromJson(json);

  final MoneyDto income;
  final MoneyDto expense;

  Map<String, dynamic> toJson() => _$SummaryOutDtoToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CategorySpendingOutDto {
  const CategorySpendingOutDto({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.ratio,
    this.category,
  });

  factory CategorySpendingOutDto.fromJson(Map<String, dynamic> json) =>
      _$CategorySpendingOutDtoFromJson(json);

  /// Категория верхнего уровня; null — если её уже нет.
  final AnalyticsCategoryRefDto? category;
  final String categoryId;
  final String categoryName;
  final MoneyDto amount;

  /// Доля от расходов периода, 0..1.
  final double ratio;

  Map<String, dynamic> toJson() => _$CategorySpendingOutDtoToJson(this);
}

/// Свой тип, а не DTO других фич: фичи не зависят друг от друга.
@JsonSerializable(fieldRename: FieldRename.snake)
class AnalyticsCategoryRefDto {
  const AnalyticsCategoryRefDto({
    required this.id,
    this.name,
    this.icon,
    this.color,
  });

  factory AnalyticsCategoryRefDto.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsCategoryRefDtoFromJson(json);

  final String id;
  final String? name;
  final String? icon;
  final String? color;

  Map<String, dynamic> toJson() => _$AnalyticsCategoryRefDtoToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class TrendPointOutDto {
  const TrendPointOutDto({
    required this.start,
    required this.income,
    required this.expense,
  });

  factory TrendPointOutDto.fromJson(Map<String, dynamic> json) =>
      _$TrendPointOutDtoFromJson(json);

  /// yyyy-MM-dd, первый день отрезка.
  final String start;
  final MoneyDto income;
  final MoneyDto expense;

  Map<String, dynamic> toJson() => _$TrendPointOutDtoToJson(this);
}
