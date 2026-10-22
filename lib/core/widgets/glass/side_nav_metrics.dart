abstract final class SideNavMetrics {
  static const railWidth = 64.0;
  static const extendedWidth = 240.0;
  static const gap = 12.0;

  static double contentInset({required bool extended}) =>
      gap * 2 + (extended ? extendedWidth : railWidth);
}
