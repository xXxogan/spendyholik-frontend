import 'package:json_annotation/json_annotation.dart';
import 'package:spendyholik/core/models/money_dto.dart';
import 'package:spendyholik/features/transactions/transactions.dart';

part 'feed_dtos.g.dart';

/// toJson у ответов — для кэша чтения.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class FeedPageDto {
  const FeedPageDto({required this.items, this.nextCursor});

  factory FeedPageDto.fromJson(Map<String, dynamic> json) =>
      _$FeedPageDtoFromJson(json);

  final List<FeedItemOutDto> items;
  final String? nextCursor;

  Map<String, dynamic> toJson() => _$FeedPageDtoToJson(this);
}

/// `kind` и `effect` — строками: неизвестное значение пропускается в
/// репозитории, а не роняет разбор всей страницы.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class FeedItemOutDto {
  const FeedItemOutDto({
    required this.kind,
    required this.id,
    required this.date,
    required this.amount,
    required this.effect,
    this.transaction,
    this.debt,
    this.goal,
  });

  factory FeedItemOutDto.fromJson(Map<String, dynamic> json) =>
      _$FeedItemOutDtoFromJson(json);

  final String kind;
  final String id;

  /// yyyy-MM-dd.
  final String date;
  final MoneyDto amount;
  final String effect;
  final TransactionOutDto? transaction;
  final FeedDebtDto? debt;
  final FeedGoalDto? goal;

  Map<String, dynamic> toJson() => _$FeedItemOutDtoToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class FeedDebtDto {
  const FeedDebtDto({
    required this.id,
    required this.personName,
    required this.direction,
  });

  factory FeedDebtDto.fromJson(Map<String, dynamic> json) =>
      _$FeedDebtDtoFromJson(json);

  final String id;
  final String personName;

  /// `i_owe` | `owed_to_me`.
  final String direction;

  Map<String, dynamic> toJson() => _$FeedDebtDtoToJson(this);
}

@JsonSerializable()
class FeedGoalDto {
  const FeedGoalDto({required this.id, required this.name});

  factory FeedGoalDto.fromJson(Map<String, dynamic> json) =>
      _$FeedGoalDtoFromJson(json);

  final String id;
  final String name;

  Map<String, dynamic> toJson() => _$FeedGoalDtoToJson(this);
}
