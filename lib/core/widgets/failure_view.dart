import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/widgets/failure_message.dart';
import 'package:spendyholik/l10n/l10n.dart';

class FailureView extends StatelessWidget {
  const FailureView({super.key, required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final message = failureMessage(l10n, failure);

    return Padding(
      padding: const .all(24),
      child: Column(
        mainAxisSize: .min,
        children: [
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: .center,
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
        ],
      ),
    );
  }
}
