import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/accounts/accounts.dart';
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

  final _currencies = <String, Currency>{};

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
        for (final account in accounts) {
          _currencies[account.id] = account.currency;
        }
        final active = accounts.where((account) => !account.isArchived);
        emit(
          TransactionFormState(
            type: type,
            accountId: active.firstOrNull?.id,
            accountCurrency: active.firstOrNull?.currency,
            occurredAt: DateTime.now(),
          ),
        );
        return;
      }
      final t = await _transactions.getTransaction(transactionId);
      _currencies[t.account.id] = t.currency;
      emit(
        TransactionFormState(
          transactionId: transactionId,
          type: t.type,
          amount: formatAmountInput(t.amount),
          title: t.title,
          categoryId: t.category?.id,
          accountId: t.account.id,
          accountCurrency: t.currency,
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
  /// В правке тип не меняется: сервер не принимает `type` в PATCH
  /// (решение 2026-11-08) — другой тип = удалить и создать заново.
  void typeChanged(TransactionType value) {
    if (value == state.type || state.transactionId != null) return;
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

  void categoryChanged(String? value) => emit(
    state.copyWith(categoryId: value, fieldErrors: _without(.categoryId)),
  );

  Future<void> accountChanged(String? value) async {
    emit(
      state.copyWith(
        accountId: value,
        accountCurrency: _currencies[value],
        fieldErrors: _without(.accountId)..remove(TransactionField.toAccountId),
      ),
    );
    // В правке список счетов ещё не грузился.
    if (value == null || _currencies.containsKey(value)) return;
    try {
      for (final account in await _accounts.getAccounts()) {
        _currencies[account.id] = account.currency;
      }
    } on Failure catch (failure, stackTrace) {
      // Суффикс остаётся базовой валютой, сохранению это не мешает.
      getIt<Talker>().handle(failure, stackTrace);
      return;
    }
    if (state.accountId == value) {
      emit(state.copyWith(accountCurrency: _currencies[value]));
    }
  }

  void toAccountChanged(String? value) => emit(
    state.copyWith(toAccountId: value, fieldErrors: _without(.toAccountId)),
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
    if (!isTransfer && state.categoryId == null) {
      errors[.categoryId] = .required;
    }
    final accountId = state.accountId;
    if (accountId == null) errors[.accountId] = .required;
    if (isTransfer) {
      if (state.toAccountId == null) {
        errors[.toAccountId] = .required;
      } else if (state.toAccountId == accountId) {
        errors[.toAccountId] = .sameAccount;
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
      final field = TransactionField.values.asNameMap()[failure.field];
      emit(
        field == null
            ? state.copyWith(status: .failure, failure: failure)
            : state.copyWith(
                status: .failure,
                fieldErrors: {field: failure.reason},
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
