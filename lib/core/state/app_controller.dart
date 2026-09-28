// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/goals/domain/savings_goal.dart';
import '../../features/adult/domain/parent_access_service.dart';
import '../../features/budget/domain/budget_plan.dart';
import '../../features/budget/domain/budget_usage.dart';
import '../../features/finance/data/financial_transaction_repository.dart';
import '../../features/finance/domain/financial_transaction.dart';
import '../../features/home/domain/pet_models.dart';
import '../../features/missions/data/daily_mission_generator.dart';
import '../../features/missions/domain/mission_models.dart';
import '../../features/periods/data/demo_period_definitions.dart';
import '../../features/periods/domain/game_period.dart';
import '../../features/pet_progression/domain/pet_appearance.dart';
import '../../features/pet_progression/domain/pet_progression.dart';
import '../../features/pet_progression/domain/pet_progression_policy.dart';
import '../../features/play/domain/mini_game_models.dart';
import '../../features/profile/domain/profile_models.dart';
import '../assets/app_assets.dart';
import '../storage/app_state_repository.dart';
import '../storage/app_state_snapshot.dart';

class AppController extends ChangeNotifier {
  AppController({
    DateTime? now,
    AppStateRepository? repository,
    FinancialTransactionStore? financialTransactions,
    ParentProfile parentProfile = const ParentProfile.initial(),
    ParentAccessService? parentAccessService,
    bool persistenceEnabled = true,
  }) : _repository = repository,
       _financialTransactions =
           financialTransactions ?? InMemoryFinancialTransactionRepository(),
       _parentProfile = parentProfile,
       _parentAccessService =
           parentAccessService ??
           ParentAccessService(
             MemoryParentCredentialStore(),
             const UnavailableParentBiometricAuthenticator(),
           ),
       _persistenceEnabled = persistenceEnabled {
    final startedAt = now ?? DateTime.now();
    petState = PetState(mood: 75, satiety: 65, care: 70, lastFedAt: startedAt);
    _lastHungerCheckAt = startedAt;
  }

  factory AppController.fromSnapshot({
    required AppStateSnapshot snapshot,
    AppStateRepository? repository,
    FinancialTransactionStore? financialTransactions,
    ParentProfile parentProfile = const ParentProfile.initial(),
    ParentAccessService? parentAccessService,
  }) {
    final controller = AppController(
      now: snapshot.lastHungerCheckAt,
      repository: repository,
      financialTransactions: financialTransactions,
      parentProfile: parentProfile,
      parentAccessService: parentAccessService,
    );
    controller._restore(snapshot);
    return controller;
  }

  static const Duration _hungerInterval = Duration(minutes: 15);
  static const int _satietyLossPerInterval = 3;

  final AppStateRepository? _repository;
  final FinancialTransactionStore _financialTransactions;
  final ParentAccessService _parentAccessService;
  ParentProfile _parentProfile;
  bool _persistenceEnabled;
  AppStateSnapshot? _volatileNormalSnapshot;
  AppStateSnapshot? _volatileDemoSnapshot;

  AppRunMode runMode = AppRunMode.normal;
  GamePeriod? activeGamePeriod;
  final List<GamePeriod> completedGamePeriods = [];
  int demoPeriodIndex = 1;

  ChildProfile childProfile = const ChildProfile.initial();
  DifficultyLevel difficultyLevel = DifficultyLevel.junior;
  int balance = 1250;
  int savings = 2400;
  String selectedGoalId = 'bicycle';
  final List<SavingsGoal> goals = const [
    SavingsGoal(
      id: 'bicycle',
      title: 'Накопить на велосипед',
      price: 5000,
      assetPath: AppAssets.goalBicycleBlue,
    ),
    SavingsGoal(
      id: 'scooter',
      title: 'Самокат',
      price: 3200,
      assetPath: AppAssets.goalScooterPurple,
    ),
    SavingsGoal(
      id: 'building_set',
      title: 'Конструктор',
      price: 1800,
      assetPath: AppAssets.goalBuildingSet,
    ),
  ];
  BudgetPlan budgetPlan = const BudgetPlan(
    essentialsPlanned: 500,
    wantsPlanned: 350,
    savingsPlanned: 400,
  );
  bool budgetPlanConfirmed = false;
  int streak = 4;
  int petLevel = 5;
  int petXp = 680;
  int petGrowthPoints = 0;
  int completedTasks = 18;
  int completedMissions = 0;
  int achievedGoals = 2;
  final Set<String> completedGoalIds = {};
  int daysTogether = 12;
  late PetState petState;
  BudgetUsage budgetUsage = const BudgetUsage();
  bool soundEnabled = true;
  bool hintsEnabled = true;
  PetAppearance petAppearance = const PetAppearance();

  ParentProfile get parentProfile => _parentProfile;

  bool get parentSetupCompleted => _parentProfile.parentSetupCompleted;

  String get childName => childProfile.name;

  int get age => childProfile.age;

  DailyMission? activeMission;
  DailyMission? _cachedDailyMission;
  String? _cachedDailyMissionKey;
  final List<String> lastLocationIds = [];
  final List<String> lastTaskTemplateIds = [];
  int currentTaskIndex = 0;
  MissionResult? lastResult;

  int sessionEarnedCoins = 0;
  int sessionSpentCoins = 0;
  int sessionSavedCoins = 0;
  int sessionXp = 0;
  int sessionCompletedTasks = 0;

  bool _awaitingAdvance = false;
  late DateTime _lastHungerCheckAt;
  int _transactionSequence = 0;

  String get financialProfileId => runMode.name;

  SavingsGoal get selectedGoal => goals.firstWhere(
    (goal) => goal.id == selectedGoalId,
    orElse: () => goals.first,
  );

  int get goalPrice => selectedGoal.price;

  int get goalRemaining => (goalPrice - savings).clamp(0, goalPrice);

  int get maxSavingsContribution {
    if (balance <= 0 || goalRemaining <= 0) return 0;
    return balance < goalRemaining ? balance : goalRemaining;
  }

  int get savingsPlanRemaining =>
      (budgetPlan.savingsPlanned - budgetUsage.savingsDeposited)
          .clamp(0, budgetPlan.savingsPlanned)
          .toInt();

  bool wouldExceedSavingsPlan(int amount) {
    if (amount <= 0) return false;
    return budgetUsage.savingsDeposited + amount > budgetPlan.savingsPlanned;
  }

  bool get isGoalReached => savings >= goalPrice;

  bool isGoalCompleted(String goalId) => completedGoalIds.contains(goalId);

  bool get isSelectedGoalCompleted => isGoalCompleted(selectedGoal.id);

  bool get canCompleteSelectedGoal =>
      !isSelectedGoalCompleted && savings >= selectedGoal.price;

  bool get hasActiveMission => activeMission != null;

  bool get awaitingMissionAdvance => _awaitingAdvance;

  bool get isDemoMode => runMode == AppRunMode.demo;

  bool get isCurrentPeriodCompleted =>
      activeGamePeriod?.status == GamePeriodStatus.completed;

  bool get isDemoComplete =>
      isDemoMode &&
      demoPeriodIndex >= DemoPeriodDefinitions.count &&
      isCurrentPeriodCompleted;

  int get demoTotalEarned => completedGamePeriods
      .where((period) => period.isDemoPeriod)
      .fold(0, (sum, period) => sum + period.earnedCoins);

  int get demoTotalEssentialSpent => completedGamePeriods
      .where((period) => period.isDemoPeriod)
      .fold(0, (sum, period) => sum + period.essentialSpent);

  int get demoTotalWantSpent => completedGamePeriods
      .where((period) => period.isDemoPeriod)
      .fold(0, (sum, period) => sum + period.wantSpent);

  int get demoTotalDeposited => completedGamePeriods
      .where((period) => period.isDemoPeriod)
      .fold(0, (sum, period) => sum + period.depositedToSavings);

  int get demoTotalTasks => completedGamePeriods
      .where((period) => period.isDemoPeriod)
      .fold(0, (sum, period) => sum + period.completedTaskCount);

  int get demoTotalGrowthPoints => completedGamePeriods
      .where((period) => period.isDemoPeriod)
      .fold(0, (sum, period) => sum + period.growthPointsAwarded);

  PetGrowthStage get petGrowthStage =>
      PetProgressionConfig.stageForPoints(petGrowthPoints);

  int get totalBudgetAllocated => budgetPlan.totalAllocated;

  int get budgetRemainingToAllocate => balance - totalBudgetAllocated;

  bool get canConfirmBudget => totalBudgetAllocated == balance;

  bool get budgetPlanNeedsUpdate => totalBudgetAllocated != balance;

  int plannedForExpense(ExpenseCategory category) {
    return switch (category) {
      ExpenseCategory.essential => budgetPlan.essentialsPlanned,
      ExpenseCategory.want => budgetPlan.wantsPlanned,
    };
  }

  int spentForExpense(ExpenseCategory category) {
    return budgetUsage.spentFor(category);
  }

  bool wouldExceedBudgetPlan(int amount, ExpenseCategory category) {
    if (amount <= 0) return false;
    return spentForExpense(category) + amount > plannedForExpense(category);
  }

  double get budgetAllocationProgress {
    if (balance <= 0) return totalBudgetAllocated == 0 ? 1 : 0;
    return (totalBudgetAllocated / balance).clamp(0, 1).toDouble();
  }

  MissionTask? get currentTask {
    final mission = activeMission;
    if (mission == null || currentTaskIndex >= mission.tasks.length) {
      return null;
    }
    return mission.tasks[currentTaskIndex];
  }

  DailyMission missionForToday({DateTime? now}) {
    final actualDate = now ?? DateTime.now();
    final existingPeriod = activeGamePeriod;
    if (existingPeriod != null &&
        existingPeriod.status == GamePeriodStatus.active &&
        (activeMission != null || _cachedDailyMission != null)) {
      return activeMission ?? _cachedDailyMission!;
    }

    if (!isDemoMode && existingPeriod != null) {
      final sameCalendarDay = _isSameDay(existingPeriod.startedAt, actualDate);
      if (existingPeriod.status == GamePeriodStatus.completed &&
          sameCalendarDay &&
          (activeMission != null || _cachedDailyMission != null)) {
        return activeMission ?? _cachedDailyMission!;
      }
      if (existingPeriod.status == GamePeriodStatus.completed &&
          !sameCalendarDay) {
        _clearMissionRuntime();
        activeGamePeriod = null;
      }
    }

    final demoDefinition = isDemoMode
        ? DemoPeriodDefinitions.forSequence(demoPeriodIndex)
        : null;
    final missionDate = isDemoMode
        ? DateTime(2026, 1, demoPeriodIndex)
        : actualDate;
    final key = isDemoMode
        ? 'demo|$demoPeriodIndex|$childName|$age'
        : '${missionDate.year}-${missionDate.month}-${missionDate.day}|'
              '$childName|$age';
    if (_cachedDailyMissionKey == key && _cachedDailyMission != null) {
      activeGamePeriod ??= _createGamePeriod(
        _cachedDailyMission!,
        startedAt: actualDate,
        resetPeriodBudget: activeMission == null,
      );
      return _cachedDailyMission!;
    }
    _cachedDailyMission = const DailyMissionGenerator().generate(
      date: missionDate,
      childName: childName,
      age: age,
      difficulty: difficultyLevel,
      balance: balance,
      recentLocationIds: lastLocationIds,
      recentTaskTemplateIds: lastTaskTemplateIds,
      seedKey: demoDefinition?.seedKey,
      locationId: demoDefinition?.locationId,
      theme: demoDefinition?.missionTheme,
      primaryTheme: demoDefinition?.primaryTheme,
      secondaryTheme: demoDefinition?.secondaryTheme,
    );
    _cachedDailyMissionKey = key;
    activeGamePeriod ??= _createGamePeriod(
      _cachedDailyMission!,
      startedAt: actualDate,
      resetPeriodBudget: activeMission == null,
    );
    _persist();
    return _cachedDailyMission!;
  }

  double get goalProgress {
    if (goalPrice <= 0) return 0;
    return (savings / goalPrice).clamp(0, 1).toDouble();
  }

  SavingsDepositResult addToSavings(
    int amount, {
    bool confirmPlanOverrun = false,
  }) {
    if (isSelectedGoalCompleted ||
        amount <= 0 ||
        amount > balance ||
        amount > goalRemaining) {
      return SavingsDepositResult.insufficientFunds;
    }
    if (!confirmPlanOverrun && wouldExceedSavingsPlan(amount)) {
      return SavingsDepositResult.requiresConfirmation;
    }
    final balanceBefore = balance;
    final savingsBefore = savings;
    balance -= amount;
    savings += amount;
    budgetUsage = budgetUsage.addSavingsDeposit(amount);
    _recordPeriodDeposit(amount, intentional: true);
    _recordFinancialTransaction(
      type: FinancialTransactionType.savingsDeposit,
      source: FinancialTransactionSource.savings,
      title: 'В копилку',
      description: selectedGoal.title,
      sourceId: selectedGoal.id,
      amount: amount,
      balanceBefore: balanceBefore,
      balanceAfter: balance,
      savingsBefore: savingsBefore,
      savingsAfter: savings,
    );
    _notifyAndPersist();
    return SavingsDepositResult.success;
  }

  SavingsWithdrawalResult withdrawFromSavings(int amount, {DateTime? now}) {
    if (amount <= 0) return SavingsWithdrawalResult.invalidAmount;
    if (amount > savings) return SavingsWithdrawalResult.insufficientSavings;

    final balanceBefore = balance;
    final savingsBefore = savings;
    balance += amount;
    savings -= amount;
    _recordFinancialTransaction(
      type: FinancialTransactionType.savingsWithdrawal,
      source: FinancialTransactionSource.savings,
      title: 'Из копилки',
      description: isSelectedGoalCompleted ? null : selectedGoal.title,
      sourceId: selectedGoal.id,
      amount: amount,
      balanceBefore: balanceBefore,
      balanceAfter: balance,
      savingsBefore: savingsBefore,
      savingsAfter: savings,
      createdAt: now,
    );
    _notifyAndPersist();
    return SavingsWithdrawalResult.success;
  }

  GoalCompletionResult completeSelectedGoal({DateTime? now}) {
    final goal = selectedGoal;
    if (isGoalCompleted(goal.id)) {
      return GoalCompletionResult.alreadyCompleted;
    }
    if (savings < goal.price) {
      return GoalCompletionResult.insufficientSavings;
    }

    final balanceBefore = balance;
    final savingsBefore = savings;
    savings -= goal.price;
    completedGoalIds.add(goal.id);
    achievedGoals += 1;
    _recordFinancialTransaction(
      id: '${financialProfileId}_goal_purchase_${goal.id}',
      type: FinancialTransactionType.goalPurchase,
      source: FinancialTransactionSource.savings,
      title: 'Мечта: ${_goalDisplayName(goal)}',
      description: 'Мечта достигнута',
      sourceId: goal.id,
      amount: goal.price,
      balanceBefore: balanceBefore,
      balanceAfter: balance,
      savingsBefore: savingsBefore,
      savingsAfter: savings,
      createdAt: now,
    );
    _notifyAndPersist();
    return GoalCompletionResult.success;
  }

  bool updateBudgetCategory(BudgetCategory category, int delta) {
    if (delta == 0) return false;
    final nextAmount = budgetPlan.amountFor(category) + delta;
    final nextTotal = totalBudgetAllocated + delta;
    if (nextAmount < 0 || (delta > 0 && nextTotal > balance)) return false;

    budgetPlan = budgetPlan.withAmount(category, nextAmount);
    budgetPlanConfirmed = false;
    _notifyAndPersist();
    return true;
  }

  bool allocateBudgetRemainder(BudgetCategory category) {
    final remainder = budgetRemainingToAllocate;
    if (remainder <= 0) return false;
    budgetPlan = budgetPlan.withAmount(
      category,
      budgetPlan.amountFor(category) + remainder,
    );
    budgetPlanConfirmed = false;
    _notifyAndPersist();
    return true;
  }

  bool confirmBudgetPlan() {
    if (!canConfirmBudget) return false;
    budgetPlanConfirmed = true;
    final period = activeGamePeriod;
    if (period != null && period.status == GamePeriodStatus.active) {
      activeGamePeriod = period.copyWith(
        budgetWasConfirmed: true,
        budgetPlanSnapshot: budgetPlan,
      );
    }
    _notifyAndPersist();
    return true;
  }

  void refreshPetState({DateTime? now}) {
    if (_applyHunger(now ?? DateTime.now())) _notifyAndPersist();
  }

  SpendCoinsResult spendCoins(
    int amount,
    ExpenseCategory category, {
    bool confirmPlanOverrun = false,
    String? title,
    String? description,
    FinancialTransactionSource source = FinancialTransactionSource.system,
    String? sourceId,
    DateTime? now,
  }) {
    final actionTime = now ?? DateTime.now();
    final hungerChanged = _applyHunger(actionTime);
    if (amount <= 0 || amount > balance) {
      if (hungerChanged) _notifyAndPersist();
      return SpendCoinsResult.insufficientFunds;
    }
    if (!confirmPlanOverrun && wouldExceedBudgetPlan(amount, category)) {
      if (hungerChanged) _notifyAndPersist();
      return SpendCoinsResult.requiresConfirmation;
    }
    final balanceBefore = balance;
    final savingsBefore = savings;
    _recordExpense(amount, category);
    _recordFinancialTransaction(
      type: _expenseTransactionType(category),
      source: source,
      title: title ?? _defaultExpenseTitle(category),
      description: description,
      sourceId: sourceId,
      amount: amount,
      balanceBefore: balanceBefore,
      balanceAfter: balance,
      savingsBefore: savingsBefore,
      savingsAfter: savings,
      createdAt: actionTime,
    );
    _notifyAndPersist();
    return SpendCoinsResult.success;
  }

  FeedPetResult feedPet(
    FoodType type, {
    DateTime? now,
    bool confirmPlanOverrun = false,
  }) {
    final actionTime = now ?? DateTime.now();
    final hungerChanged = _applyHunger(actionTime);
    if (type.cost > balance) {
      if (hungerChanged) _notifyAndPersist();
      return FeedPetResult.insufficientFunds;
    }
    if (!confirmPlanOverrun &&
        wouldExceedBudgetPlan(type.cost, type.expenseCategory)) {
      if (hungerChanged) _notifyAndPersist();
      return FeedPetResult.requiresConfirmation;
    }

    final balanceBefore = balance;
    final savingsBefore = savings;
    _recordExpense(type.cost, type.expenseCategory);
    _recordFinancialTransaction(
      type: _expenseTransactionType(type.expenseCategory),
      source: FinancialTransactionSource.petCare,
      title: _foodTransactionTitle(type),
      description: 'Забота о Рыжике',
      sourceId: type.name,
      amount: type.cost,
      balanceBefore: balanceBefore,
      balanceAfter: balance,
      savingsBefore: savingsBefore,
      savingsAfter: savings,
      createdAt: actionTime,
    );

    petState = petState.copyWith(
      satiety: petState.satiety + type.satietyGain,
      mood: petState.mood + type.moodGain,
      care: petState.care + type.careGain,
      lastFedAt: actionTime,
    );
    _lastHungerCheckAt = actionTime;
    _notifyAndPersist();
    return FeedPetResult.success;
  }

  void petFox({DateTime? now}) {
    final actionTime = now ?? DateTime.now();
    _applyHunger(actionTime);
    petState = petState.copyWith(
      mood: petState.mood + 6,
      care: petState.care + 12,
      lastPettedAt: actionTime,
    );
    _notifyAndPersist();
  }

  MiniGameReward completeMiniGame(
    MiniGameType gameType,
    MiniGameResult result, {
    DateTime? now,
  }) {
    final actionTime = now ?? DateTime.now();
    _applyHunger(actionTime);
    if (activeGamePeriod == null) {
      missionForToday(now: actionTime);
    }

    final period = activeGamePeriod;
    final gameId = gameType.persistentId;
    final isFirstCompletion =
        period != null && !period.rewardedMiniGameIds.contains(gameId);
    final xpAwarded = isFirstCompletion ? MiniGameReward.firstCompletionXp : 0;

    if (period != null && isFirstCompletion) {
      final updated = period.copyWith(
        rewardedMiniGameIds: [...period.rewardedMiniGameIds, gameId],
      );
      activeGamePeriod = updated;
      if (updated.status == GamePeriodStatus.completed) {
        final index = completedGamePeriods.indexWhere(
          (candidate) => candidate.id == updated.id,
        );
        if (index >= 0) completedGamePeriods[index] = updated;
      }
    }

    petXp += xpAwarded;
    sessionXp += xpAwarded;
    petState = petState.copyWith(
      mood: petState.mood + (isFirstCompletion ? 10 : 3),
      lastPlayedAt: actionTime,
    );
    _notifyAndPersist();
    return MiniGameReward(xp: xpAwarded);
  }

  void setSoundEnabled(bool value) {
    if (soundEnabled == value) return;
    soundEnabled = value;
    _notifyAndPersist();
  }

  /// Visual only: hoodie colour and accessories chosen in Profile.
  void setPetAppearance(PetAppearance value) {
    if (petAppearance == value) return;
    petAppearance = value;
    _notifyAndPersist();
  }

  void setHintsEnabled(bool value) {
    if (hintsEnabled == value) return;
    hintsEnabled = value;
    _notifyAndPersist();
  }

  Future<bool> createParentPin(String pin) {
    return _parentAccessService.setPin(pin);
  }

  Future<bool> verifyParentPin(String pin) {
    return _parentAccessService.verifyPin(pin);
  }

  Future<bool> isParentBiometricAvailable() {
    return _parentAccessService.isBiometricAvailable();
  }

  Future<bool> authenticateParentWithBiometrics() async {
    if (!_parentProfile.biometricEnabled) return false;
    return _parentAccessService.authenticateWithBiometrics();
  }

  Future<bool> changeParentPin({
    required String currentPin,
    required String newPin,
  }) {
    return _parentAccessService.changePin(
      currentPin: currentPin,
      newPin: newPin,
    );
  }

  Future<void> completeParentSetup({
    required String childName,
    required int age,
    bool biometricEnabled = false,
  }) async {
    final normalizedName = _normalizedChildName(childName);
    if (normalizedName == null || !_isSupportedChildAge(age)) {
      throw ArgumentError('Child profile is incomplete.');
    }
    if (!await _parentAccessService.hasPin()) {
      throw StateError('Parent PIN must be configured before setup completes.');
    }

    childProfile = ChildProfile(name: normalizedName, age: age);
    difficultyLevel = _difficultyForAge(age);
    _parentProfile = _parentProfile.copyWith(
      parentSetupCompleted: true,
      biometricEnabled: biometricEnabled,
    );
    missionForToday();
    notifyListeners();
    await _repository?.saveParentProfile(_parentProfile);
    await _repository?.save(toSnapshot());
  }

  Future<void> setParentBiometricEnabled(bool enabled) async {
    final nextValue = enabled && await isParentBiometricAvailable();
    if (_parentProfile.biometricEnabled == nextValue) return;
    _parentProfile = _parentProfile.copyWith(biometricEnabled: nextValue);
    notifyListeners();
    await _repository?.saveParentProfile(_parentProfile);
  }

  void updateChildProfile({String? name, int? age}) {
    final nextName = name == null ? childName : _normalizedChildName(name);
    final nextAge = age ?? this.age;
    if (nextName == null || !_isSupportedChildAge(nextAge)) return;
    if (nextName == childName && nextAge == this.age) return;

    childProfile = ChildProfile(name: nextName, age: nextAge);
    difficultyLevel = _difficultyForAge(nextAge);
    // The generated mission is a snapshot of its original age parameters.
    // A profile change applies only after that mission/period is finished.
    _notifyAndPersist();
  }

  Future<void> resetDemoData({DateTime? now}) async {
    final profileId = financialProfileId;
    final resetAt = now ?? DateTime.now();
    _resetProfileFields(mode: runMode, resetAt: resetAt);
    if (isDemoMode) missionForToday(now: resetAt);
    _persistenceEnabled = true;
    notifyListeners();
    await _financialTransactions.clearForProfile(profileId);
    await _repository?.replaceWith(toSnapshot());
  }

  Future<bool> enterDemoMode({DateTime? now}) async {
    if (isDemoMode) return true;
    final repository = _repository;
    final normalSnapshot = toSnapshot();
    _volatileNormalSnapshot = normalSnapshot;
    if (repository != null) {
      await repository.saveProfile(normalSnapshot, makeActive: false);
      final storedDemo = await repository.loadProfile(AppRunMode.demo);
      if (storedDemo.isCorrupted) return false;
      if (storedDemo.snapshot case final demoSnapshot?) {
        _restore(demoSnapshot);
      } else {
        _resetProfileFields(
          mode: AppRunMode.demo,
          resetAt: now ?? DateTime.now(),
        );
        missionForToday(now: now ?? DateTime.now());
      }
      await repository.save(toSnapshot());
    } else {
      final existingDemo = _volatileDemoSnapshot;
      if (existingDemo != null) {
        _restore(existingDemo);
      } else {
        _resetProfileFields(
          mode: AppRunMode.demo,
          resetAt: now ?? DateTime.now(),
        );
        missionForToday(now: now ?? DateTime.now());
      }
    }
    notifyListeners();
    return true;
  }

  Future<bool> exitDemoMode({DateTime? now}) async {
    if (!isDemoMode) return true;
    final repository = _repository;
    final demoSnapshot = toSnapshot();
    _volatileDemoSnapshot = demoSnapshot;
    if (repository != null) {
      await repository.saveProfile(demoSnapshot, makeActive: false);
      final storedNormal = await repository.loadProfile(AppRunMode.normal);
      if (storedNormal.isCorrupted) return false;
      if (storedNormal.snapshot case final normalSnapshot?) {
        _restore(normalSnapshot);
      } else {
        _resetProfileFields(
          mode: AppRunMode.normal,
          resetAt: now ?? DateTime.now(),
        );
      }
      await repository.save(toSnapshot());
    } else {
      final normalSnapshot = _volatileNormalSnapshot;
      if (normalSnapshot != null) {
        _restore(normalSnapshot);
      } else {
        _resetProfileFields(
          mode: AppRunMode.normal,
          resetAt: now ?? DateTime.now(),
        );
      }
    }
    notifyListeners();
    return true;
  }

  Future<void> resetDemoMode({DateTime? now}) async {
    if (!isDemoMode) return;
    final resetAt = now ?? DateTime.now();
    _resetProfileFields(mode: AppRunMode.demo, resetAt: resetAt);
    missionForToday(now: resetAt);
    _volatileDemoSnapshot = toSnapshot();
    notifyListeners();
    await _financialTransactions.clearForProfile(AppRunMode.demo.name);
    await _repository?.replaceWith(toSnapshot());
  }

  Future<bool> deleteCurrentProfileData({DateTime? now}) async {
    if (isDemoMode) return false;
    final resetAt = now ?? DateTime.now();
    _persistenceEnabled = false;
    try {
      await _repository?.deleteProfileData(AppRunMode.normal);
      await _financialTransactions.clearForProfile(AppRunMode.normal.name);
      await _repository?.deleteParentProfile();
      await _parentAccessService.clear();
      _parentProfile = const ParentProfile.initial();
      _resetProfileFields(mode: AppRunMode.normal, resetAt: resetAt);
    } finally {
      _persistenceEnabled = true;
    }
    notifyListeners();
    return true;
  }

  void _recordExpense(int amount, ExpenseCategory category) {
    balance -= amount;
    budgetUsage = budgetUsage.addExpense(amount, category);
    _recordPeriodExpense(amount, category);
  }

  bool _applyHunger(DateTime now) {
    if (now.isBefore(_lastHungerCheckAt)) {
      _lastHungerCheckAt = now;
      return false;
    }
    final intervals =
        now.difference(_lastHungerCheckAt).inMinutes ~/
        _hungerInterval.inMinutes;
    if (intervals <= 0 || petState.satiety == 0) return false;

    petState = petState.copyWith(
      satiety: petState.satiety - intervals * _satietyLossPerInterval,
    );
    _lastHungerCheckAt = _lastHungerCheckAt.add(
      Duration(minutes: intervals * _hungerInterval.inMinutes),
    );
    return true;
  }

  bool selectGoal(String goalId) {
    if (goalId == selectedGoalId ||
        isGoalCompleted(goalId) ||
        !goals.any((goal) => goal.id == goalId)) {
      return false;
    }
    selectedGoalId = goalId;
    _notifyAndPersist();
    return true;
  }

  double get missionProgress {
    final total = activeMission?.tasks.length ?? 0;
    if (total == 0) return 0;
    return (sessionCompletedTasks / total).clamp(0, 1).toDouble();
  }

  void startMission(DailyMission mission) {
    activeGamePeriod ??= _createGamePeriod(
      mission,
      startedAt: DateTime.now(),
      resetPeriodBudget: true,
    );
    activeMission = mission;
    currentTaskIndex = 0;
    lastResult = null;
    sessionEarnedCoins = 0;
    sessionSpentCoins = 0;
    sessionSavedCoins = 0;
    sessionXp = 0;
    sessionCompletedTasks = 0;
    _awaitingAdvance = false;
    _notifyAndPersist();
  }

  bool canAffordOption(MissionTaskOption option) {
    return option.spendCoins <= balance && option.spendFromSavings <= savings;
  }

  MissionResult submitCurrentTask({
    String? selectedOptionId,
    bool? isCorrectOverride,
  }) {
    if (_awaitingAdvance && lastResult != null) return lastResult!;

    final task = currentTask;
    if (task == null) {
      throw StateError('There is no active mission task.');
    }

    MissionTaskOption? option;
    if (selectedOptionId != null) {
      for (final candidate in task.options) {
        if (candidate.id == selectedOptionId) {
          option = candidate;
          break;
        }
      }
    }

    var isCorrect =
        isCorrectOverride ??
        (task.acceptAnyOption
            ? option != null
            : selectedOptionId == task.correctOptionId);
    final rawRequestedSpend = task.spendCoins + (option?.spendCoins ?? 0);
    final isRealExpense =
        task.economyType == TaskEconomyType.realExpense ||
        (task.templateId == 'legacy' && rawRequestedSpend > 0);
    final requestedSpend = isRealExpense ? rawRequestedSpend : 0;
    final requestedSavingsSpend =
        task.spendFromSavings + (option?.spendFromSavings ?? 0);
    final affordable =
        requestedSpend <= balance && requestedSavingsSpend <= savings;
    if (!affordable) isCorrect = false;

    final balanceBefore = balance;
    final savingsBefore = savings;
    final spentCoins = isCorrect && affordable ? requestedSpend : 0;
    final spentFromSavings = isCorrect && affordable
        ? requestedSavingsSpend
        : 0;
    final baseReward = option != null && option.rewardCoins > 0
        ? option.rewardCoins
        : task.rewardCoins;
    final rewardCoins = isCorrect ? baseReward : 0;
    final savingsReward = isCorrect
        ? task.savingsReward + (option?.savingsReward ?? 0)
        : 0;
    final baseXp = option != null && option.xpReward > 0
        ? option.xpReward
        : task.xpReward;
    final xpEarned = isCorrect ? baseXp : 0;

    balance = balance - spentCoins + rewardCoins;
    savings = savings - spentFromSavings + savingsReward;
    petXp += xpEarned;
    completedTasks += 1;
    sessionCompletedTasks += 1;
    sessionEarnedCoins += rewardCoins;
    sessionSpentCoins += spentCoins + spentFromSavings;
    sessionSavedCoins += savingsReward - spentFromSavings;
    sessionXp += xpEarned;
    final expenseCategory = option?.expenseCategory ?? task.expenseCategory;
    if (spentCoins > 0 && expenseCategory != null) {
      budgetUsage = budgetUsage.addExpense(spentCoins, expenseCategory);
      _recordPeriodExpense(spentCoins, expenseCategory, isMissionExpense: true);
    }
    _recordPeriodEarning(rewardCoins);
    _recordPeriodDeposit(savingsReward);
    _recordPeriodTask(task: task, isCorrect: isCorrect);

    var ledgerBalance = balanceBefore;
    var ledgerSavings = savingsBefore;
    final transactionBaseId =
        '${financialProfileId}_${activeGamePeriod?.id ?? 'no_period'}_${task.id}_$currentTaskIndex';
    if (spentCoins > 0) {
      final after = ledgerBalance - spentCoins;
      _recordFinancialTransaction(
        id: '${transactionBaseId}_expense_balance',
        type: _expenseTransactionType(expenseCategory ?? ExpenseCategory.want),
        source: FinancialTransactionSource.mission,
        title: option?.label ?? task.title,
        description: task.description,
        sourceId: task.id,
        amount: spentCoins,
        balanceBefore: ledgerBalance,
        balanceAfter: after,
        savingsBefore: ledgerSavings,
        savingsAfter: ledgerSavings,
      );
      ledgerBalance = after;
    }
    if (spentFromSavings > 0) {
      final after = ledgerSavings - spentFromSavings;
      _recordFinancialTransaction(
        id: '${transactionBaseId}_expense_savings',
        type: _expenseTransactionType(expenseCategory ?? ExpenseCategory.want),
        source: FinancialTransactionSource.mission,
        title: option?.label ?? task.title,
        description: 'Покупка из накоплений',
        sourceId: task.id,
        amount: spentFromSavings,
        balanceBefore: ledgerBalance,
        balanceAfter: ledgerBalance,
        savingsBefore: ledgerSavings,
        savingsAfter: after,
      );
      ledgerSavings = after;
    }
    if (rewardCoins > 0) {
      final after = ledgerBalance + rewardCoins;
      _recordFinancialTransaction(
        id: '${transactionBaseId}_reward',
        type: FinancialTransactionType.earning,
        source: FinancialTransactionSource.mission,
        title: 'Награда за задание',
        description: task.title,
        sourceId: task.id,
        amount: rewardCoins,
        balanceBefore: ledgerBalance,
        balanceAfter: after,
        savingsBefore: ledgerSavings,
        savingsAfter: ledgerSavings,
      );
      ledgerBalance = after;
    }
    if (savingsReward > 0) {
      final after = ledgerSavings + savingsReward;
      _recordFinancialTransaction(
        id: '${transactionBaseId}_savings_reward',
        type: FinancialTransactionType.earning,
        source: FinancialTransactionSource.mission,
        title: 'Награда в копилку',
        description: task.title,
        sourceId: task.id,
        amount: savingsReward,
        balanceBefore: ledgerBalance,
        balanceAfter: ledgerBalance,
        savingsBefore: ledgerSavings,
        savingsAfter: after,
      );
    }

    final explanation = !affordable
        ? 'Для этой покупки пока не хватает монет. Баланс не ушёл в минус.'
        : isCorrect
        ? option?.feedback ?? task.explanation
        : task.explanation;

    lastResult = MissionResult(
      taskId: task.id,
      isCorrect: isCorrect,
      explanation: explanation,
      balanceBefore: balanceBefore,
      balanceAfter: balance,
      savingsBefore: savingsBefore,
      savingsAfter: savings,
      rewardCoins: rewardCoins,
      spentCoins: spentCoins,
      spentFromSavings: spentFromSavings,
      savedCoins: savingsReward,
      xpEarned: xpEarned,
      correctAnswer: _correctAnswerFor(task),
    );
    _awaitingAdvance = true;
    _notifyAndPersist();
    return lastResult!;
  }

  String _correctAnswerFor(MissionTask task) {
    if (task.type == MissionTaskType.classification) {
      return task.options
          .map((option) => '${option.label} — ${option.category}')
          .join(', ');
    }
    if (task.type == MissionTaskType.budgetSplit) {
      return 'Распредели ровно ${task.totalAmount} монет.';
    }
    for (final option in task.options) {
      if (option.id == task.correctOptionId) {
        return option.subtitle == null
            ? option.label
            : '${option.label}: ${option.subtitle}';
      }
    }
    return task.explanation;
  }

  MissionNextStep advanceAfterResult() {
    final mission = activeMission;
    if (mission == null || !_awaitingAdvance) {
      throw StateError('A completed task is required before advancing.');
    }

    _awaitingAdvance = false;
    lastResult = null;
    currentTaskIndex += 1;

    if (currentTaskIndex >= mission.tasks.length) {
      completedMissions += 1;
      _completeCurrentPeriod(now: DateTime.now());
      _notifyAndPersist();
      return MissionNextStep.complete;
    }

    final showCheckpoint = sessionCompletedTasks % 4 == 0;
    _notifyAndPersist();
    return showCheckpoint ? MissionNextStep.checkpoint : MissionNextStep.task;
  }

  void finishMission() {
    _completeCurrentPeriod(now: DateTime.now());
    _rememberCompletedMission();
    activeMission = null;
    currentTaskIndex = 0;
    lastResult = null;
    _awaitingAdvance = false;
    _notifyAndPersist();
  }

  GamePeriod? completeCurrentPeriod({DateTime? now}) {
    final wasAlreadyCompleted =
        activeGamePeriod?.status == GamePeriodStatus.completed;
    final completed = _completeCurrentPeriod(now: now ?? DateTime.now());
    if (completed != null && !wasAlreadyCompleted) _notifyAndPersist();
    return completed;
  }

  Future<bool> startNextDemoPeriod({DateTime? now}) async {
    if (!isDemoMode || !isCurrentPeriodCompleted) return false;
    if (demoPeriodIndex >= DemoPeriodDefinitions.count) return false;

    _rememberCompletedMission();
    _clearMissionRuntime();
    activeGamePeriod = null;
    demoPeriodIndex += 1;
    missionForToday(now: now ?? DateTime.now());
    _notifyAndPersist();
    await flushPersistence();
    return true;
  }

  AppStateSnapshot toSnapshot() {
    return AppStateSnapshot(
      childProfile: childProfile,
      difficultyLevel: difficultyLevel,
      balance: balance,
      savings: savings,
      selectedGoalId: selectedGoalId,
      budgetPlan: budgetPlan,
      budgetUsage: budgetUsage,
      budgetPlanConfirmed: budgetPlanConfirmed,
      petState: petState,
      petXp: petXp,
      petGrowthPoints: petGrowthPoints,
      petLevel: petLevel,
      completedTasks: completedTasks,
      completedMissions: completedMissions,
      achievedGoals: achievedGoals,
      completedGoalIds: completedGoalIds.toList(growable: false),
      daysTogether: daysTogether,
      streak: streak,
      soundEnabled: soundEnabled,
      hintsEnabled: hintsEnabled,
      petAppearance: petAppearance,
      cachedDailyMission: _cachedDailyMission,
      cachedDailyMissionKey: _cachedDailyMissionKey,
      activeMission: activeMission,
      currentTaskIndex: currentTaskIndex,
      lastResult: lastResult,
      lastLocationIds: List<String>.unmodifiable(lastLocationIds),
      lastTaskTemplateIds: List<String>.unmodifiable(lastTaskTemplateIds),
      sessionEarnedCoins: sessionEarnedCoins,
      sessionSpentCoins: sessionSpentCoins,
      sessionSavedCoins: sessionSavedCoins,
      sessionXp: sessionXp,
      sessionCompletedTasks: sessionCompletedTasks,
      awaitingAdvance: _awaitingAdvance,
      lastHungerCheckAt: _lastHungerCheckAt,
      runMode: runMode,
      activeGamePeriod: activeGamePeriod,
      completedGamePeriods: List<GamePeriod>.unmodifiable(completedGamePeriods),
      demoPeriodIndex: demoPeriodIndex,
    );
  }

  void _restore(AppStateSnapshot snapshot) {
    childProfile = snapshot.childProfile;
    difficultyLevel = snapshot.difficultyLevel;
    balance = snapshot.balance.clamp(0, 1 << 31).toInt();
    savings = snapshot.savings.clamp(0, 1 << 31).toInt();
    selectedGoalId = goals.any((goal) => goal.id == snapshot.selectedGoalId)
        ? snapshot.selectedGoalId
        : goals.first.id;
    budgetPlan = snapshot.budgetPlan;
    budgetUsage = snapshot.budgetUsage;
    budgetPlanConfirmed = snapshot.budgetPlanConfirmed;
    petState = snapshot.petState;
    petXp = snapshot.petXp.clamp(0, 1 << 31).toInt();
    petGrowthPoints = snapshot.petGrowthPoints.clamp(0, 1 << 31).toInt();
    petLevel = snapshot.petLevel.clamp(1, 1 << 16).toInt();
    completedTasks = snapshot.completedTasks.clamp(0, 1 << 31).toInt();
    completedMissions = snapshot.completedMissions.clamp(0, 1 << 31).toInt();
    achievedGoals = snapshot.achievedGoals.clamp(0, 1 << 31).toInt();
    completedGoalIds
      ..clear()
      ..addAll(
        snapshot.completedGoalIds.where(
          (id) => goals.any((goal) => goal.id == id),
        ),
      );
    daysTogether = snapshot.daysTogether.clamp(0, 1 << 31).toInt();
    streak = snapshot.streak.clamp(0, 1 << 31).toInt();
    soundEnabled = snapshot.soundEnabled;
    hintsEnabled = snapshot.hintsEnabled;
    petAppearance = snapshot.petAppearance;
    _cachedDailyMission = snapshot.cachedDailyMission;
    _cachedDailyMissionKey = snapshot.cachedDailyMissionKey;
    activeMission = snapshot.activeMission;
    final taskCount = activeMission?.tasks.length ?? 0;
    currentTaskIndex = snapshot.currentTaskIndex.clamp(0, taskCount).toInt();
    lastResult = snapshot.lastResult;
    lastLocationIds
      ..clear()
      ..addAll(snapshot.lastLocationIds);
    lastTaskTemplateIds
      ..clear()
      ..addAll(snapshot.lastTaskTemplateIds);
    sessionEarnedCoins = snapshot.sessionEarnedCoins;
    sessionSpentCoins = snapshot.sessionSpentCoins;
    sessionSavedCoins = snapshot.sessionSavedCoins;
    sessionXp = snapshot.sessionXp;
    sessionCompletedTasks = snapshot.sessionCompletedTasks
        .clamp(0, taskCount)
        .toInt();
    _awaitingAdvance =
        snapshot.awaitingAdvance && lastResult != null && activeMission != null;
    _lastHungerCheckAt = snapshot.lastHungerCheckAt;
    runMode = snapshot.runMode;
    activeGamePeriod = snapshot.activeGamePeriod;
    completedGamePeriods
      ..clear()
      ..addAll(snapshot.completedGamePeriods);
    demoPeriodIndex = snapshot.demoPeriodIndex
        .clamp(1, DemoPeriodDefinitions.count)
        .toInt();
  }

  void _notifyAndPersist() {
    notifyListeners();
    _persist();
  }

  void _persist() {
    final repository = _repository;
    if (!_persistenceEnabled || repository == null) return;
    final snapshot = toSnapshot();
    // A ledger entry is queued before this method is reached. Waiting for that
    // queue keeps the append-only history durable before the matching profile
    // snapshot is persisted.
    unawaited(
      _financialTransactions.flush().then((_) => repository.save(snapshot)),
    );
  }

  Future<void> flushPersistence() async {
    await _financialTransactions.flush();
    await _repository?.flush();
  }

  Future<List<FinancialTransaction>> recentFinancialTransactions({
    int limit = 100,
    FinancialTransactionType? type,
  }) {
    return _financialTransactions.getRecent(
      profileId: financialProfileId,
      limit: limit,
      type: type,
    );
  }

  Future<List<FinancialTransaction>> financialTransactionsForPeriod(
    String gamePeriodId,
  ) {
    return _financialTransactions.getForPeriod(
      gamePeriodId,
      profileId: financialProfileId,
    );
  }

  Future<List<FinancialTransaction>> financialTransactionsForProfile(
    AppRunMode mode, {
    int limit = 100,
    FinancialTransactionType? type,
  }) {
    return _financialTransactions.getForProfile(
      mode.name,
      limit: limit,
      type: type,
    );
  }

  void _recordFinancialTransaction({
    String? id,
    required FinancialTransactionType type,
    required FinancialTransactionSource source,
    required String title,
    required int amount,
    required int balanceBefore,
    required int balanceAfter,
    required int savingsBefore,
    required int savingsAfter,
    String? description,
    String? sourceId,
    DateTime? createdAt,
  }) {
    if (amount <= 0) return;
    final timestamp = createdAt ?? DateTime.now();
    final transaction = FinancialTransaction(
      id:
          id ??
          '${financialProfileId}_${timestamp.microsecondsSinceEpoch}_${_transactionSequence++}',
      profileId: financialProfileId,
      gamePeriodId: activeGamePeriod?.id,
      createdAt: timestamp,
      type: type,
      source: source,
      title: title,
      description: description,
      sourceId: sourceId,
      amount: amount,
      balanceBefore: balanceBefore,
      balanceAfter: balanceAfter,
      savingsBefore: savingsBefore,
      savingsAfter: savingsAfter,
    );
    unawaited(_financialTransactions.add(transaction));
  }

  FinancialTransactionType _expenseTransactionType(ExpenseCategory category) =>
      switch (category) {
        ExpenseCategory.essential => FinancialTransactionType.essentialExpense,
        ExpenseCategory.want => FinancialTransactionType.wantExpense,
      };

  String _defaultExpenseTitle(ExpenseCategory category) => switch (category) {
    ExpenseCategory.essential => 'Покупка на важное',
    ExpenseCategory.want => 'Покупка на приятное',
  };

  String _foodTransactionTitle(FoodType type) => switch (type) {
    FoodType.basic => 'Корм для Рыжика',
    FoodType.healthy => 'Полезный перекус',
    FoodType.treat => 'Вкусняшка для Рыжика',
  };

  String _goalDisplayName(SavingsGoal goal) {
    const prefix = 'Накопить на ';
    final title = goal.title;
    if (!title.startsWith(prefix)) return title;
    final value = title.substring(prefix.length);
    return value.isEmpty
        ? title
        : '${value[0].toUpperCase()}${value.substring(1)}';
  }

  void _resetProfileFields({
    required AppRunMode mode,
    required DateTime resetAt,
  }) {
    runMode = mode;
    childProfile = ChildProfile(
      name: 'Миша',
      age: mode == AppRunMode.demo ? 9 : 8,
    );
    difficultyLevel = mode == AppRunMode.demo
        ? DifficultyLevel.middle
        : DifficultyLevel.junior;
    balance = 1250;
    savings = 2400;
    selectedGoalId = 'bicycle';
    budgetPlan = const BudgetPlan(
      essentialsPlanned: 500,
      wantsPlanned: 350,
      savingsPlanned: 400,
    );
    budgetPlanConfirmed = false;
    budgetUsage = const BudgetUsage();
    petState = PetState(mood: 75, satiety: 65, care: 70, lastFedAt: resetAt);
    _lastHungerCheckAt = resetAt;
    soundEnabled = true;
    hintsEnabled = true;
    petAppearance = const PetAppearance();
    streak = 4;
    petLevel = 5;
    petXp = 680;
    petGrowthPoints = mode == AppRunMode.demo ? 18 : 0;
    completedTasks = 18;
    completedMissions = 0;
    achievedGoals = 2;
    completedGoalIds.clear();
    daysTogether = 12;
    activeMission = null;
    _cachedDailyMission = null;
    _cachedDailyMissionKey = null;
    lastLocationIds.clear();
    lastTaskTemplateIds.clear();
    currentTaskIndex = 0;
    lastResult = null;
    sessionEarnedCoins = 0;
    sessionSpentCoins = 0;
    sessionSavedCoins = 0;
    sessionXp = 0;
    sessionCompletedTasks = 0;
    _awaitingAdvance = false;
    activeGamePeriod = null;
    completedGamePeriods.clear();
    demoPeriodIndex = 1;
  }

  GamePeriod _createGamePeriod(
    DailyMission mission, {
    required DateTime startedAt,
    required bool resetPeriodBudget,
  }) {
    final progress = goalProgress;
    if (resetPeriodBudget) {
      budgetUsage = const BudgetUsage();
      budgetPlanConfirmed = false;
    }
    final sequence = isDemoMode
        ? demoPeriodIndex
        : completedGamePeriods.where((period) => !period.isDemoPeriod).length +
              1;
    return GamePeriod(
      id: isDemoMode
          ? 'demo_period_$demoPeriodIndex'
          : 'normal_${mission.date.year}_${mission.date.month}_${mission.date.day}',
      sequenceNumber: sequence,
      startedAt: startedAt,
      completedAt: null,
      status: GamePeriodStatus.active,
      startingBalance: balance,
      startingSavings: savings,
      selectedGoalIdAtStart: selectedGoalId,
      goalProgressAtStart: progress,
      budgetPlanSnapshot: budgetPlan,
      budgetWasConfirmed: false,
      earnedCoins: 0,
      essentialSpent: 0,
      wantSpent: 0,
      depositedToSavings: 0,
      completedTaskCount: 0,
      correctTaskCount: 0,
      missionId: mission.id,
      locationId: mission.locationId,
      themeId: mission.theme.name,
      endingBalance: balance,
      endingSavings: savings,
      goalProgressAtEnd: progress,
      petStateAtStart: PetStateSnapshot.fromPetState(petState),
      petStateAtEnd: PetStateSnapshot.fromPetState(petState),
      isDemoPeriod: isDemoMode,
      missionTaskCount: mission.tasks.length,
      petGrowthPointsAtStart: petGrowthPoints,
      petGrowthPointsAtEnd: petGrowthPoints,
      petStageAtStart: petGrowthStage,
      petStageAtEnd: petGrowthStage,
      trainedThemeIds: mission.tasks
          .map((task) => task.taskTheme.name)
          .toSet()
          .toList(growable: false),
    );
  }

  void _recordPeriodEarning(int amount) {
    final period = activeGamePeriod;
    if (period == null ||
        period.status != GamePeriodStatus.active ||
        amount <= 0) {
      return;
    }
    activeGamePeriod = period.copyWith(
      earnedCoins: period.earnedCoins + amount,
    );
  }

  void _recordPeriodExpense(
    int amount,
    ExpenseCategory category, {
    bool isMissionExpense = false,
  }) {
    final period = activeGamePeriod;
    if (period == null ||
        period.status != GamePeriodStatus.active ||
        amount <= 0) {
      return;
    }
    activeGamePeriod = switch (category) {
      ExpenseCategory.essential => period.copyWith(
        essentialSpent: period.essentialSpent + amount,
        missionEssentialSpent: isMissionExpense
            ? period.missionEssentialSpent + amount
            : period.missionEssentialSpent,
      ),
      ExpenseCategory.want => period.copyWith(
        wantSpent: period.wantSpent + amount,
        missionWantSpent: isMissionExpense
            ? period.missionWantSpent + amount
            : period.missionWantSpent,
      ),
    };
  }

  void _recordPeriodDeposit(int amount, {bool intentional = false}) {
    final period = activeGamePeriod;
    if (period == null ||
        period.status != GamePeriodStatus.active ||
        amount <= 0) {
      return;
    }
    activeGamePeriod = period.copyWith(
      depositedToSavings: period.depositedToSavings + amount,
      intentionalSavingsDeposited: intentional
          ? period.intentionalSavingsDeposited + amount
          : period.intentionalSavingsDeposited,
    );
  }

  void _recordPeriodTask({required MissionTask task, required bool isCorrect}) {
    final period = activeGamePeriod;
    if (period == null || period.status != GamePeriodStatus.active) return;
    activeGamePeriod = period.copyWith(
      completedTaskCount: period.completedTaskCount + 1,
      correctTaskCount: period.correctTaskCount + (isCorrect ? 1 : 0),
      financialTaskCount:
          period.financialTaskCount +
          (PetProgressionPolicy.isFinancialTask(task) ? 1 : 0),
      correctFinancialTaskCount:
          period.correctFinancialTaskCount +
          (PetProgressionPolicy.isFinancialTask(task) && isCorrect ? 1 : 0),
    );
  }

  GamePeriod? _completeCurrentPeriod({required DateTime now}) {
    final period = activeGamePeriod;
    if (period == null) return null;
    if (period.status == GamePeriodStatus.completed) return period;
    final periodSnapshot = period.copyWith(
      completedAt: now,
      status: GamePeriodStatus.completed,
      budgetWasConfirmed: budgetPlanConfirmed,
      budgetPlanSnapshot: budgetPlan,
      essentialSpent: budgetUsage.essentialsSpent,
      wantSpent: budgetUsage.wantsSpent,
      completedTaskCount: sessionCompletedTasks,
      endingBalance: balance,
      endingSavings: savings,
      goalProgressAtEnd: goalProgress,
      petStateAtEnd: PetStateSnapshot.fromPetState(petState),
    );
    final evaluation = PetProgressionPolicy.evaluate(periodSnapshot);
    final oldGrowthPoints = petGrowthPoints;
    final newGrowthPoints = oldGrowthPoints + evaluation.totalPoints;
    petGrowthPoints = newGrowthPoints;
    final completed = periodSnapshot.copyWith(
      growthPointsAwarded: evaluation.totalPoints,
      growthEvaluation: evaluation,
      petGrowthPointsAtEnd: newGrowthPoints,
      petStageAtEnd: PetProgressionConfig.stageForPoints(newGrowthPoints),
      growthEvaluated: true,
    );
    activeGamePeriod = completed;
    completedGamePeriods
      ..removeWhere((candidate) => candidate.id == completed.id)
      ..add(completed);
    return completed;
  }

  void _rememberCompletedMission() {
    final completedMission = activeMission;
    if (completedMission == null) return;
    lastLocationIds
      ..remove(completedMission.locationId)
      ..insert(0, completedMission.locationId);
    if (lastLocationIds.length > 7) {
      lastLocationIds.removeRange(7, lastLocationIds.length);
    }
    for (final task in completedMission.tasks.reversed) {
      lastTaskTemplateIds
        ..remove(task.templateId)
        ..insert(0, task.templateId);
    }
    if (lastTaskTemplateIds.length > 24) {
      lastTaskTemplateIds.removeRange(24, lastTaskTemplateIds.length);
    }
  }

  void _clearMissionRuntime() {
    activeMission = null;
    _cachedDailyMission = null;
    _cachedDailyMissionKey = null;
    currentTaskIndex = 0;
    lastResult = null;
    sessionEarnedCoins = 0;
    sessionSpentCoins = 0;
    sessionSavedCoins = 0;
    sessionXp = 0;
    sessionCompletedTasks = 0;
    _awaitingAdvance = false;
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String? _normalizedChildName(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty ||
        normalized.length > ChildProfile.maximumNameLength) {
      return null;
    }
    return normalized;
  }

  bool _isSupportedChildAge(int value) {
    return value >= ChildProfile.minimumAge && value <= ChildProfile.maximumAge;
  }

  DifficultyLevel _difficultyForAge(int value) => switch (value) {
    <= 8 => DifficultyLevel.junior,
    <= 10 => DifficultyLevel.middle,
    _ => DifficultyLevel.senior,
  };
}
