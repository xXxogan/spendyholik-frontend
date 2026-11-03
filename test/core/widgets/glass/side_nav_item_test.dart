import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/glass/app_nav_destination.dart';
import 'package:spendyholik/core/widgets/glass/side_nav_item.dart';

import '../../../helpers/pump_app.dart';

AppNavDestination destination({int badgeCount = 0}) => AppNavDestination(
  icon: Icons.notifications_outlined,
  selectedIcon: Icons.notifications,
  label: 'Уведомления',
  badgeCount: badgeCount,
);

Future<void> pumpItem(
  WidgetTester tester,
  AppNavDestination destination, {
  required bool extended,
}) => pumpPage(
  tester,
  SizedBox(
    width: extended ? 224 : 48,
    child: SideNavItem(
      destination: destination,
      selected: false,
      extended: extended,
      onTap: () {},
    ),
  ),
);

void main() {
  testWidgets('широкая панель — число справа от подписи', (tester) async {
    await pumpItem(tester, destination(badgeCount: 3), extended: true);

    expect(find.text('Уведомления'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('рейл — бейдж с числом на иконке', (tester) async {
    await pumpItem(tester, destination(badgeCount: 3), extended: false);

    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('3')),
      findsOneWidget,
    );
  });

  testWidgets('ноль — без счётчика', (tester) async {
    await pumpItem(tester, destination(), extended: true);

    expect(find.byType(Badge), findsNothing);
    expect(find.text('0'), findsNothing);
  });
}
