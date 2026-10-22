import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/widgets.dart';

import '../../../helpers/pump_app.dart';

void main() {
  Future<void> open(
    WidgetTester tester, {
    required String cancel,
    required String confirm,
  }) async {
    await pumpPage(
      tester,
      Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => showAppConfirmDialog(
              context,
              title: 'Архивировать счёт?',
              confirmLabel: confirm,
              cancelLabel: cancel,
              destructive: true,
            ),
            child: const Text('open'),
          ),
        ),
      ),
      width: 360,
    );
    await tester.tap(find.text('open'));
    await settle(tester);
  }

  testWidgets('короткие подписи — кнопки в ряд', (tester) async {
    await open(tester, cancel: 'Нет', confirm: 'Да');

    expect(
      tester.getTopLeft(find.text('Нет')).dy,
      tester.getTopLeft(find.text('Да')).dy,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'подпись не помещается в половину — столбиком, действие над отменой, без переполнения',
    (tester) async {
      await open(
        tester,
        cancel: 'Отмена',
        confirm: 'Архивировать безвозвратно',
      );

      expect(
        tester.getTopLeft(find.text('Архивировать безвозвратно')).dy,
        lessThan(tester.getTopLeft(find.text('Отмена')).dy),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('кнопки возвращают выбор', (tester) async {
    bool? result;
    await pumpPage(
      tester,
      Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () async => result = await showAppConfirmDialog(
              context,
              title: 't',
              confirmLabel: 'Да',
              cancelLabel: 'Нет',
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await settle(tester);
    await tester.tap(find.text('Да'));
    await settle(tester);

    expect(result, isTrue);
  });
}
