import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/widgets.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('большой заголовок в контенте и шапка управляются одним контроллером', (tester) async {
    await pumpPage(
      tester,
      const AppGlassScaffold(
        title: 'Счета',
        largeTitle: true,
        body: BaseLayout(largeTitle: 'Счета', children: [SizedBox(height: 2000)]),
      ),
    );
    await settle(tester);

    final largeTitle = tester.widget<GlassLargeTitle>(find.byType(GlassLargeTitle));
    final appBar = tester.widget<GlassAppBar>(find.byType(GlassAppBar));
    expect(largeTitle.text, 'Счета');
    expect(appBar.largeTitleController, same(largeTitle.controller));
  });

  testWidgets('без большого заголовка шапка обычная', (tester) async {
    await pumpPage(
      tester,
      const AppGlassScaffold(
        title: 'Счета',
        body: BaseLayout(children: [SizedBox(height: 2000)]),
      ),
    );
    await settle(tester);

    expect(find.byType(GlassLargeTitle), findsNothing);
    expect(tester.widget<GlassAppBar>(find.byType(GlassAppBar)).largeTitleController, isNull);
  });
}
