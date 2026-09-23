import 'package:flutter/material.dart';

import '../../../../core/state/app_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_modal_sheet.dart';
import '../../../../core/widgets/primary_gradient_button.dart';
import '../../../profile/domain/profile_models.dart';

Future<void> showEditChildProfileSheet({
  required BuildContext context,
  required AppController state,
  bool focusName = false,
}) {
  return showAppModalSheet<void>(
    context: context,
    builder: (_) => EditChildProfileSheet(state: state, focusName: focusName),
  );
}

class EditChildProfileSheet extends StatefulWidget {
  const EditChildProfileSheet({
    required this.state,
    this.focusName = false,
    super.key,
  });

  final AppController state;
  final bool focusName;

  @override
  State<EditChildProfileSheet> createState() => _EditChildProfileSheetState();
}

class _EditChildProfileSheetState extends State<EditChildProfileSheet> {
  late final TextEditingController _nameController;
  late int _age;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.state.childName);
    _age = widget.state.age;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (name.isEmpty || name.length > ChildProfile.maximumNameLength) {
      setState(() {
        _error =
            'Введите имя длиной до ${ChildProfile.maximumNameLength} символов.';
      });
      return;
    }
    widget.state.updateChildProfile(name: name, age: _age);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Данные ребёнка', style: AppTextStyles.heading),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const ValueKey('adult_child_name_field'),
          controller: _nameController,
          autofocus: widget.focusName,
          maxLength: ChildProfile.maximumNameLength,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Имя ребёнка'),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('Возраст', style: AppTextStyles.cardTitle),
        const SizedBox(height: 4),
        Text(
          'Возраст влияет на сложность будущих заданий. Текущая миссия не изменится.',
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
                      : AppColors.surfaceSoft,
                  borderRadius: AppRadii.mediumBorder,
                  child: InkWell(
                    key: ValueKey('adult_child_age_$age'),
                    onTap: () => setState(() => _age = age),
                    borderRadius: AppRadii.mediumBorder,
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
          const SizedBox(height: AppSpacing.xs),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(color: AppColors.pink),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        PrimaryGradientButton(
          key: const ValueKey('adult_child_profile_save'),
          label: 'Сохранить',
          onPressed: _save,
        ),
      ],
    );
  }
}
