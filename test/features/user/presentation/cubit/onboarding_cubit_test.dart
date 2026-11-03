import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/features/user/data/repositories/onboarding_repository.dart';
import 'package:spendyholik/features/user/presentation/cubit/onboarding_cubit.dart';

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

void main() {
  late MockOnboardingRepository repository;

  setUp(() {
    repository = MockOnboardingRepository();
    when(() => repository.markSeen()).thenAnswer((_) async {});
  });

  OnboardingCubit build() => OnboardingCubit(repository);

  blocTest<OnboardingCubit, int>(
    'next листает слайды, онбординг ещё не пройден',
    build: build,
    act: (cubit) async {
      expect(await cubit.next(), isFalse);
      expect(await cubit.next(), isFalse);
    },
    expect: () => [1, 2],
    verify: (_) => verifyNever(() => repository.markSeen()),
  );

  blocTest<OnboardingCubit, int>(
    'next на последнем слайде — markSeen и готово',
    build: build,
    seed: () => OnboardingCubit.lastPage,
    act: (cubit) async => expect(await cubit.next(), isTrue),
    expect: () => <int>[],
    verify: (_) => verify(() => repository.markSeen()).called(1),
  );

  blocTest<OnboardingCubit, int>(
    'skip с любого слайда — markSeen',
    build: build,
    act: (cubit) => cubit.skip(),
    verify: (_) => verify(() => repository.markSeen()).called(1),
  );
}
