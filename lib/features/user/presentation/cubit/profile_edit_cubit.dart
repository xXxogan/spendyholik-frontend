import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/validation/email.dart';
import 'package:spendyholik/features/user/data/models/models.dart';
import 'package:spendyholik/features/user/data/repositories/repositories.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'profile_edit_cubit.freezed.dart';
part 'profile_edit_state.dart';

@injectable
class ProfileEditCubit extends Cubit<ProfileEditState>
    with CubitLogging<ProfileEditState> {
  ProfileEditCubit(this._auth) : super(const ProfileEditState());

  final AuthRepository _auth;

  void init(UserModel user) {
    final currency = user.baseCurrency ?? Currency.rub;
    emit(
      ProfileEditState(
        name: user.name,
        email: user.email,
        initialEmail: user.email,
        currency: currency,
        initialCurrency: currency,
      ),
    );
  }

  void nameChanged(String value) =>
      emit(state.copyWith(name: value, fieldErrors: _without(.name)));

  void emailChanged(String value) =>
      emit(state.copyWith(email: value, fieldErrors: _without(.email)));

  void currencyChanged(Currency value) => emit(state.copyWith(currency: value));

  void currentPasswordChanged(String value) => emit(
    state.copyWith(
      currentPassword: value,
      fieldErrors: _without(.currentPassword),
    ),
  );

  /// Пароль здесь не меняется: у него свой экран с кодом из письма.
  Future<void> save() async {
    final errors = <ProfileField, FieldError>{};
    final name = state.name.trim();
    final email = state.email.trim();
    if (name.isEmpty) errors[.name] = .required;
    if (!isValidEmail(email)) errors[.email] = .invalidEmail;
    final emailChanged = state.emailChanged;
    if (emailChanged && state.currentPassword.isEmpty) {
      errors[.currentPassword] = .required;
    }
    if (errors.isNotEmpty) {
      emit(state.copyWith(fieldErrors: errors));
      return;
    }

    emit(state.copyWith(status: .submitting, failure: null));
    try {
      await _auth.updateProfile(
        name: name,
        email: email,
        currentPassword: emailChanged ? state.currentPassword : null,
      );
      if (state.currency != state.initialCurrency) {
        await _auth.setBaseCurrency(state.currency);
      }
      emit(state.copyWith(status: .success));
    } on ValidationFailure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      final field = ProfileField.values.asNameMap()[failure.field];
      emit(
        field == null
            ? state.copyWith(status: .failure, failure: failure)
            : state.copyWith(
                status: .failure,
                fieldErrors: {field: failure.reason},
              ),
      );
    } on EmailTakenFailure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(
        state.copyWith(
          status: .failure,
          fieldErrors: {ProfileField.email: FieldError.emailTaken},
        ),
      );
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(state.copyWith(status: .failure, failure: failure));
    }
  }

  Map<ProfileField, FieldError> _without(ProfileField field) =>
      Map.of(state.fieldErrors)..remove(field);
}
