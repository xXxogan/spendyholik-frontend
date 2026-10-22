import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.dart';
import 'package:spendyholik/app/theme/app_theme.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/widgets/glass/glass.dart';
import 'package:spendyholik/features/accounts/data/models/models.dart';
import 'package:spendyholik/features/accounts/data/repositories/repositories.dart';
import 'package:spendyholik/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:spendyholik/features/accounts/presentation/cubit/total_balance_cubit.dart';
import 'package:spendyholik/l10n/l10n.dart';

import '../../../../helpers/pump_app.dart';

Future<void> pumpApp(
  WidgetTester tester, {
  required double width,
  Locale locale = const Locale('ru'),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp.router(
      builder: (_, child) => Material(type: .transparency, child: child),
      theme: AppTheme.light(),
      locale: locale,
      localizationsDelegates: AppLocalizationsSetup.delegates,
      supportedLocales: AppLocalizationsSetup.supportedLocales,
      routerConfig: AppRouter().config(),
    ),
  );
  await settle(tester);
}

class MockAccountRepository extends Mock implements AccountRepository {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

void main() {
  // Оболочке не важны данные вкладок — Главной хватает пустых счетов.
  setUp(() {
    final repository = MockAccountRepository();
    final bus = MockDataChangeBus();
    when(() => bus.changes).thenAnswer((_) => const Stream.empty());
    when(() => repository.getAccounts()).thenAnswer((_) async => []);
    when(() => repository.getTotalBalance())
        .thenAnswer((_) async => const TotalBalance(total: 0, monthDelta: 0));
    getIt
      ..registerFactory(() => AccountsCubit(repository, bus))
      ..registerFactory(() => TotalBalanceCubit(repository, bus));
  });

  tearDown(getIt.reset);

  testWidgets('узкий экран — нижняя навигация, без боковой', (tester) async {
    await pumpApp(tester, width: 400);

    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(find.byType(AppSideNav), findsNothing);
  });

  testWidgets('средний экран — узкая боковая панель', (tester) async {
    await pumpApp(tester, width: 800);

    expect(find.byType(AppBottomNav), findsNothing);
    final sideNav = tester.widget<AppSideNav>(find.byType(AppSideNav));
    expect(sideNav.extended, isFalse);
  });

  testWidgets('широкий экран — широкая боковая панель', (tester) async {
    await pumpApp(tester, width: 1280);

    expect(find.byType(AppBottomNav), findsNothing);
    final sideNav = tester.widget<AppSideNav>(find.byType(AppSideNav));
    expect(sideNav.extended, isTrue);
  });

  testWidgets('выбранная вкладка сохраняется при смене ширины', (tester) async {
    await pumpApp(tester, width: 400);
    await tester.tap(find.text('Аналитика').first);
    await settle(tester);

    tester.view.physicalSize = const Size(1280, 900);
    await settle(tester);

    final sideNav = tester.widget<AppSideNav>(find.byType(AppSideNav));
    expect(sideNav.selectedIndex, 2);
  });

  testWidgets('подписи навигации на языке приложения', (tester) async {
    await pumpApp(tester, width: 400, locale: const Locale('en'));

    // GlassTabBar рисует слой всех вкладок и поверх него выбранную — подпись выбранной дважды.
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Budgets'), findsWidgets);
    expect(find.text('Главная'), findsNothing);
  });
}
