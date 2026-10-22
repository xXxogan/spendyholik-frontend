import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/two_column_layout.dart';

import '../../helpers/pump_app.dart';

void main() {
  const primary = SizedBox(key: Key('primary'), height: 100);
  const secondary = SizedBox(key: Key('secondary'), height: 100);

  Future<void> pump(WidgetTester tester, double width) => pumpPage(
    tester,
    const SingleChildScrollView(
      child: TwoColumnLayout(primary: [primary], secondary: [secondary]),
    ),
    width: width,
  );

  testWidgets('узкий и средний экран — блоки в столбец', (tester) async {
    for (final width in [400.0, 900.0]) {
      await pump(tester, width);

      final p = tester.getTopLeft(find.byKey(const Key('primary')));
      final s = tester.getTopLeft(find.byKey(const Key('secondary')));
      expect(s.dy, greaterThan(p.dy), reason: 'ширина $width');
      expect(s.dx, p.dx, reason: 'ширина $width');
    }
  });

  testWidgets('широкий экран — две колонки', (tester) async {
    await pump(tester, 1280);

    final p = tester.getTopLeft(find.byKey(const Key('primary')));
    final s = tester.getTopLeft(find.byKey(const Key('secondary')));
    expect(s.dy, p.dy);
    expect(s.dx, greaterThan(p.dx));
  });
}
