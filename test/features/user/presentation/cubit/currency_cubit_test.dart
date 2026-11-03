import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/user/data/models/user_model.dart';
import 'package:spendyholik/features/user/data/repositories/auth_repository.dart';
import 'package:spendyholik/features/user/presentation/cubit/currency_cubit.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const maria = UserModel(
  id: 'u1',
  name: 'Мария',
  email: 'maria@example.com',
  baseCurrency: Currency.usd,
);

void main() {
  late MockAuthRepository auth;

  setUpAll(() => registerFallbackValue(Currency.rub));

  setUp(() => auth = MockAuthRepository());

  CurrencyCubit build() => CurrencyCubit(auth);

  test('по умолчанию — рубль', () {
    expect(build().state.selected, Currency.rub);
  });

  blocTest<CurrencyCubit, CurrencyState>(
    'init с валютой пользователя — она выбрана',
    build: build,
    act: (cubit) => cubit.init(Currency.eur),
    expect: () => [const CurrencyState(selected: Currency.eur)],
  );

  blocTest<CurrencyCubit, CurrencyState>(
    'submit: setBaseCurrency с выбранной, затем success',
    setUp: () =>
        when(() => auth.setBaseCurrency(any())).thenAnswer((_) async => maria),
    build: build,
    act: (cubit) => cubit
      ..select(Currency.usd)
      ..submit(),
    expect: () => [
      const CurrencyState(selected: Currency.usd),
      const CurrencyState(
        selected: Currency.usd,
        status: FormStatus.submitting,
      ),
      const CurrencyState(selected: Currency.usd, status: FormStatus.success),
    ],
    verify: (_) => verify(() => auth.setBaseCurrency(Currency.usd)).called(1),
  );

  blocTest<CurrencyCubit, CurrencyState>(
    'ошибка — failure, выбор не теряется',
    setUp: () =>
        when(() => auth.setBaseCurrency(any()))
            .thenThrow(const NetworkFailure()),
    build: build,
    act: (cubit) => cubit.submit(),
    skip: 1,
    expect: () => [
      const CurrencyState(
        status: FormStatus.failure,
        failure: NetworkFailure(),
      ),
    ],
  );
}
