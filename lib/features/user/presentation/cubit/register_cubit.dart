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

part 'register_cubit.freezed.dart';
part 'register_state.dart';

@injectable
class RegisterCubit extends Cubit<RegisterState>
    with CubitLogging<RegisterState> {
  RegisterCubit(this._auth) : super(const RegisterState());

  static const minPasswordLength = 8;

  final AuthRepository _auth;

  void nameChanged(String value) =>
      emit(state.copyWith(name: value, fieldErrors: _without(.name)));

  void emailChanged(String value) =>
      emit(state.copyWith(email: value, fieldErrors: _without(.email)));

  void passwordChanged(String value) =>
      emit(state.copyWith(password: value, fieldErrors: _without(.password)));

  Future<void> submit() async {
    final errors = <RegisterField, FieldError>{};
    final name = state.name.trim();
    final email = state.email.trim();
    if (name.isEmpty) errors[.name] = .required;
    if (!isValidEmail(email)) errors[.email] = .invalidEmail;
    if (state.password.length < minPasswordLength) {
      errors[.password] = .tooShort;
    }
    if (errors.isNotEmpty) {
      emit(state.copyWith(fieldErrors: errors));
      return;
    }

    emit(state.copyWith(status: .submitting, failure: null));
    try {
      await _auth.register(name, email, state.password);
      emit(state.copyWith(status: .success));
    } on EmailTakenFailure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(
        state.copyWith(
          status: .failure,
          fieldErrors: {RegisterField.email: FieldError.emailTaken},
        ),
      );
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(state.copyWith(status: .failure, failure: failure));
    }
  }

  Map<RegisterField, FieldError> _without(RegisterField field) =>
      Map.of(state.fieldErrors)..remove(field);
}
