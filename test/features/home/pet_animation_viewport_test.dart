import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:finance_pet/core/assets/app_assets.dart';
import 'package:finance_pet/features/home/presentation/pet_animation/pet_animation_coordinator.dart';
import 'package:finance_pet/features/home/presentation/pet_animation/pet_animation_models.dart';
import 'package:finance_pet/features/home/presentation/pet_animation/pet_animation_viewport.dart';
import 'package:finance_pet/features/pet_progression/domain/pet_progression.dart';
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

  /// Source frame counts of the 60 fps WebM masters (identical per stage).
  int sourceFrames(PetAnimationState state) => switch (state) {
    PetAnimationState.happyIdle => 298,
    PetAnimationState.hungryIdle => 300,
    PetAnimationState.petHappy || PetAnimationState.petHungry => 210,
    _ => 306,
  };

  for (final stage in PetGrowthStage.values) {
    for (final state in PetAnimationState.values) {
      final definition = PetAnimationCatalog.definition(stage, state);
      test(
        '${stage.name} $state keeps every 60 fps frame and its anchors',
        () async {
          final data = await rootBundle.load(definition.asset);
          final codec = await ui.instantiateImageCodec(
            data.buffer.asUint8List(),
          );
          try {
            // Idle loops forever; actions play once (no repetition).
            expect(codec.repetitionCount, definition.loops ? -1 : 0);
            // Every source frame survives conversion: no 30 fps sampling and no
            // merged duplicate frames.
            expect(codec.frameCount, sourceFrames(state));
            final set = PetAnimationCatalog.setFor(stage);
            final start = await still(set.stillFor(definition.startState));
            final end = await still(set.stillFor(definition.endState));
            var duration = Duration.zero;
            var longest = Duration.zero;
            ByteData? first;
            ByteData? last;
            for (var i = 0; i < codec.frameCount; i++) {
              final frame = await codec.getNextFrame();
              duration += frame.duration;
              if (frame.duration > longest) longest = frame.duration;
              expect(frame.image.width, 720);
              expect(frame.image.height, 720);
              if (i == 0) first = await rgba(frame.image);
              if (i == codec.frameCount - 1) last = await rgba(frame.image);
              frame.image.dispose();
            }
            expect(duration, definition.duration);
            // 16/17 ms frames: effective rate is 60 fps, never 58.8 or 30.
            expect(longest, const Duration(milliseconds: 17));
            final fps = codec.frameCount * 1000 / duration.inMilliseconds;
            expect(fps, closeTo(60, 0.05));
            // Codec noise between identical poses stays around 1-2 units; a
            // mismatched anchor (e.g. happy vs hungry pose) measures 20+.
            expect(
              difference(first!, start),
              lessThan(4),
              reason: 'first frame',
            );
            expect(difference(last!, end), lessThan(4), reason: 'last frame');
          } finally {
            codec.dispose();
          }
        },
      );
    }

    test('${stage.name} happy and hungry anchors are distinct poses', () async {
      final set = PetAnimationCatalog.setFor(stage);
      final happy = await still(set.happyStill);
      final hungry = await still(set.hungryStill);
      expect(difference(happy, hungry), greaterThan(10));
    });
  }

  test('older stages grow inside the scene with paws on one line', () {
    const bounds = Size(400, 360);
    final rects = {
      for (final stage in PetGrowthStage.values)
        stage: PetAnimationViewport.canvasRect(
          bounds,
          PetAnimationCatalog.setFor(stage).visual,
          minTop: -200,
        ),
    };
    double pawLine(PetGrowthStage stage) =>
        rects[stage]!.top +
        rects[stage]!.height *
            PetAnimationCatalog.setFor(stage).visual.pawLineFraction;
    double visibleHeight(PetGrowthStage stage) =>
        rects[stage]!.height *
        PetAnimationCatalog.setFor(stage).visual.visibleFraction;
    for (final stage in PetGrowthStage.values) {
      expect(pawLine(stage), closeTo(pawLine(PetGrowthStage.little), 0.01));
    }
    final little = visibleHeight(PetGrowthStage.little);
    expect(visibleHeight(PetGrowthStage.growing) / little, closeTo(1.08, 1e-6));
    expect(visibleHeight(PetGrowthStage.grown) / little, closeTo(1.16, 1e-6));
  });

  test('with little space above, older stages stop at minTop', () {
    const bounds = Size(400, 360);
    for (final stage in PetGrowthStage.values) {
      final visual = PetAnimationCatalog.setFor(stage).visual;
      final rect = PetAnimationViewport.canvasRect(bounds, visual, minTop: 0);
      final top = rect.top + rect.height * (visual.anchorTop / 960);
      final little = PetAnimationViewport.canvasRect(
        bounds,
        PetAnimationCatalog.setFor(PetGrowthStage.little).visual,
        minTop: 0,
      );
      // Never smaller than Stage 1, never above minTop unless Stage 1 is.
      expect(
        rect.height * visual.visibleFraction,
        greaterThanOrEqualTo(little.height * (899 / 960) - 0.01),
      );
      expect(
        top,
        greaterThanOrEqualTo(
          math.min(0, little.top + little.height * 61 / 960) - 0.01,
        ),
      );
    }
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
      return PetAnimationViewport.canvasRect(
        const Size(400, 320),
        PetAnimationCatalog.setFor(PetGrowthStage.little).visual,
      ).shift(origin);
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
          PetAnimationCatalog.setFor(PetGrowthStage.little).stillFor(base),
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
