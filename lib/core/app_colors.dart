import 'dart:ui';

class AppColors {
  static const Color espresso = Color(0xFF2B1711);
  static const Color cocoa = Color(0xFF4A2C23);
  static const Color caramel = Color(0xFFC97C5D);
  static const Color matcha = Color(0xFF7A8F5C);
  static const Color crema = Color(0xFFF6EEE7);
  static const Color oat = Color(0xFFF1E3D2);
  static const Color ink = Color(0xFF1B1A17);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF7F1EA);
  static const Color error = Color(0xFFB3261E);
}

extension ColorOpacityValue on Color {
  Color withOpacityValue(double opacity) =>
      withAlpha((opacity * 255).round());
}
