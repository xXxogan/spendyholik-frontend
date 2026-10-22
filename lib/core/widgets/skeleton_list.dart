import 'package:material_ui/material_ui.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.itemCount = 8, this.itemHeight = 64});

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          for (var i = 0; i < itemCount; i++)
            Container(
              height: itemHeight,
              margin: const .symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: .circular(16),
              ),
            ),
        ],
      ),
    );
  }
}
