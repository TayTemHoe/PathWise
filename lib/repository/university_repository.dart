// lib/repository/university_repository_v2.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../model/university_filter.dart';
import '../model/university.dart';
import '../services/local_data_source.dart';
import '../services/sync_service.dart';

class UniversityRepository {
  final LocalDataSource _localDataSource = LocalDataSource.instance;
  final SyncService _syncService = SyncService.instance;

  // ==================== IN-MEMORY CACHE ====================
  // Cache only currently displayed data (last loaded page)
  final Map<String, UniversityModel> _memoryCache = {};
  int _cacheSize = 0;
  static const int MAX_CACHE_SIZE = 50; // Keep only 50 universities in memory

  // ==================== PUBLIC API ====================

  /// Get universities with pagination
  Future<(List<UniversityModel>, bool)> getUniversities({
    int page = 0,
    int pageSize = 10,
    UniversityFilterModel? filter,
  }) async {
    try {
      debugPrint('📥 Loading universities page $page (size: $pageSize)');

      // Check if tuition filter is active
      final hasTuitionFilter = (filter?.minTuitionFeeMYR != null ||
          filter?.maxTuitionFeeMYR != null);

      if (hasTuitionFilter) {
        // Use chunked filtering if tuition is active
        return await _getUniversitiesWithTuitionFilter(
          page: page,
          pageSize: pageSize,
          filter: filter!,
        );
      }

      // Calculate offset for normal queries (Pagination)
      final offset = page * pageSize;

      // Load from SQLite using the unified method in LocalDataSource.
      // The filter object now contains the country/city/Malaysia default logic.
      final universities = await _localDataSource.getUniversities(
        limit: pageSize,
        offset: offset,
        filter: filter,
      );

      // Update memory cache (Cache-First)
      _updateMemoryCache(universities);

      // Determine if there are more results
      final hasMore = universities.length >= pageSize;

      debugPrint('✅ Loaded ${universities.length} universities from SQLite');

      return (universities, hasMore);
    } catch (e) {
      debugPrint('❌ Error loading universities: $e');
      return (<UniversityModel>[], false);
    }
  }

  Future<(List<UniversityModel>, bool)> _getUniversitiesWithTuitionFilter({
    required int page,
    required int pageSize,
    required UniversityFilterModel filter,
  }) async {
    // ... (chunk size definitions)
    const chunkSize = 500;
    final maxChunks = 20;

    List<UniversityModel> matchedUniversities = [];
    int currentChunk = 0;
    int skippedForPagination = page * pageSize;

    debugPrint('🔄 Starting tuition filtering for universities (page: $page, pageSize: $pageSize)');

    // Smart Queries: Create a filter for the SQL query that contains
    // ALL filters EXCEPT tuition (which will be applied manually later).
    final sqlFilter = filter.copyWith(
      minTuitionFeeMYR: null,
      maxTuitionFeeMYR: null,
    );

    while (currentChunk < maxChunks) {
      final offset = currentChunk * chunkSize;

      // 1. Fetch chunk from DB. This query now correctly applies the
      // Country/City filter via the EXISTS clause in LocalDataSource.
      final chunkUniversities = await _localDataSource.getUniversities(
        limit: chunkSize,
        offset: offset,
        filter: sqlFilter, // Pass the filter *without* tuition fields
      );

      if (chunkUniversities.isEmpty) {
        debugPrint('🛑 No more universities in database');
        break;
      }

      // 2. Apply Tuition Filter manually (uses batch-optimized data source)
      final filtered = await _localDataSource.filterUniversitiesByTuition(
        chunkUniversities,
        filter.minTuitionFeeMYR,
        filter.maxTuitionFeeMYR,
      );

      // 3. Handle pagination (Pagination strategy)
      for (var university in filtered) {
        if (skippedForPagination > 0) {
          skippedForPagination--;
          continue;
        }

        matchedUniversities.add(university);

        if (matchedUniversities.length >= pageSize) {
          break;
        }
      }

      // ... (debug prints, chunk increment, break checks)
      currentChunk++;

      if (matchedUniversities.length >= pageSize) {
        break;
      }

      if (chunkUniversities.length < chunkSize) {
        break;
      }
    }

    final hasMore = currentChunk < maxChunks && matchedUniversities.length == pageSize;

    debugPrint('✅ Filtering complete: ${matchedUniversities.length} universities (hasMore: $hasMore)');

    return (matchedUniversities, hasMore);
  }

  Future<int> getProgramCount(String universityId) async {
    try {
      return await _localDataSource.getProgramCountByUniversity(universityId);
    } catch (e) {
      debugPrint('❌ Error getting program count: $e');
      return 0;
    }
  }

  /// Search universities
  Future<List<UniversityModel>> searchUniversities(
    String query, {
    int limit = 20,
  }) async {
    try {
      // Check memory cache first
      if (query.isEmpty) return [];

      final universities = await _localDataSource.searchUniversities(
        query,
        limit: limit,
      );

      _updateMemoryCache(universities);

      return universities;
    } catch (e) {
      debugPrint('❌ Error searching universities: $e');
      return [];
    }
  }

  /// Get university by ID
  Future<UniversityModel?> getUniversityById(String universityId) async {
    try {
      // Check memory cache first
      if (_memoryCache.containsKey(universityId)) {
        debugPrint('📦 Memory cache HIT: $universityId');
        return _memoryCache[universityId];
      }

      // Load from SQLite
      final university = await _localDataSource.getUniversityById(universityId);

      if (university != null) {
        _memoryCache[universityId] = university;
        _cacheSize++;
      }

      return university;
    } catch (e) {
      debugPrint('❌ Error getting university: $e');
      return null;
    }
  }

  /// Get batch universities by IDs
  Future<List<UniversityModel>> getBatchUniversities(List<String> ids) async {
    try {
      final universities = <UniversityModel>[];

      for (var id in ids) {
        final uni = await getUniversityById(id);
        if (uni != null) {
          universities.add(uni);
        }
      }

      return universities;
    } catch (e) {
      debugPrint('❌ Error getting batch universities: $e');
      return [];
    }
  }

  // ==================== SYNC OPERATIONS ====================

  /// Check if initial sync is needed
  Future<bool> needsInitialSync() async {
    return await _syncService.needsInitialSync();
  }

  /// Perform initial sync
  Future<void> performInitialSync({
    Function(String, double)? onProgress,
  }) async {
    debugPrint('🔄 Starting initial sync...');
    await _syncService.fullSync(onProgress: onProgress);
  }

  /// Perform incremental sync
  Future<void> performIncrementalSync({
    Function(String, double)? onProgress,
  }) async {
    debugPrint('🔄 Starting incremental sync...');
    await _syncService.incrementalSync(onProgress: onProgress);
  }

  /// Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    return await _syncService.getSyncStatistics();
  }

  // ==================== CACHE MANAGEMENT ====================

  /// Update memory cache with LRU strategy
  void _updateMemoryCache(List<UniversityModel> universities) {
    for (var uni in universities) {
      _memoryCache[uni.universityId] = uni;
      _cacheSize++;
    }

    // Enforce cache size limit
    if (_cacheSize > MAX_CACHE_SIZE) {
      _evictOldestFromCache();
    }
  }

  /// Evict oldest items from memory cache
  void _evictOldestFromCache() {
    final keysToRemove = _memoryCache.keys
        .take(_cacheSize - MAX_CACHE_SIZE)
        .toList();
    for (var key in keysToRemove) {
      _memoryCache.remove(key);
      _cacheSize--;
    }
    debugPrint('🧹 Evicted ${keysToRemove.length} items from memory cache');
  }

  /// Clear memory cache
  void clearMemoryCache() {
    _memoryCache.clear();
    _cacheSize = 0;
    debugPrint('🧹 Memory cache cleared');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'memory_cache_size': _cacheSize,
      'memory_cache_limit': MAX_CACHE_SIZE,
    };
  }
}
