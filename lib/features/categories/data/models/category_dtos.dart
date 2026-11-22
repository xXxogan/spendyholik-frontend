import 'package:json_annotation/json_annotation.dart';

part 'category_dtos.g.dart';

/// toJson у ответа — для кэша чтения.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CategoryOutDto {
  const CategoryOutDto({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    required this.isSystem,
    required this.transactionCount,
    this.parentId,
  });

  factory CategoryOutDto.fromJson(Map<String, dynamic> json) =>
      _$CategoryOutDtoFromJson(json);

  final String id;
  final String name;
  final String type;
  final String icon;
  final String color;
  final String? parentId;
  final bool isSystem;
  final int transactionCount;

  Map<String, dynamic> toJson() => _$CategoryOutDtoToJson(this);
}

@JsonSerializable(createFactory: false, fieldRename: FieldRename.snake)
class CategoryCreateBody {
  const CategoryCreateBody({
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.parentId,
  });

  final String name;
  final String type;
  final String icon;
  final String color;
  final String? parentId;

  Map<String, dynamic> toJson() => _$CategoryCreateBodyToJson(this);
}

/// Тип категории не меняется: в API его нет в теле правки.
@JsonSerializable(createFactory: false, fieldRename: FieldRename.snake)
class CategoryPatchBody {
  const CategoryPatchBody({
    required this.name,
    this.icon,
    this.color,
    this.parentId,
  });

  final String name;
  @JsonKey(includeIfNull: false)
  final String? icon;
  @JsonKey(includeIfNull: false)
  final String? color;
  final String? parentId;

  Map<String, dynamic> toJson() => _$CategoryPatchBodyToJson(this);
}
