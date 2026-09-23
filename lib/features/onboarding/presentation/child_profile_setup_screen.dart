import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_gradient_button.dart';
import '../../profile/domain/profile_models.dart';
import 'widgets/onboarding_frame.dart';

class ChildProfileSetupResult {
  const ChildProfileSetupResult({required this.name, required this.age});

  final String name;
  final int age;
}

class ChildProfileSetupScreen extends StatefulWidget {
  const ChildProfileSetupScreen({required this.onCompleted, super.key});

  final ValueChanged<ChildProfileSetupResult> onCompleted;

  @override
  State<ChildProfileSetupScreen> createState() =>
      _ChildProfileSetupScreenState();
}

class _ChildProfileSetupScreenState extends State<ChildProfileSetupScreen> {
  final _nameController = TextEditingController();
  int _age = 8;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _continue() {
    final name = _nameController.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (name.isEmpty || name.length > ChildProfile.maximumNameLength) {
      setState(() {
        _error =
            'Введите имя длиной до ${ChildProfile.maximumNameLength} символов.';
      });
      return;
    }
    widget.onCompleted(ChildProfileSetupResult(name: name, age: _age));
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingFrame(
      icon: Icons.child_care_rounded,
      title: 'Данные ребёнка',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const ValueKey('onboarding_child_name'),
            controller: _nameController,
            maxLength: ChildProfile.maximumNameLength,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Имя ребёнка'),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Возраст', style: AppTextStyles.cardTitle),
          const SizedBox(height: 4),
          Text(
            'Возраст помогает подобрать подходящую сложность заданий.',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (
                var age = ChildProfile.minimumAge;
                age <= ChildProfile.maximumAge;
                age++
              )
                SizedBox.square(
                  dimension: 56,
                  child: Material(
                    color: age == _age
                        ? AppColors.primaryBlue
                        : AppColors.surface,
                    borderRadius: AppRadii.mediumBorder,
                    child: InkWell(
                      key: ValueKey('onboarding_age_$age'),
                      borderRadius: AppRadii.mediumBorder,
                      onTap: () => setState(() => _age = age),
                      child: Center(
                        child: Text(
                          '$age',
                          style: AppTextStyles.cardTitle.copyWith(
                            color: age == _age
                                ? AppColors.surface
                                : AppColors.navy,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(color: AppColors.pink),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          PrimaryGradientButton(
            key: const ValueKey('onboarding_child_continue'),
            label: 'Продолжить',
            onPressed: _continue,
          ),
        ],
      ),
    );
  }
}
