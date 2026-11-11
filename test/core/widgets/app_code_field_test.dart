import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pinput/pinput.dart';
import 'package:spendyholik/core/widgets/app_code_field.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('вставка кода с лишними символами — 6 цифр и onCompleted', (
    tester,
  ) async {
    String? completed;
    await pumpPage(
      tester,
      Scaffold(body: AppCodeField(onCompleted: (code) => completed = code)),
    );

    await tester.enterText(find.byType(EditableText), 'код: 48-29 13.');
    await tester.pump();

    expect(completed, '482913');
  });

  testWidgets('буквы не проходят, неполный код onCompleted не зовёт', (
    tester,
  ) async {
    String? completed;
    await pumpPage(
      tester,
      Scaffold(body: AppCodeField(onCompleted: (code) => completed = code)),
    );

    await tester.enterText(find.byType(EditableText), 'abc123');
    await tester.pump();

    expect(completed, isNull);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('ошибка видна под полем; вставка из меню включена', (
    tester,
  ) async {
    await pumpPage(
      tester,
      Scaffold(
        body: AppCodeField(onCompleted: (_) {}, errorText: 'Неверный код'),
      ),
    );
    await tester.pump();

    expect(find.text('Неверный код'), findsOneWidget);
    final pinput = tester.widget<Pinput>(find.byType(Pinput));
    expect(pinput.length, 6);
    expect(pinput.enableInteractiveSelection, isTrue);
  });
}
