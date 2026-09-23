import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/storage/app_database.dart';
import '../domain/financial_transaction.dart';

abstract interface class FinancialTransactionStore {
  Future<void> add(FinancialTransaction transaction);

  Future<List<FinancialTransaction>> getRecent({
    required String profileId,
    int limit = 100,
    FinancialTransactionType? type,
  });

  Future<List<FinancialTransaction>> getForPeriod(
    String gamePeriodId, {
    required String profileId,
  });

  Future<List<FinancialTransaction>> getForProfile(
    String profileId, {
    int limit = 100,
    FinancialTransactionType? type,
  });

  Future<void> clearForProfile(String profileId);

  Future<void> flush();
}

class FinancialTransactionRepository implements FinancialTransactionStore {
  FinancialTransactionRepository(this._appDatabase);

  final AppDatabase _appDatabase;
  Future<void> _writeQueue = Future<void>.value();

  @override
  Future<void> add(FinancialTransaction transaction) {
    return _enqueueWrite(() async {
      final database = await _appDatabase.database;
      await database.insert(
        AppDatabase.tableFinancialTransactions,
        transaction.toDatabaseMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    });
  }

  @override
  Future<List<FinancialTransaction>> getRecent({
    required String profileId,
    int limit = 100,
    FinancialTransactionType? type,
  }) => getForProfile(profileId, limit: limit, type: type);

  @override
  Future<List<FinancialTransaction>> getForPeriod(
    String gamePeriodId, {
    required String profileId,
  }) async {
    await flush();
    final database = await _appDatabase.database;
    final rows = await database.query(
      AppDatabase.tableFinancialTransactions,
      where: 'profile_id = ? AND game_period_id = ?',
      whereArgs: [profileId, gamePeriodId],
      orderBy: 'created_at ASC, id ASC',
    );
    return rows.map(FinancialTransaction.fromDatabaseMap).toList();
  }

  @override
  Future<List<FinancialTransaction>> getForProfile(
    String profileId, {
    int limit = 100,
    FinancialTransactionType? type,
  }) async {
    await flush();
    final database = await _appDatabase.database;
    final rows = await database.query(
      AppDatabase.tableFinancialTransactions,
      where: type == null ? 'profile_id = ?' : 'profile_id = ? AND type = ?',
      whereArgs: type == null ? [profileId] : [profileId, type.name],
      orderBy: 'created_at DESC, id DESC',
      limit: limit.clamp(1, 1000),
    );
    return rows.map(FinancialTransaction.fromDatabaseMap).toList();
  }

  @override
  Future<void> clearForProfile(String profileId) {
    return _enqueueWrite(() async {
      final database = await _appDatabase.database;
      await database.delete(
        AppDatabase.tableFinancialTransactions,
        where: 'profile_id = ?',
        whereArgs: [profileId],
      );
    });
  }

  @override
  Future<void> flush() => _writeQueue;

  Future<void> _enqueueWrite(Future<void> Function() action) {
    final operation = _writeQueue.then((_) => action());
    _writeQueue = operation.catchError((Object error, StackTrace stackTrace) {
      debugPrint('Unable to persist financial transaction: $error');
      debugPrintStack(stackTrace: stackTrace);
    });
    return _writeQueue;
  }
}

class InMemoryFinancialTransactionRepository
    implements FinancialTransactionStore {
  final List<FinancialTransaction> _transactions = [];

  @override
  Future<void> add(FinancialTransaction transaction) async {
    if (_transactions.any((candidate) => candidate.id == transaction.id)) {
      return;
    }
    _transactions.add(transaction);
  }

  @override
  Future<List<FinancialTransaction>> getRecent({
    required String profileId,
    int limit = 100,
    FinancialTransactionType? type,
  }) => getForProfile(profileId, limit: limit, type: type);

  @override
  Future<List<FinancialTransaction>> getForPeriod(
    String gamePeriodId, {
    required String profileId,
  }) async {
    final result =
        _transactions
            .where(
              (transaction) =>
                  transaction.profileId == profileId &&
                  transaction.gamePeriodId == gamePeriodId,
            )
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List.unmodifiable(result);
  }

  @override
  Future<List<FinancialTransaction>> getForProfile(
    String profileId, {
    int limit = 100,
    FinancialTransactionType? type,
  }) async {
    final result =
        _transactions
            .where(
              (transaction) =>
                  transaction.profileId == profileId &&
                  (type == null || transaction.type == type),
            )
            .toList()
          ..sort((a, b) {
            final byDate = b.createdAt.compareTo(a.createdAt);
            return byDate != 0 ? byDate : b.id.compareTo(a.id);
          });
    return List.unmodifiable(result.take(limit.clamp(1, 1000)));
  }

  @override
  Future<void> clearForProfile(String profileId) async {
    _transactions.removeWhere(
      (transaction) => transaction.profileId == profileId,
    );
  }

  @override
  Future<void> flush() async {}
}
