import 'package:finance_pet/core/theme/app_colors.dart';
import 'package:finance_pet/core/theme/app_text_styles.dart';
import 'package:finance_pet/core/widgets/amount_stepper.dart';
import 'package:finance_pet/core/widgets/app_settings_button.dart';
import 'package:finance_pet/core/widgets/currency_balance_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shared controls have readable labels and 48dp targets', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: AppColors.surface,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Общие действия', style: AppTextStyles.body),
                const SizedBox(height: 24),
                CurrencyBalanceChip(amount: '1 250', onAdd: () {}),
                const SizedBox(height: 24),
                AmountStepper(
                  value: 300,
                  onDecrease: () {},
                  onIncrease: () {},
                  keyPrefix: 'accessibility_stepper',
                ),
                const SizedBox(height: 24),
                AppSettingsButton(onPressed: () {}),
              ],
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('accessibility_stepper_minus'))),
      const Size(48, 48),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('accessibility_stepper_plus'))),
      const Size(48, 48),
    );
    expect(tester.getSize(find.byType(InkResponse)), const Size(48, 48));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}
