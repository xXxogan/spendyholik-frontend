import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/core/config/app_config.dart';
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
        SessionState.unauthenticated(onboardingSeen: await _onboardingSeen()),
      );
    }
    getIt<Talker>().info('Session restored: ${state.runtimeType}');
  }

  Future<void> signOut() => _auth.signOut();

  /// Ответ входа или смены валюты приходит раньше, чем пользователь — через
  /// userChanges. null — не дождались: поток оборвался или сервер молчит.
  Future<SessionState?> waitFor(
    bool Function(SessionState state) test, {
    Duration timeout = AppConfig.sessionWaitTimeout,
  }) async {
    if (test(state)) return state;
    try {
      return await stream.firstWhere(test).timeout(timeout);
    } on TimeoutException {
      getIt<Talker>().warning('Session wait timed out');
      return null;
    } on StateError {
      return null;
    }
  }

  /// Хранилище недоступно — покажем онбординг ещё раз, это безвредно.
  Future<bool> _onboardingSeen() async {
    try {
      return await _onboarding.isSeen();
    } on Exception catch (error, stackTrace) {
      getIt<Talker>().handle(error, stackTrace, 'Onboarding flag read failed');
      return false;
    }
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
