import 'package:flutter/material.dart';

import '../../../core/state/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_modal_sheet.dart';
import '../../../core/widgets/primary_gradient_button.dart';

Future<bool> showParentUnlockSheet(BuildContext context) async {
  final result = await showAppModalSheet<bool>(
    context: context,
    builder: (_) => const ParentUnlockSheet(),
  );
  return result ?? false;
}

class ParentUnlockSheet extends StatefulWidget {
  const ParentUnlockSheet({super.key});

  @override
  State<ParentUnlockSheet> createState() => _ParentUnlockSheetState();
}

class _ParentUnlockSheetState extends State<ParentUnlockSheet> {
  final _pinController = TextEditingController();
  bool _busy = false;
  bool _biometricAvailable = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkBiometrics();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    final state = AppScope.of(context);
    final available =
        state.parentProfile.biometricEnabled &&
        await state.isParentBiometricAvailable();
    if (mounted) setState(() => _biometricAvailable = available);
  }

  Future<void> _verifyPin() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final verified = await AppScope.of(context)
        .verifyParentPin(_pinController.text);
    if (!mounted) return;
    if (verified) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _error = 'PIN не совпал. Попробуйте ещё раз.';
    });
  }

  Future<void> _useBiometrics() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final authenticated = await AppScope.of(context)
        .authenticateParentWithBiometrics();
    if (!mounted) return;
    if (authenticated) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _error = 'Биометрия не сработала. Введите родительский PIN.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.admin_panel_settings_rounded,
          size: 52,
          color: AppColors.primaryBlue,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Для родителей',
          textAlign: TextAlign.center,
          style: AppTextStyles.heading,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Введите PIN',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySecondary,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const ValueKey('parent_unlock_pin'),
          controller: _pinController,
          autofocus: true,
          obscureText: true,
          maxLength: 6,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _verifyPin(),
          decoration: const InputDecoration(
            labelText: 'Родительский PIN',
            prefixIcon: Icon(Icons.pin_rounded),
          ),
        ),
        if (_error != null) ...[
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(color: AppColors.pink),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        PrimaryGradientButton(
          key: const ValueKey('parent_unlock_continue'),
          label: 'Войти',
          onPressed: _busy ? null : _verifyPin,
        ),
        if (_biometricAvailable) ...[
          const SizedBox(height: AppSpacing.xs),
          TextButton.icon(
            key: const ValueKey('parent_unlock_biometric'),
            onPressed: _busy ? null : _useBiometrics,
            icon: const Icon(Icons.fingerprint_rounded),
            label: const Text('Использовать биометрию'),
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Если PIN утрачен, безопасное восстановление возможно только '
            'через ранее включённую биометрию. Скрытого обхода PIN нет.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ],
    );
  }
}
