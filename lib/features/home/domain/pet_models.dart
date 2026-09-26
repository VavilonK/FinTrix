import '../../budget/domain/budget_usage.dart';

enum FoodType { basic, healthy, treat }

enum FeedPetResult { success, insufficientFunds, requiresConfirmation }

enum SpendCoinsResult { success, insufficientFunds, requiresConfirmation }

enum MiniGameResult { won, draw, lost, completed }

class PetState {
  const PetState({
    required this.mood,
    required this.satiety,
    required this.care,
    this.lastFedAt,
    this.lastPlayedAt,
    this.lastPettedAt,
  });

  final int mood;
  final int satiety;
  final int care;
  final DateTime? lastFedAt;
  final DateTime? lastPlayedAt;
  final DateTime? lastPettedAt;

  /// Satiety below this value makes Ryzhik hungry.
  static const int hungrySatietyThreshold = 30;

  bool get isHungry => satiety < hungrySatietyThreshold;

  PetState copyWith({
    int? mood,
    int? satiety,
    int? care,
    DateTime? lastFedAt,
    DateTime? lastPlayedAt,
    DateTime? lastPettedAt,
  }) {
    return PetState(
      mood: (mood ?? this.mood).clamp(0, 100),
      satiety: (satiety ?? this.satiety).clamp(0, 100),
      care: (care ?? this.care).clamp(0, 100),
      lastFedAt: lastFedAt ?? this.lastFedAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      lastPettedAt: lastPettedAt ?? this.lastPettedAt,
    );
  }
}

extension FoodTypeDetails on FoodType {
  int get cost => switch (this) {
    FoodType.basic => 20,
    FoodType.healthy => 35,
    FoodType.treat => 50,
  };

  int get satietyGain => switch (this) {
    FoodType.basic => 30,
    FoodType.healthy => 22,
    FoodType.treat => 15,
  };

  int get moodGain => switch (this) {
    FoodType.basic => 4,
    FoodType.healthy => 8,
    FoodType.treat => 15,
  };

  int get careGain => switch (this) {
    FoodType.basic => 0,
    FoodType.healthy => 3,
    FoodType.treat => 0,
  };

  ExpenseCategory get expenseCategory => switch (this) {
    FoodType.basic || FoodType.healthy => ExpenseCategory.essential,
    FoodType.treat => ExpenseCategory.want,
  };
}
