import 'package:finance_pet/app/app.dart';
import 'package:finance_pet/core/state/app_controller.dart';
import 'package:finance_pet/core/storage/app_database.dart';
import 'package:finance_pet/core/storage/app_state_repository.dart';
import 'package:finance_pet/features/adult/domain/parent_access_service.dart';
import 'package:finance_pet/features/home/presentation/home_screen.dart';
import 'package:finance_pet/features/periods/domain/game_period.dart';
import 'package:finance_pet/features/profile/presentation/profile_screen.dart';
import 'package:finance_pet/features/onboarding/presentation/game_intro_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  testWidgets('parent-first onboarding completes before Home opens', (
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

    await tester.pumpWidget(App(controller: controller));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsNothing);

    await tester.tap(find.byKey(const ValueKey('onboarding_welcome_continue')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('parent_pin_create')),
      '4826',
    );
    await tester.tap(find.byKey(const ValueKey('parent_pin_continue')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('parent_pin_repeat')),
      '4826',
    );
    await tester.tap(find.byKey(const ValueKey('parent_pin_continue')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('onboarding_child_name')),
      'Лена',
    );
    await tester.tap(find.byKey(const ValueKey('onboarding_age_10')));
    await tester.tap(find.byKey(const ValueKey('onboarding_child_continue')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Лена'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding_finish')));
    await tester.pumpAndSettle();

    // The child's intro to the three decisions follows the parent's setup.
    expect(find.byType(GameIntroScreen), findsOneWidget);
    for (var page = 0; page < 4; page++) {
      await tester.tap(find.byKey(const ValueKey('intro_next')));
      await tester.pumpAndSettle();
    }
    expect(find.byType(GameIntroScreen), findsNothing);
    expect(controller.tutorialSeen, isTrue);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(controller.parentSetupCompleted, isTrue);
    expect(controller.childName, 'Лена');
    expect(controller.age, 10);
    expect(await controller.verifyParentPin('4826'), isTrue);
  });

  test('PIN setup, age, and parent profile survive restart', () async {
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final repository = AppStateRepository(database);
    final store = MemoryParentCredentialStore();
    final access = ParentAccessService(
      store,
      const UnavailableParentBiometricAuthenticator(),
    );
    final controller = AppController(
      repository: repository,
      parentAccessService: access,
    );
    await controller.createParentPin('4826');
    await controller.completeParentSetup(childName: 'Саша', age: 11);
    await controller.flushPersistence();

    final snapshot = (await repository.loadProfile(AppRunMode.normal))
        .snapshot!;
    final parentProfile = await repository.loadParentProfile();
    final restarted = AppController.fromSnapshot(
      snapshot: snapshot,
      repository: repository,
      parentProfile: parentProfile,
      parentAccessService: ParentAccessService(
        store,
        const UnavailableParentBiometricAuthenticator(),
      ),
    );

    expect(restarted.parentSetupCompleted, isTrue);
    expect(restarted.childName, 'Саша');
    expect(restarted.age, 11);
    expect(await restarted.verifyParentPin('4826'), isTrue);
  });

  testWidgets('child Profile shows name and age without edit controls', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = AppController();
    await controller.createParentPin('4826');
    await controller.completeParentSetup(childName: 'Миша', age: 8);
    await tester.pumpWidget(App(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(InkWell, 'Профиль'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('child_age_read_only')),
      350,
    );
    expect(find.byKey(const ValueKey('child_age_read_only')), findsOneWidget);
    expect(find.byKey(const ValueKey('age_selector')), findsNothing);
    expect(find.textContaining('разделе для родителей'), findsOneWidget);
  });
}
