import 'dart:ui' as ui;

import 'package:finance_pet/core/assets/app_assets.dart';
import 'package:finance_pet/features/home/presentation/pet_animation/pet_animation_coordinator.dart';
import 'package:finance_pet/features/home/presentation/pet_animation/pet_animation_models.dart';
import 'package:finance_pet/features/home/presentation/pet_animation/pet_animation_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ByteData> rgba(ui.Image image) async =>
      (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;

  /// Mean premultiplied RGBA difference (0-255) between two frames.
  double difference(ByteData a, ByteData b) {
    var total = 0.0;
    for (var i = 0; i < a.lengthInBytes; i += 4) {
      final alphaA = a.getUint8(i + 3) / 255;
      final alphaB = b.getUint8(i + 3) / 255;
      for (var c = 0; c < 3; c++) {
        total += (a.getUint8(i + c) * alphaA - b.getUint8(i + c) * alphaB)
            .abs();
      }
      total += (a.getUint8(i + 3) - b.getUint8(i + 3)).abs();
    }
    return total / a.lengthInBytes;
  }

  Future<ByteData> still(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final pixels = await rgba(frame.image);
    frame.image.dispose();
    codec.dispose();
    return pixels;
  }

  for (final state in PetAnimationState.values) {
    final definition = state.definition;
    test('$state asset timing and anchors match its definition', () async {
      final data = await rootBundle.load(definition.asset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      try {
        if (definition.isStill) {
          expect(codec.frameCount, 1);
        } else {
          // Idle loops forever; actions play once (no repetition).
          expect(codec.repetitionCount, definition.loops ? -1 : 0);
        }
        final start = await still(
          PetAnimationCatalog.idleFor(definition.startState)
              .definition
              .stillAsset,
        );
        final end = await still(
          PetAnimationCatalog.idleFor(definition.endState)
              .definition
              .stillAsset,
        );
        var duration = Duration.zero;
        ByteData? first;
        ByteData? last;
        for (var i = 0; i < codec.frameCount; i++) {
          final frame = await codec.getNextFrame();
          duration += frame.duration;
          expect(frame.image.width, 720);
          expect(frame.image.height, 720);
          if (i == 0) first = await rgba(frame.image);
          if (i == codec.frameCount - 1) last = await rgba(frame.image);
          frame.image.dispose();
        }
        expect(duration, definition.duration);
        // Codec noise between identical poses stays around 1-2 units; a
        // mismatched anchor (e.g. happy vs hungry pose) measures ~29.
        expect(difference(first!, start), lessThan(4), reason: 'first frame');
        expect(difference(last!, end), lessThan(4), reason: 'last frame');
      } finally {
        codec.dispose();
      }
    });
  }

  test('happy and hungry anchors are distinct poses', () async {
    final happy = await still(AppAssets.foxHappyStill);
    final hungry = await still(AppAssets.foxHungryStill);
    expect(difference(happy, hungry), greaterThan(10));
  });

  group('viewport', () {
    Widget host(
      PetAnimationCoordinator coordinator, {
      bool reduceMotion = false,
      AssetBundle? bundle,
    }) {
      final content = MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Center(
          child: SizedBox(
            width: 400,
            height: 320,
            child: PetAnimationViewport(
              coordinator: coordinator,
              fallbackAsset: AppAssets.foxSittingHappyLevel05,
              isActive: true,
            ),
          ),
        ),
      );
      return MaterialApp(
        home: bundle == null
            ? content
            : DefaultAssetBundle(bundle: bundle, child: content),
      );
    }

    Rect canvas(WidgetTester tester) {
      final origin = tester.getTopLeft(find.byType(PetAnimationViewport));
      return PetAnimationViewport.canvasRect(const Size(400, 320))
          .shift(origin);
    }

    for (final base in PetBaseState.values) {
      testWidgets('reduce motion shows the $base anchor frame', (tester) async {
        final coordinator = PetAnimationCoordinator(
          baseState: base,
          animationsEnabled: false,
        );
        addTearDown(coordinator.dispose);
        await tester.pumpWidget(host(coordinator, reduceMotion: true));
        final image = tester.widget<Image>(
          find.byKey(const ValueKey('pet_static_frame')),
        );
        expect(
          (image.image as AssetImage).assetName,
          PetAnimationCatalog.idleFor(base).definition.stillAsset,
        );
        expect(find.byKey(const ValueKey('pet_animation_frame')), findsNothing);
        expect(
          tester.getRect(find.byKey(const ValueKey('pet_static_frame'))),
          canvas(tester),
        );
        // Actions still succeed functionally without any clip.
        expect(coordinator.playPet(), isTrue);
        expect(coordinator.isActionPlaying, isFalse);
      });
    }

    testWidgets('clips replace each other inside one fixed canvas', (
      tester,
    ) async {
      final coordinator = PetAnimationCoordinator(
        baseState: PetBaseState.happy,
      );
      await tester.pumpWidget(host(coordinator));
      final size = tester.getSize(find.byType(PetAnimationViewport));
      // First paint is the anchor still, already in the final geometry.
      expect(
        tester.getRect(find.byKey(const ValueKey('pet_static_frame'))),
        canvas(tester),
      );

      final frame = find.byKey(const ValueKey('pet_animation_frame'));
      Future<void> waitForFrame() async {
        for (var i = 0; i < 100 && frame.evaluate().isEmpty; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump();
        }
      }

      await waitForFrame();
      expect(frame, findsOneWidget);
      expect(tester.getRect(frame), canvas(tester));

      coordinator.playPet();
      final playId = coordinator.playId;
      for (var i = 0; i < 100 && coordinator.playId == playId; i++) {
        final shown = tester.widget<RawImage>(frame).image;
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 40));
        if (coordinator.isActionPlaying &&
            tester.widget<RawImage>(frame).image != shown) {
          break;
        }
      }
      // Never a gap: some decoded frame is on screen during the switch.
      expect(frame, findsOneWidget);
      expect(tester.getRect(frame), canvas(tester));
      expect(tester.getSize(find.byType(PetAnimationViewport)), size);
      expect(coordinator.current, PetAnimationState.petHappy);
      expect(tester.takeException(), isNull);
      // Release the end-of-clip watchdog before the fake clock is verified.
      await tester.pumpWidget(const SizedBox());
      coordinator.dispose();
    });

    testWidgets('asset failure keeps the PNG in unchanged bounds', (
      tester,
    ) async {
      final coordinator = PetAnimationCoordinator(
        baseState: PetBaseState.happy,
      );
      addTearDown(coordinator.dispose);
      await tester.pumpWidget(host(coordinator, bundle: _BrokenBundle()));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pet_static_fallback')), findsOneWidget);
      expect(
        tester.getSize(find.byType(PetAnimationViewport)),
        const Size(400, 320),
      );
      // A failed clip must not leave the state machine stuck in an action.
      coordinator.playPet();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      expect(coordinator.isActionPlaying, isFalse);
      expect(tester.takeException(), isNull);
    });
  });
}

class _BrokenBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    if (key.startsWith('assets/animations/')) {
      return Future.error(StateError('Intentional animation load failure'));
    }
    return rootBundle.load(key);
  }
}
