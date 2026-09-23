import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_gradient_button.dart';
import 'widgets/onboarding_frame.dart';

class SetupCompleteScreen extends StatefulWidget {
  const SetupCompleteScreen({
    required this.childName,
    required this.onStart,
    super.key,
  });

  final String childName;
  final Future<void> Function() onStart;

  @override
  State<SetupCompleteScreen> createState() => _SetupCompleteScreenState();
}

class _SetupCompleteScreenState extends State<SetupCompleteScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _start() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onStart();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Не удалось завершить настройку. Попробуйте ещё раз.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingFrame(
      icon: Icons.check_circle_rounded,
      title: 'Всё готово!',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Теперь можно передать устройство ребёнку — ${widget.childName}.\n'
            'Рыжик уже ждёт!',
            textAlign: TextAlign.center,
            style: AppTextStyles.cardTitle,
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
            key: const ValueKey('onboarding_finish'),
            label: 'Начать',
            onPressed: _busy ? null : _start,
          ),
        ],
      ),
    );
  }
}
