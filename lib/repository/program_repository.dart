// lib/repository/program_repository_v2.dart
import 'package:flutter/foundation.dart';
import '../model/program.dart';
import '../model/program_filter.dart';
import '../model/branch.dart';
import '../model/university.dart';
import '../services/local_data_source.dart';
import '../services/sync_service.dart';

class ProgramRepository {
  final LocalDataSource _localDataSource = LocalDataSource.instance;
  final SyncService _syncService = SyncService.instance;

  // ==================== IN-MEMORY CACHE ====================
  final Map<String, ProgramModel> _programCache = {};
  final Map<String, UniversityModel> _universityCache = {};
  final Map<String, BranchModel> _branchCache = {};

  int _cacheSize = 0;
  static const int MAX_CACHE_SIZE = 50;

  // ==================== PUBLIC API ====================

  /// Get programs with pagination
  Future<(List<ProgramModel>, bool)> getPrograms({
    required int page,
    required int pageSize,
    ProgramFilterModel? filter,
  }) async {
    try {
      final hasTuitionFilter = (filter?.minTuitionFeeMYR != null ||
          filter?.maxTuitionFeeMYR != null);

      if (hasTuitionFilter) {
        // ✅ OPTIMIZED: Use larger chunks and fetch until we have enough matches
        return await _getProgramsWithTuitionFilter(
          page: page,
          pageSize: pageSize,
          filter: filter!,
        );
      } else {
        // Normal pagination for other filters
        final offset = page * pageSize;
        final programs = await _localDataSource.getPrograms(
          limit: pageSize,
          offset: offset,
          filter: filter,
        );

        final hasMore = programs.length == pageSize;
        return (programs, hasMore);
      }
    } catch (e) {
      debugPrint('❌ Repository error: $e');
      return (<ProgramModel>[], false);
    }
  }

  Future<(List<ProgramModel>, bool)> _getProgramsWithTuitionFilter({
    required int page,
    required int pageSize,
    required ProgramFilterModel filter,
  }) async {
    const chunkSize = 1000; // ✅ Increased from 500 to 1000
    final maxChunks = 150; // ✅ Increased from 20 to 150 (allows scanning 150k programs)

    List<ProgramModel> matchedPrograms = [];
    int currentChunk = 0;
    int totalProcessed = 0;
    int skippedForPagination = page * pageSize; // ✅ NEW: Track how many to skip

    debugPrint('🔄 Starting tuition filtering (page: $page, pageSize: $pageSize)');

    while (currentChunk < maxChunks) {
      final offset = currentChunk * chunkSize;

      // Fetch chunk
      final chunkPrograms = await _localDataSource.getPrograms(
        limit: chunkSize,
        offset: offset,
        filter: filter.copyWith(
          minTuitionFeeMYR: null,
          maxTuitionFeeMYR: null,
        ),
      );

      if (chunkPrograms.isEmpty) {
        debugPrint('🛑 No more programs in database');
        break;
      }

      totalProcessed += chunkPrograms.length;

      // Apply tuition filter to chunk
      final filtered = await _localDataSource.filterProgramsByTuitionPublic(
        chunkPrograms,
        filter.minTuitionFeeMYR,
        filter.maxTuitionFeeMYR,
      );

      // ✅ NEW: Handle pagination by skipping already-shown results
      for (var program in filtered) {
        if (skippedForPagination > 0) {
          skippedForPagination--;
          continue; // Skip this program (already shown in previous pages)
        }

        matchedPrograms.add(program);

        if (matchedPrograms.length >= pageSize) {
          break; // Got enough for this page
        }
      }

      debugPrint('   Chunk $currentChunk: ${filtered.length} matches (total: ${matchedPrograms.length}/$pageSize)');

      currentChunk++;

      // Stop if we have enough programs for this page
      if (matchedPrograms.length >= pageSize) {
        break;
      }

      // Stop if chunk wasn't full (end of database)
      if (chunkPrograms.length < chunkSize) {
        debugPrint('📄 Reached end of database');
        break;
      }
    }

    // ✅ FIXED: Determine if there are more results
    final hasMore = currentChunk < maxChunks && matchedPrograms.length == pageSize;

    debugPrint('✅ Filtering complete: ${matchedPrograms.length} programs (hasMore: $hasMore)');

    return (matchedPrograms, hasMore);
  }

  /// Search programs
  Future<List<ProgramModel>> searchPrograms(
      String query, {
        int limit = 20,
      }) async {
    try {
      if (query.isEmpty) return [];

      final programs = await _localDataSource.searchPrograms(
        query,
        limit: limit,
      );

      _updateProgramCache(programs);

      return programs;
    } catch (e) {
      debugPrint('❌ Error searching programs: $e');
      return [];
    }
  }

  Future<Set<String>> getBranchIdsByCountries(List<String> countries) async {
    return await _localDataSource.getBranchIdsByCountries(countries);
  }

  /// Get program by ID
  Future<ProgramModel?> getProgramById(String programId) async {
    try {
      // Check memory cache first
      if (_programCache.containsKey(programId)) {
        debugPrint('📦 Memory cache HIT: Program $programId');
        return _programCache[programId];
      }

      // Load from SQLite
      final program = await _localDataSource.getProgramById(programId);

      if (program != null) {
        _programCache[programId] = program;
        _cacheSize++;
      }

      return program;
    } catch (e) {
      debugPrint('❌ Error getting program: $e');
      return null;
    }
  }

  /// Get programs by university
  Future<List<ProgramModel>> getProgramsByUniversity(
      String universityId, {
        int limit = 50,
      }) async {
    try {
      final programs = await _localDataSource.getProgramsByUniversity(
        universityId,
        limit: limit,
      );

      _updateProgramCache(programs);

      return programs;
    } catch (e) {
      debugPrint('❌ Error getting programs by university: $e');
      return [];
    }
  }

  /// Get programs by branch
  Future<List<ProgramModel>> getProgramsByBranch(
      String branchId, {
        int limit = 100,
      }) async {
    try {
      final programs = await _localDataSource.getProgramsByBranch(
        branchId,
        limit: limit,
      );

      _updateProgramCache(programs);

      return programs;
    } catch (e) {
      debugPrint('❌ Error getting programs by branch: $e');
      return [];
    }
  }

  /// Get programs grouped by study level
  Future<Map<String, List<ProgramModel>>> getProgramsByStudyLevel(
      String universityId,
      ) async {
    try {
      final programsByLevel = await _localDataSource.getProgramsByStudyLevel(
        universityId,
      );

      // Cache all programs
      for (var programs in programsByLevel.values) {
        _updateProgramCache(programs);
      }

      return programsByLevel;
    } catch (e) {
      debugPrint('❌ Error getting programs by level: $e');
      return {};
    }
  }

  /// Get related programs by level
  Future<Map<String, List<ProgramModel>>> getRelatedProgramsByLevel(
      String universityId,
      String studyLevel,
      String excludeProgramId,
      ) async {
    try {
      final relatedPrograms = await _localDataSource.getRelatedProgramsByLevel(
        universityId,
        studyLevel,
        excludeProgramId,
      );

      // Cache programs
      for (var programs in relatedPrograms.values) {
        _updateProgramCache(programs);
      }

      return relatedPrograms;
    } catch (e) {
      debugPrint('❌ Error getting related programs: $e');
      return {};
    }
  }

  /// Get program count by university
  Future<int> getProgramCountByUniversity(String universityId) async {
    try {
      return await _localDataSource.getProgramCountByUniversity(universityId);
    } catch (e) {
      debugPrint('❌ Error getting program count: $e');
      return 0;
    }
  }

  // ==================== UNIVERSITY & BRANCH DATA ====================

  /// Get university for program
  Future<UniversityModel?> getUniversityForProgram(String universityId) async {
    try {
      // Check memory cache first
      if (_universityCache.containsKey(universityId)) {
        debugPrint('📦 Memory cache HIT: University $universityId');
        return _universityCache[universityId];
      }

      // Load from SQLite
      final university = await _localDataSource.getUniversityById(universityId);

      if (university != null) {
        _universityCache[universityId] = university;
      }

      return university;
    } catch (e) {
      debugPrint('❌ Error getting university: $e');
      return null;
    }
  }

  /// Get branch for program
  Future<BranchModel?> getBranchForProgram(String branchId) async {
    try {
      // Check memory cache first
      if (_branchCache.containsKey(branchId)) {
        debugPrint('📦 Memory cache HIT: Branch $branchId');
        return _branchCache[branchId];
      }

      // Load from SQLite
      final branch = await _localDataSource.getBranchById(branchId);

      if (branch != null) {
        _branchCache[branchId] = branch;
      }

      return branch;
    } catch (e) {
      debugPrint('❌ Error getting branch: $e');
      return null;
    }
  }

  // ==================== CACHE MANAGEMENT ====================

  void _updateProgramCache(List<ProgramModel> programs) {
    for (var program in programs) {
      _programCache[program.programId] = program;
      _cacheSize++;
    }

    if (_cacheSize > MAX_CACHE_SIZE) {
      _evictOldestFromCache();
    }
  }

  void _evictOldestFromCache() {
    final keysToRemove = _programCache.keys
        .take(_cacheSize - MAX_CACHE_SIZE)
        .toList();

    for (var key in keysToRemove) {
      _programCache.remove(key);
      _cacheSize--;
    }

    debugPrint('🧹 Evicted ${keysToRemove.length} items from memory cache');
  }

  void clearMemoryCache() {
    _programCache.clear();
    _universityCache.clear();
    _branchCache.clear();
    _cacheSize = 0;
    debugPrint('🧹 Memory cache cleared');
  }

  Map<String, dynamic> getCacheStats() {
    return {
      'program_cache_size': _programCache.length,
      'university_cache_size': _universityCache.length,
      'branch_cache_size': _branchCache.length,
      'total_cache_size': _cacheSize,
      'cache_limit': MAX_CACHE_SIZE,
    };
  }
}