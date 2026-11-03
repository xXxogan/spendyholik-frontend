import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/user/data/repositories/repositories.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'currency_cubit.freezed.dart';
part 'currency_state.dart';

@injectable
class CurrencyCubit extends Cubit<CurrencyState>
    with CubitLogging<CurrencyState> {
  CurrencyCubit(this._auth) : super(const CurrencyState());

  final AuthRepository _auth;

  void init(Currency? current) {
    if (current != null) emit(CurrencyState(selected: current));
  }

  void select(Currency currency) => emit(state.copyWith(selected: currency));

  Future<void> submit() async {
    emit(state.copyWith(status: .submitting, failure: null));
    try {
      await _auth.setBaseCurrency(state.selected);
      emit(state.copyWith(status: .success));
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(state.copyWith(status: .failure, failure: failure));
    }
  }
}
