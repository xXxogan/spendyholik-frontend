import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/network/network_status.dart';
import 'package:spendyholik/core/widgets/offline_banner.dart';

import '../../helpers/pump_app.dart';

void main() {
  late NetworkStatus status;

  setUp(() => status = NetworkStatus());
  tearDown(() => status.close());

  Future<void> pump(WidgetTester tester) => pumpPage(
    tester,
    BlocProvider.value(
      value: status,
      child: const Stack(children: [OfflineBanner()]),
    ),
  );

  testWidgets('сеть есть — плашки нет', (tester) async {
    await pump(tester);
    expect(find.text('Нет сети'), findsNothing);
  });

  testWidgets('показ из кэша — плашка видна, сеть вернулась — скрыта', (
    tester,
  ) async {
    await pump(tester);

    status.reportOffline();
    await tester.pumpAndSettle();
    expect(find.text('Нет сети'), findsOneWidget);

    status.reportOnline();
    await tester.pumpAndSettle();
    expect(find.text('Нет сети'), findsNothing);
  });
}
