class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.title,
    required this.price,
    this.assetPath,
  });

  final String id;
  final String title;
  final int price;
  final String? assetPath;
}

enum SavingsWithdrawalResult { success, invalidAmount, insufficientSavings }

enum GoalCompletionResult { success, insufficientSavings, alreadyCompleted }
