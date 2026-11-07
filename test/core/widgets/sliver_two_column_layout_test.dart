import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/sliver_two_column_layout.dart';

import '../../helpers/pump_app.dart';

void main() {
  const primary = SliverToBoxAdapter(
    child: SizedBox(key: Key('primary'), height: 100),
  );
  const secondary = SliverToBoxAdapter(
    child: SizedBox(key: Key('secondary'), height: 100),
  );

  Future<void> pump(WidgetTester tester, double width) => pumpPage(
    tester,
    const CustomScrollView(
      slivers: [
        SliverTwoColumnLayout(primary: [primary], secondary: [secondary]),
      ],
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

  testWidgets('смена раскладки не пересоздаёт блоки', (tester) async {
    var created = 0;
    Future<void> pumpAt(double width) => pumpPage(
      tester,
      CustomScrollView(
        slivers: [
          SliverTwoColumnLayout(
            primary: [
              SliverToBoxAdapter(child: _Probe(onCreate: () => created++)),
            ],
            secondary: const [SliverToBoxAdapter(child: SizedBox(height: 100))],
          ),
        ],
      ),
      width: width,
    );

    await pumpAt(1280);
    await pumpAt(900);
    await pumpAt(1280);

    expect(created, 1);
  });
}

class _Probe extends StatefulWidget {
  const _Probe({required this.onCreate});

  final VoidCallback onCreate;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.onCreate();
  }

  @override
  Widget build(BuildContext context) => const SizedBox(height: 100);
}
