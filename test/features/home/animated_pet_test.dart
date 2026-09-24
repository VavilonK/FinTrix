import 'package:finance_pet/core/assets/app_assets.dart';
import 'package:finance_pet/features/home/presentation/widgets/animated_pet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host({
    bool active = true,
    bool enabled = true,
    bool reduceMotion = false,
    AssetBundle? bundle,
  }) {
    final content = MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Center(
        child: SizedBox(
          width: 400,
          height: 320,
          child: AnimatedPet(
            fallbackAsset: AppAssets.foxSittingHappyLevel05,
            isActive: active,
            animationsEnabled: enabled,
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

  for (final reduceMotion in [false, true]) {
    testWidgets(
      reduceMotion ? 'reduce motion uses PNG' : 'disabled animation uses PNG',
      (tester) async {
        await tester.pumpWidget(
          host(enabled: reduceMotion, reduceMotion: reduceMotion),
        );
        final fallback = tester.widget<Image>(
          find.byKey(const ValueKey('pet_static_fallback')),
        );
        expect(
          (fallback.image as AssetImage).assetName,
          AppAssets.foxSittingHappyLevel05,
        );
        expect(find.byKey(const ValueKey('pet_idle_animation')), findsNothing);
        expect(tester.getSize(find.byType(AnimatedPet)), const Size(400, 320));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('hidden or backgrounded pet pauses without replacing image', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    final image = find.byKey(const ValueKey('pet_idle_animation'));
    final imageState = tester.state(image);
    await tester.pumpWidget(host(active: false));
    expect(TickerMode.valuesOf(tester.element(image)).enabled, isFalse);
    expect(tester.state(image), same(imageState));
    await tester.pumpWidget(host());
    expect(TickerMode.valuesOf(tester.element(image)).enabled, isTrue);
    // Inactive still permits a test frame; paused deliberately suspends frames.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(TickerMode.valuesOf(tester.element(image)).enabled, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(TickerMode.valuesOf(tester.element(image)).enabled, isTrue);
    expect(tester.state(image), same(imageState));
    expect(find.byKey(const ValueKey('pet_static_fallback')), findsNothing);
  });

  testWidgets('asset failure uses PNG in unchanged bounds', (tester) async {
    await tester.pumpWidget(host(bundle: _BrokenAnimationBundle()));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pet_static_fallback')), findsOneWidget);
    expect(tester.getSize(find.byType(AnimatedPet)), const Size(400, 320));
    expect(tester.takeException(), isNull);
  });
}

class _BrokenAnimationBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    if (key == AppAssets.ryzhikIdleAnimation) {
      return Future.error(StateError('Intentional animation load failure'));
    }
    return rootBundle.load(key);
  }
}
