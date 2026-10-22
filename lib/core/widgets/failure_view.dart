import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/l10n/l10n.dart';

class FailureView extends StatelessWidget {
  const FailureView({super.key, required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final message = switch (failure) {
      NetworkFailure() => l10n.errorNetwork,
      NotFoundFailure() => l10n.errorNotFound,
      _ => l10n.errorUnknown,
    };

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
        ],
      ),
    );
  }
}
