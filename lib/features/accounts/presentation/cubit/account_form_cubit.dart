import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/accounts/data/models/models.dart';
import 'package:spendyholik/features/accounts/data/repositories/repositories.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'account_form_cubit.freezed.dart';
part 'account_form_state.dart';

@injectable
class AccountFormCubit extends Cubit<AccountFormState>
    with CubitLogging<AccountFormState> {
  AccountFormCubit(this._repository) : super(const AccountFormState());

  final AccountRepository _repository;

  Future<void> init(String? accountId) async {
    if (accountId == null) return;
    emit(AccountFormState(accountId: accountId, isLoading: true));
    try {
      final account = await _repository.getAccount(accountId);
      emit(
        AccountFormState(
          accountId: accountId,
          name: account.name,
          type: account.type,
          balance: formatAmountInput(account.balance),
          color: account.color,
          cardLast4: account.cardLast4 ?? '',
          interestRate: account.interestRate?.toString() ?? '',
          creditLimit: switch (account.creditLimit) {
            final limit? => formatAmountInput(limit),
            null => '',
          },
        ),
      );
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(AccountFormState(accountId: accountId, failure: failure));
    }
  }

  void nameChanged(String value) =>
      emit(state.copyWith(name: value, fieldErrors: _without(.name)));

  void typeChanged(AccountType value) => emit(state.copyWith(type: value));

  void balanceChanged(String value) =>
      emit(state.copyWith(balance: value, fieldErrors: _without(.balance)));

  void colorChanged(EntityColor value) => emit(state.copyWith(color: value));

  void cardLast4Changed(String value) =>
      emit(state.copyWith(cardLast4: value, fieldErrors: _without(.cardLast4)));

  void interestRateChanged(String value) => emit(
    state.copyWith(interestRate: value, fieldErrors: _without(.interestRate)),
  );

  void creditLimitChanged(String value) => emit(
    state.copyWith(creditLimit: value, fieldErrors: _without(.creditLimit)),
  );

  Future<void> save() async {
    final type = state.type;
    final hasCard = type == .debit || type == .credit;
    final errors = <AccountField, FieldError>{};

    final name = state.name.trim();
    if (name.isEmpty) errors[.name] = .required;

    final balance = state.balance.trim().isEmpty
        ? 0
        : parseSignedAmountInput(state.balance);
    if (balance == null || (balance < 0 && type != .credit)) {
      errors[.balance] = .invalidAmount;
    }

    final cardLast4 = hasCard ? _optional(state.cardLast4) : null;
    if (cardLast4 != null && cardLast4.length != 4) {
      errors[.cardLast4] = .tooShort;
    }

    final rateInput = type == .savings ? _optional(state.interestRate) : null;
    final interestRate = rateInput == null
        ? null
        : double.tryParse(rateInput.replaceAll(',', '.'));
    if (rateInput != null && (interestRate == null || interestRate < 0)) {
      errors[.interestRate] = .invalidAmount;
    }

    final limitInput = type == .credit ? _optional(state.creditLimit) : null;
    final creditLimit = limitInput == null
        ? null
        : parseAmountInput(limitInput);
    if (limitInput != null && creditLimit == null) {
      errors[.creditLimit] = .invalidAmount;
    }

    if (errors.isNotEmpty) {
      emit(state.copyWith(fieldErrors: errors));
      return;
    }

    final draft = AccountDraft(
      name: name,
      type: type,
      balance: balance!,
      color: state.color,
      cardLast4: cardLast4,
      interestRate: interestRate,
      creditLimit: creditLimit,
    );
    emit(state.copyWith(status: .submitting, failure: null));
    try {
      final accountId = state.accountId;
      if (accountId == null) {
        await _repository.create(draft);
      } else {
        await _repository.update(accountId, draft);
      }
      emit(state.copyWith(status: .success));
    } on ValidationFailure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(
        state.copyWith(
          status: .failure,
          fieldErrors: {
            AccountField.values.byName(failure.field): failure.reason,
          },
        ),
      );
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(state.copyWith(status: .failure, failure: failure));
    }
  }

  Map<AccountField, FieldError> _without(AccountField field) =>
      Map.of(state.fieldErrors)..remove(field);

  static String? _optional(String input) {
    final trimmed = input.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
