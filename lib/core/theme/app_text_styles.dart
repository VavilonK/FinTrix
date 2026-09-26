import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static const String fontFamily = 'Nunito';

  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.navy,
    fontSize: 32,
    height: 1.15,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.6,
  );

  static const TextStyle heading = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.navy,
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
  );

  static const TextStyle screenTitle = heading;

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.navy,
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.navy,
    fontSize: 20,
    height: 1.25,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.navy,
    fontSize: 16,
    height: 1.35,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.secondaryText,
    fontSize: 16,
    height: 1.35,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.secondaryText,
    fontSize: 14,
    height: 1.35,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.navy,
    fontSize: 14,
    height: 1.25,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.secondaryText,
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.surface,
    fontSize: 20,
    height: 1.2,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle buttonCompact = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.surface,
    fontSize: 16,
    height: 1.2,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle balance = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.navy,
    fontSize: 24,
    height: 1,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.3,
  );

  static const TextStyle numericLarge = balance;

  static const TextStyle navigationLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );
}
