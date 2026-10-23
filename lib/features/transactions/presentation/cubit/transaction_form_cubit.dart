import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/accounts/data/repositories/repositories.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';
import 'package:spendyholik/features/transactions/data/repositories/repositories.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'transaction_form_cubit.freezed.dart';
part 'transaction_form_state.dart';

@injectable
class TransactionFormCubit extends Cubit<TransactionFormState>
    with CubitLogging<TransactionFormState> {
  TransactionFormCubit(this._transactions, this._accounts)
    : super(const TransactionFormState());

  final TransactionRepository _transactions;
  final AccountRepository _accounts;

  Future<void> init(
    String? transactionId, {
    TransactionType type = TransactionType.expense,
  }) async {
    emit(
      TransactionFormState(
        transactionId: transactionId,
        type: type,
        isLoading: true,
      ),
    );
    try {
      if (transactionId == null) {
        final accounts = await _accounts.getAccounts();
        final active = accounts.where((account) => !account.isArchived);
        emit(
          TransactionFormState(
            type: type,
            accountId: active.firstOrNull?.id,
            occurredAt: DateTime.now(),
          ),
        );
        return;
      }
      final t = await _transactions.getTransaction(transactionId);
      emit(
        TransactionFormState(
          transactionId: transactionId,
          type: t.type,
          amount: formatAmountInput(t.amount),
          title: t.title,
          categoryId: t.category?.id,
          accountId: t.account.id,
          toAccountId: t.toAccount?.id,
          occurredAt: t.occurredAt,
          note: t.note ?? '',
        ),
      );
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(
        TransactionFormState(transactionId: transactionId, failure: failure),
      );
    }
  }

  /// Категории у типов разные, а получатель есть только у перевода.
  void typeChanged(TransactionType value) {
    if (value == state.type) return;
    emit(
      state.copyWith(
        type: value,
        categoryId: null,
        toAccountId: null,
        fieldErrors: {},
      ),
    );
  }

  void amountChanged(String value) =>
      emit(state.copyWith(amount: value, fieldErrors: _without(.amount)));

  void titleChanged(String value) => emit(state.copyWith(title: value));

  void categoryChanged(String? value) =>
      emit(state.copyWith(categoryId: value, fieldErrors: _without(.category)));

  void accountChanged(String? value) => emit(
    state.copyWith(
      accountId: value,
      fieldErrors: _without(.account)..remove(TransactionField.toAccount),
    ),
  );

  void toAccountChanged(String? value) => emit(
    state.copyWith(toAccountId: value, fieldErrors: _without(.toAccount)),
  );

  void dateChanged(DateTime day) {
    final time = state.occurredAt ?? DateTime.now();
    emit(
      state.copyWith(
        occurredAt: DateTime(
          day.year,
          day.month,
          day.day,
          time.hour,
          time.minute,
          time.second,
        ),
      ),
    );
  }

  void noteChanged(String value) => emit(state.copyWith(note: value));

  Future<void> save() async {
    final isTransfer = state.type == TransactionType.transfer;
    final errors = <TransactionField, FieldError>{};

    final amount = parseAmountInput(state.amount);
    if (amount == null) errors[.amount] = .invalidAmount;
    if (!isTransfer && state.categoryId == null) errors[.category] = .required;
    final accountId = state.accountId;
    if (accountId == null) errors[.account] = .required;
    if (isTransfer) {
      if (state.toAccountId == null) {
        errors[.toAccount] = .required;
      } else if (state.toAccountId == accountId) {
        errors[.toAccount] = .sameAccount;
      }
    }
    if (errors.isNotEmpty) {
      emit(state.copyWith(fieldErrors: errors));
      return;
    }

    final note = state.note.trim();
    final draft = TransactionDraft(
      type: state.type,
      amount: amount!,
      title: state.title.trim(),
      categoryId: isTransfer ? null : state.categoryId,
      accountId: accountId!,
      toAccountId: isTransfer ? state.toAccountId : null,
      occurredAt: state.occurredAt ?? DateTime.now(),
      note: note.isEmpty ? null : note,
    );
    emit(state.copyWith(status: .submitting, failure: null));
    try {
      final transactionId = state.transactionId;
      if (transactionId == null) {
        await _transactions.create(draft);
      } else {
        await _transactions.update(transactionId, draft);
      }
      emit(state.copyWith(status: .success));
    } on ValidationFailure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(
        state.copyWith(
          status: .failure,
          fieldErrors: {
            TransactionField.values.byName(failure.field): failure.reason,
          },
        ),
      );
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(state.copyWith(status: .failure, failure: failure));
    }
  }

  Map<TransactionField, FieldError> _without(TransactionField field) =>
      Map.of(state.fieldErrors)..remove(field);
}
