import 'package:material_ui/material_ui.dart';
import 'package:shimmer/shimmer.dart';

class TotalBalanceSkeleton extends StatelessWidget {
  const TotalBalanceSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: .circular(8),
      ),
    );

    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: .start,
        children: [
          bar(120, 14),
          const SizedBox(height: 10),
          bar(220, 36),
          const SizedBox(height: 10),
          bar(160, 14),
        ],
      ),
    );
  }
}
