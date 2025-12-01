// lib/services/sync_service.dart
// OPTIMIZED VERSION WITH PROPER TRANSACTION HANDLING

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'database_helper.dart';

class SyncService {
  static final SyncService instance = SyncService._init();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  // OPTIMIZED: Reduced batch size to prevent long transactions
  static const int BATCH_SIZE = 500; // Reduced from 1000
  static const int DB_CHUNK_SIZE = 100; // New: Database insert chunk size
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

  /// Perform full sync with improved transaction handling
  Future<void> fullSync({Function(String, double)? onProgress}) async {
    if (_isSyncing) {
      debugPrint('⏸️ Sync already in progress');
      return;
    }

    _isSyncing = true;
    _syncProgress = 0.0;

    try {
      debugPrint('🔄 Starting full sync from Supabase...');

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

  /// OPTIMIZED: Sync table with chunked database operations
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

      final estimatedTotal = await _retryOperation(() async {
        return await _supabase
            .from(supabaseTable)
            .count(CountOption.exact);
      });

      debugPrint('  📊 Estimated records: $estimatedTotal');

      // FIX: Fetch in smaller batches and insert in even smaller chunks
      while (hasMore) {
        try {
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

          // Map records
          final records = data.map((item) {
            return mapper(item as Map<String, dynamic>);
          }).toList();

          // FIX: Insert in smaller chunks to avoid long transactions
          await _insertRecordsInChunks(localTable, records);

          processedRecords += records.length;
          totalRecords = processedRecords;
          offset += BATCH_SIZE;

          final progress = estimatedTotal > 0
              ? processedRecords / estimatedTotal
              : processedRecords / (processedRecords + BATCH_SIZE);

          onProgress?.call(localTable, progress);

          debugPrint('  📥 Synced $processedRecords records from $localTable');

          if (data.length < BATCH_SIZE) {
            hasMore = false;
          }

          // FIX: Longer delay between batches to prevent lock contention
          if (hasMore) {
            await Future.delayed(const Duration(milliseconds: 200));
          }

        } catch (e) {
          debugPrint('⚠️ Error in batch at offset $offset: $e');
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

  /// NEW: Insert records in smaller chunks to prevent long transactions
  Future<void> _insertRecordsInChunks(
      String tableName,
      List<Map<String, dynamic>> records,
      ) async {
    if (records.isEmpty) return;

    // Insert in chunks of DB_CHUNK_SIZE
    for (int i = 0; i < records.length; i += DB_CHUNK_SIZE) {
      final chunk = records.skip(i).take(DB_CHUNK_SIZE).toList();

      // Use the improved batchUpsert which handles transactions properly
      await _dbHelper.batchUpsert(tableName, chunk);

      // Brief pause between chunks
      if (i + DB_CHUNK_SIZE < records.length) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
  }

  /// OPTIMIZED: Incremental sync with chunked operations
  Future<void> incrementalSync({Function(String, double)? onProgress}) async {
    if (_isSyncing) {
      debugPrint('⏸️ Sync already in progress');
      return;
    }

    _isSyncing = true;
    _syncProgress = 0.0;

    try {
      debugPrint('🔄 Starting incremental sync from Supabase...');

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

      debugPrint('✅ Incremental sync completed successfully');
    } catch (e) {
      debugPrint('❌ Incremental sync failed: $e');
      rethrow;
    } finally {
      _isSyncing = false;
      _syncProgress = 1.0;
      _currentTable = '';
    }
  }

  /// OPTIMIZED: Incremental sync with chunked database operations
  Future<void> _incrementalSyncTable(
      String localTable,
      String supabaseTable,
      Map<String, dynamic> Function(Map<String, dynamic>) mapper, {
        Function(String, double)? onProgress,
      }) async {
    _currentTable = localTable;
    debugPrint('🔄 Incremental sync for $localTable...');

    try {
      final lastSync = await _dbHelper.getLastSyncTimestamp(localTable);
      final lastSyncDate = DateTime.fromMillisecondsSinceEpoch(lastSync);

      debugPrint('  📅 Last sync: $lastSyncDate');

      final response = await _retryOperation(() async {
        return await _supabase
            .from(supabaseTable)
            .select()
            .gt('updated_at', lastSyncDate.toIso8601String())
            .limit(BATCH_SIZE);
      });

      final List<dynamic> data = response as List<dynamic>;

      if (data.isEmpty) {
        debugPrint('  ✅ No updates for $localTable');
        return;
      }

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

      // FIX: Insert updates in chunks
      if (updates.isNotEmpty) {
        await _insertRecordsInChunks(localTable, updates);
        debugPrint('  ✅ Updated ${updates.length} records in $localTable');
      }

      // FIX: Process deletes in chunks
      if (deletes.isNotEmpty) {
        await _deleteRecordsInChunks(localTable, deletes);
        debugPrint('  ✅ Deleted ${deletes.length} records from $localTable');
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
      rethrow;
    }
  }

  /// NEW: Delete records in chunks
  Future<void> _deleteRecordsInChunks(
      String tableName,
      List<String> ids,
      ) async {
    if (ids.isEmpty) return;

    const chunkSize = 100;
    for (int i = 0; i < ids.length; i += chunkSize) {
      final chunk = ids.skip(i).take(chunkSize).toList();
      await _dbHelper.batchDelete(
        tableName,
        chunk,
        _getIdColumn(tableName),
      );

      if (i + chunkSize < ids.length) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
  }

  // ==================== EXISTING HELPER METHODS (UNCHANGED) ====================

  Future<T> _retryOperation<T>(Future<T> Function() operation) async {
    int retryCount = 0;

    while (retryCount < MAX_RETRIES) {
      try {
        return await operation();
      } catch (e) {
        retryCount++;
        if (retryCount >= MAX_RETRIES) {
          rethrow;
        }
        debugPrint('⚠️ Retry attempt $retryCount/$MAX_RETRIES after error: $e');
        await Future.delayed(RETRY_DELAY * retryCount);
      }
    }
    throw Exception('Max retries exceeded');
  }

  // Mapper functions remain the same...
  Map<String, dynamic> _mapUniversityFromSupabase(Map<String, dynamic> data) {
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

  Map<String, dynamic> _mapBranchFromSupabase(Map<String, dynamic> data) {
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

  Map<String, dynamic> _mapProgramFromSupabase(Map<String, dynamic> data) {
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

  Map<String, dynamic> _mapUniversityAdmissionFromSupabase(Map<String, dynamic> data) {
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

  Map<String, dynamic> _mapProgramAdmissionFromSupabase(Map<String, dynamic> data) {
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

  int _parseTimestamp(dynamic value) {
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
      case 'universities':
        return 'university_id';
      case 'branches':
        return 'branch_id';
      case 'programs':
        return 'program_id';
      case 'university_admissions':
        return 'uni_admission_id';
      case 'program_admissions':
        return 'prog_admission_id';
      default:
        return 'id';
    }
  }

  Future<bool> needsInitialSync() async {
    final status = await _dbHelper.getSyncStatus();
    for (var tableStatus in status.values) {
      if (tableStatus['total_records'] == 0) {
        return true;
      }
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

// // lib/services/sync_service.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart';
// import 'dart:convert';
// import 'database_helper.dart';
//
// class SyncService {
//   static final SyncService instance = SyncService._init();
//   final DatabaseHelper _dbHelper = DatabaseHelper.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   // Sync batch size
//   static const int BATCH_SIZE = 500;
//
//   // Sync status
//   bool _isSyncing = false;
//   double _syncProgress = 0.0;
//   String _currentTable = '';
//
//   SyncService._init();
//
//   bool get isSyncing => _isSyncing;
//   double get syncProgress => _syncProgress;
//   String get currentTable => _currentTable;
//
//   // ==================== MAIN SYNC OPERATIONS ====================
//
//   /// Perform full sync (initial or forced)
//   Future<void> fullSync({Function(String, double)? onProgress}) async {
//     if (_isSyncing) {
//       debugPrint('⏸️ Sync already in progress');
//       return;
//     }
//
//     _isSyncing = true;
//     _syncProgress = 0.0;
//
//     try {
//       debugPrint('🔄 Starting full sync...');
//
//       // Sync in order: universities → branches → programs → admissions
//       await _syncTable(
//         'universities',
//         'universities',
//         _mapUniversityFromFirebase,
//         onProgress: onProgress,
//       );
//
//       await _syncTable(
//         'branches',
//         'branches',
//         _mapBranchFromFirebase,
//         onProgress: onProgress,
//       );
//
//       await _syncTable(
//         'programs',
//         'programs',
//         _mapProgramFromFirebase,
//         onProgress: onProgress,
//       );
//
//       await _syncTable(
//         'university_admissions',
//         'university_admissions',
//         _mapUniversityAdmissionFromFirebase,
//         onProgress: onProgress,
//       );
//
//       await _syncTable(
//         'program_admissions',
//         'prog_admissions',
//         _mapProgramAdmissionFromFirebase,
//         onProgress: onProgress,
//       );
//
//       debugPrint('✅ Full sync completed successfully');
//     } catch (e) {
//       debugPrint('❌ Full sync failed: $e');
//       rethrow;
//     } finally {
//       _isSyncing = false;
//       _syncProgress = 1.0;
//       _currentTable = '';
//     }
//   }
//
//   /// Perform incremental sync (only changed records)
//   Future<void> incrementalSync({Function(String, double)? onProgress}) async {
//     if (_isSyncing) {
//       debugPrint('⏸️ Sync already in progress');
//       return;
//     }
//
//     _isSyncing = true;
//     _syncProgress = 0.0;
//
//     try {
//       debugPrint('🔄 Starting incremental sync...');
//
//       final tables = [
//         ('universities', 'universities', _mapUniversityFromFirebase),
//         ('branches', 'branches', _mapBranchFromFirebase),
//         ('programs', 'programs', _mapProgramFromFirebase),
//         ('university_admissions', 'university_admissions', _mapUniversityAdmissionFromFirebase),
//         ('program_admissions', 'prog_admissions', _mapProgramAdmissionFromFirebase),
//       ];
//
//       for (var i = 0; i < tables.length; i++) {
//         final (localTable, firebaseCollection, mapper) = tables[i];
//         await _incrementalSyncTable(
//           localTable,
//           firebaseCollection,
//           mapper,
//           onProgress: onProgress,
//         );
//         _syncProgress = (i + 1) / tables.length;
//       }
//
//       debugPrint('✅ Incremental sync completed successfully');
//     } catch (e) {
//       debugPrint('❌ Incremental sync failed: $e');
//       rethrow;
//     } finally {
//       _isSyncing = false;
//       _syncProgress = 1.0;
//       _currentTable = '';
//     }
//   }
//
//   // ==================== PRIVATE SYNC METHODS ====================
//
//   /// Sync entire table (full sync)
//   Future<void> _syncTable(
//       String localTable,
//       String firebaseCollection,
//       Map<String, dynamic> Function(Map<String, dynamic>) mapper, {
//         Function(String, double)? onProgress,
//       }) async {
//     _currentTable = localTable;
//     debugPrint('📦 Syncing $localTable...');
//
//     try {
//       // Check if table is already populated
//       final isTableEmpty = await _dbHelper.isTableEmpty(localTable);
//
//       if (!isTableEmpty) {
//         debugPrint('⏩ $localTable already synced, skipping full sync');
//         return;
//       }
//
//       int totalRecords = 0;
//       int processedRecords = 0;
//       DocumentSnapshot? lastDoc;
//
//       // Fetch in batches
//       while (true) {
//         Query query = _firestore
//             .collection(firebaseCollection)
//             .orderBy(FieldPath.documentId)
//             .limit(BATCH_SIZE);
//
//         if (lastDoc != null) {
//           query = query.startAfterDocument(lastDoc);
//         }
//
//         final snapshot = await query.get(const GetOptions(source: Source.server));
//
//         if (snapshot.docs.isEmpty) break;
//
//         // Map and insert records
//         final records = snapshot.docs.map((doc) {
//           final data = doc.data() as Map<String, dynamic>;
//           return mapper(data);
//         }).toList();
//
//         await _dbHelper.batchUpsert(localTable, records);
//
//         processedRecords += records.length;
//         totalRecords = processedRecords;
//         lastDoc = snapshot.docs.last;
//
//         // Update progress
//         if (onProgress != null) {
//           onProgress(localTable, processedRecords / (processedRecords + BATCH_SIZE));
//         }
//
//         debugPrint('  📥 Synced $processedRecords records from $localTable');
//
//         if (snapshot.docs.length < BATCH_SIZE) break;
//       }
//
//       // Update sync metadata
//       await _dbHelper.updateSyncMetadata(
//         localTable,
//         DateTime.now().millisecondsSinceEpoch,
//         totalRecords,
//         'completed',
//       );
//
//       debugPrint('✅ $localTable sync complete: $totalRecords records');
//     } catch (e) {
//       debugPrint('❌ Error syncing $localTable: $e');
//       await _dbHelper.updateSyncMetadata(
//         localTable,
//         DateTime.now().millisecondsSinceEpoch,
//         0,
//         'error',
//       );
//       rethrow;
//     }
//   }
//
//   /// Incremental sync for a table (only changed records)
//   Future<void> _incrementalSyncTable(
//       String localTable,
//       String firebaseCollection,
//       Map<String, dynamic> Function(Map<String, dynamic>) mapper, {
//         Function(String, double)? onProgress,
//       }) async {
//     _currentTable = localTable;
//     debugPrint('🔄 Incremental sync for $localTable...');
//
//     try {
//       // Get last sync timestamp
//       final lastSync = await _dbHelper.getLastSyncTimestamp(localTable);
//       final lastSyncDate = DateTime.fromMillisecondsSinceEpoch(lastSync);
//
//       debugPrint('  📅 Last sync: $lastSyncDate');
//
//       // Query records updated after last sync
//       final query = _firestore
//           .collection(firebaseCollection)
//           .where('updated_at', isGreaterThan: Timestamp.fromDate(lastSyncDate))
//           .limit(BATCH_SIZE);
//
//       final snapshot = await query.get(const GetOptions(source: Source.server));
//
//       if (snapshot.docs.isEmpty) {
//         debugPrint('  ✅ No updates for $localTable');
//         return;
//       }
//
//       // Separate updates and deletes
//       final updates = <Map<String, dynamic>>[];
//       final deletes = <String>[];
//
//       for (var doc in snapshot.docs) {
//         final data = doc.data() as Map<String, dynamic>;
//         final isDeleted = data['is_deleted'] == true || data['is_deleted'] == 1;
//
//         if (isDeleted) {
//           deletes.add(doc.id);
//         } else {
//           updates.add(mapper(data));
//         }
//       }
//
//       // Apply updates
//       if (updates.isNotEmpty) {
//         await _dbHelper.batchUpsert(localTable, updates);
//         debugPrint('  ✅ Updated ${updates.length} records in $localTable');
//       }
//
//       // Apply deletes
//       if (deletes.isNotEmpty) {
//         await _dbHelper.batchDelete(
//           localTable,
//           deletes,
//           _getIdColumn(localTable),
//         );
//         debugPrint('  ✅ Deleted ${deletes.length} records from $localTable');
//       }
//
//       // Update sync metadata
//       await _dbHelper.updateSyncMetadata(
//         localTable,
//         DateTime.now().millisecondsSinceEpoch,
//         await _dbHelper.getRecordCount(localTable, where: 'is_deleted = 0'),
//         'completed',
//       );
//
//       if (onProgress != null) {
//         onProgress(localTable, 1.0);
//       }
//     } catch (e) {
//       debugPrint('❌ Error in incremental sync for $localTable: $e');
//       rethrow;
//     }
//   }
//
//   // ==================== MAPPER FUNCTIONS ====================
//
//   Map<String, dynamic> _mapUniversityFromFirebase(Map<String, dynamic> data) {
//     return {
//       'university_id': data['university_id'] ?? '',
//       'university_name': data['university_name'] ?? '',
//       'university_logo': data['university_logo'],
//       'university_url': data['university_url'],
//       'uni_description': data['uni_description'],
//       'domestic_tuition_fee': data['domestic_tuition_fee'],
//       'international_tuition_fee': data['international_tuition_fee'],
//       'total_students': data['total_students'],
//       'international_students': data['international_students'],
//       'total_faculty_staff': data['total_faculty_staff'],
//       'min_ranking': data['min_ranking'],
//       'max_ranking': data['max_ranking'],
//       'program_count': data['program_count'] ?? 0,
//       'updated_at': _getTimestamp(data['updated_at']),
//       'is_deleted': data['is_deleted'] == true ? 1 : 0,
//       'synced_at': DateTime.now().millisecondsSinceEpoch,
//     };
//   }
//
//   Map<String, dynamic> _mapBranchFromFirebase(Map<String, dynamic> data) {
//     return {
//       'branch_id': data['branch_id'] ?? '',
//       'university_id': data['university_id'] ?? '',
//       'branch_name': data['branch_name'] ?? '',
//       'country': data['country'] ?? '',
//       'city': data['city'] ?? '',
//       'updated_at': _getTimestamp(data['updated_at']),
//       'is_deleted': data['is_deleted'] == true ? 1 : 0,
//       'synced_at': DateTime.now().millisecondsSinceEpoch,
//     };
//   }
//
//   Map<String, dynamic> _mapProgramFromFirebase(Map<String, dynamic> data) {
//     return {
//       'program_id': data['program_id'] ?? '',
//       'branch_id': data['branch_id'] ?? '',
//       'program_name': data['program_name'] ?? '',
//       'program_url': data['program_url'],
//       'prog_description': data['prog_description'],
//       'duration_months': data['duration_months']?.toString(),
//       'subject_area': data['subject_area'],
//       'study_level': data['study_level'],
//       'study_mode': data['study_mode'],
//       'intake_period': data['intake_period'] != null
//           ? jsonEncode(data['intake_period'])
//           : null,
//       'min_domestic_tuition_fee': data['min_domestic_tuition_fee'],
//       'min_international_tuition_fee': data['min_international_tuition_fee'],
//       'entry_requirement': data['entry_requirement'],
//       'min_subject_ranking': data['min_subject_ranking'],
//       'max_subject_ranking': data['max_subject_ranking'],
//       'university_id': data['university_id'] ?? '',
//       'updated_at': _getTimestamp(data['updated_at']),
//       'is_deleted': data['is_deleted'] == true ? 1 : 0,
//       'synced_at': DateTime.now().millisecondsSinceEpoch,
//     };
//   }
//
//   Map<String, dynamic> _mapUniversityAdmissionFromFirebase(Map<String, dynamic> data) {
//     return {
//       'uni_admission_id': data['uni_admission_id'] ?? '',
//       'university_id': data['university_id'] ?? '',
//       'admission_type': data['admission_type'],
//       'admission_label': data['admission_label'],
//       'admission_value': data['admission_value'],
//       'updated_at': _getTimestamp(data['updated_at']),
//       'is_deleted': data['is_deleted'] == true ? 1 : 0,
//       'synced_at': DateTime.now().millisecondsSinceEpoch,
//     };
//   }
//
//   Map<String, dynamic> _mapProgramAdmissionFromFirebase(Map<String, dynamic> data) {
//     return {
//       'prog_admission_id': data['prog_admission_id'] ?? '',
//       'program_id': data['program_id'] ?? '',
//       'prog_admission_label': data['prog_admission_label'],
//       'prog_admission_value': data['prog_admission_value'],
//       'updated_at': _getTimestamp(data['updated_at']),
//       'is_deleted': data['is_deleted'] == true ? 1 : 0,
//       'synced_at': DateTime.now().millisecondsSinceEpoch,
//     };
//   }
//
//   // ==================== HELPER METHODS ====================
//
//   int _getTimestamp(dynamic value) {
//     if (value == null) return DateTime.now().millisecondsSinceEpoch;
//     if (value is Timestamp) return value.millisecondsSinceEpoch;
//     if (value is int) return value;
//     return DateTime.now().millisecondsSinceEpoch;
//   }
//
//   String _getIdColumn(String tableName) {
//     switch (tableName) {
//       case 'universities':
//         return 'university_id';
//       case 'branches':
//         return 'branch_id';
//       case 'programs':
//         return 'program_id';
//       case 'university_admissions':
//         return 'uni_admission_id';
//       case 'program_admissions':
//         return 'prog_admission_id';
//       default:
//         return 'id';
//     }
//   }
//
//   /// Check if initial sync is needed
//   Future<bool> needsInitialSync() async {
//     final status = await _dbHelper.getSyncStatus();
//
//     for (var tableStatus in status.values) {
//       if (tableStatus['total_records'] == 0) {
//         return true;
//       }
//     }
//
//     return false;
//   }
//
//   /// Get sync statistics
//   Future<Map<String, dynamic>> getSyncStatistics() async {
//     final status = await _dbHelper.getSyncStatus();
//     final dbSize = await _dbHelper.getDatabaseSize();
//
//     int totalRecords = 0;
//     for (var tableStatus in status.values) {
//       totalRecords += (tableStatus['total_records'] as int?) ?? 0;
//     }
//
//     return {
//       'total_records': totalRecords,
//       'database_size': dbSize,
//       'tables': status,
//       'is_syncing': _isSyncing,
//       'sync_progress': _syncProgress,
//       'current_table': _currentTable,
//     };
//   }
// }