part of 'transaction_filters_cubit.dart';

/// Черновик фильтра в шторке: применяется только по «Применить».
@freezed
abstract class TransactionFiltersState with _$TransactionFiltersState {
  const factory TransactionFiltersState({
    @Default(TransactionFilter()) TransactionFilter filter,

    /// null — за всё время.
    PeriodPreset? preset,
    @Default([]) List<CategoryModel> categories,
    @Default([]) List<AccountModel> accounts,
    @Default(true) bool isLoading,
    Failure? failure,
  }) = _TransactionFiltersState;

  const TransactionFiltersState._();

  /// Категории верхнего уровня под выбранный тип; у переводов категорий нет.
  List<CategoryModel> get categoryOptions => [
    for (final category in categories)
      if (category.parentId == null &&
          switch (filter.type) {
            null => category.kind != CategoryKind.transfer,
            TransactionType.expense => category.kind == CategoryKind.expense,
            TransactionType.income => category.kind == CategoryKind.income,
            TransactionType.transfer => false,
          })
        category,
  ];
}
