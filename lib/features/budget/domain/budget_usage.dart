enum ExpenseCategory { essential, want }

enum SavingsDepositResult { success, insufficientFunds, requiresConfirmation }

class BudgetUsage {
  const BudgetUsage({
    this.essentialsSpent = 0,
    this.wantsSpent = 0,
    this.savingsDeposited = 0,
  });

  final int essentialsSpent;
  final int wantsSpent;
  final int savingsDeposited;

  int get totalSpent => essentialsSpent + wantsSpent;

  int spentFor(ExpenseCategory category) {
    return switch (category) {
      ExpenseCategory.essential => essentialsSpent,
      ExpenseCategory.want => wantsSpent,
    };
  }

  BudgetUsage addExpense(int amount, ExpenseCategory category) {
    return switch (category) {
      ExpenseCategory.essential => BudgetUsage(
        essentialsSpent: essentialsSpent + amount,
        wantsSpent: wantsSpent,
        savingsDeposited: savingsDeposited,
      ),
      ExpenseCategory.want => BudgetUsage(
        essentialsSpent: essentialsSpent,
        wantsSpent: wantsSpent + amount,
        savingsDeposited: savingsDeposited,
      ),
    };
  }

  BudgetUsage addSavingsDeposit(int amount) {
    return BudgetUsage(
      essentialsSpent: essentialsSpent,
      wantsSpent: wantsSpent,
      savingsDeposited: savingsDeposited + amount,
    );
  }
}
