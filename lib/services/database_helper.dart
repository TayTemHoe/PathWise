// lib/services/database_helper.dart
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pathwise.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3, // INCREMENTED VERSION FOR NEW TABLE
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    debugPrint('📦 Creating SQLite database schema...');

    // Universities table
    await db.execute('''
      CREATE TABLE universities (
        university_id TEXT PRIMARY KEY,
        university_name TEXT NOT NULL,
        university_logo TEXT,
        university_url TEXT,
        uni_description TEXT,
        domestic_tuition_fee TEXT,
        international_tuition_fee TEXT,
        total_students INTEGER,
        international_students INTEGER,
        total_faculty_staff INTEGER,
        min_ranking INTEGER,
        max_ranking INTEGER,
        program_count INTEGER DEFAULT 0,
        updated_at INTEGER NOT NULL,
        is_deleted INTEGER DEFAULT 0,
        synced_at INTEGER NOT NULL
      )
    ''');

    // Branches table
    await db.execute('''
      CREATE TABLE branches (
        branch_id TEXT PRIMARY KEY,
        university_id TEXT NOT NULL,
        branch_name TEXT NOT NULL,
        country TEXT NOT NULL,
        city TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        is_deleted INTEGER DEFAULT 0,
        synced_at INTEGER NOT NULL,
        FOREIGN KEY (university_id) REFERENCES universities (university_id)
      )
    ''');

    // Programs table
    await db.execute('''
      CREATE TABLE programs (
        program_id TEXT PRIMARY KEY,
        branch_id TEXT NOT NULL,
        program_name TEXT NOT NULL,
        program_url TEXT,
        prog_description TEXT,
        duration_months TEXT,
        subject_area TEXT,
        study_level TEXT,
        study_mode TEXT,
        intake_period TEXT,
        min_domestic_tuition_fee TEXT,
        min_international_tuition_fee TEXT,
        entry_requirement TEXT,
        min_subject_ranking INTEGER,
        max_subject_ranking INTEGER,
        university_id TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        is_deleted INTEGER DEFAULT 0,
        synced_at INTEGER NOT NULL,
        FOREIGN KEY (branch_id) REFERENCES branches (branch_id),
        FOREIGN KEY (university_id) REFERENCES universities (university_id)
      )
    ''');

    // University admissions table
    await db.execute('''
      CREATE TABLE university_admissions (
        uni_admission_id TEXT PRIMARY KEY,
        university_id TEXT NOT NULL,
        admission_type TEXT,
        admission_label TEXT,
        admission_value TEXT,
        updated_at INTEGER NOT NULL,
        is_deleted INTEGER DEFAULT 0,
        synced_at INTEGER NOT NULL,
        FOREIGN KEY (university_id) REFERENCES universities (university_id)
      )
    ''');

    // Program admissions table
    await db.execute('''
      CREATE TABLE program_admissions (
        prog_admission_id TEXT PRIMARY KEY,
        program_id TEXT NOT NULL,
        prog_admission_label TEXT,
        prog_admission_value TEXT,
        updated_at INTEGER NOT NULL,
        is_deleted INTEGER DEFAULT 0,
        synced_at INTEGER NOT NULL,
        FOREIGN KEY (program_id) REFERENCES programs (program_id)
      )
    ''');

    // Sync metadata table
    await db.execute('''
      CREATE TABLE sync_metadata (
        table_name TEXT PRIMARY KEY,
        last_sync_timestamp INTEGER NOT NULL,
        total_records INTEGER DEFAULT 0,
        status TEXT DEFAULT 'idle'
      )
    ''');

    // ===== NEW: COMPARISON TABLE =====
    await db.execute('''
      CREATE TABLE comparisons (
        comparison_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        item_type TEXT NOT NULL CHECK(item_type IN ('program', 'university')),
        item_id TEXT NOT NULL,
        updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
        UNIQUE(user_id, item_type, item_id)
      )
    ''');

    // Create indexes for performance
    await _createIndexes(db);

    // Initialize sync metadata
    await _initializeSyncMetadata(db);

    debugPrint('✅ SQLite database schema created successfully');
  }

  Future<void> _createIndexes(Database db) async {
    debugPrint('🔒 Creating database indexes...');

    // Universities indexes
    await db.execute('CREATE INDEX idx_uni_ranking ON universities(min_ranking)');
    await db.execute('CREATE INDEX idx_uni_students ON universities(total_students)');
    await db.execute('CREATE INDEX idx_uni_name ON universities(university_name)');
    await db.execute('CREATE INDEX idx_uni_updated ON universities(updated_at)');

    // Branches indexes
    await db.execute('CREATE INDEX idx_branch_uni ON branches(university_id)');
    await db.execute('CREATE INDEX idx_branch_country ON branches(country)');
    await db.execute('CREATE INDEX idx_branch_city ON branches(city)');
    await db.execute('CREATE INDEX idx_branch_updated ON branches(updated_at)');

    // Programs indexes
    await db.execute('CREATE INDEX idx_prog_branch ON programs(branch_id)');
    await db.execute('CREATE INDEX idx_prog_uni ON programs(university_id)');
    await db.execute('CREATE INDEX idx_prog_subject ON programs(subject_area)');
    await db.execute('CREATE INDEX idx_prog_level ON programs(study_level)');
    await db.execute('CREATE INDEX idx_prog_mode ON programs(study_mode)');
    await db.execute('CREATE INDEX idx_prog_ranking ON programs(min_subject_ranking)');
    await db.execute('CREATE INDEX idx_prog_name ON programs(program_name)');
    await db.execute('CREATE INDEX idx_prog_updated ON programs(updated_at)');

    // Admissions indexes
    await db.execute('CREATE INDEX idx_uni_adm_uni ON university_admissions(university_id)');
    await db.execute('CREATE INDEX idx_prog_adm_prog ON program_admissions(program_id)');

    // ===== NEW: COMPARISON INDEXES =====
    await db.execute('CREATE INDEX idx_comp_user ON comparisons(user_id)');
    await db.execute('CREATE INDEX idx_comp_type ON comparisons(item_type)');
    await db.execute('CREATE INDEX idx_comp_user_type ON comparisons(user_id, item_type)');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_programs_tuition_domestic ON programs(min_domestic_tuition_fee)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_programs_tuition_international ON programs(min_international_tuition_fee)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_programs_branch_id ON programs(branch_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_branches_country ON branches(country)');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_universities_tuition_domestic ON universities(domestic_tuition_fee)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_universities_tuition_international ON universities(international_tuition_fee)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_branches_university_id ON branches(university_id)');

    debugPrint('✅ Database indexes created successfully');
  }

  Future<void> _initializeSyncMetadata(Database db) async {
    final tables = [
      'universities',
      'branches',
      'programs',
      'university_admissions',
      'program_admissions'
    ];

    for (var table in tables) {
      await db.insert('sync_metadata', {
        'table_name': table,
        'last_sync_timestamp': 0,
        'total_records': 0,
        'status': 'pending'
      });
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('🔄 Upgrading database from v$oldVersion to v$newVersion');

    if (oldVersion < 3) {
      // Add comparisons table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS comparisons (
          comparison_id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL,
          item_type TEXT NOT NULL CHECK(item_type IN ('program', 'university')),
          item_id TEXT NOT NULL,
          updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
          UNIQUE(user_id, item_type, item_id)
        )
      ''');

      await db.execute('CREATE INDEX idx_comp_user ON comparisons(user_id)');
      await db.execute('CREATE INDEX idx_comp_type ON comparisons(item_type)');
      await db.execute('CREATE INDEX idx_comp_user_type ON comparisons(user_id, item_type)');

      debugPrint('✅ Added comparisons table');
    }
  }

  // ==================== COMPARISON OPERATIONS ====================

  /// Add item to comparison
  Future<bool> addComparison({
    required String userId,
    required String itemType,
    required String itemId,
  }) async {
    try {
      final db = await database;

      await db.insert(
        'comparisons',
        {
          'user_id': userId,
          'item_type': itemType,
          'item_id': itemId,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      debugPrint('✅ Added $itemType: $itemId to comparison for user: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Error adding comparison: $e');
      return false;
    }
  }

  /// Remove item from comparison
  Future<bool> removeComparison({
    required String userId,
    required String itemId,
  }) async {
    try {
      final db = await database;

      final count = await db.delete(
        'comparisons',
        where: 'user_id = ? AND item_id = ?',
        whereArgs: [userId, itemId],
      );

      debugPrint('✅ Removed comparison for item: $itemId (affected: $count)');
      return count > 0;
    } catch (e) {
      debugPrint('❌ Error removing comparison: $e');
      return false;
    }
  }

  /// Remove all comparisons for a specific type
  Future<int> removeComparisonsByType({
    required String userId,
    required String itemType,
  }) async {
    try {
      final db = await database;

      final count = await db.delete(
        'comparisons',
        where: 'user_id = ? AND item_type = ?',
        whereArgs: [userId, itemType],
      );

      debugPrint('✅ Removed $count comparisons for type: $itemType');
      return count;
    } catch (e) {
      debugPrint('❌ Error removing comparisons by type: $e');
      return 0;
    }
  }

  /// Get all comparisons for a user
  Future<List<Map<String, dynamic>>> getComparisons({
    required String userId,
    String? itemType,
  }) async {
    try {
      final db = await database;

      String where = 'user_id = ?';
      List<dynamic> whereArgs = [userId];

      if (itemType != null) {
        where += ' AND item_type = ?';
        whereArgs.add(itemType);
      }

      final results = await db.query(
        'comparisons',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'updated_at DESC',
      );

      return results;
    } catch (e) {
      debugPrint('❌ Error getting comparisons: $e');
      return [];
    }
  }

  /// Get comparison count by type
  Future<int> getComparisonCount({
    required String userId,
    required String itemType,
  }) async {
    try {
      final db = await database;

      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM comparisons WHERE user_id = ? AND item_type = ?',
        [userId, itemType],
      );

      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting comparison count: $e');
      return 0;
    }
  }

  /// Check if item is in comparison
  Future<bool> isInComparison({
    required String userId,
    required String itemId,
  }) async {
    try {
      final db = await database;

      final result = await db.query(
        'comparisons',
        where: 'user_id = ? AND item_id = ?',
        whereArgs: [userId, itemId],
        limit: 1,
      );

      return result.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking comparison: $e');
      return false;
    }
  }

  /// Clear all comparisons for user
  Future<int> clearAllComparisons(String userId) async {
    try {
      final db = await database;

      final count = await db.delete(
        'comparisons',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      debugPrint('✅ Cleared $count comparisons for user: $userId');
      return count;
    } catch (e) {
      debugPrint('❌ Error clearing comparisons: $e');
      return 0;
    }
  }

  // ==================== SYNC OPERATIONS ====================

  /// Get last sync timestamp for a table
  Future<int> getLastSyncTimestamp(String tableName) async {
    final db = await database;
    final result = await db.query(
      'sync_metadata',
      columns: ['last_sync_timestamp'],
      where: 'table_name = ?',
      whereArgs: [tableName],
    );

    if (result.isEmpty) return 0;
    return result.first['last_sync_timestamp'] as int;
  }

  /// Update sync metadata
  Future<void> updateSyncMetadata(
      String tableName,
      int timestamp,
      int totalRecords,
      String status,
      ) async {
    final db = await database;
    await db.update(
      'sync_metadata',
      {
        'last_sync_timestamp': timestamp,
        'total_records': totalRecords,
        'status': status,
      },
      where: 'table_name = ?',
      whereArgs: [tableName],
    );
  }

  /// Get sync status for all tables
  Future<Map<String, dynamic>> getSyncStatus() async {
    final db = await database;
    final result = await db.query('sync_metadata');

    return {
      for (var row in result)
        row['table_name'] as String: {
          'last_sync': row['last_sync_timestamp'],
          'total_records': row['total_records'],
          'status': row['status'],
        }
    };
  }

  // ==================== BATCH OPERATIONS ====================

  /// Batch insert or update records
  Future<void> batchUpsert(
      String tableName,
      List<Map<String, dynamic>> records,
      ) async {
    if (records.isEmpty) return;

    final db = await database;
    const chunkSize = 100;

    for (int i = 0; i < records.length; i += chunkSize) {
      final chunk = records.skip(i).take(chunkSize).toList();

      await db.transaction((txn) async {
        final batch = txn.batch();

        for (var record in chunk) {
          batch.insert(
            tableName,
            record,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        await batch.commit(noResult: true);
      });

      if (i + chunkSize < records.length) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }

    debugPrint('✅ Batch upserted ${records.length} records to $tableName in chunks');
  }

  /// Batch delete records
  Future<void> batchDelete(
      String tableName,
      List<String> ids,
      String idColumn,
      ) async {
    if (ids.isEmpty) return;

    final db = await database;
    const chunkSize = 100;

    for (int i = 0; i < ids.length; i += chunkSize) {
      final chunk = ids.skip(i).take(chunkSize).toList();

      await db.transaction((txn) async {
        final batch = txn.batch();

        for (var id in chunk) {
          batch.update(
            tableName,
            {'is_deleted': 1},
            where: '$idColumn = ?',
            whereArgs: [id],
          );
        }

        await batch.commit(noResult: true);
      }).timeout(const Duration(seconds: 5));

      if (i + chunkSize < ids.length) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }

    debugPrint('✅ Batch deleted ${ids.length} records from $tableName');
  }

  // ==================== QUERY OPERATIONS ====================

  /// Execute raw query with parameters
  Future<List<Map<String, dynamic>>> rawQuery(
      String sql,
      List<dynamic>? arguments,
      ) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  /// Get record count - optimized
  Future<int> getRecordCount(String tableName, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    final whereClause = where != null ? 'WHERE $where' : '';
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName $whereClause',
      whereArgs,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Check if table is empty
  Future<bool> isTableEmpty(String tableName) async {
    final count = await getRecordCount(tableName, where: 'is_deleted = 0');
    return count == 0;
  }

  // ==================== MAINTENANCE ====================

  /// Clear all data from a table
  Future<void> clearTable(String tableName) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete(tableName);
    }).timeout(const Duration(seconds: 5));

    debugPrint('🧹 Cleared all data from $tableName');
  }

  /// Vacuum database to reclaim space
  Future<void> vacuum() async {
    final db = await database;
    await db.execute('VACUUM');
    debugPrint('🧹 Database vacuumed');
  }

  /// Get database size
  Future<int> getDatabaseSize() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pathwise.db');
    try {
      final file = await File(path).stat();
      return file.size;
    } catch (e) {
      return 0;
    }
  }

  /// Reset database (clear all data)
  Future<void> resetDatabase() async {
    final db = await database;
    final tables = [
      'universities',
      'branches',
      'programs',
      'university_admissions',
      'program_admissions',
      'comparisons', // Include comparisons
    ];

    for (var table in tables) {
      await db.transaction((txn) async {
        await txn.delete(table);

        // Don't update sync_metadata for comparisons
        if (table != 'comparisons') {
          await txn.update(
            'sync_metadata',
            {
              'last_sync_timestamp': 0,
              'total_records': 0,
              'status': 'pending'
            },
            where: 'table_name = ?',
            whereArgs: [table],
          );
        }
      }).timeout(const Duration(seconds: 5));

      await Future.delayed(const Duration(milliseconds: 10));
    }

    debugPrint('🧹 Database reset complete');
  }

  Future<void> batchUpsertWithProgress(
      String tableName,
      List<Map<String, dynamic>> records, {
        Function(int processed, int total)? onProgress,
      }) async {
    if (records.isEmpty) return;

    final db = await database;
    const chunkSize = 100;
    int processed = 0;

    for (int i = 0; i < records.length; i += chunkSize) {
      final chunk = records.skip(i).take(chunkSize).toList();

      await db.transaction((txn) async {
        final batch = txn.batch();

        for (var record in chunk) {
          batch.insert(
            tableName,
            record,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        await batch.commit(noResult: true);
      }).timeout(const Duration(seconds: 5));

      processed += chunk.length;
      onProgress?.call(processed, records.length);

      if (i + chunkSize < records.length) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }

    debugPrint('✅ Batch upserted $processed records to $tableName');
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    debugPrint('🔒 Database closed');
  }
}