import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/features/user/data/models/models.dart';
import 'package:spendyholik/features/user/data/repositories/repositories.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'session_cubit.freezed.dart';
part 'session_state.dart';

@lazySingleton
class SessionCubit extends Cubit<SessionState> with CubitLogging<SessionState> {
  SessionCubit(this._auth, this._onboarding)
    : super(const SessionState.unknown()) {
    _changes = _auth.userChanges.listen(
      // После выхода онбординг уже пройден — сразу на вход.
      (user) => emit(
        user == null
            ? const SessionState.unauthenticated(onboardingSeen: true)
            : SessionState.authenticated(user),
      ),
    );
  }

  final AuthRepository _auth;
  final OnboardingRepository _onboarding;
  late final StreamSubscription<UserModel?> _changes;

  Future<void> restore() async {
    UserModel? user;
    try {
      user = await _auth.restoreSession();
    } on Exception catch (error, stackTrace) {
      // Без сети сессию не проверить — на вход, а не вечный splash.
      getIt<Talker>().handle(error, stackTrace, 'Session restore failed');
    }
    if (user != null) {
      emit(SessionState.authenticated(user));
    } else {
      emit(
        SessionState.unauthenticated(
          onboardingSeen: await _onboarding.isSeen(),
        ),
      );
    }
    getIt<Talker>().info('Session restored: ${state.runtimeType}');
  }

  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
