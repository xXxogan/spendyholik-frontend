import 'package:spendyholik/core/models/entity_color.dart';
import 'package:spendyholik/core/models/entity_icon.dart';

enum CategoryKind { expense, income, transfer }

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.kind,
    required this.icon,
    required this.color,
    required this.transactionCount,
    this.parentId,
  });

  final String id;
  final String name;
  final CategoryKind kind;
  final EntityIcon icon;
  final EntityColor color;
  final String? parentId;
  final int transactionCount;

  CategoryModel copyWith({int? transactionCount}) => CategoryModel(
    id: id,
    name: name,
    kind: kind,
    icon: icon,
    color: color,
    parentId: parentId,
    transactionCount: transactionCount ?? this.transactionCount,
  );

  CategoryRef toRef() =>
      CategoryRef(id: id, name: name, icon: icon, color: color);
}

class CategoryRef {
  const CategoryRef({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  final String id;
  final String name;
  final EntityIcon icon;
  final EntityColor color;
}

class CategoryDraft {
  const CategoryDraft({
    required this.name,
    required this.kind,
    required this.icon,
    required this.color,
    this.parentId,
  });

  final String name;
  final CategoryKind kind;
  final EntityIcon icon;
  final EntityColor color;
  final String? parentId;
}
