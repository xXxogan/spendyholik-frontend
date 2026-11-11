import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/resend_code_button.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('отсчёт идёт — кнопка неактивна, видно сколько ждать', (
    tester,
  ) async {
    var taps = 0;
    await pumpPage(
      tester,
      Scaffold(body: ResendCodeButton(resendIn: 42, onPressed: () => taps++)),
    );

    expect(find.text('Отправить снова через 42 с'), findsOneWidget);
    await tester.tap(find.byType(TextButton));
    expect(taps, 0);
  });

  testWidgets('отсчёт кончился — «Отправить снова» нажимается', (tester) async {
    var taps = 0;
    await pumpPage(
      tester,
      Scaffold(body: ResendCodeButton(resendIn: 0, onPressed: () => taps++)),
    );

    await tester.tap(find.text('Отправить снова'));
    expect(taps, 1);
  });
}
