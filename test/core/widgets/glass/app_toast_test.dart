import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/widgets.dart';

import '../../../helpers/pump_app.dart';

void main() {
  Future<void> show(WidgetTester tester, {double leftInset = 0}) async {
    await pumpPage(
      tester,
      ShellScope(
        leftInset: leftInset,
        child: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showAppToast(context, 'Счёт сохранён'),
              child: const Text('show'),
            ),
          ),
        ),
      ),
      width: 1280,
    );
    await tester.tap(find.text('show'));
    await settle(tester);
  }

  testWidgets('тост правее боковой панели и не шире формы', (tester) async {
    await show(tester, leftInset: 300);

    final rect = tester.getRect(find.byType(GlassToast));
    expect(rect.left, greaterThanOrEqualTo(300));
    expect(rect.width, lessThanOrEqualTo(560));

    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('сам исчезает', (tester) async {
    await show(tester);
    expect(find.text('Счёт сохранён'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Счёт сохранён'), findsNothing);
  });
}
