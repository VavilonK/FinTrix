import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class AppBottomNavigationItem {
  const AppBottomNavigationItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
  });

  final String label;
  final Widget icon;
  final Widget? selectedIcon;
}

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
  }) : assert(items.length >= 2 && items.length <= 5),
       assert(currentIndex >= 0 && currentIndex < items.length);

  final List<AppBottomNavigationItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.bottomSheet,
        boxShadow: AppShadows.elevatedCard,
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.zero,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / items.length;
            final iconSize = (itemWidth * 0.32).clamp(22, 27).toDouble();

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final selected = index == currentIndex;
                final color = selected
                    ? AppColors.primaryBlue
                    : AppColors.secondaryText;

                return Expanded(
                  child: Semantics(
                    selected: selected,
                    button: true,
                    label: item.label,
                    child: Material(
                      color: AppColors.transparent,
                      child: InkWell(
                        onTap: () => onTap(index),
                        borderRadius: AppRadii.mediumBorder,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xxs,
                            vertical: AppSpacing.xxs,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: selected ? itemWidth * 0.45 : 0,
                                height: 3,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryBlue,
                                  borderRadius: AppRadii.capsule,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              IconTheme(
                                data: IconThemeData(
                                  color: color,
                                  size: iconSize,
                                ),
                                child: selected
                                    ? item.selectedIcon ?? item.icon
                                    : item.icon,
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.navigationLabel.copyWith(
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
