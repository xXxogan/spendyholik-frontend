import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

/// Низ ленивого списка операций: скелетон, пока идёт страница, или ошибка с
/// повтором.
class TransactionsLoadMoreRow extends StatelessWidget {
  const TransactionsLoadMoreRow({
    super.key,
    required this.failed,
    required this.onRetry,
  });

  /// false — страница ещё идёт.
  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (!failed) return const SkeletonList(itemCount: 1);
    final l10n = context.l10n;

    return Padding(
      padding: const .symmetric(vertical: 8),
      child: Wrap(
        alignment: .center,
        crossAxisAlignment: .center,
        spacing: 8,
        children: [
          Text(l10n.transactionsLoadMoreFailed),
          TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
        ],
      ),
    );
  }
}
