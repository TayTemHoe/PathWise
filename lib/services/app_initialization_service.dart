// lib/services/app_initialization_service.dart
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_helper.dart';
import 'sync_service.dart';
import '../utils/currency_utils.dart';

class AppInitializationService {
  static final AppInitializationService instance = AppInitializationService._init();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final SyncService _syncService = SyncService.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isInitialized = false;
  bool _hasInternet = false;

  AppInitializationService._init();

  bool get isInitialized => _isInitialized;
  bool get hasInternet => _hasInternet;

  /// Initialize the app (call this on app startup)
  Future<void> initialize({
    Function(String message, double progress)? onProgress,
  }) async {
    if (_isInitialized) {
      debugPrint('⏸️ App already initialized');
      return;
    }

    try {
      debugPrint('🚀 Initializing PathWise app...');

      // Step 1: Check internet connectivity (0-10%)
      onProgress?.call('Checking internet connection...', 0.0);
      _hasInternet = await _checkInternetConnectivity();
      debugPrint(_hasInternet ? '✅ Internet available' : '⚠️ No internet connection');
      onProgress?.call(_hasInternet ? 'Internet connected' : 'Offline mode', 0.1);

      // Step 2: Verify Supabase connection (10-15%)
      if (_hasInternet) {
        onProgress?.call('Connecting to Supabase...', 0.1);
        final isSupabaseConnected = await _verifySupabaseConnection();
        if (!isSupabaseConnected) {
          debugPrint('⚠️ Supabase connection failed, using offline mode');
          _hasInternet = false;
        } else {
          debugPrint('✅ Supabase connected');
        }
        onProgress?.call('Database connection verified', 0.15);
      }

      // Step 3: Initialize local database (15-20%)
      onProgress?.call('Initializing local database...', 0.15);
      await _dbHelper.database;
      debugPrint('✅ Local database initialized');
      onProgress?.call('Local database ready', 0.2);

      // Step 4: Initialize currency rates (20-25%)
      onProgress?.call('Loading currency rates...', 0.2);
      try {
        await CurrencyUtils.fetchExchangeRates();
        debugPrint('✅ Currency rates loaded');
        onProgress?.call('Currency rates loaded', 0.25);
      } catch (e) {
        debugPrint('⚠️ Currency rates unavailable, using fallback: $e');
        onProgress?.call('Using cached currency rates', 0.25);
      }

      // Step 5: Check if initial sync is needed (25-30%)
      onProgress?.call('Checking sync status...', 0.25);
      final needsSync = await _syncService.needsInitialSync();
      onProgress?.call('Sync status checked', 0.3);

      if (needsSync && _hasInternet) {
        // Perform initial sync (30-95%)
        debugPrint('🔄 Starting initial data sync from Supabase...');
        onProgress?.call('Downloading data from Supabase (this may take a few minutes)...', 0.3);

        await _syncService.fullSync(
          onProgress: (table, progress) {
            final overallProgress = 0.3 + (progress * 0.65); // 30% to 95%
            onProgress?.call('Syncing $table...', overallProgress);
          },
        );

        onProgress?.call('Initial sync completed', 0.95);
        debugPrint('✅ Initial sync completed');
      } else if (!needsSync) {
        debugPrint('✅ Data already synced');
        onProgress?.call('Data already synced', 0.95);

        if (_hasInternet) {
          // Perform incremental sync in background (non-blocking)
          _performBackgroundSync();
        }
      } else {
        debugPrint('⚠️ No internet - using offline data');
        onProgress?.call('Using offline data', 0.95);
      }

      // Step 6: Finalize (95-100%)
      onProgress?.call('Finalizing...', 0.95);
      await Future.delayed(const Duration(milliseconds: 200));

      _isInitialized = true;
      onProgress?.call('App ready!', 1.0);
      debugPrint('✅ App initialization completed');

      // Log statistics
      await _logInitializationStats();

    } catch (e, stackTrace) {
      debugPrint('❌ App initialization failed: $e');
      debugPrint('Stack trace: $stackTrace');

      // Allow app to continue with offline mode
      _isInitialized = true;
      onProgress?.call('App ready (offline mode)', 1.0);

      // Don't rethrow - allow app to work offline
    }
  }

  /// Verify Supabase connection
  Future<bool> _verifySupabaseConnection() async {
    try {
      // Try a simple query to check connection
      await _supabase
          .from('universities')
          .select('university_id')
          .limit(1)
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Connection timeout'),
      );
      return true;
    } catch (e) {
      debugPrint('⚠️ Supabase connection verification failed: $e');
      return false;
    }
  }

  /// Perform background sync (incremental)
  Future<void> _performBackgroundSync() async {
    try {
      debugPrint('🔄 Starting background incremental sync...');

      // Run in background without blocking
      Future.microtask(() async {
        try {
          await _syncService.incrementalSync();
          debugPrint('✅ Background sync completed');
        } catch (e) {
          debugPrint('⚠️ Background sync failed: $e');
        }
      });
    } catch (e) {
      debugPrint('⚠️ Background sync initialization failed: $e');
    }
  }

  /// Check internet connectivity
  Future<bool> _checkInternetConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.first != ConnectivityResult.none;
    } catch (e) {
      debugPrint('⚠️ Error checking connectivity: $e');
      return false;
    }
  }

  /// Manually trigger sync (for pull-to-refresh)
  Future<void> manualSync({
    Function(String message, double progress)? onProgress,
  }) async {
    if (!_hasInternet) {
      throw Exception('No internet connection');
    }

    if (_syncService.isSyncing) {
      debugPrint('⏸️ Sync already in progress');
      return;
    }

    debugPrint('🔄 Manual sync triggered...');

    try {
      onProgress?.call('Syncing data from Supabase...', 0.0);

      await _syncService.incrementalSync(
        onProgress: (table, progress) {
          onProgress?.call('Syncing $table...', progress);
        },
      );

      onProgress?.call('Sync completed', 1.0);
      debugPrint('✅ Manual sync completed');
    } catch (e) {
      debugPrint('❌ Manual sync failed: $e');
      rethrow;
    }
  }

  /// Get initialization status
  Future<Map<String, dynamic>> getStatus() async {
    try {
      final syncStats = await _syncService.getSyncStatistics();
      final dbSize = await _dbHelper.getDatabaseSize();

      return {
        'initialized': _isInitialized,
        'has_internet': _hasInternet,
        'database_size': dbSize,
        'database_size_mb': (dbSize / 1024 / 1024).toStringAsFixed(2),
        'sync_statistics': syncStats,
        'supabase_connected': _hasInternet,
      };
    } catch (e) {
      debugPrint('⚠️ Error getting status: $e');
      return {
        'initialized': _isInitialized,
        'has_internet': _hasInternet,
        'error': e.toString(),
      };
    }
  }

  /// Reset app data (for development/testing)
  Future<void> resetAppData() async {
    debugPrint('🧹 Resetting app data...');

    try {
      await _dbHelper.resetDatabase();
      await _dbHelper.vacuum();

      _isInitialized = false;

      debugPrint('✅ App data reset completed');
    } catch (e) {
      debugPrint('❌ Reset failed: $e');
      rethrow;
    }
  }

  /// Force full resync (download all data again from Supabase)
  Future<void> forceFullResync({
    Function(String message, double progress)? onProgress,
  }) async {
    if (!_hasInternet) {
      throw Exception('No internet connection');
    }

    if (_syncService.isSyncing) {
      throw Exception('Sync already in progress');
    }

    debugPrint('🔄 Force full resync triggered...');

    try {
      // Clear existing data
      onProgress?.call('Clearing local data...', 0.0);
      await _dbHelper.resetDatabase();
      onProgress?.call('Local data cleared', 0.05);

      // Perform full sync from Supabase
      onProgress?.call('Downloading data from Supabase...', 0.1);
      await _syncService.fullSync(
        onProgress: (table, progress) {
          final overallProgress = 0.1 + (progress * 0.9);
          onProgress?.call('Syncing $table...', overallProgress);
        },
      );

      onProgress?.call('Resync completed', 1.0);
      debugPrint('✅ Full resync completed');

      // Log new statistics
      await _logInitializationStats();
    } catch (e) {
      debugPrint('❌ Full resync failed: $e');
      rethrow;
    }
  }

  /// Schedule periodic sync (call this in main app)
  void schedulePeriodicSync() {
    // Perform incremental sync every 6 hours
    Future.delayed(const Duration(hours: 6), () async {
      try {
        // Re-check internet before syncing
        _hasInternet = await _checkInternetConnectivity();

        if (_hasInternet && !_syncService.isSyncing) {
          debugPrint('⏰ Periodic sync triggered');
          await _performBackgroundSync();
        } else if (!_hasInternet) {
          debugPrint('⏰ Periodic sync skipped - no internet');
        } else {
          debugPrint('⏰ Periodic sync skipped - sync in progress');
        }
      } catch (e) {
        debugPrint('⚠️ Periodic sync error: $e');
      } finally {
        // Reschedule regardless of outcome
        schedulePeriodicSync();
      }
    });
  }

  /// Log initialization statistics
  Future<void> _logInitializationStats() async {
    try {
      final stats = await _syncService.getSyncStatistics();
      final dbSize = await _dbHelper.getDatabaseSize();

      debugPrint('📊 === Initialization Statistics ===');
      debugPrint('📊 Database Size: ${(dbSize / 1024 / 1024).toStringAsFixed(2)} MB');
      debugPrint('📊 Total Records: ${stats['total_records']}');

      final tables = stats['tables'] as Map<String, dynamic>;
      for (var entry in tables.entries) {
        final tableStats = entry.value as Map<String, dynamic>;
        debugPrint('📊 ${entry.key}: ${tableStats['total_records']} records');
      }
      debugPrint('📊 ================================');
    } catch (e) {
      debugPrint('⚠️ Could not log stats: $e');
    }
  }

  /// Check sync health
  Future<Map<String, dynamic>> checkSyncHealth() async {
    try {
      final syncStats = await _syncService.getSyncStatistics();
      final tables = syncStats['tables'] as Map<String, dynamic>;

      bool allTablesHealthy = true;
      final unhealthyTables = <String>[];

      for (var entry in tables.entries) {
        final tableStats = entry.value as Map<String, dynamic>;
        if (tableStats['status'] != 'completed' || tableStats['total_records'] == 0) {
          allTablesHealthy = false;
          unhealthyTables.add(entry.key);
        }
      }

      return {
        'healthy': allTablesHealthy,
        'unhealthy_tables': unhealthyTables,
        'has_internet': _hasInternet,
        'is_syncing': _syncService.isSyncing,
        'details': syncStats,
      };
    } catch (e) {
      return {
        'healthy': false,
        'error': e.toString(),
      };
    }
  }
}


// // lib/services/app_initialization_service.dart
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/foundation.dart';
// import 'database_helper.dart';
// import 'sync_service.dart';
// import '../utils/currency_utils.dart';
//
// class AppInitializationService {
//   static final AppInitializationService instance = AppInitializationService._init();
//
//   final DatabaseHelper _dbHelper = DatabaseHelper.instance;
//   final SyncService _syncService = SyncService.instance;
//
//   bool _isInitialized = false;
//   bool _hasInternet = false;
//
//   AppInitializationService._init();
//
//   bool get isInitialized => _isInitialized;
//   bool get hasInternet => _hasInternet;
//
//   /// Initialize the app (call this on app startup)
//   Future<void> initialize({
//     Function(String message, double progress)? onProgress,
//   }) async {
//     if (_isInitialized) {
//       debugPrint('⏸️ App already initialized');
//       return;
//     }
//
//     try {
//       debugPrint('🚀 Initializing PathWise app...');
//
//       // Step 1: Check internet connectivity
//       onProgress?.call('Checking internet connection...', 0.1);
//       _hasInternet = await _checkInternetConnectivity();
//       debugPrint(_hasInternet ? '✅ Internet available' : '⚠️ No internet connection');
//
//       // Step 2: Initialize database
//       onProgress?.call('Initializing database...', 0.2);
//       await _dbHelper.database;
//       debugPrint('✅ Database initialized');
//
//       // Step 3: Initialize currency rates
//       onProgress?.call('Loading currency rates...', 0.3);
//       try {
//         await CurrencyUtils.fetchExchangeRates();
//         debugPrint('✅ Currency rates loaded');
//       } catch (e) {
//         debugPrint('⚠️ Currency rates unavailable, using fallback: $e');
//       }
//
//       // Step 4: Check if initial sync is needed
//       onProgress?.call('Checking sync status...', 0.4);
//       final needsSync = await _syncService.needsInitialSync();
//
//       if (needsSync && _hasInternet) {
//         // Perform initial sync
//         onProgress?.call('Performing initial sync (this may take a few minutes)...', 0.5);
//         debugPrint('🔄 Starting initial data sync...');
//
//         await _syncService.fullSync(
//           onProgress: (table, progress) {
//             final overallProgress = 0.5 + (progress * 0.4); // 50% to 90%
//             onProgress?.call('Syncing $table...', overallProgress);
//           },
//         );
//
//         onProgress?.call('Initial sync completed', 0.9);
//         debugPrint('✅ Initial sync completed');
//       } else if (!needsSync) {
//         debugPrint('✅ Data already synced');
//
//         if (_hasInternet) {
//           // Perform incremental sync in background
//           _performBackgroundSync();
//         }
//       } else {
//         debugPrint('⚠️ No internet - using offline data');
//       }
//
//       // Step 5: Finalize
//       onProgress?.call('Finalizing...', 1.0);
//       _isInitialized = true;
//       debugPrint('✅ App initialization completed');
//
//     } catch (e) {
//       debugPrint('❌ App initialization failed: $e');
//       // Allow app to continue with offline mode
//       _isInitialized = true;
//       rethrow;
//     }
//   }
//
//   /// Perform background sync (incremental)
//   Future<void> _performBackgroundSync() async {
//     try {
//       debugPrint('🔄 Starting background incremental sync...');
//
//       await _syncService.incrementalSync();
//
//       debugPrint('✅ Background sync completed');
//     } catch (e) {
//       debugPrint('⚠️ Background sync failed: $e');
//     }
//   }
//
//   /// Check internet connectivity
//   Future<bool> _checkInternetConnectivity() async {
//     try {
//       final connectivityResult = await Connectivity().checkConnectivity();
//       return connectivityResult != ConnectivityResult.none;
//     } catch (e) {
//       debugPrint('⚠️ Error checking connectivity: $e');
//       return false;
//     }
//   }
//
//   /// Manually trigger sync (for pull-to-refresh)
//   Future<void> manualSync({
//     Function(String message, double progress)? onProgress,
//   }) async {
//     if (!_hasInternet) {
//       throw Exception('No internet connection');
//     }
//
//     debugPrint('🔄 Manual sync triggered...');
//
//     try {
//       onProgress?.call('Syncing data...', 0.0);
//
//       await _syncService.incrementalSync(
//         onProgress: (table, progress) {
//           onProgress?.call('Syncing $table...', progress);
//         },
//       );
//
//       onProgress?.call('Sync completed', 1.0);
//       debugPrint('✅ Manual sync completed');
//     } catch (e) {
//       debugPrint('❌ Manual sync failed: $e');
//       rethrow;
//     }
//   }
//
//   /// Get initialization status
//   Future<Map<String, dynamic>> getStatus() async {
//     final syncStats = await _syncService.getSyncStatistics();
//     final dbSize = await _dbHelper.getDatabaseSize();
//
//     return {
//       'initialized': _isInitialized,
//       'has_internet': _hasInternet,
//       'database_size': dbSize,
//       'sync_statistics': syncStats,
//     };
//   }
//
//   /// Reset app data (for development/testing)
//   Future<void> resetAppData() async {
//     debugPrint('🧹 Resetting app data...');
//
//     try {
//       await _dbHelper.resetDatabase();
//       await _dbHelper.vacuum();
//
//       _isInitialized = false;
//
//       debugPrint('✅ App data reset completed');
//     } catch (e) {
//       debugPrint('❌ Reset failed: $e');
//       rethrow;
//     }
//   }
//
//   /// Force full resync (download all data again)
//   Future<void> forceFullResync({
//     Function(String message, double progress)? onProgress,
//   }) async {
//     if (!_hasInternet) {
//       throw Exception('No internet connection');
//     }
//
//     debugPrint('🔄 Force full resync triggered...');
//
//     try {
//       // Clear existing data
//       onProgress?.call('Clearing local data...', 0.0);
//       await _dbHelper.resetDatabase();
//
//       // Perform full sync
//       onProgress?.call('Downloading data...', 0.1);
//       await _syncService.fullSync(
//         onProgress: (table, progress) {
//           final overallProgress = 0.1 + (progress * 0.9);
//           onProgress?.call('Syncing $table...', overallProgress);
//         },
//       );
//
//       onProgress?.call('Resync completed', 1.0);
//       debugPrint('✅ Full resync completed');
//     } catch (e) {
//       debugPrint('❌ Full resync failed: $e');
//       rethrow;
//     }
//   }
//
//   /// Schedule periodic sync (call this in main app)
//   void schedulePeriodicSync() {
//     // Perform incremental sync every 6 hours
//     Future.delayed(const Duration(hours: 6), () async {
//       if (_hasInternet && !_syncService.isSyncing) {
//         await _performBackgroundSync();
//       }
//       schedulePeriodicSync(); // Reschedule
//     });
//   }
// }