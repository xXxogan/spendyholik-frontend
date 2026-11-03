import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/validation/email.dart';
import 'package:spendyholik/features/user/data/repositories/repositories.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'login_cubit.freezed.dart';
part 'login_state.dart';

@injectable
class LoginCubit extends Cubit<LoginState> with CubitLogging<LoginState> {
  LoginCubit(this._auth) : super(const LoginState());

  final AuthRepository _auth;

  void emailChanged(String value) => emit(
    state.copyWith(email: value, fieldErrors: _without(.email), failure: null),
  );

  void passwordChanged(String value) => emit(
    state.copyWith(
      password: value,
      fieldErrors: _without(.password),
      failure: null,
    ),
  );

  Future<void> submit() async {
    final errors = <LoginField, FieldError>{};
    final email = state.email.trim();
    if (!isValidEmail(email)) errors[.email] = .invalidEmail;
    if (state.password.isEmpty) errors[.password] = .required;
    if (errors.isNotEmpty) {
      emit(state.copyWith(fieldErrors: errors));
      return;
    }
    emit(state.copyWith(status: .submitting, failure: null));
    try {
      await _auth.signIn(email, state.password);
      emit(state.copyWith(status: .success));
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(state.copyWith(status: .failure, failure: failure));
    }
  }

  Map<LoginField, FieldError> _without(LoginField field) =>
      Map.of(state.fieldErrors)..remove(field);
}
