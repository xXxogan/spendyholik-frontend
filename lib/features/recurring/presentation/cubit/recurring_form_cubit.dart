import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/recurring/data/models/models.dart';
import 'package:spendyholik/features/recurring/data/repositories/repositories.dart';
import 'package:spendyholik/features/transactions/transactions.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'recurring_form_cubit.freezed.dart';
part 'recurring_form_state.dart';

@injectable
class RecurringFormCubit extends Cubit<RecurringFormState>
    with CubitLogging<RecurringFormState> {
  RecurringFormCubit(this._repository) : super(const RecurringFormState());

  final RecurringRepository _repository;

  /// Полдень, чтобы сдвиг часового пояса не переносил дату выполнения.
  static DateTime _atNoon(DateTime day) =>
      DateTime(day.year, day.month, day.day, 12);

  void start(DateTime now) => emit(RecurringFormState(anchor: _atNoon(now)));

  Future<void> init(String recurringId) async {
    emit(RecurringFormState(recurringId: recurringId, isLoading: true));
    try {
      final templates = await _repository.getAll();
      // В контракте нет getOne — берём из общего списка.
      final template = templates.firstWhere(
        (t) => t.id == recurringId,
        orElse: () => throw const NotFoundFailure(),
      );
      emit(
        RecurringFormState(
          recurringId: recurringId,
          title: template.title,
          type: template.type,
          amount: formatAmountInput(template.amount),
          categoryId: template.category.id,
          accountId: template.account.id,
          frequency: template.frequency,
          anchor: template.anchor,
        ),
      );
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(RecurringFormState(recurringId: recurringId, failure: failure));
    }
  }

  void titleChanged(String value) =>
      emit(state.copyWith(title: value, fieldErrors: _without(.title)));

  void amountChanged(String value) =>
      emit(state.copyWith(amount: value, fieldErrors: _without(.amount)));

  /// Категории расходов и доходов разные, поэтому смена типа сбрасывает выбор.
  void typeChanged(TransactionType value) {
    if (value == state.type || value == TransactionType.transfer) return;
    emit(
      state.copyWith(
        type: value,
        categoryId: null,
        fieldErrors: _without(.categoryId),
      ),
    );
  }

  void categoryChanged(String value) => emit(
    state.copyWith(categoryId: value, fieldErrors: _without(.categoryId)),
  );

  void accountChanged(String? value) =>
      emit(state.copyWith(accountId: value, fieldErrors: _without(.accountId)));

  void frequencyChanged(RecurrenceFrequency value) =>
      emit(state.copyWith(frequency: value));

  void anchorChanged(DateTime value) =>
      emit(state.copyWith(anchor: _atNoon(value)));

  Future<void> save() async {
    final errors = <RecurringField, FieldError>{};
    final title = state.title.trim();
    if (title.isEmpty) errors[.title] = .required;
    final amount = parseAmountInput(state.amount);
    if (amount == null) errors[.amount] = .invalidAmount;
    final categoryId = state.categoryId;
    if (categoryId == null) errors[.categoryId] = .required;
    final accountId = state.accountId;
    if (accountId == null) errors[.accountId] = .required;
    final anchor = state.anchor;
    if (errors.isNotEmpty || anchor == null) {
      emit(state.copyWith(fieldErrors: errors));
      return;
    }

    final draft = RecurringDraft(
      title: title,
      type: state.type,
      amount: amount!,
      categoryId: categoryId!,
      accountId: accountId!,
      frequency: state.frequency,
      anchor: anchor,
    );
    emit(state.copyWith(status: .submitting, failure: null));
    try {
      final recurringId = state.recurringId;
      if (recurringId == null) {
        await _repository.create(draft);
      } else {
        await _repository.update(recurringId, draft);
      }
      emit(state.copyWith(status: .success));
    } on ValidationFailure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(
        state.copyWith(
          status: .failure,
          fieldErrors: {
            RecurringField.values.byName(failure.field): failure.reason,
          },
        ),
      );
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(state.copyWith(status: .failure, failure: failure));
    }
  }

  Map<RecurringField, FieldError> _without(RecurringField field) =>
      Map.of(state.fieldErrors)..remove(field);
}
