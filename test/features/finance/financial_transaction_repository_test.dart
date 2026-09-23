import 'dart:io';

import 'package:finance_pet/core/storage/app_database.dart';
import 'package:finance_pet/features/finance/data/financial_transaction_repository.dart';
import 'package:finance_pet/features/finance/domain/financial_transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('SQLite repository persists, filters, and isolates profiles', () async {
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final repository = FinancialTransactionRepository(database);
    await repository.add(_transaction(id: 'normal_1', profileId: 'normal'));
    await repository.add(
      _transaction(
        id: 'normal_2',
        profileId: 'normal',
        type: FinancialTransactionType.wantExpense,
      ),
    );
    await repository.add(_transaction(id: 'demo_1', profileId: 'demo'));

    expect(await repository.getForProfile('normal'), hasLength(2));
    expect(
      await repository.getForProfile(
        'normal',
        type: FinancialTransactionType.wantExpense,
      ),
      hasLength(1),
    );
    expect(
      await repository.getForPeriod('period_1', profileId: 'normal'),
      hasLength(2),
    );

    await repository.clearForProfile('demo');
    expect(await repository.getForProfile('demo'), isEmpty);
    expect(await repository.getForProfile('normal'), hasLength(2));
  });

  test('version 5 database migrates without deleting profile state', () async {
    final directory = await Directory.systemTemp.createTemp('finance_pet_v5_');
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}${Platform.pathSeparator}state.db';
    final legacy = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 5,
        onCreate: (database, _) async {
          await database.execute('''
            CREATE TABLE app_state (
              id INTEGER PRIMARY KEY,
              schema_version INTEGER NOT NULL,
              payload_json TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
          await database.execute('''
            CREATE TABLE app_metadata (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
          await database.insert('app_state', {
            'id': 1,
            'schema_version': 5,
            'payload_json': '{"kept":true}',
            'updated_at': DateTime(2026, 9, 23).toIso8601String(),
          });
        },
      ),
    );
    await legacy.close();

    final migrated = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: path,
    );
    addTearDown(migrated.close);
    final database = await migrated.database;
    expect(await database.query(AppDatabase.tableAppState), hasLength(1));
    final tables = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [AppDatabase.tableFinancialTransactions],
    );
    expect(tables, hasLength(1));
  });

  test('history is restored exactly after reopening the database', () async {
    final directory = await Directory.systemTemp.createTemp('finance_pet_tx_');
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}${Platform.pathSeparator}state.db';
    var database = AppDatabase(factory: databaseFactoryFfi, databasePath: path);
    var repository = FinancialTransactionRepository(database);
    await repository.add(_transaction(id: 'kept_1', profileId: 'normal'));
    await repository.flush();
    await database.close();

    database = AppDatabase(factory: databaseFactoryFfi, databasePath: path);
    repository = FinancialTransactionRepository(database);
    final restored = await repository.getForProfile('normal');

    expect(restored, hasLength(1));
    expect(restored.single.id, 'kept_1');
    expect(restored.single.amount, 10);
    await database.close();
  });
}

FinancialTransaction _transaction({
  required String id,
  required String profileId,
  FinancialTransactionType type = FinancialTransactionType.earning,
}) {
  return FinancialTransaction(
    id: id,
    profileId: profileId,
    gamePeriodId: 'period_1',
    createdAt: DateTime(2026, 9, 23, 10),
    type: type,
    source: FinancialTransactionSource.system,
    title: 'Операция',
    amount: 10,
    balanceBefore: type == FinancialTransactionType.earning ? 100 : 110,
    balanceAfter: type == FinancialTransactionType.earning ? 110 : 100,
    savingsBefore: 50,
    savingsAfter: 50,
  );
}
