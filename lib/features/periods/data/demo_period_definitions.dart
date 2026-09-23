import '../../missions/domain/mission_models.dart';

class DemoPeriodDefinition {
  const DemoPeriodDefinition({
    required this.sequenceNumber,
    required this.locationId,
    required this.missionTheme,
    required this.primaryTheme,
    required this.secondaryTheme,
    required this.seedKey,
  });

  final int sequenceNumber;
  final String locationId;
  final MissionTheme missionTheme;
  final TaskTheme primaryTheme;
  final TaskTheme secondaryTheme;
  final String seedKey;
}

abstract final class DemoPeriodDefinitions {
  static const int count = 5;

  static const List<DemoPeriodDefinition> all = [
    DemoPeriodDefinition(
      sequenceNumber: 1,
      locationId: 'school',
      missionTheme: MissionTheme.math,
      primaryTheme: TaskTheme.math,
      secondaryTheme: TaskTheme.logic,
      seedKey: 'demo_period_1',
    ),
    DemoPeriodDefinition(
      sequenceNumber: 2,
      locationId: 'game_center',
      missionTheme: MissionTheme.logic,
      primaryTheme: TaskTheme.logic,
      secondaryTheme: TaskTheme.entertainment,
      seedKey: 'demo_period_2',
    ),
    DemoPeriodDefinition(
      sequenceNumber: 3,
      locationId: 'supermarket',
      missionTheme: MissionTheme.shopping,
      primaryTheme: TaskTheme.finance,
      secondaryTheme: TaskTheme.math,
      seedKey: 'demo_period_3',
    ),
    DemoPeriodDefinition(
      sequenceNumber: 4,
      locationId: 'museum',
      missionTheme: MissionTheme.logic,
      primaryTheme: TaskTheme.memory,
      secondaryTheme: TaskTheme.attention,
      seedKey: 'demo_period_4',
    ),
    DemoPeriodDefinition(
      sequenceNumber: 5,
      locationId: 'science_center',
      missionTheme: MissionTheme.mixed,
      primaryTheme: TaskTheme.logic,
      secondaryTheme: TaskTheme.finance,
      seedKey: 'demo_period_5',
    ),
  ];

  static DemoPeriodDefinition forSequence(int sequenceNumber) {
    if (sequenceNumber < 1 || sequenceNumber > all.length) {
      throw RangeError.range(sequenceNumber, 1, all.length, 'sequenceNumber');
    }
    return all[sequenceNumber - 1];
  }
}
