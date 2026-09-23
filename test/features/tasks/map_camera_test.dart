import 'package:finance_pet/features/tasks/data/location_definitions.dart';
import 'package:finance_pet/features/missions/presentation/widgets/location_scene_widgets.dart';
import 'package:finance_pet/features/tasks/presentation/widgets/map_camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const viewport = Size(412, 728);
  const scene = Size(1080, 1280);
  const cardHeight = 178.0;
  const topOverlayHeight = 205.0;

  const locations = <String, Offset>{
    'top': Offset(0.22, 0.18),
    'center': Offset(0.58, 0.35),
    'bottom': Offset(0.47, 0.83),
    'left': Offset(0.16, 0.52),
    'right': Offset(0.84, 0.42),
  };

  for (final entry in locations.entries) {
    test(
      '${entry.key} location keeps fox and marker above the mission card',
      () {
        final plan = MapCamera.plan(
          viewport: viewport,
          sceneSize: scene,
          normalizedLocation: entry.value,
          bottomOverlayHeight: cardHeight,
          topOverlayHeight: topOverlayHeight,
        );
        final activePoint = Offset(
          entry.value.dx * scene.width,
          entry.value.dy * scene.height,
        );
        final markerOnScreen = MatrixUtils.transformPoint(
          plan.transform,
          activePoint,
        );
        final foxOnScreen = MatrixUtils.transformPoint(
          plan.transform,
          plan.foxPoint,
        );

        expect(plan.safeViewport.contains(markerOnScreen), isTrue);
        expect(plan.safeViewport.contains(foxOnScreen), isTrue);
        expect(foxOnScreen.dy, lessThan(viewport.height - cardHeight - 24));
        expect(plan.foxPoint.dx, inInclusiveRange(0, scene.width));
        expect(plan.foxPoint.dy, inInclusiveRange(0, scene.height));
      },
    );
  }

  test('all twelve locations expose one canonical scene asset', () {
    final scenes = LocationDefinitions.all
        .map((location) => location.sceneAsset)
        .toSet();

    expect(LocationDefinitions.all, hasLength(12));
    expect(scenes, hasLength(12));
    expect(
      scenes.every((asset) => asset.contains('/locations/scenes/')),
      isTrue,
    );
    for (final id in ['sports_center', 'library', 'game_center', 'museum']) {
      expect(LocationDefinitions.byId(id).sceneAsset, isNotEmpty);
    }
  });

  testWidgets(
    'four representative location heroes load without layout errors',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      for (final id in ['sports_center', 'library', 'game_center', 'museum']) {
        final location = LocationDefinitions.byId(id);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 380,
                  child: LocationHeroCard(
                    location: location,
                    speech: 'Потренируемся думать и принимать решения!',
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(location.title), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );
}
