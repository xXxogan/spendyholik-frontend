import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/user/data/repositories/repositories.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'email_confirm_cubit.freezed.dart';
part 'email_confirm_state.dart';

@injectable
class EmailConfirmCubit extends Cubit<EmailConfirmState>
    with CubitLogging<EmailConfirmState> {
  EmailConfirmCubit(this._auth) : super(const EmailConfirmState());

  /// Как у сервера: новый код не раньше чем через минуту после прошлого.
  static const resendCooldown = 60;

  final AuthRepository _auth;
  Timer? _timer;

  /// Код уже отправлен регистрацией или сменой email — отсчёт сразу.
  void init(String email) {
    emit(state.copyWith(email: email));
    _startCooldown();
  }

  void codeChanged(String value) =>
      emit(state.copyWith(code: value, codeError: null, failure: null));

  Future<void> submit(String code) async {
    // Pinput зовёт onCompleted снова при повторном вводе — отправка одна.
    if (state.status == .submitting) return;
    emit(
      state.copyWith(
        code: code,
        status: .submitting,
        codeError: null,
        failure: null,
      ),
    );
    try {
      await _auth.confirmEmail(code);
      emit(state.copyWith(status: .success));
    } on ValidationFailure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(
        state.copyWith(
          status: .failure,
          code: '',
          codeError: failure.field == 'code'
              ? failure.reason
              : FieldError.invalid,
        ),
      );
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(state.copyWith(status: .failure, failure: failure));
    }
  }

  Future<void> resend() async {
    if (state.resendIn > 0) return;
    try {
      await _auth.resendEmailCode();
      emit(state.copyWith(failure: null, codeError: null, code: ''));
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

  Future<void> signOut() => _auth.signOut();

  void _startCooldown() {
    _timer?.cancel();
    emit(state.copyWith(resendIn: resendCooldown));
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = state.resendIn - 1;
      emit(state.copyWith(resendIn: left));
      if (left <= 0) timer.cancel();
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
