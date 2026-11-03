import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/debts/data/models/models.dart';
import 'package:spendyholik/features/debts/data/repositories/repositories.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'debt_repay_cubit.freezed.dart';
part 'debt_repay_state.dart';

@injectable
class DebtRepayCubit extends Cubit<DebtRepayState>
    with CubitLogging<DebtRepayState> {
  DebtRepayCubit(this._repository) : super(const DebtRepayState());

  final DebtRepository _repository;

  void init(DebtModel debt) => emit(
    DebtRepayState(
      debtId: debt.id,
      remaining: debt.remaining,
      amount: formatAmountInput(debt.remaining),
    ),
  );

  void amountChanged(String value) =>
      emit(state.copyWith(amount: value, fieldErrors: _without(.amount)));

  void accountChanged(String? value) =>
      emit(state.copyWith(accountId: value, fieldErrors: _without(.accountId)));

  void setFull() => amountChanged(formatAmountInput(state.remaining));

  /// Половина остатка вниз до целых единиц валюты: копейки в половине
  /// пользователю не нужны.
  void setHalf() =>
      amountChanged(formatAmountInput(state.remaining ~/ 2 ~/ 100 * 100));

  Future<void> submit() async {
    final errors = <RepayField, FieldError>{};
    final amount = parseAmountInput(state.amount);
    if (amount == null) errors[.amount] = .invalidAmount;
    final accountId = state.accountId;
    if (accountId == null) errors[.accountId] = .required;
    if (errors.isNotEmpty) {
      emit(state.copyWith(fieldErrors: errors));
      return;
    }

    emit(state.copyWith(status: .submitting, failure: null));
    try {
      await _repository.repay(state.debtId!, amount!, accountId!);
      emit(state.copyWith(status: .success));
    } on ValidationFailure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(
        state.copyWith(
          status: .failure,
          fieldErrors: {
            RepayField.values.byName(failure.field): failure.reason,
          },
        ),
      );
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(state.copyWith(status: .failure, failure: failure));
    }
  }

  Map<RepayField, FieldError> _without(RepayField field) =>
      Map.of(state.fieldErrors)..remove(field);
}
