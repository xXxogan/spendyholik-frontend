import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/countdown.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/validation/email.dart';
import 'package:spendyholik/features/user/data/repositories/repositories.dart';
import 'package:spendyholik/features/user/presentation/cubit/email_confirm_cubit.dart';
import 'package:spendyholik/features/user/presentation/cubit/register_cubit.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'forgot_password_cubit.freezed.dart';
part 'forgot_password_state.dart';

/// Сброс забытого пароля без входа: почта → код из письма и новый пароль.
@injectable
class ForgotPasswordCubit extends Cubit<ForgotPasswordState>
    with CubitLogging<ForgotPasswordState> {
  ForgotPasswordCubit(this._auth) : super(const ForgotPasswordState());

  final AuthRepository _auth;
  final _cooldown = Countdown();

  void emailChanged(String value) => emit(
    state.copyWith(email: value, fieldErrors: _without(.email), failure: null),
  );

  void codeChanged(String value) =>
      emit(state.copyWith(code: value, fieldErrors: _without(.code)));

  void newPasswordChanged(String value) => emit(
    state.copyWith(newPassword: value, fieldErrors: _without(.newPassword)),
  );

  Future<void> requestCode() async {
    if (state.status == .submitting) return;
    if (!isValidEmail(state.email)) {
      emit(state.copyWith(fieldErrors: {.email: .invalidEmail}));
      return;
    }
    emit(state.copyWith(status: .submitting, failure: null));
    try {
      await _auth.requestPasswordReset(state.email.trim());
      emit(state.copyWith(status: .idle, step: .code));
      _startCooldown();
    } on ValidationFailure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      final field = ForgotPasswordField.values.asNameMap()[failure.field];
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

  Future<void> resend() async {
    if (state.resendIn > 0 || state.status == .submitting) return;
    try {
      await _auth.requestPasswordReset(state.email.trim());
      emit(state.copyWith(failure: null));
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

  Future<void> submit() async {
    if (state.status == .submitting) return;
    final errors = <ForgotPasswordField, FieldError>{};
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
      await _auth.confirmPasswordReset(
        state.email.trim(),
        state.code,
        state.newPassword,
      );
      emit(state.copyWith(status: .success, step: .done));
    } on ValidationFailure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      final field = ForgotPasswordField.values.asNameMap()[failure.field];
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

  Map<ForgotPasswordField, FieldError> _without(ForgotPasswordField field) =>
      Map.of(state.fieldErrors)..remove(field);

  @override
  Future<void> close() {
    _cooldown.cancel();
    return super.close();
  }
}
