import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/widgets.dart';

import '../../helpers/pump_app.dart';

void main() {
  Future<Rect> open(WidgetTester tester, {required double width}) async {
    await pumpPage(
      tester,
      Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => showAppDateRangePicker(
              context,
              firstDate: DateTime(2016),
              lastDate: DateTime(2026, 10, 22),
            ),
            child: const Text('open'),
          ),
        ),
      ),
      width: width,
    );
    await tester.tap(find.text('open'));
    await settle(tester);
    return tester.getRect(find.byType(Dialog));
  }

  testWidgets('телефон — календарь на весь экран', (tester) async {
    final dialog = await open(tester, width: 600);

    expect(dialog.size, const Size(600, 900));
  });

  testWidgets('шире телефона — панель по центру', (tester) async {
    final dialog = await open(tester, width: 1280);

    expect(dialog.width, lessThanOrEqualTo(480));
    expect(dialog.height, lessThan(900));
    expect(dialog.center, const Offset(640, 450));
  });
}
