import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static const TextStyle display = TextStyle(
    color: AppColors.navy,
    fontSize: 32,
    height: 1.15,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.6,
  );

  static const TextStyle heading = TextStyle(
    color: AppColors.navy,
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
  );

  static const TextStyle sectionTitle = TextStyle(
    color: AppColors.navy,
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
  );

  static const TextStyle cardTitle = TextStyle(
    color: AppColors.navy,
    fontSize: 20,
    height: 1.25,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle body = TextStyle(
    color: AppColors.navy,
    fontSize: 16,
    height: 1.35,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodySecondary = TextStyle(
    color: AppColors.secondaryText,
    fontSize: 16,
    height: 1.35,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle caption = TextStyle(
    color: AppColors.secondaryText,
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle button = TextStyle(
    color: AppColors.surface,
    fontSize: 20,
    height: 1.2,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle balance = TextStyle(
    color: AppColors.navy,
    fontSize: 24,
    height: 1,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.3,
  );

  static const TextStyle navigationLabel = TextStyle(
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );
}
