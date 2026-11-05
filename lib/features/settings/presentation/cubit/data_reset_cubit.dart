import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/settings/data/repositories/repositories.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'data_reset_cubit.freezed.dart';
part 'data_reset_state.dart';

@injectable
class DataResetCubit extends Cubit<DataResetState>
    with CubitLogging<DataResetState> {
  DataResetCubit(this._repository) : super(const DataResetState());

  final DataResetRepository _repository;

  Future<void> wipe() async {
    emit(const DataResetState(status: .submitting));
    try {
      await _repository.wipeAll();
      emit(const DataResetState(status: .success));
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(DataResetState(status: .failure, failure: failure));
    }
  }
}
