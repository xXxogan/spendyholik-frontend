import 'package:material_ui/material_ui.dart';

/// Колонка экранов входа: по центру, не шире формы, с прокруткой под клавиатуру.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.children});

  final List<Widget> children;

  static const _maxWidth = 400.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const .all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxWidth),
              child: Column(crossAxisAlignment: .stretch, children: children),
            ),
          ),
        ),
      ),
    );
  }
}
