part of 'currency_cubit.dart';

@freezed
abstract class CurrencyState with _$CurrencyState {
  const factory CurrencyState({
    @Default(Currency.rub) Currency selected,
    @Default(FormStatus.idle) FormStatus status,
    Failure? failure,
  }) = _CurrencyState;
}
