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

part 'debt_form_cubit.freezed.dart';
part 'debt_form_state.dart';

@injectable
class DebtFormCubit extends Cubit<DebtFormState>
    with CubitLogging<DebtFormState> {
  DebtFormCubit(this._repository) : super(const DebtFormState());

  final DebtRepository _repository;

  void start(DebtDirection direction) =>
      emit(DebtFormState(direction: direction));

  Future<void> init(String debtId) async {
    emit(DebtFormState(debtId: debtId, isLoading: true));
    try {
      final debt = await _repository.getDebt(debtId);
      emit(
        DebtFormState(
          debtId: debtId,
          counterparty: debt.counterparty,
          direction: debt.direction,
          amount: formatAmountInput(debt.total),
          dueDate: debt.dueDate,
          note: debt.note ?? '',
        ),
      );
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(DebtFormState(debtId: debtId, failure: failure));
    }
  }

  void counterpartyChanged(String value) => emit(
    state.copyWith(counterparty: value, fieldErrors: _without(.counterparty)),
  );

  void directionChanged(DebtDirection value) {
    // Погашения уже сдвинули балансы в сторону старого направления.
    if (state.debtId != null) return;
    emit(state.copyWith(direction: value));
  }

  void amountChanged(String value) =>
      emit(state.copyWith(amount: value, fieldErrors: _without(.amount)));

  void dueDateChanged(DateTime? value) => emit(state.copyWith(dueDate: value));

  void noteChanged(String value) => emit(state.copyWith(note: value));

  Future<void> save() async {
    final errors = <DebtField, FieldError>{};
    final counterparty = state.counterparty.trim();
    if (counterparty.isEmpty) errors[.counterparty] = .required;
    final amount = parseAmountInput(state.amount);
    if (amount == null) errors[.amount] = .invalidAmount;
    if (errors.isNotEmpty) {
      emit(state.copyWith(fieldErrors: errors));
      return;
    }

    final note = state.note.trim();
    final draft = DebtDraft(
      counterparty: counterparty,
      direction: state.direction,
      amount: amount!,
      dueDate: state.dueDate,
      note: note.isEmpty ? null : note,
    );
    emit(state.copyWith(status: .submitting, failure: null));
    try {
      final debtId = state.debtId;
      if (debtId == null) {
        await _repository.create(draft);
      } else {
        await _repository.update(debtId, draft);
      }
      emit(state.copyWith(status: .success));
    } on ValidationFailure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      final field = DebtField.values.asNameMap()[failure.field];
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

  Map<DebtField, FieldError> _without(DebtField field) =>
      Map.of(state.fieldErrors)..remove(field);
}
