import 'dart:convert';

import 'package:finance_pet/app/app.dart';
import 'package:finance_pet/core/state/app_controller.dart';
import 'package:finance_pet/core/storage/app_database.dart';
import 'package:finance_pet/core/storage/app_state_repository.dart';
import 'package:finance_pet/features/adult/domain/parent_access_service.dart';
import 'package:finance_pet/features/adult/presentation/adult_dashboard_screen.dart';
import 'package:finance_pet/features/adult/presentation/parent_unlock_sheet.dart';
import 'package:finance_pet/features/home/presentation/home_screen.dart';
import 'package:finance_pet/features/onboarding/presentation/parent_welcome_screen.dart';
import 'package:finance_pet/features/profile/domain/profile_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('parent PIN verifier survives service recreation', () async {
    final store = MemoryParentCredentialStore();
    final first = ParentAccessService(
      store,
      const UnavailableParentBiometricAuthenticator(),
    );
    expect(await first.setPin('4826'), isTrue);

    final restarted = ParentAccessService(
      store,
      const UnavailableParentBiometricAuthenticator(),
    );
    expect(await restarted.verifyPin('4826'), isTrue);
    expect(await restarted.verifyPin('1111'), isFalse);
  });

  testWidgets('clean install shows ParentWelcome and blocks Child Home', (
    tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.byType(ParentWelcomeScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('wrong PIN keeps dashboard locked and correct PIN opens it', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = await _configuredController();

    await tester.pumpWidget(App(controller: controller));
    await tester.pumpAndSettle();
    await _openUnlock(tester);

    await tester.enterText(
      find.byKey(const ValueKey('parent_unlock_pin')),
      '1111',
    );
    await tester.tap(find.byKey(const ValueKey('parent_unlock_continue')));
    await tester.pumpAndSettle();

    expect(find.text('PIN не совпал. Попробуйте ещё раз.'), findsOneWidget);
    expect(find.byType(AdultDashboardScreen), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('parent_unlock_pin')),
      '4826',
    );
    await tester.tap(find.byKey(const ValueKey('parent_unlock_continue')));
    await tester.pumpAndSettle();

    expect(find.byType(AdultDashboardScreen), findsOneWidget);
  });

  testWidgets('leaving adult section requires a new unlock', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = await _configuredController();

    await tester.pumpWidget(App(controller: controller));
    await tester.pumpAndSettle();
    await _openUnlock(tester);
    await tester.enterText(
      find.byKey(const ValueKey('parent_unlock_pin')),
      '4826',
    );
    await tester.tap(find.byKey(const ValueKey('parent_unlock_continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Назад'));
    await tester.pumpAndSettle();

    await _openUnlock(tester);
    expect(find.byType(ParentUnlockSheet), findsOneWidget);
    expect(find.byType(AdultDashboardScreen), findsNothing);
  });

  test('parent PIN is absent from ordinary snapshot JSON', () async {
    final controller = await _configuredController();
    final encoded = jsonEncode(controller.toSnapshot().toJson());

    expect(encoded, isNot(contains('4826')));
    expect(encoded, isNot(contains('parent_access_pin')));
  });

  test('parent PIN is absent from SQLite app state and metadata', () async {
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final repository = AppStateRepository(database);
    final store = MemoryParentCredentialStore();
    final service = ParentAccessService(
      store,
      const UnavailableParentBiometricAuthenticator(),
    );
    final controller = AppController(
      repository: repository,
      parentAccessService: service,
    );
    addTearDown(controller.dispose);
    await controller.createParentPin('4826');
    await controller.completeParentSetup(childName: 'Миша', age: 8);
    await controller.flushPersistence();

    final sqlite = await database.database;
    final stateRows = await sqlite.query(AppDatabase.tableAppState);
    final metadataRows = await sqlite.query(AppDatabase.tableAppMetadata);
    final persisted = jsonEncode([...stateRows, ...metadataRows]);

    expect(persisted, isNot(contains('4826')));
    expect(await store.readPin(), '4826');
  });

  testWidgets('app restart requires parent unlock again', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = MemoryParentCredentialStore();
    final service = ParentAccessService(
      store,
      const UnavailableParentBiometricAuthenticator(),
    );
    final first = AppController(parentAccessService: service);
    await first.createParentPin('4826');
    await first.completeParentSetup(childName: 'Миша', age: 8);
    final restarted = AppController(
      parentProfile: const ParentProfile(parentSetupCompleted: true),
      parentAccessService: ParentAccessService(
        store,
        const UnavailableParentBiometricAuthenticator(),
      ),
    );

    await tester.pumpWidget(App(controller: first));
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      App(key: const ValueKey('restarted_app'), controller: restarted),
    );
    await tester.pumpAndSettle();
    await _openUnlock(tester);

    expect(find.byType(ParentUnlockSheet), findsOneWidget);
    expect(find.byType(AdultDashboardScreen), findsNothing);
  });

  test('demo PIN opens the parent section only in demo mode', () async {
    final controller = await _configuredController();
    expect(
      await controller.verifyParentPin(AppController.demoParentPin),
      isFalse,
    );
    await controller.enterDemoMode();
    expect(
      await controller.verifyParentPin(AppController.demoParentPin),
      isTrue,
    );
    // The real PIN still works in the demo.
    expect(await controller.verifyParentPin('4826'), isTrue);
    expect(await controller.verifyParentPin('0000'), isFalse);
    await controller.exitDemoMode();
    expect(
      await controller.verifyParentPin(AppController.demoParentPin),
      isFalse,
    );
  });

  testWidgets('demo unlock shows the PIN and hides PIN settings', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = await _configuredController();
    await controller.enterDemoMode();

    await tester.pumpWidget(App(controller: controller));
    await tester.pumpAndSettle();
    await _openUnlock(tester);
    expect(find.text('Демо-режим: PIN 1234'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('parent_unlock_pin')),
      AppController.demoParentPin,
    );
    await tester.tap(find.byKey(const ValueKey('parent_unlock_continue')));
    await tester.pumpAndSettle();
    expect(find.byType(AdultDashboardScreen), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('adult_exit_demo')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const ValueKey('adult_change_pin')), findsNothing);
    expect(find.byKey(const ValueKey('adult_biometric_switch')), findsNothing);
  });

  testWidgets('a missing PIN can be set again instead of locking out', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = MemoryParentCredentialStore();
    final controller = AppController(
      parentAccessService: ParentAccessService(
        store,
        const UnavailableParentBiometricAuthenticator(),
      ),
    );
    await controller.createParentPin('4826');
    await controller.completeParentSetup(childName: 'Миша', age: 8);
    // Android restored the app data, but not the encrypted PIN.
    await store.clearPin();

    await tester.pumpWidget(App(controller: controller));
    await tester.pumpAndSettle();
    await _openUnlock(tester);
    expect(
      find.byKey(const ValueKey('parent_unlock_pin_repeat')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('parent_unlock_pin')),
      '2468',
    );
    await tester.enterText(
      find.byKey(const ValueKey('parent_unlock_pin_repeat')),
      '2460',
    );
    await tester.tap(find.byKey(const ValueKey('parent_unlock_continue')));
    await tester.pumpAndSettle();
    expect(find.text('PIN не совпадают. Введите ещё раз.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('parent_unlock_pin_repeat')),
      '2468',
    );
    await tester.tap(find.byKey(const ValueKey('parent_unlock_continue')));
    await tester.pumpAndSettle();
    expect(find.byType(AdultDashboardScreen), findsOneWidget);
    expect(await controller.verifyParentPin('2468'), isTrue);
  });
}

Future<AppController> _configuredController() async {
  final service = ParentAccessService(
    MemoryParentCredentialStore(),
    const UnavailableParentBiometricAuthenticator(),
  );
  final controller = AppController(parentAccessService: service);
  await controller.createParentPin('4826');
  await controller.completeParentSetup(childName: 'Миша', age: 8);
  return controller;
}

Future<void> _openUnlock(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings_rounded));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('settings_adult_section')));
  await tester.pumpAndSettle();
  expect(find.byType(ParentUnlockSheet), findsOneWidget);
}
