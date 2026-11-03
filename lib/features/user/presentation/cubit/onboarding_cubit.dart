import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/features/user/data/repositories/repositories.dart';

/// Состояние — номер слайда.
@injectable
class OnboardingCubit extends Cubit<int> with CubitLogging<int> {
  OnboardingCubit(this._onboarding) : super(0);

  static const lastPage = 2;

  final OnboardingRepository _onboarding;

  /// true — слайды кончились, онбординг пройден.
  Future<bool> next() async {
    if (state < lastPage) {
      emit(state + 1);
      return false;
    }
    await _onboarding.markSeen();
    return true;
  }

  Future<void> skip() => _onboarding.markSeen();

  void goTo(int page) => emit(page.clamp(0, lastPage));
}
