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
import 'package:spendyholik/features/user/presentation/cubit/register_cubit.dart';
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

  void newPasswordChanged(String value) => emit(
    state.copyWith(newPassword: value, fieldErrors: _without(.newPassword)),
  );

  /// Пароль — последним: если профиль не сохранится (занят email), пароль
  /// останется старым. Обратное (имя сохранено, пароль нет) безопасно —
  /// повторное сохранение ничего не ломает.
  Future<void> save() async {
    final errors = <ProfileField, FieldError>{};
    final name = state.name.trim();
    final email = state.email.trim();
    if (name.isEmpty) errors[.name] = .required;
    if (!isValidEmail(email)) errors[.email] = .invalidEmail;
    final changesPassword =
        state.currentPassword.isNotEmpty || state.newPassword.isNotEmpty;
    if (changesPassword) {
      if (state.currentPassword.isEmpty) errors[.currentPassword] = .required;
      if (state.newPassword.length < RegisterCubit.minPasswordLength) {
        errors[.newPassword] = .tooShort;
      }
    }
    if (errors.isNotEmpty) {
      emit(state.copyWith(fieldErrors: errors));
      return;
    }

    emit(state.copyWith(status: .submitting, failure: null));
    try {
      await _auth.updateProfile(name: name, email: email);
      if (state.currency != state.initialCurrency) {
        await _auth.setBaseCurrency(state.currency);
      }
      if (changesPassword) {
        await _auth.changePassword(state.currentPassword, state.newPassword);
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
