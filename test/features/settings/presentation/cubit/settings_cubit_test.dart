import 'package:bloc_test/bloc_test.dart';
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
    'setDarkTheme(true) → dark и сохранение',
    build: build,
    act: (cubit) => cubit.setDarkTheme(true),
    expect: () => [const AppSettings(themeMode: AppThemeMode.dark)],
    verify: (_) => verify(
      () => repository.save(const AppSettings(themeMode: AppThemeMode.dark)),
    ).called(1),
  );

  blocTest<SettingsCubit, AppSettings>(
    'setDarkTheme(false) → light',
    build: build,
    act: (cubit) => cubit.setDarkTheme(false),
    expect: () => [const AppSettings(themeMode: AppThemeMode.light)],
  );

  blocTest<SettingsCubit, AppSettings>(
    'переключатели уведомлений сохраняются',
    build: build,
    act: (cubit) => cubit
      ..setPush(false)
      ..setBudgetReminders(false)
      ..setWeeklyReport(true),
    expect: () => [
      const AppSettings(pushEnabled: false),
      const AppSettings(pushEnabled: false, budgetReminders: false),
      const AppSettings(
        pushEnabled: false,
        budgetReminders: false,
        weeklyReport: true,
      ),
    ],
    verify: (_) => verify(() => repository.save(any())).called(3),
  );
}
