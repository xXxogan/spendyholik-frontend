import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/settings/data/repositories/repositories.dart';
import 'package:spendyholik/features/settings/presentation/cubit/data_reset_cubit.dart';

class MockDataResetRepository extends Mock implements DataResetRepository {}

void main() {
  late MockDataResetRepository repository;

  setUp(() => repository = MockDataResetRepository());

  blocTest<DataResetCubit, DataResetState>(
    'wipe: submitting, затем success; репозиторий вызван',
    build: () {
      when(() => repository.wipeAll()).thenAnswer((_) async {});
      return DataResetCubit(repository);
    },
    act: (cubit) => cubit.wipe(),
    expect: () => [
      const DataResetState(status: FormStatus.submitting),
      const DataResetState(status: FormStatus.success),
    ],
    verify: (_) => verify(() => repository.wipeAll()).called(1),
  );

  blocTest<DataResetCubit, DataResetState>(
    'ошибка репозитория: submitting, затем failure',
    build: () {
      when(() => repository.wipeAll()).thenThrow(const NetworkFailure());
      return DataResetCubit(repository);
    },
    act: (cubit) => cubit.wipe(),
    expect: () => [
      const DataResetState(status: FormStatus.submitting),
      const DataResetState(
        status: FormStatus.failure,
        failure: NetworkFailure(),
      ),
    ],
  );
}
