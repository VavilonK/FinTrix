import 'package:finance_pet/core/state/app_controller.dart';
import 'package:finance_pet/core/state/app_scope.dart';
import 'package:finance_pet/core/theme/app_theme.dart';
import 'package:finance_pet/features/missions/data/mock_daily_missions.dart';
import 'package:finance_pet/features/pet_progression/domain/pet_progression.dart';
import 'package:finance_pet/features/profile/presentation/profile_screen.dart';
import 'package:finance_pet/features/tasks/data/location_definitions.dart';
import 'package:finance_pet/features/tasks/presentation/widgets/mission_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final scale in [1.0, 1.3, 1.5, 2.0]) {
    for (final width in [360.0, 390.0, 1080 / 2.625]) {
      for (final id in [
        'supermarket',
        'sports_center',
        'game_center',
        'library',
        'science_center',
      ]) {
        testWidgets(
          'MissionCard $id keeps right CTA and bottom chips at $width/$scale',
          (tester) async {
            await _setViewport(tester, width, scale);
            var starts = 0;
            final mission = MockDailyMissions.today;
            final location = LocationDefinitions.byId(id);
            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.light,
                home: Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        height: (width < 400 ? 190 : 172) + (scale - 1) * 160,
                        child: MissionCard(
                          mission: mission,
                          location: location,
                          onStartMission: () => starts++,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final info = tester.getRect(
              find.byKey(const ValueKey('mission_metadata')),
            );
            final actionFinder = find.byKey(const ValueKey('mission_start'));
            final action = tester.getRect(actionFinder);
            final chipsFinder = find.byKey(
              const ValueKey('mission_categories'),
            );
            final chips = tester.getRect(chipsFinder);
            final card = tester.getRect(find.byType(MissionCard));
            final thumbnail = tester.getRect(
              find.byKey(const ValueKey('mission_thumbnail')),
            );
            final mainRow = find.byKey(const ValueKey('mission_main'));
            expect(
              find.descendant(of: mainRow, matching: actionFinder),
              findsOneWidget,
            );
            expect(thumbnail.right, lessThan(info.left));
            expect(action.left, greaterThan(info.right));
            expect(action.right, lessThan(card.right));
            expect(action.height, greaterThanOrEqualTo(48));
            expect(chips.top, greaterThanOrEqualTo(info.bottom));
            expect(chips.top, greaterThanOrEqualTo(action.bottom));

            final row = tester.widget<Row>(chipsFinder);
            final chipSizes = row.children
                .whereType<Expanded>()
                .map((child) => tester.getSize(find.byWidget(child.child)))
                .toList();
            expect(chipSizes, hasLength(3));
            for (final size in chipSizes.skip(1)) {
              expect(size.width, closeTo(chipSizes.first.width, 0.1));
              expect(size.height, closeTo(chipSizes.first.height, 0.1));
            }
            for (final label in [
              location.title,
              'Сегодня',
              '${mission.tasks.length} заданий • ~${mission.estimatedMinutes}\u00a0мин',
              'Награда: до ${mission.maxReward} монет',
              'Отправиться',
            ]) {
              final paragraph = tester.renderObject<RenderParagraph>(
                find.text(label),
              );
              expect(paragraph.didExceedMaxLines, isFalse, reason: label);
            }
            await tester.ensureVisible(actionFinder);
            await tester.tap(actionFinder);
            expect(starts, 1);
            await tester.ensureVisible(chipsFinder);
            await tester.pumpAndSettle();
            expect(chipsFinder.hitTestable(), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
    for (final width in [360.0, 390.0, 1080 / 2.625]) {
      for (final points in [0, 40, 90]) {
        testWidgets('Profile stages fit $width/$scale at $points points', (
          tester,
        ) async {
          await _setViewport(tester, width, scale);
          final controller = AppController()..petGrowthPoints = points;
          addTearDown(controller.dispose);
          await tester.pumpWidget(
            AppScope(
              controller: controller,
              child: MaterialApp(
                theme: AppTheme.light,
                home: Scaffold(body: ProfileScreen(onOpenGoals: () {})),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final stages = find.byKey(const ValueKey('pet_growth_stages'));
          await tester.ensureVisible(stages);
          await tester.pumpAndSettle();
          final icons = PetGrowthStage.values
              .map(
                (stage) => tester.getRect(
                  find.byKey(ValueKey('growth_icon_${stage.name}')),
                ),
              )
              .toList();
          for (final icon in icons) {
            expect(icon.center.dy, closeTo(icons.first.center.dy, 0.1));
            expect(icon.left, greaterThanOrEqualTo(0));
            expect(icon.right, lessThanOrEqualTo(width));
          }
          final connectors = find.descendant(
            of: stages,
            matching: find.byIcon(Icons.chevron_right_rounded),
          );
          expect(connectors, findsNWidgets(2));
          for (var index = 0; index < 2; index++) {
            expect(
              tester.getCenter(connectors.at(index)).dy,
              closeTo(icons.first.center.dy, 0.1),
            );
          }
          expect(find.text('Сейчас'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}

Future<void> _setViewport(
  WidgetTester tester,
  double width,
  double scale,
) async {
  await tester.binding.setSurfaceSize(Size(width, 800));
  tester.binding.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(() async {
    tester.binding.platformDispatcher.clearTextScaleFactorTestValue();
    await tester.binding.setSurfaceSize(null);
  });
}
