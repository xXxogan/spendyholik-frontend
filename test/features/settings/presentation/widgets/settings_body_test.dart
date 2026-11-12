import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/features/settings/data/models/models.dart';
import 'package:spendyholik/features/settings/presentation/cubit/data_reset_cubit.dart';
import 'package:spendyholik/features/settings/presentation/cubit/notification_preferences_cubit.dart';
import 'package:spendyholik/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:spendyholik/features/settings/presentation/widgets/widgets.dart';

import '../../../../helpers/pump_app.dart';

class MockSettingsCubit extends MockCubit<AppSettings>
    implements SettingsCubit {}

class MockNotificationPreferencesCubit
    extends MockCubit<NotificationPreferencesState>
    implements NotificationPreferencesCubit {}

class MockDataResetCubit extends MockCubit<DataResetState>
    implements DataResetCubit {}

const preferences = NotificationPreferences(
  budget: true,
  goal: false,
  recurring: true,
  income: true,
);

void main() {
  late MockSettingsCubit settings;
  late MockNotificationPreferencesCubit notifications;
  late MockDataResetCubit reset;

  setUpAll(() {
    registerFallbackValue(NotificationPreference.budget);
    registerFallbackValue(AppLanguage.system);
  });

  setUp(() {
    settings = MockSettingsCubit();
    when(() => settings.state).thenReturn(const AppSettings());
    notifications = MockNotificationPreferencesCubit();
    when(() => notifications.toggle(any(), any())).thenAnswer((_) async {});
    when(() => notifications.load()).thenAnswer((_) async {});
    when(() => settings.setLanguage(any())).thenReturn(null);
    reset = MockDataResetCubit();
    when(() => reset.state).thenReturn(const DataResetState());
  });

  Future<void> pump(WidgetTester tester) => pumpPage(
    tester,
    MultiBlocProvider(
      providers: [
        BlocProvider<SettingsCubit>.value(value: settings),
        BlocProvider<NotificationPreferencesCubit>.value(value: notifications),
        BlocProvider<DataResetCubit>.value(value: reset),
      ],
      child: const SingleChildScrollView(child: SettingsBody()),
    ),
  );

  bool switchValue(WidgetTester tester, String title) => tester
      .widget<SwitchListTile>(find.widgetWithText(SwitchListTile, title))
      .value;

  testWidgets('push и четыре серверных переключателя, без отчёта', (
    tester,
  ) async {
    when(() => notifications.state)
        .thenReturn(const NotificationPreferencesState.loaded(preferences));
    await pump(tester);

    expect(find.byType(SwitchListTile), findsNWidgets(5));
    expect(switchValue(tester, 'Push-уведомления'), isTrue);
    expect(switchValue(tester, 'Напоминания о бюджете'), isTrue);
    expect(switchValue(tester, 'Цели'), isFalse);
    expect(switchValue(tester, 'Регулярные платежи'), isTrue);
    expect(switchValue(tester, 'Доходы'), isTrue);
    expect(find.textContaining('Еженедельный'), findsNothing);
  });

  testWidgets('сегмент языка вызывает setLanguage', (tester) async {
    when(() => notifications.state)
        .thenReturn(const NotificationPreferencesState.loaded(preferences));
    await pump(tester);

    expect(find.text('Язык'), findsOneWidget);
    await tester.tap(find.text('English'));
    verify(() => settings.setLanguage(.en)).called(1);
    await tester.tap(find.text('Русский'));
    verify(() => settings.setLanguage(.ru)).called(1);
  });

  testWidgets('переключение уходит в Cubit уведомлений', (tester) async {
    when(() => notifications.state)
        .thenReturn(const NotificationPreferencesState.loaded(preferences));
    await pump(tester);

    await tester.tap(find.text('Цели'));
    await tester.tap(find.text('Доходы'));

    verify(() => notifications.toggle(.goal, true)).called(1);
    verify(() => notifications.toggle(.income, false)).called(1);
  });

  testWidgets('ошибка загрузки — «Повторить» перечитывает', (tester) async {
    when(() => notifications.state)
        .thenReturn(const NotificationPreferencesState.error(NetworkFailure()));
    await pump(tester);

    expect(find.byType(SwitchListTile), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    verify(() => notifications.load()).called(1);
  });

  testWidgets('несохранённое переключение — тост с причиной', (tester) async {
    whenListen(
      notifications,
      Stream.value(
        const NotificationPreferencesState.loaded(
          preferences,
          failure: NetworkFailure(),
        ),
      ),
      initialState: const NotificationPreferencesState.loaded(preferences),
    );
    await pump(tester);
    await settle(tester);

    expect(find.text('Нет соединения'), findsOneWidget);
  });
}
