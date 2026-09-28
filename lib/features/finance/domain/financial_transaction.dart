enum FinancialTransactionType {
  earning,
  essentialExpense,
  wantExpense,
  savingsDeposit,
  savingsWithdrawal,
  goalPurchase,
}

enum FinancialTransactionSource {
  mission,
  petCare,
  miniGame,
  savings,
  system,
  parent,
}

class FinancialTransaction {
  FinancialTransaction({
    required this.id,
    required this.profileId,
    required this.createdAt,
    required this.type,
    required this.source,
    required this.title,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.savingsBefore,
    required this.savingsAfter,
    this.gamePeriodId,
    this.description,
    this.sourceId,
  }) {
    if (id.isEmpty || profileId.isEmpty || title.trim().isEmpty) {
      throw ArgumentError('Transaction identity and title must not be empty.');
    }
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'Must be positive.');
    }
    if ([
      balanceBefore,
      balanceAfter,
      savingsBefore,
      savingsAfter,
    ].any((value) => value < 0)) {
      throw ArgumentError('Financial snapshots must not be negative.');
    }
  }

  final String id;
  final String profileId;
  final String? gamePeriodId;
  final DateTime createdAt;
  final FinancialTransactionType type;
  final FinancialTransactionSource source;
  final String title;
  final String? description;
  final String? sourceId;
  final int amount;
  final int balanceBefore;
  final int balanceAfter;
  final int savingsBefore;
  final int savingsAfter;

  bool get isIncome => type == FinancialTransactionType.earning;

  Map<String, Object?> toDatabaseMap() => {
    'id': id,
    'profile_id': profileId,
    'game_period_id': gamePeriodId,
    'created_at': createdAt.toUtc().toIso8601String(),
    'type': type.name,
    'source': source.name,
    'title': title,
    'description': description,
    'source_id': sourceId,
    'amount': amount,
    'balance_before': balanceBefore,
    'balance_after': balanceAfter,
    'savings_before': savingsBefore,
    'savings_after': savingsAfter,
  };

  factory FinancialTransaction.fromDatabaseMap(Map<String, Object?> map) {
    return FinancialTransaction(
      id: map['id']! as String,
      profileId: map['profile_id']! as String,
      gamePeriodId: map['game_period_id'] as String?,
      createdAt: DateTime.parse(map['created_at']! as String).toLocal(),
      type: FinancialTransactionType.values.byName(map['type']! as String),
      source: FinancialTransactionSource.values.byName(
        map['source']! as String,
      ),
      title: map['title']! as String,
      description: map['description'] as String?,
      sourceId: map['source_id'] as String?,
      amount: map['amount']! as int,
      balanceBefore: map['balance_before']! as int,
      balanceAfter: map['balance_after']! as int,
      savingsBefore: map['savings_before']! as int,
      savingsAfter: map['savings_after']! as int,
    );
  }
}
