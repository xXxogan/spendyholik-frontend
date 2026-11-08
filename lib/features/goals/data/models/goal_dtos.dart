import 'package:json_annotation/json_annotation.dart';
import 'package:spendyholik/core/models/money_dto.dart';

part 'goal_dtos.g.dart';

/// toJson у ответов — для кэша чтения. icon, color, progress не читаем:
/// в модели их нет, прогресс считается из сумм.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class GoalOutDto {
  const GoalOutDto({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
  });

  factory GoalOutDto.fromJson(Map<String, dynamic> json) =>
      _$GoalOutDtoFromJson(json);

  final String id;
  final String name;
  final MoneyDto targetAmount;
  final MoneyDto currentAmount;

  /// yyyy-MM-dd.
  final String? deadline;

  Map<String, dynamic> toJson() => _$GoalOutDtoToJson(this);
}

@JsonSerializable()
class GoalAccountRefDto {
  const GoalAccountRefDto({
    required this.id,
    required this.name,
    required this.color,
  });

  factory GoalAccountRefDto.fromJson(Map<String, dynamic> json) =>
      _$GoalAccountRefDtoFromJson(json);

  final String id;
  final String name;
  final String color;

  Map<String, dynamic> toJson() => _$GoalAccountRefDtoToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ContributionOutDto {
  const ContributionOutDto({
    required this.id,
    required this.amount,
    required this.date,
    this.accountId,
    this.account,
  });

  factory ContributionOutDto.fromJson(Map<String, dynamic> json) =>
      _$ContributionOutDtoFromJson(json);

  final String id;
  final MoneyDto amount;
  final String date;
  final String? accountId;

  /// null — счёт удалён.
  final GoalAccountRefDto? account;

  Map<String, dynamic> toJson() => _$ContributionOutDtoToJson(this);
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class ForecastOutDto {
  const ForecastOutDto({this.projectedCompletion});

  factory ForecastOutDto.fromJson(Map<String, dynamic> json) =>
      _$ForecastOutDtoFromJson(json);

  /// yyyy-MM-dd; null — пополнений нет, прогноза нет.
  final String? projectedCompletion;
}

@JsonSerializable(createFactory: false, fieldRename: FieldRename.snake)
class GoalCreateBody {
  const GoalCreateBody({
    required this.name,
    required this.targetAmountMinor,
    required this.currency,
    required this.initialAmountMinor,
    this.accountId,
    this.deadline,
  });

  final String name;
  final int targetAmountMinor;
  final String currency;
  final String? accountId;
  final int initialAmountMinor;
  final String? deadline;

  Map<String, dynamic> toJson() => _$GoalCreateBodyToJson(this);
}

/// null в PATCH сервер принимает только для `deadline` (так срок снимается).
@JsonSerializable(createFactory: false, fieldRename: FieldRename.snake)
class GoalPatchBody {
  const GoalPatchBody({
    required this.name,
    required this.targetAmountMinor,
    this.deadline,
  });

  final String name;
  final int targetAmountMinor;
  final String? deadline;

  Map<String, dynamic> toJson() => _$GoalPatchBodyToJson(this);
}

@JsonSerializable(createFactory: false, fieldRename: FieldRename.snake)
class ContributeBody {
  const ContributeBody({
    required this.accountId,
    required this.amountMinor,
    required this.date,
  });

  final String accountId;
  final int amountMinor;
  final String date;

  Map<String, dynamic> toJson() => _$ContributeBodyToJson(this);
}
