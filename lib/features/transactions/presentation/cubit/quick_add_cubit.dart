import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/accounts/accounts.dart';
import 'package:spendyholik/features/categories/categories.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';
import 'package:spendyholik/features/transactions/data/repositories/repositories.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'quick_add_cubit.freezed.dart';
part 'quick_add_state.dart';

@injectable
class QuickAddCubit extends Cubit<QuickAddState>
    with CubitLogging<QuickAddState> {
  QuickAddCubit(this._transactions, this._accounts, this._categories)
    : super(const QuickAddState());

  final TransactionRepository _transactions;
  final AccountRepository _accounts;
  final CategoryRepository _categories;

  static const _shortListSize = 6;

  Future<void> init() => _loadCategories(state.type);

  Future<void> typeChanged(TransactionType value) async {
    if (value == state.type) return;
    emit(state.copyWith(type: value, categoryId: null, fieldErrors: {}));
    await _loadCategories(value);
  }

  void amountChanged(String value) =>
      emit(state.copyWith(amount: value, fieldErrors: _without(.amount)));

  void categoryChanged(String value) =>
      emit(state.copyWith(categoryId: value, fieldErrors: _without(.category)));

  Future<void> submit() async {
    final amount = parseAmountInput(state.amount);
    final errors = <QuickAddField, FieldError>{
      if (amount == null) QuickAddField.amount: FieldError.invalidAmount,
      if (state.categoryId == null) QuickAddField.category: FieldError.required,
    };
    if (errors.isNotEmpty) {
      emit(state.copyWith(fieldErrors: errors));
      return;
    }

    emit(state.copyWith(status: .submitting, failure: null));
    try {
      final accounts = await _accounts.getAccounts();
      final card = accounts
          .where((a) => !a.isArchived && a.type == AccountType.debit)
          .firstOrNull;
      if (card == null) {
        emit(
          state.copyWith(
            status: .failure,
            fieldErrors: {QuickAddField.account: FieldError.required},
          ),
        );
        return;
      }
      await _transactions.create(
        TransactionDraft(
          type: state.type,
          amount: amount!,
          title: '',
          categoryId: state.categoryId,
          accountId: card.id,
          occurredAt: DateTime.now(),
        ),
      );
      emit(state.copyWith(status: .success));
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(state.copyWith(status: .failure, failure: failure));
    }
  }

  Future<void> _loadCategories(TransactionType type) async {
    emit(state.copyWith(isLoading: true, failure: null));
    try {
      final categories = await _categories.getCategories(
        kind: type == TransactionType.income
            ? CategoryKind.income
            : CategoryKind.expense,
      );
      if (type != state.type) return;
      final topLevel = categories.where((c) => c.parentId == null).toList()
        ..sort((a, b) => b.transactionCount.compareTo(a.transactionCount));
      emit(
        state.copyWith(
          categories: topLevel.take(_shortListSize).toList(),
          isLoading: false,
        ),
      );
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(state.copyWith(isLoading: false, failure: failure));
    }
  }

  Map<QuickAddField, FieldError> _without(QuickAddField field) =>
      Map.of(state.fieldErrors)..remove(field);
}
