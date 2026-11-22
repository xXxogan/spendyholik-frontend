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
    this.hasKnownIcon = true,
    this.hasKnownColor = true,
  });

  final String id;
  final String name;
  final CategoryKind kind;
  final EntityIcon icon;
  final EntityColor color;
  final String? parentId;
  final int transactionCount;
  final bool hasKnownIcon;
  final bool hasKnownColor;

  CategoryModel copyWith({int? transactionCount}) => CategoryModel(
    id: id,
    name: name,
    kind: kind,
    icon: icon,
    color: color,
    parentId: parentId,
    transactionCount: transactionCount ?? this.transactionCount,
    hasKnownIcon: hasKnownIcon,
    hasKnownColor: hasKnownColor,
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
    this.sendIcon = true,
    this.sendColor = true,
  });

  final String name;
  final CategoryKind kind;
  final EntityIcon icon;
  final EntityColor color;
  final String? parentId;
  final bool sendIcon;
  final bool sendColor;
}

class CategoryNode {
  const CategoryNode({required this.category, required this.children});

  final CategoryModel category;
  final List<CategoryModel> children;
}
