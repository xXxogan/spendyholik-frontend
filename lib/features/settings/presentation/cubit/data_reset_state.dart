part of 'data_reset_cubit.dart';

@freezed
abstract class DataResetState with _$DataResetState {
  const factory DataResetState({
    @Default(FormStatus.idle) FormStatus status,
    Failure? failure,
  }) = _DataResetState;
}
