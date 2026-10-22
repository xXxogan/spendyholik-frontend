import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/categories/data/models/models.dart';
import 'package:spendyholik/features/categories/data/repositories/repositories.dart';

part 'category_form_cubit.freezed.dart';
part 'category_form_state.dart';

@injectable
class CategoryFormCubit extends Cubit<CategoryFormState> {
  CategoryFormCubit(this._repository) : super(const CategoryFormState());

  final CategoryRepository _repository;

  Future<void> init(String? categoryId) async {
    emit(CategoryFormState(categoryId: categoryId, isLoading: true));
    try {
      final categories = await _repository.getCategories();
      if (categoryId == null) {
        emit(CategoryFormState(categories: categories));
        return;
      }
      // В контракте нет getCategory — берём из общего списка.
      final category = categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => throw const NotFoundFailure(),
      );
      emit(
        CategoryFormState(
          categoryId: categoryId,
          name: category.name,
          kind: category.kind,
          icon: category.icon,
          color: category.color,
          parentId: category.parentId,
          categories: categories,
        ),
      );
    } on Failure catch (failure) {
      emit(CategoryFormState(categoryId: categoryId, failure: failure));
    }
  }

  void nameChanged(String value) =>
      emit(state.copyWith(name: value, fieldErrors: _without(.name)));

  /// Тип задаётся только при создании: у существующей категории операции
  /// и подкатегории остались бы старого типа. Родитель другого типа
  /// недопустим, поэтому смена типа его сбрасывает.
  void kindChanged(CategoryKind value) {
    if (state.categoryId != null) return;
    emit(
      state.copyWith(
        kind: value,
        parentId: value == state.kind ? state.parentId : null,
      ),
    );
  }

  void iconChanged(EntityIcon value) => emit(state.copyWith(icon: value));

  void colorChanged(EntityColor value) => emit(state.copyWith(color: value));

  void parentChanged(String? value) => emit(state.copyWith(parentId: value));

  Future<void> save() async {
    final name = state.name.trim();
    if (name.isEmpty) {
      emit(state.copyWith(fieldErrors: {CategoryField.name: .required}));
      return;
    }

    final draft = CategoryDraft(
      name: name,
      kind: state.kind,
      icon: state.icon,
      color: state.color,
      parentId: state.canHaveParent ? state.parentId : null,
    );
    emit(state.copyWith(status: .submitting, failure: null));
    try {
      final categoryId = state.categoryId;
      if (categoryId == null) {
        await _repository.create(draft);
      } else {
        await _repository.update(categoryId, draft);
      }
      emit(state.copyWith(status: .success));
    } on ValidationFailure catch (failure) {
      emit(
        state.copyWith(
          status: .failure,
          fieldErrors: {
            CategoryField.values.byName(failure.field): failure.reason,
          },
        ),
      );
    } on Failure catch (failure) {
      emit(state.copyWith(status: .failure, failure: failure));
    }
  }

  Map<CategoryField, FieldError> _without(CategoryField field) =>
      Map.of(state.fieldErrors)..remove(field);
}
