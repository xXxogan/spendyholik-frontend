import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/widgets.dart';

import '../../../helpers/pump_app.dart';

void main() {
  Future<Rect> pumpAction(WidgetTester tester, {double leftInset = 0}) async {
    final scaffold = AppGlassScaffold(
      title: 'Счета',
      actions: [
        AppGlassIconButton(icon: Icons.add, tooltip: 'add', onPressed: () {}),
      ],
      body: const SizedBox(),
    );
    await pumpPage(
      tester,
      leftInset == 0
          ? scaffold
          : ShellScope(leftInset: leftInset, child: scaffold),
      width: 1280,
    );
    await settle(tester);
    return tester.getRect(find.byType(AppGlassIconButton));
  }

  testWidgets('с боковой панелью — кнопки шапки вровень с верхом панели', (
    tester,
  ) async {
    final action = await pumpAction(
      tester,
      leftInset: SideNavMetrics.contentInset(extended: true),
    );

    expect(action.top, SideNavMetrics.gap);
  });

  testWidgets('телефон — над кнопками место под бейдж со счётчиком', (
    tester,
  ) async {
    final action = await pumpAction(tester);

    // Бейдж Badge с числом выступает над иконкой примерно на 8.
    expect(action.top, greaterThanOrEqualTo(8));
  });

  testWidgets('кнопки справа — с отступом от края', (tester) async {
    final action = await pumpAction(tester);

    expect(1280 - action.right, 16);
  });
}
