import 'dart:convert';
import 'dart:ui' as ui;

import 'package:finance_pet/app/app.dart';
import 'package:finance_pet/core/state/app_controller.dart';
import 'package:finance_pet/core/storage/app_state_snapshot.dart';
import 'package:finance_pet/features/adult/domain/parent_access_service.dart';
import 'package:finance_pet/core/assets/app_assets.dart';
import 'package:finance_pet/features/home/presentation/pet_animation/pet_animation_coordinator.dart';
import 'package:finance_pet/features/home/presentation/pet_animation/pet_animation_models.dart';
import 'package:finance_pet/features/home/presentation/pet_animation/pet_animation_viewport.dart';
import 'package:finance_pet/features/home/presentation/pet_animation/pet_look_still.dart';
import 'package:finance_pet/features/home/presentation/pet_animation/pet_look.dart';
import 'package:finance_pet/features/pet_progression/domain/pet_appearance.dart';
import 'package:finance_pet/features/pet_progression/domain/pet_progression.dart';
import 'package:finance_pet/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PetAppearance', () {
    test('default look is blue without accessories', () {
      const look = PetAppearance();
      expect(look.isDefault, isTrue);
      expect(look.toggle(PetAccessory.bow).isDefault, isFalse);
      expect(look.copyWith(hoodie: HoodieColor.red).isDefault, isFalse);
    });

    test('at least 9 visually different combinations', () {
      final looks = <PetAppearance>{
        for (final hoodie in HoodieColor.values)
          for (final glasses in [false, true])
            for (final bow in [false, true])
              PetAppearance(
                hoodie: hoodie,
                accessories: {
                  if (glasses) PetAccessory.glasses,
                  if (bow) PetAccessory.bow,
                },
              ),
      };
      expect(looks.length, greaterThanOrEqualTo(9));
    });

    test('json round trip and tolerant parsing', () {
      const look = PetAppearance(
        hoodie: HoodieColor.purple,
        accessories: {PetAccessory.glasses, PetAccessory.bow},
      );
      expect(
        PetAppearance.fromJson(jsonDecode(jsonEncode(look.toJson()))),
        look,
      );
      expect(PetAppearance.fromJson(null), const PetAppearance());
      expect(
        PetAppearance.fromJson({
          'hoodie': 'gold',
          'accessories': ['hat'],
        }),
        const PetAppearance(),
      );
    });

    test('appearance survives a save and restore', () {
      final controller = AppController(
        parentAccessService: ParentAccessService(
          MemoryParentCredentialStore(),
          const UnavailableParentBiometricAuthenticator(),
        ),
      );
      const look = PetAppearance(
        hoodie: HoodieColor.green,
        accessories: {PetAccessory.bow},
      );
      controller.setPetAppearance(look);
      final json = jsonDecode(jsonEncode(controller.toSnapshot().toJson()));
      final restored = AppStateSnapshot.fromJson(json as Map<String, dynamic>);
      expect(restored.petAppearance, look);
      // Saves from before customisation restore the default look.
      final legacy = Map<String, dynamic>.of(json)..remove('petAppearance');
      expect(
        AppStateSnapshot.fromJson(legacy).petAppearance,
        const PetAppearance(),
      );
    });
  });

  group('look data matches every clip frame for frame', () {
    for (final stage in PetGrowthStage.values) {
      for (final state in PetAnimationState.values) {
        final clip = PetAnimationCatalog.definition(stage, state).asset;
        test('${stage.name} ${state.name}', () async {
          final data = await rootBundle.load(clip);
          final codec = await ui.instantiateImageCodec(
            data.buffer.asUint8List(),
          );
          final frames = codec.frameCount;
          codec.dispose();

          final pose = await PetPose.load(
            rootBundle,
            PetLookAssets.poseFor(clip),
          );
          expect(pose, isNotNull);
          expect(pose!.length, frames);
          for (var i = 0; i < pose.length; i++) {
            final e = pose.eyes(i);
            // Pupils stay on the canvas and in reading order.
            expect(e.every((v) => v > 0 && v < 1), isTrue);
            expect(e[2], greaterThan(e[0]));
          }

          final mask = await rootBundle.load(PetLookAssets.hoodieMaskFor(clip));
          final maskCodec = await ui.instantiateImageCodec(
            mask.buffer.asUint8List(),
          );
          expect(maskCodec.frameCount, frames);
          final first = await maskCodec.getNextFrame();
          expect(first.image.width, 320);
          first.image.dispose();
          maskCodec.dispose();
        });
      }
    }
  });

  testWidgets('Profile changes hoodie and accessories', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
    await tester.tap(find.widgetWithText(InkWell, 'Профиль'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);

    final red = find.byKey(const ValueKey('hoodie_red'));
    await tester.ensureVisible(red);
    await tester.pumpAndSettle();
    await tester.tap(red);
    await tester.pump();
    expect(controller.petAppearance.hoodie, HoodieColor.red);

    await tester.tap(find.byKey(const ValueKey('accessory_glasses')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('accessory_bow')));
    await tester.pump();
    expect(controller.petAppearance.accessories, {
      PetAccessory.glasses,
      PetAccessory.bow,
    });
    await tester.tap(find.byKey(const ValueKey('accessory_bow')));
    await tester.pump();
    expect(controller.petAppearance.accessories, {PetAccessory.glasses});
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  group('viewport with a custom look', () {
    const look = PetAppearance(
      hoodie: HoodieColor.purple,
      accessories: {PetAccessory.glasses, PetAccessory.bow},
    );

    Widget host(
      PetAnimationCoordinator coordinator, {
      bool reduceMotion = false,
    }) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: Center(
            child: SizedBox(
              width: 400,
              height: 320,
              child: PetAnimationViewport(
                coordinator: coordinator,
                fallbackAsset: AppAssets.foxSittingHappyLevel05,
                isActive: true,
                appearance: look,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('frames are painted with the look in the same canvas', (
      tester,
    ) async {
      final coordinator = PetAnimationCoordinator(
        baseState: PetBaseState.happy,
      );
      await tester.pumpWidget(host(coordinator));
      final frame = find.byKey(const ValueKey('pet_animation_frame'));
      for (var i = 0; i < 100 && frame.evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      expect(tester.widget(frame), isA<CustomPaint>());
      final origin = tester.getTopLeft(find.byType(PetAnimationViewport));
      expect(
        tester.getRect(frame),
        PetAnimationViewport.canvasRect(
          const Size(400, 320),
          PetAnimationCatalog.setFor(PetGrowthStage.little).visual,
        ).shift(origin),
      );
      expect(
        tester.getSize(find.byType(PetAnimationViewport)),
        const Size(400, 320),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      coordinator.dispose();
    });

    testWidgets('reduce motion shows the dressed still', (tester) async {
      final coordinator = PetAnimationCoordinator(
        baseState: PetBaseState.hungry,
        growthStage: PetGrowthStage.grown,
        animationsEnabled: false,
      );
      addTearDown(coordinator.dispose);
      await tester.pumpWidget(host(coordinator, reduceMotion: true));
      final still = tester.widget<PetLookStill>(find.byType(PetLookStill));
      final set = PetAnimationCatalog.setFor(PetGrowthStage.grown);
      expect(still.stillAsset, set.hungryStill);
      expect(still.idleAsset, set.hungryIdle);
      expect(still.appearance, look);
    });
  });
}
