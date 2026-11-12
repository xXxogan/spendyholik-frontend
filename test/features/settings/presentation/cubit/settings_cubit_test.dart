import 'package:bloc_test/bloc_test.dart';

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/features/settings/data/models/app_settings.dart';
import 'package:spendyholik/features/settings/data/repositories/settings_repository.dart';
import 'package:spendyholik/features/settings/presentation/cubit/settings_cubit.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository repository;

  setUpAll(() => registerFallbackValue(const AppSettings()));

  setUp(() {
    repository = MockSettingsRepository();
    when(() => repository.save(any())).thenAnswer((_) async {});
  });

  SettingsCubit build() => SettingsCubit(repository);

  blocTest<SettingsCubit, AppSettings>(
    'load — сохранённые настройки',
    setUp: () => when(
      () => repository.load(),
    ).thenAnswer((_) async => const AppSettings(themeMode: AppThemeMode.light)),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [const AppSettings(themeMode: AppThemeMode.light)],
  );

  blocTest<SettingsCubit, AppSettings>(
    'setThemeMode(dark) → dark и сохранение',
    build: build,
    act: (cubit) => cubit.setThemeMode(AppThemeMode.dark),
    expect: () => [const AppSettings(themeMode: AppThemeMode.dark)],
    verify: (_) => verify(
      () => repository.save(const AppSettings(themeMode: AppThemeMode.dark)),
    ).called(1),
  );

  blocTest<SettingsCubit, AppSettings>(
    'setLanguage(en) → en и сохранение',
    build: build,
    act: (cubit) => cubit.setLanguage(AppLanguage.en),
    expect: () => [const AppSettings(language: AppLanguage.en)],
    verify: (_) => verify(
      () => repository.save(const AppSettings(language: AppLanguage.en)),
    ).called(1),
  );

  test('AppLanguage.locale: system → null, ru и en — свои', () {
    expect(AppLanguage.system.locale, isNull);
    expect(AppLanguage.ru.locale, const Locale('ru'));
    expect(AppLanguage.en.locale, const Locale('en'));
  });

  blocTest<SettingsCubit, AppSettings>(
    'после ручного выбора можно вернуть системную',
    build: build,
    act: (cubit) => cubit
      ..setThemeMode(AppThemeMode.light)
      ..setThemeMode(AppThemeMode.system),
    expect: () => [
      const AppSettings(themeMode: AppThemeMode.light),
      const AppSettings(),
    ],
    verify: (_) => verify(() => repository.save(const AppSettings())).called(1),
  );

  blocTest<SettingsCubit, AppSettings>(
    'push — локально, сохраняется',
    build: build,
    act: (cubit) => cubit.setPush(false),
    expect: () => [const AppSettings(pushEnabled: false)],
    verify: (_) =>
        verify(() => repository.save(const AppSettings(pushEnabled: false)))
            .called(1),
  );
}
