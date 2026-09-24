import 'package:finance_pet/app/app.dart';
import 'package:finance_pet/core/state/app_controller.dart';
import 'package:finance_pet/core/widgets/app_bottom_navigation.dart';
import 'package:finance_pet/core/widgets/app_settings_button.dart';
import 'package:finance_pet/features/adult/domain/parent_access_service.dart';
import 'package:finance_pet/features/budget/presentation/budget_screen.dart';
import 'package:finance_pet/features/goals/presentation/goals_screen.dart';
import 'package:finance_pet/features/home/presentation/home_screen.dart';
import 'package:finance_pet/features/profile/presentation/profile_screen.dart';
import 'package:finance_pet/features/tasks/presentation/tasks_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [
    const Size(360, 640),
    const Size(360, 800),
    const Size(390, 844),
    const Size(412, 915),
  ]) {
    testWidgets('main tabs fit ${size.width}×${size.height} at 1×', (
      tester,
    ) async {
      await _prepare(tester, size: size, textScale: 1);
      await _checkMainTabs(tester);
    });
  }

  for (final textScale in [1.3, 1.5, 2.0]) {
    testWidgets('main tabs remain usable at 360×800, $textScale× text', (
      tester,
    ) async {
      await _prepare(tester, size: const Size(360, 800), textScale: textScale);
      await _checkMainTabs(tester);
    });
  }

  testWidgets('header settings work on all tabs that show a gear', (
    tester,
  ) async {
    await _prepare(tester, size: const Size(412, 915), textScale: 1);
    final destinations = find.descendant(
      of: find.byType(AppBottomNavigation),
      matching: find.byType(InkWell),
    );
    for (final index in [0, 2, 3, 4]) {
      if (index != 0) {
        await tester.tap(destinations.at(index));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byType(AppSettingsButton));
      await tester.pumpAndSettle();
      expect(find.text('Настройки'), findsOneWidget);
      Navigator.of(tester.element(find.text('Настройки'))).pop();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Tasks balance plus opens the shared quick actions', (
    tester,
  ) async {
    await _prepare(tester, size: const Size(412, 915), textScale: 1);
    final destinations = find.descendant(
      of: find.byType(AppBottomNavigation),
      matching: find.byType(InkWell),
    );
    await tester.tap(destinations.at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(InkResponse));
    await tester.pumpAndSettle();
    expect(find.text('Как получить или распределить монеты?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _prepare(
  WidgetTester tester, {
  required Size size,
  required double textScale,
}) async {
  await tester.binding.setSurfaceSize(size);
  tester.binding.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() async {
    tester.binding.platformDispatcher.clearTextScaleFactorTestValue();
    await tester.binding.setSurfaceSize(null);
  });
  final controller = AppController(
    parentAccessService: ParentAccessService(
      MemoryParentCredentialStore(),
      const UnavailableParentBiometricAuthenticator(),
    ),
  );
  await controller.createParentPin('4826');
  await controller.completeParentSetup(childName: 'Миша', age: 8);
  await tester.pumpWidget(App(controller: controller));
  await tester.pumpAndSettle();
}

Future<void> _checkMainTabs(WidgetTester tester) async {
  expect(find.byType(HomeScreen), findsOneWidget);
  expect(tester.takeException(), isNull);
  final destinations = find.descendant(
    of: find.byType(AppBottomNavigation),
    matching: find.byType(InkWell),
  );
  expect(destinations, findsNWidgets(5));
  for (final (index, screen) in <Type>[
    TasksScreen,
    BudgetScreen,
    GoalsScreen,
    ProfileScreen,
  ].indexed) {
    await tester.tap(destinations.at(index + 1));
    await tester.pumpAndSettle();
    expect(find.byType(screen), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'tab ${index + 1}: $screen');
  }
}
