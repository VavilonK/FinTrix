abstract final class AppSpacing {
  /// Half-step used only for compact icon and text separation.
  static const double xxs = 4;

  /// Base spacing unit.
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
  static const double xxxl = 48;

  static const double minimumTouchTarget = 48;

  static double screenHorizontal(double width) {
    return (width * 0.05).clamp(md, xl).toDouble();
  }
}
