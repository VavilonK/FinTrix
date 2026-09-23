enum BudgetCategory { essentials, wants, savings }

class BudgetPlan {
  const BudgetPlan({
    required this.essentialsPlanned,
    required this.wantsPlanned,
    required this.savingsPlanned,
  });

  final int essentialsPlanned;
  final int wantsPlanned;
  final int savingsPlanned;

  int get totalAllocated => essentialsPlanned + wantsPlanned + savingsPlanned;

  int amountFor(BudgetCategory category) {
    return switch (category) {
      BudgetCategory.essentials => essentialsPlanned,
      BudgetCategory.wants => wantsPlanned,
      BudgetCategory.savings => savingsPlanned,
    };
  }

  BudgetPlan withAmount(BudgetCategory category, int amount) {
    return switch (category) {
      BudgetCategory.essentials => BudgetPlan(
        essentialsPlanned: amount,
        wantsPlanned: wantsPlanned,
        savingsPlanned: savingsPlanned,
      ),
      BudgetCategory.wants => BudgetPlan(
        essentialsPlanned: essentialsPlanned,
        wantsPlanned: amount,
        savingsPlanned: savingsPlanned,
      ),
      BudgetCategory.savings => BudgetPlan(
        essentialsPlanned: essentialsPlanned,
        wantsPlanned: wantsPlanned,
        savingsPlanned: amount,
      ),
    };
  }
}
