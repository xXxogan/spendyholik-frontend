import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/countdown.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/user/data/repositories/repositories.dart';
import 'package:spendyholik/features/user/presentation/cubit/email_confirm_cubit.dart';
import 'package:spendyholik/features/user/presentation/cubit/register_cubit.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'password_change_cubit.freezed.dart';
part 'password_change_state.dart';

/// Смена пароля по коду из письма: сервер больше не спрашивает старый пароль.
@injectable
class PasswordChangeCubit extends Cubit<PasswordChangeState>
    with CubitLogging<PasswordChangeState> {
  PasswordChangeCubit(this._auth) : super(const PasswordChangeState());

  final AuthRepository _auth;
  final _cooldown = Countdown();

  Future<void> sendCode() async {
    if (state.resendIn > 0) return;
    try {
      await _auth.requestPasswordChangeCode();
      emit(state.copyWith(codeSent: true, failure: null));
      _startCooldown();
    } on RateLimitedFailure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(state.copyWith(failure: failure));
      // «Подождите» — сервер ещё считает минуту; дневной лимит отсчётом не снять.
      if (!failure.daily) _startCooldown();
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(state.copyWith(failure: failure));
    }
  }

  void codeChanged(String value) =>
      emit(state.copyWith(code: value, fieldErrors: _without(.code)));

  void newPasswordChanged(String value) => emit(
    state.copyWith(newPassword: value, fieldErrors: _without(.newPassword)),
  );

  Future<void> submit() async {
    if (state.status == .submitting) return;
    final errors = <PasswordChangeField, FieldError>{};
    if (state.code.isEmpty) errors[.code] = .required;
    if (state.newPassword.length < RegisterCubit.minPasswordLength) {
      errors[.newPassword] = .tooShort;
    }
    if (errors.isNotEmpty) {
      emit(state.copyWith(fieldErrors: errors));
      return;
    }

    emit(state.copyWith(status: .submitting, failure: null));
    try {
      await _auth.changePassword(state.code, state.newPassword);
      emit(state.copyWith(status: .success));
    } on ValidationFailure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      final field = PasswordChangeField.values.asNameMap()[failure.field];
      emit(
        field == null
            ? state.copyWith(status: .failure, failure: failure)
            : state.copyWith(
                status: .failure,
                // Неверный код вводят заново целиком.
                code: field == .code ? '' : state.code,
                fieldErrors: {field: failure.reason},
              ),
      );
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(state.copyWith(status: .failure, failure: failure));
    }
  }

  void _startCooldown() => _cooldown.start(
    EmailConfirmCubit.resendCooldown,
    (left) => emit(state.copyWith(resendIn: left)),
  );

  Map<PasswordChangeField, FieldError> _without(PasswordChangeField field) =>
      Map.of(state.fieldErrors)..remove(field);

  @override
  Future<void> close() {
    _cooldown.cancel();
    return super.close();
  }
}
