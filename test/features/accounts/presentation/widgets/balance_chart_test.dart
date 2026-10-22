import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/models/currency.dart';
import 'package:spendyholik/features/accounts/data/models/account_model.dart';
import 'package:spendyholik/features/accounts/presentation/widgets/balance_chart.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  final history = [
    BalancePoint(at: DateTime(2026, 10, 1), balance: 1000000),
    BalancePoint(at: DateTime(2026, 10, 3, 12), balance: 880000),
    BalancePoint(at: DateTime(2026, 10, 10), balance: 2000000),
  ];

  Future<LineChartBarData> pumpChart(WidgetTester tester) async {
    await pumpPage(
      tester,
      BalanceChart(
        history: history,
        color: Colors.blue,
        currency: Currency.rub,
      ),
    );
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    return chart.data.lineBarsData.single;
  }

  testWidgets('баланс меняется скачком в момент операции — ступенчатая линия', (
    tester,
  ) async {
    final bar = await pumpChart(tester);

    expect(bar.isStepLineChart, isTrue);
    expect(
      bar.lineChartStepData.stepDirection,
      LineChartStepData.stepDirectionForward,
    );
    expect(bar.isCurved, isFalse);
  });

  testWidgets('точки видны и стоят по времени, а не по номеру', (tester) async {
    final bar = await pumpChart(tester);

    expect(bar.dotData.show, isTrue);
    expect(bar.spots.map((s) => s.x), [0, 2.5, 9]);
    expect(bar.spots.map((s) => s.y), [10000, 8800, 20000]);
  });
}
