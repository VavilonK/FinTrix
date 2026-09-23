import 'package:flutter/material.dart';

import '../../../core/state/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_gradient_button.dart';
import '../../../core/widgets/rounded_surface_card.dart';
import '../../adult/domain/parent_access_service.dart';
import 'widgets/onboarding_frame.dart';

class ParentAccessSetupScreen extends StatefulWidget {
  const ParentAccessSetupScreen({required this.onCompleted, super.key});

  final ValueChanged<bool> onCompleted;

  @override
  State<ParentAccessSetupScreen> createState() =>
      _ParentAccessSetupScreenState();
}

class _ParentAccessSetupScreenState extends State<ParentAccessSetupScreen> {
  final _firstController = TextEditingController();
  final _repeatController = TextEditingController();
  bool _showRepeat = false;
  bool _busy = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadBiometricAvailability();
  }

  @override
  void dispose() {
    _firstController.dispose();
    _repeatController.dispose();
    super.dispose();
  }

  Future<void> _loadBiometricAvailability() async {
    final available = await AppScope.of(context).isParentBiometricAvailable();
    if (mounted) setState(() => _biometricAvailable = available);
  }

  Future<void> _continue() async {
    if (_busy) return;
    final first = _firstController.text;
    if (!ParentAccessService.isValidPinFormat(first)) {
      setState(() => _error = 'PIN должен содержать от 4 до 6 цифр.');
      return;
    }
    if (!_showRepeat) {
      setState(() {
        _showRepeat = true;
        _error = null;
      });
      return;
    }
    if (_repeatController.text != first) {
      setState(() => _error = 'PIN-коды не совпадают. Попробуйте ещё раз.');
      return;
    }

    setState(() => _busy = true);
    final saved = await AppScope.of(context).createParentPin(first);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!saved) {
      setState(() => _error = 'Не удалось сохранить PIN. Попробуйте ещё раз.');
      return;
    }
    widget.onCompleted(_biometricEnabled);
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingFrame(
      icon: Icons.admin_panel_settings_rounded,
      title: 'Родительский доступ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _showRepeat ? 'Повторите PIN' : 'Создайте PIN из 4–6 цифр',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const ValueKey('parent_pin_create'),
            controller: _firstController,
            enabled: !_showRepeat,
            autofocus: true,
            obscureText: true,
            maxLength: 6,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'PIN'),
          ),
          if (_showRepeat) ...[
            const SizedBox(height: AppSpacing.xs),
            TextField(
              key: const ValueKey('parent_pin_repeat'),
              controller: _repeatController,
              autofocus: true,
              obscureText: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Повторите PIN'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(color: AppColors.pink),
            ),
          ],
          if (_biometricAvailable) ...[
            const SizedBox(height: AppSpacing.sm),
            RoundedSurfaceCard(
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                key: const ValueKey('onboarding_biometric_switch'),
                minTileHeight: 56,
                title: const Text('Использовать биометрию'),
                subtitle: const Text('PIN всегда останется доступен'),
                secondary: const Icon(Icons.fingerprint_rounded),
                value: _biometricEnabled,
                onChanged: (value) => setState(() => _biometricEnabled = value),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          PrimaryGradientButton(
            key: const ValueKey('parent_pin_continue'),
            label: _showRepeat ? 'Сохранить PIN' : 'Продолжить',
            onPressed: _busy ? null : _continue,
          ),
        ],
      ),
    );
  }
}
