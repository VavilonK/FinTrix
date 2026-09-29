import 'package:flutter/material.dart';

import '../../../core/state/app_controller.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_modal_sheet.dart';
import '../../../core/widgets/primary_gradient_button.dart';
import '../domain/parent_access_service.dart';

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
  final _repeatController = TextEditingController();
  bool _busy = false;
  bool _biometricAvailable = false;
  bool _checked = false;

  /// No stored PIN (e.g. data restored from a backup): the parent sets a new
  /// one here instead of being locked out.
  bool _needsNewPin = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checked) return;
    _checked = true;
    _checkBiometrics();
    _checkPin();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _repeatController.dispose();
    super.dispose();
  }

  Future<void> _checkPin() async {
    final state = AppScope.of(context);
    final hasPin = await state.hasParentPin();
    if (mounted && !hasPin && !state.isDemoMode) {
      setState(() => _needsNewPin = true);
    }
  }

  Future<void> _createPin() async {
    if (_busy) return;
    final pin = _pinController.text;
    if (!ParentAccessService.isValidPinFormat(pin)) {
      setState(() => _error = 'PIN — от 4 до 6 цифр.');
      return;
    }
    if (pin != _repeatController.text) {
      setState(() => _error = 'PIN не совпадают. Введите ещё раз.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final saved = await AppScope.of(context).createParentPin(pin);
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _error = 'Не удалось сохранить PIN. Попробуйте ещё раз.';
    });
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
    final demo = AppScope.of(context).isDemoMode;
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
          _needsNewPin
              ? 'Родительский PIN не найден на устройстве. '
                    'Придумайте новый PIN из 4–6 цифр.'
              : 'Введите PIN',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySecondary,
        ),
        if (demo) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Демо-режим: PIN ${AppController.demoParentPin}',
            key: const ValueKey('parent_unlock_demo_hint'),
            textAlign: TextAlign.center,
            style: AppTextStyles.cardTitle.copyWith(color: AppColors.purple),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const ValueKey('parent_unlock_pin'),
          controller: _pinController,
          autofocus: true,
          obscureText: true,
          maxLength: 6,
          keyboardType: TextInputType.number,
          textInputAction: _needsNewPin
              ? TextInputAction.next
              : TextInputAction.done,
          onSubmitted: (_) => _needsNewPin ? null : _verifyPin(),
          decoration: InputDecoration(
            labelText: _needsNewPin ? 'Новый PIN' : 'Родительский PIN',
            prefixIcon: const Icon(Icons.pin_rounded),
          ),
        ),
        if (_needsNewPin)
          TextField(
            key: const ValueKey('parent_unlock_pin_repeat'),
            controller: _repeatController,
            obscureText: true,
            maxLength: 6,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _createPin(),
            decoration: const InputDecoration(
              labelText: 'Повторите PIN',
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
          label: _needsNewPin ? 'Сохранить PIN и войти' : 'Войти',
          onPressed: _busy
              ? null
              : _needsNewPin
              ? _createPin
              : _verifyPin,
        ),
        if (_needsNewPin || demo)
          const SizedBox.shrink()
        else if (_biometricAvailable) ...[
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
