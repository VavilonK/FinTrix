import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase({DatabaseFactory? factory, String? databasePath})
    : _databaseFactory = factory ?? databaseFactory,
      _databasePath = databasePath; // ignore: prefer_initializing_formals

  static const int version = 6;
  static const String tableAppState = 'app_state';
  static const String tableAppMetadata = 'app_metadata';
  static const String tableFinancialTransactions = 'financial_transactions';
  static const int singletonStateId = 1;
  static const int normalProfileId = 1;
  static const int demoProfileId = 2;

  final DatabaseFactory _databaseFactory;
  final String? _databasePath;
  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;

    final resolvedPath =
        _databasePath ??
        path.join(await getDatabasesPath(), 'finance_pet_state.db');
    final opened = await _databaseFactory.openDatabase(
      resolvedPath,
      options: OpenDatabaseOptions(
        version: version,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
    _database = opened;
    return opened;
  }

  Future<void> _onCreate(Database database, int version) async {
    await database.execute('''
      CREATE TABLE $tableAppState (
        id INTEGER PRIMARY KEY,
        schema_version INTEGER NOT NULL,
        payload_json TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await _createMetadataTable(database);
    await _createFinancialTransactionsTable(database);
  }

  Future<void> _onUpgrade(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion > newVersion) {
      throw StateError(
        'Database downgrade is not supported: $oldVersion -> $newVersion',
      );
    }
    if (oldVersion < 2) {
      await _createMetadataTable(database);
    }
    if (oldVersion < 6) {
      await _createFinancialTransactionsTable(database);
    }
    // Versions 3–5 extend versioned JSON/metadata. Version 6 adds the
    // append-only financial ledger without touching stored profile snapshots.
  }

  Future<void> _createMetadataTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS $tableAppMetadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createFinancialTransactionsTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS $tableFinancialTransactions (
        id TEXT PRIMARY KEY,
        profile_id TEXT NOT NULL,
        game_period_id TEXT,
        created_at TEXT NOT NULL,
        type TEXT NOT NULL,
        source TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        source_id TEXT,
        amount INTEGER NOT NULL CHECK (amount > 0),
        balance_before INTEGER NOT NULL CHECK (balance_before >= 0),
        balance_after INTEGER NOT NULL CHECK (balance_after >= 0),
        savings_before INTEGER NOT NULL CHECK (savings_before >= 0),
        savings_after INTEGER NOT NULL CHECK (savings_after >= 0)
      )
    ''');
    await database.execute('''
      CREATE INDEX IF NOT EXISTS idx_financial_transactions_profile_created
      ON $tableFinancialTransactions (profile_id, created_at DESC)
    ''');
    await database.execute('''
      CREATE INDEX IF NOT EXISTS idx_financial_transactions_period
      ON $tableFinancialTransactions (game_period_id, created_at ASC)
    ''');
  }

  Future<void> close() async {
    final database = _database;
    _database = null;
    await database?.close();
  }
}
