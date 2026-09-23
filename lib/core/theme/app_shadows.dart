import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.cardShadow,
      offset: Offset(0, 6),
      blurRadius: 20,
    ),
  ];

  static const List<BoxShadow> elevatedCard = [
    BoxShadow(
      color: AppColors.cardShadow,
      offset: Offset(0, 10),
      blurRadius: 28,
    ),
  ];

  static const List<BoxShadow> primaryControl = [
    BoxShadow(
      color: AppColors.controlShadow,
      offset: Offset(0, 8),
      blurRadius: 22,
    ),
  ];
}
