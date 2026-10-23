import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/features/categories/data/models/models.dart';
import 'package:spendyholik/features/categories/data/repositories/repositories.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'category_picker_cubit.freezed.dart';
part 'category_picker_state.dart';

@injectable
class CategoryPickerCubit extends Cubit<CategoryPickerState>
    with CubitLogging<CategoryPickerState> {
  CategoryPickerCubit(this._repository)
    : super(const CategoryPickerState.loading());

  final CategoryRepository _repository;

  Future<void> load(CategoryKind kind) async {
    emit(const CategoryPickerState.loading());
    try {
      final categories = await _repository.getCategories(kind: kind);
      final ids = {for (final category in categories) category.id};
      bool isTopLevel(CategoryModel c) =>
          c.parentId == null || !ids.contains(c.parentId);
      emit(
        CategoryPickerState.loaded([
          for (final parent in categories.where(isTopLevel)) ...[
            parent,
            ...categories.where((c) => c.parentId == parent.id),
          ],
        ]),
      );
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(CategoryPickerState.error(failure));
    }
  }
}
