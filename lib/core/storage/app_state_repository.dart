import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'app_database.dart';
import 'app_state_snapshot.dart';
import '../../features/periods/domain/game_period.dart';
import '../../features/profile/domain/profile_models.dart';

class AppStateLoadResult {
  const AppStateLoadResult._({
    required this.snapshot,
    required this.hasStoredData,
    required this.error,
  });

  const AppStateLoadResult.empty()
    : this._(snapshot: null, hasStoredData: false, error: null);

  const AppStateLoadResult.success(AppStateSnapshot snapshot)
    : this._(snapshot: snapshot, hasStoredData: true, error: null);

  const AppStateLoadResult.corrupted(Object error)
    : this._(snapshot: null, hasStoredData: true, error: error);

  final AppStateSnapshot? snapshot;
  final bool hasStoredData;
  final Object? error;

  bool get isCorrupted => hasStoredData && snapshot == null;
}

class AppStateRepository {
  AppStateRepository(this._appDatabase);

  final AppDatabase _appDatabase;
  Future<void> _writeQueue = Future<void>.value();

  Future<AppStateLoadResult> load() async {
    try {
      final mode = await loadActiveRunMode();
      return await loadProfile(mode);
    } catch (error, stackTrace) {
      _logLoadError(error, stackTrace);
      return AppStateLoadResult.corrupted(error);
    }
  }

  Future<AppRunMode> loadActiveRunMode() async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      AppDatabase.tableAppMetadata,
      columns: const ['value'],
      where: 'key = ?',
      whereArgs: const ['active_profile'],
      limit: 1,
    );
    if (rows.isEmpty) return AppRunMode.normal;
    final value = rows.single['value'];
    if (value is! String) {
      throw const FormatException('Active profile metadata is invalid.');
    }
    return AppRunMode.values.byName(value);
  }

  Future<ParentProfile> loadParentProfile() async {
    try {
      final database = await _appDatabase.database;
      final rows = await database.query(
        AppDatabase.tableAppMetadata,
        columns: const ['value'],
        where: 'key = ?',
        whereArgs: const ['parent_profile'],
        limit: 1,
      );
      if (rows.isEmpty) return const ParentProfile.initial();
      final payload = rows.single['value'];
      if (payload is! String) {
        throw const FormatException('Parent profile metadata is invalid.');
      }
      final decoded = jsonDecode(payload);
      if (decoded is! Map) {
        throw const FormatException('Parent profile is not a JSON object.');
      }
      return ParentProfile.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value as Object?)),
      );
    } catch (error, stackTrace) {
      _logLoadError(error, stackTrace);
      return const ParentProfile.initial();
    }
  }

  Future<void> saveParentProfile(ParentProfile profile) {
    return _enqueueWrite(() async {
      final database = await _appDatabase.database;
      await database.insert(AppDatabase.tableAppMetadata, {
        'key': 'parent_profile',
        'value': jsonEncode(profile.toJson()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> deleteParentProfile() {
    return _enqueueWrite(() async {
      final database = await _appDatabase.database;
      await database.delete(
        AppDatabase.tableAppMetadata,
        where: 'key = ?',
        whereArgs: const ['parent_profile'],
      );
    });
  }

  Future<AppStateLoadResult> loadProfile(AppRunMode mode) async {
    try {
      final database = await _appDatabase.database;
      final rows = await database.query(
        AppDatabase.tableAppState,
        columns: const ['schema_version', 'payload_json'],
        where: 'id = ?',
        whereArgs: [_profileId(mode)],
        limit: 1,
      );
      if (rows.isEmpty) return const AppStateLoadResult.empty();

      final row = rows.single;
      final databaseSchemaVersion = row['schema_version'];
      if (databaseSchemaVersion is! int ||
          databaseSchemaVersion < 1 ||
          databaseSchemaVersion > AppStateSnapshot.schemaVersion) {
        throw FormatException(
          'Unsupported stored schema version: $databaseSchemaVersion',
        );
      }
      final payload = row['payload_json'];
      if (payload is! String) {
        throw const FormatException('Stored snapshot payload is not text.');
      }
      final decoded = jsonDecode(payload);
      if (decoded is! Map) {
        throw const FormatException('Stored snapshot is not a JSON object.');
      }
      final json = decoded.map(
        (key, value) => MapEntry(key.toString(), value as Object?),
      );
      return AppStateLoadResult.success(AppStateSnapshot.fromJson(json));
    } catch (error, stackTrace) {
      _logLoadError(error, stackTrace);
      return AppStateLoadResult.corrupted(error);
    }
  }

  Future<void> save(AppStateSnapshot snapshot) =>
      saveProfile(snapshot, makeActive: true);

  Future<void> saveProfile(
    AppStateSnapshot snapshot, {
    required bool makeActive,
  }) {
    return _enqueueWrite(() async {
      final database = await _appDatabase.database;
      await database.transaction((transaction) async {
        await _insertSnapshot(transaction, snapshot);
        if (makeActive) {
          await _writeActiveMode(transaction, snapshot.runMode);
        }
      });
    });
  }

  Future<void> replaceWith(AppStateSnapshot snapshot) {
    return _enqueueWrite(() async {
      final database = await _appDatabase.database;
      await database.transaction((transaction) async {
        await transaction.delete(
          AppDatabase.tableAppState,
          where: 'id = ?',
          whereArgs: [_profileId(snapshot.runMode)],
        );
        await _insertSnapshot(transaction, snapshot);
        await _writeActiveMode(transaction, snapshot.runMode);
      });
    });
  }

  Future<void> clear({AppRunMode mode = AppRunMode.normal}) {
    return deleteProfileData(mode);
  }

  Future<void> deleteProfileData(AppRunMode mode) {
    return _enqueueWrite(() async {
      final database = await _appDatabase.database;
      await database.delete(
        AppDatabase.tableAppState,
        where: 'id = ?',
        whereArgs: [_profileId(mode)],
      );
    });
  }

  Future<void> setActiveRunMode(AppRunMode mode) {
    return _enqueueWrite(() async {
      final database = await _appDatabase.database;
      await _writeActiveMode(database, mode);
    });
  }

  Future<void> flush() => _writeQueue;

  Future<void> _enqueueWrite(Future<void> Function() action) {
    final operation = _writeQueue.then((_) => action());
    _writeQueue = operation.catchError((Object error, StackTrace stackTrace) {
      debugPrint('Unable to persist app state: $error');
      debugPrintStack(stackTrace: stackTrace);
    });
    return _writeQueue;
  }

  int _profileId(AppRunMode mode) => switch (mode) {
    AppRunMode.normal => AppDatabase.normalProfileId,
    AppRunMode.demo => AppDatabase.demoProfileId,
  };

  Future<void> _insertSnapshot(
    DatabaseExecutor database,
    AppStateSnapshot snapshot,
  ) {
    return database.insert(AppDatabase.tableAppState, {
      'id': _profileId(snapshot.runMode),
      'schema_version': AppStateSnapshot.schemaVersion,
      'payload_json': jsonEncode(snapshot.toJson()),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _writeActiveMode(DatabaseExecutor database, AppRunMode mode) {
    return database.insert(AppDatabase.tableAppMetadata, {
      'key': 'active_profile',
      'value': mode.name,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  void _logLoadError(Object error, StackTrace stackTrace) {
    debugPrint('Unable to restore app state: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
