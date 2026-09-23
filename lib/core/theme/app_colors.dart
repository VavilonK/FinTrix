import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primaryBlue = Color(0xFF2780F7);
  static const Color primaryBlueDark = Color(0xFF176AF3);
  static const Color primaryBlueLight = Color(0xFFDCEEFF);

  static const Color navy = Color(0xFF08154B);
  static const Color secondaryText = Color(0xFF596797);

  static const Color purple = Color(0xFF8649F4);
  static const Color purpleDark = Color(0xFF6530D7);
  static const Color yellow = Color(0xFFFFC43D);
  static const Color green = Color(0xFF55C969);
  static const Color pink = Color(0xFFF25375);
  static const Color orange = Color(0xFFFFA51F);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceTranslucent = Color(0xF2FFFFFF);
  static const Color surfaceSoft = Color(0xFFF8FAFF);
  static const Color backgroundLavender = Color(0xFFF2F4FF);
  static const Color borderLight = Color(0xFFE6EBF7);
  static const Color track = Color(0xFFDDE2EE);
  static const Color peachBackground = Color(0xFFFFE1D0);

  static const Color disabled = Color(0xFFB7BED3);
  static const Color cardShadow = Color(0x1F1C326F);
  static const Color controlShadow = Color(0x472780F7);
  static const Color scrim = Color(0x8F08102F);
  static const Color backgroundHighlight = Color(0x26FFFFFF);
  static const Color backgroundHighlightSoft = Color(0x0DFFFFFF);
  static const Color transparent = Colors.transparent;
}

abstract final class AppGradients {
  static const LinearGradient primaryCta = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF51A8FF), AppColors.primaryBlueDark],
  );

  static const LinearGradient levelBadge = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.purple, AppColors.purpleDark],
  );
}
