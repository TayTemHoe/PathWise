// lib/services/sync_service.dart
// HIGH PERFORMANCE VERSION

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'database_helper.dart';

class SyncService {
  static final SyncService instance = SyncService._init();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  // OPTIMIZATION: Larger batches for high-throughput sync
  static const int BATCH_SIZE = 1000; // Increased from 500
  static const int DB_CHUNK_SIZE = 1000; // Matched with DB Helper
  static const int MAX_RETRIES = 3;
  static const Duration RETRY_DELAY = Duration(seconds: 2);

  bool _isSyncing = false;
  double _syncProgress = 0.0;
  String _currentTable = '';

  SyncService._init();

  bool get isSyncing => _isSyncing;
  double get syncProgress => _syncProgress;
  String get currentTable => _currentTable;

  // ==================== OPTIMIZED SYNC OPERATIONS ====================

  /// Perform full sync with high-performance batching
  Future<void> fullSync({Function(String, double)? onProgress}) async {
    if (_isSyncing) {
      debugPrint('⏸️ Sync already in progress');
      return;
    }

    _isSyncing = true;
    _syncProgress = 0.0;

    try {
      debugPrint('🚀 Starting HIGH-PERFORMANCE sync from Supabase...');

      final tables = [
        ('universities', 'universities', _mapUniversityFromSupabase, 0.20),
        ('branches', 'branches', _mapBranchFromSupabase, 0.20),
        ('programs', 'programs', _mapProgramFromSupabase, 0.35),
        ('university_admissions', 'university_admissions', _mapUniversityAdmissionFromSupabase, 0.10),
        ('program_admissions', 'program_admissions', _mapProgramAdmissionFromSupabase, 0.15),
      ];

      double cumulativeProgress = 0.0;

      for (var i = 0; i < tables.length; i++) {
        final (localTable, supabaseTable, mapper, weight) = tables[i];

        await _syncTable(
          localTable,
          supabaseTable,
          mapper,
          onProgress: (table, progress) {
            final tableProgress = cumulativeProgress + (progress * weight);
            onProgress?.call(table, tableProgress);
          },
        );

        cumulativeProgress += weight;
      }

      debugPrint('✅ Full sync completed successfully');
    } catch (e) {
      debugPrint('❌ Full sync failed: $e');
      rethrow;
    } finally {
      _isSyncing = false;
      _syncProgress = 1.0;
      _currentTable = '';
    }
  }

  /// Sync table with zero-delay chunked operations
  Future<void> _syncTable(
      String localTable,
      String supabaseTable,
      Map<String, dynamic> Function(Map<String, dynamic>) mapper, {
        Function(String, double)? onProgress,
      }) async {
    _currentTable = localTable;
    debugPrint('📦 Syncing $localTable from Supabase...');

    try {
      final isTableEmpty = await _dbHelper.isTableEmpty(localTable);

      if (!isTableEmpty) {
        debugPrint('⏩ $localTable already synced, skipping full sync');
        return;
      }

      int totalRecords = 0;
      int processedRecords = 0;
      int offset = 0;
      bool hasMore = true;

      // Get count first
      final estimatedTotal = await _retryOperation(() async {
        return await _supabase
            .from(supabaseTable)
            .count(CountOption.exact);
      });

      debugPrint('  📊 Records to fetch: $estimatedTotal');

      while (hasMore) {
        try {
          // Fetch large batch
          final response = await _retryOperation(() async {
            return await _supabase
                .from(supabaseTable)
                .select()
                .order(_getIdColumn(localTable))
                .range(offset, offset + BATCH_SIZE - 1);
          });

          final List<dynamic> data = response as List<dynamic>;

          if (data.isEmpty) {
            hasMore = false;
            break;
          }

          // Map records efficiently
          final records = data.map((item) {
            return mapper(item as Map<String, dynamic>);
          }).toList();

          // Insert immediately
          await _insertRecordsInChunks(localTable, records);

          processedRecords += records.length;
          totalRecords = processedRecords;
          offset += BATCH_SIZE;

          // Calculate progress
          final progress = estimatedTotal > 0
              ? processedRecords / estimatedTotal
              : processedRecords / (processedRecords + BATCH_SIZE);

          onProgress?.call(localTable, progress);

          if (processedRecords % 5000 == 0) {
            debugPrint('  📥 Processed $processedRecords records...');
          }

          if (data.length < BATCH_SIZE) {
            hasMore = false;
          }

          // YIELD: Give UI a chance to frame, but don't wait 200ms
          await Future.delayed(Duration.zero);

        } catch (e) {
          debugPrint('⚠️ Error in batch at offset $offset: $e');
          // Retry current batch logic could be added here, but simple offset skip prevents infinite loops on bad data
          offset += BATCH_SIZE;
          if (offset > estimatedTotal + BATCH_SIZE) {
            hasMore = false;
          }
        }
      }

      await _dbHelper.updateSyncMetadata(
        localTable,
        DateTime.now().millisecondsSinceEpoch,
        totalRecords,
        'completed',
      );

      debugPrint('✅ $localTable sync complete: $totalRecords records');
    } catch (e) {
      debugPrint('❌ Error syncing $localTable: $e');
      await _dbHelper.updateSyncMetadata(
        localTable,
        DateTime.now().millisecondsSinceEpoch,
        0,
        'error',
      );
      rethrow;
    }
  }

  /// Insert records using DatabaseHelper's optimized batch transaction
  Future<void> _insertRecordsInChunks(
      String tableName,
      List<Map<String, dynamic>> records,
      ) async {
    if (records.isEmpty) return;

    // DatabaseHelper now handles 1000-record chunks automatically.
    // We just pass the whole batch to it.
    await _dbHelper.batchUpsert(tableName, records);
  }

  /// Incremental sync (Optimized)
  Future<void> incrementalSync({Function(String, double)? onProgress}) async {
    if (_isSyncing) return;

    _isSyncing = true;
    _syncProgress = 0.0;

    try {
      debugPrint('🔄 Starting fast incremental sync...');

      final tables = [
        ('universities', 'universities', _mapUniversityFromSupabase),
        ('branches', 'branches', _mapBranchFromSupabase),
        ('programs', 'programs', _mapProgramFromSupabase),
        ('university_admissions', 'university_admissions', _mapUniversityAdmissionFromSupabase),
        ('program_admissions', 'program_admissions', _mapProgramAdmissionFromSupabase),
      ];

      for (var i = 0; i < tables.length; i++) {
        final (localTable, supabaseTable, mapper) = tables[i];
        await _incrementalSyncTable(
          localTable,
          supabaseTable,
          mapper,
          onProgress: onProgress,
        );
        _syncProgress = (i + 1) / tables.length;
      }

      debugPrint('✅ Incremental sync completed');
    } catch (e) {
      debugPrint('❌ Incremental sync failed: $e');
      rethrow;
    } finally {
      _isSyncing = false;
      _syncProgress = 1.0;
      _currentTable = '';
    }
  }

  Future<void> _incrementalSyncTable(
      String localTable,
      String supabaseTable,
      Map<String, dynamic> Function(Map<String, dynamic>) mapper, {
        Function(String, double)? onProgress,
      }) async {
    _currentTable = localTable;

    try {
      final lastSync = await _dbHelper.getLastSyncTimestamp(localTable);
      final lastSyncDate = DateTime.fromMillisecondsSinceEpoch(lastSync);

      // Use 2000 batch size for incremental updates (likely fewer records)
      final response = await _retryOperation(() async {
        return await _supabase
            .from(supabaseTable)
            .select()
            .gt('updated_at', lastSyncDate.toIso8601String())
            .limit(2000);
      });

      final List<dynamic> data = response as List<dynamic>;

      if (data.isEmpty) return;

      debugPrint('  🔄 Updating ${data.length} records in $localTable...');

      final updates = <Map<String, dynamic>>[];
      final deletes = <String>[];

      for (var item in data) {
        final record = item as Map<String, dynamic>;
        final isDeleted = record['is_deleted'] == true || record['is_deleted'] == 1;

        if (isDeleted) {
          deletes.add(record[_getIdColumn(localTable)] as String);
        } else {
          updates.add(mapper(record));
        }
      }

      if (updates.isNotEmpty) {
        await _insertRecordsInChunks(localTable, updates);
      }

      if (deletes.isNotEmpty) {
        await _deleteRecordsInChunks(localTable, deletes);
      }

      await _dbHelper.updateSyncMetadata(
        localTable,
        DateTime.now().millisecondsSinceEpoch,
        await _dbHelper.getRecordCount(localTable, where: 'is_deleted = 0'),
        'completed',
      );

      onProgress?.call(localTable, 1.0);
    } catch (e) {
      debugPrint('❌ Error in incremental sync for $localTable: $e');
      // Don't rethrow incremental errors to keep app usable
    }
  }

  Future<void> _deleteRecordsInChunks(
      String tableName,
      List<String> ids,
      ) async {
    if (ids.isEmpty) return;
    await _dbHelper.batchDelete(tableName, ids, _getIdColumn(tableName));
  }

  Future<T> _retryOperation<T>(Future<T> Function() operation) async {
    int retryCount = 0;
    while (retryCount < MAX_RETRIES) {
      try {
        return await operation();
      } catch (e) {
        retryCount++;
        if (retryCount >= MAX_RETRIES) rethrow;
        await Future.delayed(RETRY_DELAY * retryCount);
      }
    }
    throw Exception('Max retries exceeded');
  }

  // ==================== STATIC MAPPERS (Optimized for performance) ====================
  // Made static to avoid instance overhead and allow potential isolation

  static Map<String, dynamic> _mapUniversityFromSupabase(Map<String, dynamic> data) {
    return {
      'university_id': data['university_id'] ?? '',
      'university_name': data['university_name'] ?? '',
      'university_logo': data['university_logo'],
      'university_url': data['university_url'],
      'uni_description': data['uni_description'],
      'domestic_tuition_fee': data['domestic_tuition_fee'],
      'international_tuition_fee': data['international_tuition_fee'],
      'total_students': data['total_students'],
      'international_students': data['international_students'],
      'total_faculty_staff': data['total_faculty_staff'],
      'min_ranking': data['min_ranking'],
      'max_ranking': data['max_ranking'],
      'program_count': data['program_count'] ?? 0,
      'updated_at': _parseTimestamp(data['updated_at']),
      'is_deleted': data['is_deleted'] == true ? 1 : 0,
      'synced_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Map<String, dynamic> _mapBranchFromSupabase(Map<String, dynamic> data) {
    return {
      'branch_id': data['branch_id'] ?? '',
      'university_id': data['university_id'] ?? '',
      'branch_name': data['branch_name'] ?? '',
      'country': data['country'] ?? '',
      'city': data['city'] ?? '',
      'updated_at': _parseTimestamp(data['updated_at']),
      'is_deleted': data['is_deleted'] == true ? 1 : 0,
      'synced_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Map<String, dynamic> _mapProgramFromSupabase(Map<String, dynamic> data) {
    String? intakePeriodJson;
    if (data['intake_period'] != null) {
      if (data['intake_period'] is List) {
        intakePeriodJson = jsonEncode(data['intake_period']);
      } else if (data['intake_period'] is String) {
        intakePeriodJson = data['intake_period'] as String;
      }
    }

    return {
      'program_id': data['program_id'] ?? '',
      'branch_id': data['branch_id'] ?? '',
      'program_name': data['program_name'] ?? '',
      'program_url': data['program_url'],
      'prog_description': data['prog_description'],
      'duration_months': data['duration_months']?.toString(),
      'subject_area': data['subject_area'],
      'study_level': data['study_level'],
      'study_mode': data['study_mode'],
      'intake_period': intakePeriodJson,
      'min_domestic_tuition_fee': data['min_domestic_tuition_fee'],
      'min_international_tuition_fee': data['min_international_tuition_fee'],
      'entry_requirement': data['entry_requirement'],
      'min_subject_ranking': data['min_subject_ranking'],
      'max_subject_ranking': data['max_subject_ranking'],
      'university_id': data['university_id'] ?? '',
      'updated_at': _parseTimestamp(data['updated_at']),
      'is_deleted': data['is_deleted'] == true ? 1 : 0,
      'synced_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Map<String, dynamic> _mapUniversityAdmissionFromSupabase(Map<String, dynamic> data) {
    return {
      'uni_admission_id': data['uni_admission_id'] ?? '',
      'university_id': data['university_id'] ?? '',
      'admission_type': data['admission_type'],
      'admission_label': data['admission_label'],
      'admission_value': data['admission_value'],
      'updated_at': _parseTimestamp(data['updated_at']),
      'is_deleted': data['is_deleted'] == true ? 1 : 0,
      'synced_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Map<String, dynamic> _mapProgramAdmissionFromSupabase(Map<String, dynamic> data) {
    return {
      'prog_admission_id': data['prog_admission_id'] ?? '',
      'program_id': data['program_id'] ?? '',
      'prog_admission_label': data['prog_admission_label'],
      'prog_admission_value': data['prog_admission_value'],
      'updated_at': _parseTimestamp(data['updated_at']),
      'is_deleted': data['is_deleted'] == true ? 1 : 0,
      'synced_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static int _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now().millisecondsSinceEpoch;
    if (value is String) {
      try {
        return DateTime.parse(value).millisecondsSinceEpoch;
      } catch (e) {
        return DateTime.now().millisecondsSinceEpoch;
      }
    }
    if (value is int) return value;
    return DateTime.now().millisecondsSinceEpoch;
  }

  String _getIdColumn(String tableName) {
    switch (tableName) {
      case 'universities': return 'university_id';
      case 'branches': return 'branch_id';
      case 'programs': return 'program_id';
      case 'university_admissions': return 'uni_admission_id';
      case 'program_admissions': return 'prog_admission_id';
      default: return 'id';
    }
  }

  Future<bool> needsInitialSync() async {
    final status = await _dbHelper.getSyncStatus();
    for (var tableStatus in status.values) {
      if (tableStatus['total_records'] == 0) return true;
    }
    return false;
  }

  Future<Map<String, dynamic>> getSyncStatistics() async {
    final status = await _dbHelper.getSyncStatus();
    final dbSize = await _dbHelper.getDatabaseSize();
    int totalRecords = 0;
    for (var tableStatus in status.values) {
      totalRecords += (tableStatus['total_records'] as int?) ?? 0;
    }
    return {
      'total_records': totalRecords,
      'database_size': dbSize,
      'tables': status,
      'is_syncing': _isSyncing,
      'sync_progress': _syncProgress,
      'current_table': _currentTable,
    };
  }
}