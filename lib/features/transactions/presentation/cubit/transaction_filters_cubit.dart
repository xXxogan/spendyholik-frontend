import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/accounts/data/models/models.dart';
import 'package:spendyholik/features/accounts/data/repositories/repositories.dart';
import 'package:spendyholik/features/categories/data/models/models.dart';
import 'package:spendyholik/features/categories/data/repositories/repositories.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'transaction_filters_cubit.freezed.dart';
part 'transaction_filters_state.dart';

@injectable
class TransactionFiltersCubit extends Cubit<TransactionFiltersState>
    with CubitLogging<TransactionFiltersState> {
  TransactionFiltersCubit(this._categories, this._accounts)
    : super(const TransactionFiltersState());

  final CategoryRepository _categories;
  final AccountRepository _accounts;

  Future<void> init(TransactionFilter current) async {
    try {
      final categories = await _categories.getCategories();
      final accounts = await _accounts.getAccounts();
      emit(
        TransactionFiltersState(
          filter: current,
          preset: _presetOf(current.period),
          categories: categories,
          accounts: [
            for (final account in accounts)
              if (!account.isArchived || account.id == current.accountId)
                account,
          ],
          isLoading: false,
        ),
      );
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(TransactionFiltersState(isLoading: false, failure: failure));
    }
  }

  /// [custom] — только для [PeriodPreset.custom], остальные считаются от сегодня.
  void setPeriod(PeriodPreset? preset, {DatePeriod? custom}) {
    final period = switch (preset) {
      null => null,
      PeriodPreset.custom => custom,
      _ => DatePeriod.current(preset, DateTime.now()),
    };
    emit(
      state.copyWith(preset: preset, filter: state.filter.withPeriod(period)),
    );
  }

  void setType(TransactionType? type) {
    final typed = state.copyWith(filter: state.filter.withType(type));
    final keepsCategory = typed.categoryOptions.any(
      (category) => category.id == state.filter.categoryId,
    );
    emit(
      keepsCategory
          ? typed
          : typed.copyWith(filter: typed.filter.withCategory(null)),
    );
  }

  void setCategory(String? categoryId) =>
      emit(state.copyWith(filter: state.filter.withCategory(categoryId)));

  void setAccount(String? accountId) =>
      emit(state.copyWith(filter: state.filter.withAccount(accountId)));

  void reset() =>
      emit(state.copyWith(filter: const TransactionFilter(), preset: null));

  static PeriodPreset? _presetOf(DatePeriod? period) {
    if (period == null) return null;
    final now = DateTime.now();
    for (final preset in [
      PeriodPreset.week,
      PeriodPreset.month,
      PeriodPreset.year,
    ]) {
      if (DatePeriod.current(preset, now) == period) return preset;
    }
    return PeriodPreset.custom;
  }
}
