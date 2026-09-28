import '../../features/budget/domain/budget_plan.dart';
import '../../features/budget/domain/budget_usage.dart';
import '../../features/home/domain/pet_models.dart';
import '../../features/missions/domain/mission_models.dart';
import '../../features/periods/domain/game_period.dart';
import '../../features/profile/domain/profile_models.dart';
import 'serializers/app_state_serializers.dart';
import '../../features/pet_progression/domain/pet_appearance.dart';

class AppStateSnapshot {
  const AppStateSnapshot({
    required this.childProfile,
    required this.difficultyLevel,
    required this.balance,
    required this.savings,
    required this.selectedGoalId,
    required this.budgetPlan,
    required this.budgetUsage,
    required this.budgetPlanConfirmed,
    required this.petState,
    required this.petXp,
    this.petGrowthPoints = 0,
    required this.petLevel,
    required this.completedTasks,
    required this.completedMissions,
    required this.achievedGoals,
    this.completedGoalIds = const [],
    required this.daysTogether,
    required this.streak,
    required this.soundEnabled,
    required this.hintsEnabled,
    this.petAppearance = const PetAppearance(),
    required this.cachedDailyMission,
    required this.cachedDailyMissionKey,
    required this.activeMission,
    required this.currentTaskIndex,
    required this.lastResult,
    required this.lastLocationIds,
    required this.lastTaskTemplateIds,
    required this.sessionEarnedCoins,
    required this.sessionSpentCoins,
    required this.sessionSavedCoins,
    required this.sessionXp,
    required this.sessionCompletedTasks,
    required this.awaitingAdvance,
    required this.lastHungerCheckAt,
    required this.runMode,
    required this.activeGamePeriod,
    required this.completedGamePeriods,
    required this.demoPeriodIndex,
  });

  static const int schemaVersion = 7;

  final ChildProfile childProfile;
  final DifficultyLevel difficultyLevel;
  final int balance;
  final int savings;
  final String selectedGoalId;
  final BudgetPlan budgetPlan;
  final BudgetUsage budgetUsage;
  final bool budgetPlanConfirmed;
  final PetState petState;
  final int petXp;
  final int petGrowthPoints;
  final int petLevel;
  final int completedTasks;
  final int completedMissions;
  final int achievedGoals;
  final List<String> completedGoalIds;
  final int daysTogether;
  final int streak;
  final bool soundEnabled;
  final bool hintsEnabled;
  final PetAppearance petAppearance;
  final DailyMission? cachedDailyMission;
  final String? cachedDailyMissionKey;
  final DailyMission? activeMission;
  final int currentTaskIndex;
  final MissionResult? lastResult;
  final List<String> lastLocationIds;
  final List<String> lastTaskTemplateIds;
  final int sessionEarnedCoins;
  final int sessionSpentCoins;
  final int sessionSavedCoins;
  final int sessionXp;
  final int sessionCompletedTasks;
  final bool awaitingAdvance;
  final DateTime lastHungerCheckAt;
  final AppRunMode runMode;
  final GamePeriod? activeGamePeriod;
  final List<GamePeriod> completedGamePeriods;
  final int demoPeriodIndex;

  String get childName => childProfile.name;

  int get age => childProfile.age;

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'childProfile': childProfile.toJson(),
    'difficultyLevel': difficultyLevel.name,
    'balance': balance,
    'savings': savings,
    'selectedGoalId': selectedGoalId,
    'budgetPlan': AppStateSerializers.budgetPlanToJson(budgetPlan),
    'budgetUsage': AppStateSerializers.budgetUsageToJson(budgetUsage),
    'budgetPlanConfirmed': budgetPlanConfirmed,
    'petState': AppStateSerializers.petStateToJson(petState),
    'petXp': petXp,
    'petGrowthPoints': petGrowthPoints,
    'petLevel': petLevel,
    'completedTasks': completedTasks,
    'completedMissions': completedMissions,
    'achievedGoals': achievedGoals,
    'completedGoalIds': completedGoalIds,
    'daysTogether': daysTogether,
    'streak': streak,
    'soundEnabled': soundEnabled,
    'hintsEnabled': hintsEnabled,
    'petAppearance': petAppearance.toJson(),
    'cachedDailyMission': cachedDailyMission == null
        ? null
        : AppStateSerializers.dailyMissionToJson(cachedDailyMission!),
    'cachedDailyMissionKey': cachedDailyMissionKey,
    'activeMission': activeMission == null
        ? null
        : AppStateSerializers.dailyMissionToJson(activeMission!),
    'currentTaskIndex': currentTaskIndex,
    'lastResult': lastResult == null
        ? null
        : AppStateSerializers.missionResultToJson(lastResult!),
    'lastLocationIds': lastLocationIds,
    'lastTaskTemplateIds': lastTaskTemplateIds,
    'sessionEarnedCoins': sessionEarnedCoins,
    'sessionSpentCoins': sessionSpentCoins,
    'sessionSavedCoins': sessionSavedCoins,
    'sessionXp': sessionXp,
    'sessionCompletedTasks': sessionCompletedTasks,
    'awaitingAdvance': awaitingAdvance,
    'lastHungerCheckAt': lastHungerCheckAt.toIso8601String(),
    'runMode': runMode.name,
    'activeGamePeriod': activeGamePeriod == null
        ? null
        : AppStateSerializers.gamePeriodToJson(activeGamePeriod!),
    'completedGamePeriods': completedGamePeriods
        .map(AppStateSerializers.gamePeriodToJson)
        .toList(),
    'demoPeriodIndex': demoPeriodIndex,
  };

  factory AppStateSnapshot.fromJson(Map<String, Object?> json) {
    final version = _int(json, 'schemaVersion');
    if (version < 1 || version > schemaVersion) {
      throw FormatException('Unsupported snapshot schema version: $version');
    }
    final runMode = version >= 2
        ? AppRunMode.values.byName(_string(json, 'runMode'))
        : AppRunMode.normal;
    final childProfile = version >= 5
        ? ChildProfile.fromJson(_map(json, 'childProfile'))
        : ChildProfile(
            name: _string(json, 'childName'),
            age: _int(
              json,
              'age',
            ).clamp(ChildProfile.minimumAge, ChildProfile.maximumAge),
          );
    return AppStateSnapshot(
      childProfile: childProfile,
      difficultyLevel: DifficultyLevel.values.byName(
        _string(json, 'difficultyLevel'),
      ),
      balance: _int(json, 'balance'),
      savings: _int(json, 'savings'),
      selectedGoalId: _string(json, 'selectedGoalId'),
      budgetPlan: AppStateSerializers.budgetPlanFromJson(
        _map(json, 'budgetPlan'),
      ),
      budgetUsage: AppStateSerializers.budgetUsageFromJson(
        _map(json, 'budgetUsage'),
      ),
      budgetPlanConfirmed: _bool(json, 'budgetPlanConfirmed'),
      petState: AppStateSerializers.petStateFromJson(_map(json, 'petState')),
      petXp: _int(json, 'petXp'),
      petGrowthPoints: version >= 3
          ? _int(json, 'petGrowthPoints')
          : runMode == AppRunMode.demo
          ? 18
          : 0,
      petLevel: _int(json, 'petLevel'),
      completedTasks: _int(json, 'completedTasks'),
      completedMissions: _int(json, 'completedMissions'),
      achievedGoals: _int(json, 'achievedGoals'),
      completedGoalIds: version >= 6
          ? _stringList(json, 'completedGoalIds')
          : const [],
      daysTogether: _int(json, 'daysTogether'),
      streak: _int(json, 'streak'),
      soundEnabled: _bool(json, 'soundEnabled'),
      hintsEnabled: _bool(json, 'hintsEnabled'),
      // Absent in saves from before pet customisation: default look.
      petAppearance: PetAppearance.fromJson(json['petAppearance']),
      cachedDailyMission: _nullableMap(json['cachedDailyMission']) == null
          ? null
          : AppStateSerializers.dailyMissionFromJson(
              _nullableMap(json['cachedDailyMission'])!,
            ),
      cachedDailyMissionKey: json['cachedDailyMissionKey'] as String?,
      activeMission: _nullableMap(json['activeMission']) == null
          ? null
          : AppStateSerializers.dailyMissionFromJson(
              _nullableMap(json['activeMission'])!,
            ),
      currentTaskIndex: _int(json, 'currentTaskIndex'),
      lastResult: _nullableMap(json['lastResult']) == null
          ? null
          : AppStateSerializers.missionResultFromJson(
              _nullableMap(json['lastResult'])!,
            ),
      lastLocationIds: _stringList(json, 'lastLocationIds'),
      lastTaskTemplateIds: _stringList(json, 'lastTaskTemplateIds'),
      sessionEarnedCoins: _int(json, 'sessionEarnedCoins'),
      sessionSpentCoins: _int(json, 'sessionSpentCoins'),
      sessionSavedCoins: _int(json, 'sessionSavedCoins'),
      sessionXp: _int(json, 'sessionXp'),
      sessionCompletedTasks: _int(json, 'sessionCompletedTasks'),
      awaitingAdvance: _bool(json, 'awaitingAdvance'),
      lastHungerCheckAt: DateTime.parse(_string(json, 'lastHungerCheckAt')),
      runMode: runMode,
      activeGamePeriod:
          version >= 2 && _nullableMap(json['activeGamePeriod']) != null
          ? AppStateSerializers.gamePeriodFromJson(
              _nullableMap(json['activeGamePeriod'])!,
            )
          : null,
      completedGamePeriods: version >= 2
          ? _mapList(
              json,
              'completedGamePeriods',
            ).map(AppStateSerializers.gamePeriodFromJson).toList()
          : const [],
      demoPeriodIndex: version >= 2 ? _int(json, 'demoPeriodIndex') : 1,
    );
  }

  static int _int(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is int) return value;
    throw FormatException('Expected int for $key, got $value');
  }

  static String _string(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is String) return value;
    throw FormatException('Expected String for $key, got $value');
  }

  static bool _bool(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is bool) return value;
    throw FormatException('Expected bool for $key, got $value');
  }

  static Map<String, Object?> _map(Map<String, Object?> json, String key) {
    final value = _nullableMap(json[key]);
    if (value == null) throw FormatException('Expected object for $key');
    return value;
  }

  static Map<String, Object?>? _nullableMap(Object? value) {
    if (value == null) return null;
    if (value is! Map) throw FormatException('Expected JSON object');
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  static List<String> _stringList(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! List) throw FormatException('Expected List for $key');
    return value.map((item) {
      if (item is! String) throw FormatException('Expected String in $key');
      return item;
    }).toList();
  }

  static List<Map<String, Object?>> _mapList(
    Map<String, Object?> json,
    String key,
  ) {
    final value = json[key];
    if (value is! List) throw FormatException('Expected List for $key');
    return value.map((item) {
      final mapped = _nullableMap(item);
      if (mapped == null) throw FormatException('Expected object in $key');
      return mapped;
    }).toList();
  }
}
