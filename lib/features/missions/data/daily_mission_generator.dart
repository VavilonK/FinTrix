import 'dart:math';

import '../../tasks/data/location_definitions.dart';
import '../../tasks/domain/location_definition.dart';
import '../domain/mission_models.dart';
import 'daily_task_templates.dart';

class DailyMissionGenerator {
  const DailyMissionGenerator();

  DailyMission generate({
    required DateTime date,
    required String childName,
    required int age,
    required DifficultyLevel difficulty,
    required int balance,
    List<String> recentLocationIds = const [],
    List<String> recentTaskTemplateIds = const [],
    int taskCount = 12,
    String? seedKey,
    String? locationId,
    MissionTheme? theme,
    TaskTheme? primaryTheme,
    TaskTheme? secondaryTheme,
  }) {
    final day = DateTime(date.year, date.month, date.day);
    final seed = _stableHash(
      seedKey ?? '${day.year}-${day.month}-${day.day}|$childName|$age',
    );
    final random = Random(seed);
    final missionTheme =
        theme ?? MissionTheme.values[seed % MissionTheme.values.length];
    final desiredThemes = _themesForDay(missionTheme);
    final dayOrdinal =
        day.toUtc().millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    final profileOffset =
        _stableHash('$childName|$age') % LocationDefinitions.all.length;
    final location = locationId == null
        ? _chooseLocation(
            cycleIndex: dayOrdinal + profileOffset,
            recentLocationIds: recentLocationIds,
          )
        : LocationDefinitions.byId(locationId);
    final resolvedPrimaryTheme =
        primaryTheme ??
        location.preferredThemes.firstWhere(
          desiredThemes.contains,
          orElse: () => location.preferredThemes.first,
        );
    final resolvedSecondaryTheme =
        secondaryTheme ??
        location.preferredThemes.firstWhere(
          (candidate) => candidate != resolvedPrimaryTheme,
          orElse: () => TaskTheme.logic,
        );
    final templates = _chooseTemplates(
      random: random,
      location: location,
      missionTheme: missionTheme,
      balance: balance,
      recentTaskTemplateIds: recentTaskTemplateIds,
      taskCount: taskCount.clamp(10, 15),
    );
    final tasks = <MissionTask>[];
    for (var index = 0; index < templates.length; index++) {
      tasks.add(
        DailyTaskTemplates.build(
          templateId: templates[index],
          id:
              '${day.year}${day.month.toString().padLeft(2, '0')}'
              '${day.day.toString().padLeft(2, '0')}_${index + 1}',
          difficulty: difficulty,
          variant: random.nextInt(10000),
          availableBalance: balance,
        ),
      );
    }
    final seconds = tasks.fold<int>(
      0,
      (total, task) => total + task.estimatedSeconds,
    );
    final estimatedMinutes = (seconds / 60).ceil().clamp(18, 25);
    // Choice tasks may pay per option (e.g. reward split with the piggy
    // bank): count the largest option.
    final maxReward = tasks.fold<int>(0, (total, task) {
      final best = task.options.fold<int>(
        0,
        (value, option) =>
            max(value, option.rewardCoins + option.savingsReward),
      );
      return total + max(task.rewardCoins, best);
    });

    return DailyMission(
      id: '${day.year}_${day.month}_${day.day}_${location.id}_$age',
      date: day,
      locationId: location.id,
      title: _titleFor(missionTheme),
      theme: missionTheme,
      primaryTaskTheme: resolvedPrimaryTheme,
      secondaryTaskTheme: resolvedSecondaryTheme,
      tasks: tasks,
      estimatedMinutes: estimatedMinutes,
      maxReward: maxReward,
    );
  }

  LocationDefinition _chooseLocation({
    required int cycleIndex,
    required List<String> recentLocationIds,
  }) {
    final recent = recentLocationIds.take(7).toSet();
    final locations = LocationDefinitions.all;
    for (var offset = 0; offset < locations.length; offset++) {
      final candidate = locations[(cycleIndex + offset) % locations.length];
      if (!recent.contains(candidate.id)) return candidate;
    }
    return locations[cycleIndex % locations.length];
  }

  List<String> _chooseTemplates({
    required Random random,
    required LocationDefinition location,
    required MissionTheme missionTheme,
    required int balance,
    required List<String> recentTaskTemplateIds,
    required int taskCount,
  }) {
    final desiredThemes = _themesForDay(missionTheme);
    final recent = recentTaskTemplateIds.take(16).toSet();
    final earningPool = <String>[
      'count_coins',
      'fix_fox_mistake',
      'find_coins',
      'continue_sequence',
      'repeat_after_fox',
    ];
    earningPool.shuffle(random);
    earningPool.sort((a, b) {
      final aWasRecent = recent.contains(a) ? 1 : 0;
      final bWasRecent = recent.contains(b) ? 1 : 0;
      return aWasRecent.compareTo(bWasRecent);
    });
    final selected = <String>[...earningPool.take(3)];
    // One savings scenario in every mission (ТЗ 2.5.8), preferring the one
    // not played recently.
    final savingsPool = [...DailyTaskTemplates.savingsTemplateIds]
      ..shuffle(random)
      ..sort(
        (a, b) =>
            (recent.contains(a) ? 1 : 0).compareTo(recent.contains(b) ? 1 : 0),
      );
    selected.add(savingsPool.first);
    final nonExpense = DailyTaskTemplates.allTemplateIds
        .where(
          (id) =>
              !DailyTaskTemplates.realExpenseTemplateIds.contains(id) &&
              !selected.contains(id),
        )
        .toList();
    nonExpense.shuffle(random);
    nonExpense.sort((a, b) {
      final aScore = _templateScore(
        a,
        desiredThemes,
        location.preferredThemes,
        recent,
      );
      final bScore = _templateScore(
        b,
        desiredThemes,
        location.preferredThemes,
        recent,
      );
      return bScore.compareTo(aScore);
    });

    final expenseCount = balance >= 20 ? 1 : 0;
    final nonExpenseTarget = taskCount - expenseCount;
    for (final templateId in nonExpense) {
      if (selected.length >= nonExpenseTarget) break;
      selected.add(templateId);
    }
    while (selected.length < nonExpenseTarget) {
      selected.add(nonExpense[selected.length % nonExpense.length]);
    }
    selected.shuffle(random);

    final expensePool = _expenseTemplatesFor(location.id)
        .where((id) => !recent.contains(id))
        .toList();
    if (expensePool.length < expenseCount) {
      expensePool.addAll(
        DailyTaskTemplates.realExpenseTemplateIds.where(
          (id) => !expensePool.contains(id),
        ),
      );
    }
    expensePool.shuffle(random);

    final result = <String>[];
    var regularIndex = 0;
    var expenseIndex = 0;
    for (var index = 0; index < taskCount; index++) {
      final expenseSlot =
          expenseIndex < expenseCount &&
          (index == 4 || index == 9 || regularIndex >= selected.length);
      if (expenseSlot) {
        result.add(expensePool[expenseIndex]);
        expenseIndex += 1;
      } else {
        result.add(selected[regularIndex]);
        regularIndex += 1;
      }
    }
    return result;
  }

  int _templateScore(
    String templateId,
    Set<TaskTheme> desiredThemes,
    Set<TaskTheme> locationThemes,
    Set<String> recent,
  ) {
    final theme = DailyTaskTemplates.themeFor(templateId);
    var score = 0;
    if (desiredThemes.contains(theme)) score += 5;
    if (locationThemes.contains(theme)) score += 3;
    if (recent.contains(templateId)) score -= 8;
    return score;
  }

  Set<String> _expenseTemplatesFor(String locationId) => switch (locationId) {
    'game_center' => {'choose_entertainment', 'cultural_outing'},
    'school' => {'buy_stationery', 'choose_transport'},
    'canteen' => {'lunch_time', 'choose_transport'},
    'stationery_store' => {'buy_stationery', 'choose_transport'},
    'supermarket' => {'lunch_time', 'choose_transport'},
    'amusement_park' => {'choose_entertainment', 'choose_transport'},
    'cinema' => {'cultural_outing', 'choose_transport'},
    'museum' => {'cultural_outing', 'choose_transport'},
    'library' => {'choose_transport', 'buy_stationery'},
    'transport_hub' => {'choose_transport', 'lunch_time'},
    'sports_center' => {'choose_transport', 'choose_entertainment'},
    'science_center' => {'cultural_outing', 'choose_transport'},
    _ => {'choose_transport', 'lunch_time'},
  };

  Set<TaskTheme> _themesForDay(MissionTheme theme) => switch (theme) {
    MissionTheme.math => {TaskTheme.math},
    MissionTheme.logic => {
      TaskTheme.logic,
      TaskTheme.attention,
      TaskTheme.memory,
    },
    MissionTheme.shopping => {TaskTheme.finance, TaskTheme.math},
    MissionTheme.savings => {TaskTheme.finance, TaskTheme.math},
    MissionTheme.entertainment => {
      TaskTheme.entertainment,
      TaskTheme.memory,
      TaskTheme.attention,
    },
    MissionTheme.mixed => TaskTheme.values.toSet(),
  };

  String _titleFor(MissionTheme theme) => switch (theme) {
    MissionTheme.math => 'День математики',
    MissionTheme.logic => 'День логики',
    MissionTheme.shopping => 'День покупок',
    MissionTheme.savings => 'День накоплений',
    MissionTheme.entertainment => 'День впечатлений',
    MissionTheme.mixed => 'Большое приключение',
  };

  int _stableHash(String value) {
    var hash = 2166136261;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash;
  }
}
