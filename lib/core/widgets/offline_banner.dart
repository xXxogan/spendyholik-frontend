import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/network/network_status.dart';
import 'package:spendyholik/l10n/l10n.dart';

/// Пометка «данные из кэша» поверх оболочки; кладётся в Stack.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.leftInset = 0});

  /// Ширина боковой панели: плашка центрируется по контенту, а не по окну.
  final double leftInset;

  static const _duration = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    final offline = !context.watch<NetworkStatus>().state;

    return Positioned(
      top: MediaQuery.paddingOf(context).top + 8,
      left: leftInset,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: AnimatedSwitcher(
            duration: _duration,
            child: offline
                ? GlassChip(
                    key: const ValueKey('offline'),
                    label: context.l10n.offlineBanner,
                    icon: const Icon(Icons.cloud_off_rounded),
                    useOwnLayer: true,
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
