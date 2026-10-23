import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/features/categories/data/models/models.dart';
import 'package:spendyholik/features/categories/data/repositories/repositories.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'categories_cubit.freezed.dart';
part 'categories_state.dart';

@injectable
class CategoriesCubit extends Cubit<CategoriesState>
    with CubitLogging<CategoriesState> {
  CategoriesCubit(this._repository, DataChangeBus bus)
    : super(const CategoriesState.loading()) {
    _changes = bus.changes
        .where(
          (topics) =>
              topics.contains(DataTopic.categories) ||
              topics.contains(DataTopic.transactions),
        )
        .listen((_) => load());
  }

  final CategoryRepository _repository;
  late final StreamSubscription<Set<DataTopic>> _changes;

  Future<void> load() async {
    if (state is! CategoriesLoaded) emit(const CategoriesState.loading());
    try {
      final categories = await _repository.getCategories();
      emit(CategoriesState.loaded(_group(categories)));
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(CategoriesState.error(failure));
    }
  }

  static Map<CategoryKind, List<CategoryNode>> _group(
    List<CategoryModel> categories,
  ) {
    final ids = {for (final category in categories) category.id};
    bool isTopLevel(CategoryModel category) =>
        category.parentId == null || !ids.contains(category.parentId);

    return {
      for (final kind in CategoryKind.values)
        kind: [
          for (final parent in categories)
            if (parent.kind == kind && isTopLevel(parent))
              CategoryNode(
                category: parent,
                children: [
                  for (final child in categories)
                    if (child.parentId == parent.id) child,
                ],
              ),
        ],
    };
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
