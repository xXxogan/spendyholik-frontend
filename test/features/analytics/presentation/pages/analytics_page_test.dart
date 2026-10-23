import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/analytics/data/models/models.dart';
import 'package:spendyholik/features/analytics/presentation/cubit/analytics_cubit.dart';
import 'package:spendyholik/features/analytics/presentation/pages/analytics_page.dart';
import 'package:spendyholik/features/categories/data/models/models.dart';

import '../../../../helpers/pump_app.dart';

class MockAnalyticsCubit extends MockCubit<AnalyticsState>
    implements AnalyticsCubit {}

void main() {
  late MockAnalyticsCubit cubit;

  const nbsp = ' ';
  final report = AnalyticsReport(
    period: DatePeriod(start: DateTime(2026, 10), end: DateTime(2026, 11)),
    income: 11850000,
    expense: 7410000,
    expenseChange: 0.12,
    expenseByCategory: const [
      CategoryShare(
        category: CategoryRef(
          id: 'housing',
          name: 'Жильё',
          icon: EntityIcon.home,
          color: EntityColor.orange,
        ),
        amount: 4500000,
        share: 0.607,
      ),
    ],
    monthly: const [],
  );

  setUpAll(() => registerFallbackValue(PeriodPreset.month));

  setUp(() => cubit = MockAnalyticsCubit());

  Future<void> pump(WidgetTester tester, AnalyticsState state) async {
    when(() => cubit.state).thenReturn(state);
    await pumpPage(
      tester,
      BlocProvider<AnalyticsCubit>.value(
        value: cubit,
        child: const AnalyticsView(),
      ),
    );
    await settle(tester);
  }

  testWidgets('доходы, расходы, итог и сравнение с прошлым месяцем', (
    tester,
  ) async {
    await pump(tester, AnalyticsState.loaded(report, .month, const [61]));

    expect(find.text('+118${nbsp}500$nbsp₽'), findsOneWidget);
    expect(find.text('−74${nbsp}100$nbsp₽'), findsOneWidget);
    expect(find.textContaining('+44${nbsp}400$nbsp₽'), findsOneWidget);
    expect(
      find.text('Расходы на 12% больше, чем в прошлом месяце'),
      findsOneWidget,
    );
  });

  testWidgets('категории: сумма и доля в процентах из Cubit', (tester) async {
    await pump(tester, AnalyticsState.loaded(report, .month, const [61]));

    expect(find.text('Жильё'), findsOneWidget);
    expect(find.text('45${nbsp}000$nbsp₽ · 61%'), findsOneWidget);
  });

  testWidgets('«Неделя» вызывает selectPeriod(week)', (tester) async {
    when(() => cubit.selectPeriod(any())).thenAnswer((_) async {});
    await pump(tester, AnalyticsState.loaded(report, .month, const [61]));

    await tester.tap(find.text('Неделя'));

    verify(() => cubit.selectPeriod(PeriodPreset.week)).called(1);
  });

  testWidgets('пустой период — текст, сегменты остаются', (tester) async {
    await pump(tester, const AnalyticsState.empty(.year));

    expect(find.text('Нет операций за этот период'), findsOneWidget);
    expect(find.text('Год'), findsOneWidget);
  });

  testWidgets('ошибка — «Повторить» вызывает load', (tester) async {
    when(() => cubit.load()).thenAnswer((_) async {});
    await pump(tester, const AnalyticsState.error(NetworkFailure(), .month));

    await tester.tap(find.text('Повторить'));

    verify(() => cubit.load()).called(1);
  });
}
