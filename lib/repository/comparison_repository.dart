// lib/repository/comparison_repository.dart

import 'package:flutter/foundation.dart';
import '../model/comparison.dart';
import '../model/program.dart';
import '../model/university.dart';
import '../model/branch.dart';
import '../model/program_admission.dart';
import '../model/university_admission.dart';
import '../services/database_helper.dart';
import '../services/local_data_source.dart';

class ComparisonRepository {
  static final ComparisonRepository instance = ComparisonRepository._init();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final LocalDataSource _localDataSource = LocalDataSource.instance;

  // In-memory cache to minimize SQLite reads
  String? _currentCachedUserId;
  final Map<String, ProgramModel> _programCache = {};
  final Map<String, UniversityModel> _universityCache = {};
  final Map<String, BranchModel> _branchCache = {};
  final Map<String, List<ProgramAdmissionModel>> _programAdmissionsCache = {};
  final Map<String, List<UniversityAdmissionModel>> _universityAdmissionsCache = {};
  final Map<String, List<BranchModel>> _universityBranchesCache = {};
  bool _cacheValidForUser(String userId) {
    return _currentCachedUserId == userId;
  }

  ComparisonRepository._init();

  // ==================== COMPARISON CRUD ====================

  /// Add item to comparison (SQLite + Cache)
  Future<bool> addToComparison({
    required String userId,
    required ComparisonItem item,
  }) async {
    try {
      _validateUserCache(userId);
      // Check limit before adding
      final itemType = item.type == ComparisonType.programs ? 'program' : 'university';
      final currentCount = await _dbHelper.getComparisonCount(
        userId: userId,
        itemType: itemType,
      );

      if (currentCount >= 3) {
        debugPrint('⚠️ Comparison limit reached for $itemType');
        return false;
      }

      // Add to SQLite
      final success = await _dbHelper.addComparison(
        userId: userId,
        itemType: itemType,
        itemId: item.id,
      );

      if (success) {
        debugPrint('✅ Added ${item.name} to comparison');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error adding to comparison: $e');
      return false;
    }
  }

  /// Remove item from comparison
  Future<bool> removeFromComparison({
    required String userId,
    required String itemId,
  }) async {
    try {
      final success = await _dbHelper.removeComparison(
        userId: userId,
        itemId: itemId,
      );

      if (success) {
        // Clean up cache
        _programCache.remove(itemId);
        _universityCache.remove(itemId);
        _programAdmissionsCache.remove(itemId);
        _universityAdmissionsCache.remove(itemId);
        _universityBranchesCache.remove(itemId);

        debugPrint('✅ Removed item $itemId from comparison');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error removing from comparison: $e');
      return false;
    }
  }

  /// Remove all items of a specific type
  Future<int> clearComparisonByType({
    required String userId,
    required ComparisonType type,
  }) async {
    try {
      final itemType = type == ComparisonType.programs ? 'program' : 'university';

      final count = await _dbHelper.removeComparisonsByType(
        userId: userId,
        itemType: itemType,
      );

      // Clear relevant caches
      if (type == ComparisonType.programs) {
        _programCache.clear();
        _programAdmissionsCache.clear();
      } else {
        _universityCache.clear();
        _universityAdmissionsCache.clear();
        _universityBranchesCache.clear();
      }

      debugPrint('✅ Cleared $count items from $itemType comparison');
      return count;
    } catch (e) {
      debugPrint('❌ Error clearing comparison: $e');
      return 0;
    }
  }

  Future<void> debugPrintSQLiteState(String userId) async {
    try {
      debugPrint('🔍 CHECKING SQLITE STATE FOR USER: $userId');

      // Get raw rows from SQLite
      final rows = await _dbHelper.getComparisons(
        userId: userId,
        itemType: null, // Get ALL
      );

      debugPrint('📦 Found ${rows.length} rows in SQLite');

      for (var row in rows) {
        debugPrint('   Row: ${row['item_type']} - ${row['item_id']}');
      }

      // Now get the formatted items
      final items = await getComparisonItems(userId: userId, type: null);

      debugPrint('📋 After formatting: ${items.length} items');
      for (var item in items) {
        debugPrint('   ${item.type}: ${item.name} (${item.id})');
      }

      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      debugPrint('❌ Error in debug: $e');
    }
  }

  /// Get all comparison items for user
  Future<List<ComparisonItem>> getComparisonItems({
    required String userId,
    ComparisonType? type,
  }) async {
    try {
      _validateUserCache(userId);
      final itemType = type != null
          ? (type == ComparisonType.programs ? 'program' : 'university')
          : null;

      debugPrint('🔎 getComparisonItems called:');
      debugPrint('   userId: $userId');
      debugPrint('   type filter: $itemType');

      // Get from SQLite
      final rows = await _dbHelper.getComparisons(
        userId: userId,
        itemType: itemType,
      );

      debugPrint('📦 SQLite returned ${rows.length} rows');

      final items = <ComparisonItem>[];

      // Batch fetch details to minimize queries
      for (var row in rows) {
        final itemId = row['item_id'] as String;
        final rowType = row['item_type'] as String;

        debugPrint('   Processing: $rowType - $itemId');

        if (rowType == 'program') {
          final program = await _getProgramWithCache(itemId);
          if (program != null) {
            final university = await _getUniversityWithCache(program.universityId);

            items.add(ComparisonItem(
              id: program.programId,
              name: program.programName,
              logoUrl: university?.universityLogo,
              type: ComparisonType.programs,
            ));
            debugPrint('      ✅ Added program: ${program.programName}');
          } else {
            debugPrint('      ❌ Program not found in database');
          }
        } else {
          final university = await _getUniversityWithCache(itemId);
          if (university != null) {
            items.add(ComparisonItem(
              id: university.universityId,
              name: university.universityName,
              logoUrl: university.universityLogo,
              type: ComparisonType.universities,
            ));
            debugPrint('      ✅ Added university: ${university.universityName}');
          } else {
            debugPrint('      ❌ University not found in database');
          }
        }
      }

      debugPrint('📋 Final result: ${items.length} items');
      return items;
    } catch (e) {
      debugPrint('❌ Error getting comparison items: $e');
      return [];
    }
  }

  /// Get comparison count
  Future<int> getComparisonCount({
    required String userId,
    required ComparisonType type,
  }) async {
    try {
      final itemType = type == ComparisonType.programs ? 'program' : 'university';

      return await _dbHelper.getComparisonCount(
        userId: userId,
        itemType: itemType,
      );
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
      return await _dbHelper.isInComparison(
        userId: userId,
        itemId: itemId,
      );
    } catch (e) {
      debugPrint('❌ Error checking comparison: $e');
      return false;
    }
  }

  // ==================== DATA FETCHING WITH CACHING ====================

  /// Get program with cache
  Future<ProgramModel?> _getProgramWithCache(String programId) async {
    // Check cache first
    if (!_cacheValidForUser(_currentCachedUserId ?? '')) {
      clearCache();
    }

    if (_programCache.containsKey(programId)) {
      return _programCache[programId];
    }

    // Fetch from SQLite
    final program = await _localDataSource.getProgramById(programId);

    if (program != null) {
      _programCache[programId] = program;
    }

    return program;
  }

  /// Get university with cache
  Future<UniversityModel?> _getUniversityWithCache(String universityId) async {
    // Check cache first
    if (_universityCache.containsKey(universityId)) {
      return _universityCache[universityId];
    }

    // Fetch from SQLite
    final university = await _localDataSource.getUniversityById(universityId);

    if (university != null) {
      _universityCache[universityId] = university;
    }

    return university;
  }

  /// Get program details (with related data)
  Future<ProgramModel?> getProgramDetails(String programId) async {
    final program = await _getProgramWithCache(programId);

    if (program != null) {
      // Preload related data
      _loadBranchForProgram(program.branchId);
      _loadUniversityForProgram(program.universityId);
      _loadProgramAdmissions(programId);
    }

    return program;
  }

  /// Get university details (with related data)
  Future<UniversityModel?> getUniversityDetails(String universityId) async {
    final university = await _getUniversityWithCache(universityId);

    if (university != null) {
      // Preload related data
      _loadUniversityBranches(universityId);
      _loadUniversityAdmissions(universityId);
    }

    return university;
  }

  /// Get branch for program
  Future<BranchModel?> getBranchForProgram(String branchId) async {
    if (_branchCache.containsKey(branchId)) {
      return _branchCache[branchId];
    }

    final branch = await _localDataSource.getBranchById(branchId);

    if (branch != null) {
      _branchCache[branchId] = branch;
    }

    return branch;
  }

  /// Get university for program
  Future<UniversityModel?> getUniversityForProgram(String universityId) async {
    return await _getUniversityWithCache(universityId);
  }

  /// Get program admissions
  Future<List<ProgramAdmissionModel>> getProgramAdmissions(String programId) async {
    if (_programAdmissionsCache.containsKey(programId)) {
      return _programAdmissionsCache[programId]!;
    }

    final admissions = await _localDataSource.getProgramAdmissions(programId);
    _programAdmissionsCache[programId] = admissions;

    return admissions;
  }

  /// Get university admissions
  Future<List<UniversityAdmissionModel>> getUniversityAdmissions(String universityId) async {
    if (_universityAdmissionsCache.containsKey(universityId)) {
      return _universityAdmissionsCache[universityId]!;
    }

    final admissions = await _localDataSource.getUniversityAdmissions(universityId);
    _universityAdmissionsCache[universityId] = admissions;

    return admissions;
  }

  /// Get university branches
  Future<List<BranchModel>> getUniversityBranches(String universityId) async {
    if (_universityBranchesCache.containsKey(universityId)) {
      return _universityBranchesCache[universityId]!;
    }

    final branches = await _localDataSource.getBranchesByUniversity(universityId);
    _universityBranchesCache[universityId] = branches;

    return branches;
  }

  // ==================== BACKGROUND PRELOADING ====================

  Future<void> _loadBranchForProgram(String branchId) async {
    if (!_branchCache.containsKey(branchId)) {
      final branch = await _localDataSource.getBranchById(branchId);
      if (branch != null) {
        _branchCache[branchId] = branch;
      }
    }
  }

  Future<void> _loadUniversityForProgram(String universityId) async {
    if (!_universityCache.containsKey(universityId)) {
      final university = await _localDataSource.getUniversityById(universityId);
      if (university != null) {
        _universityCache[universityId] = university;
      }
    }
  }

  Future<void> _loadProgramAdmissions(String programId) async {
    if (!_programAdmissionsCache.containsKey(programId)) {
      final admissions = await _localDataSource.getProgramAdmissions(programId);
      _programAdmissionsCache[programId] = admissions;
    }
  }

  Future<void> _loadUniversityBranches(String universityId) async {
    if (!_universityBranchesCache.containsKey(universityId)) {
      final branches = await _localDataSource.getBranchesByUniversity(universityId);
      _universityBranchesCache[universityId] = branches;
    }
  }

  Future<void> _loadUniversityAdmissions(String universityId) async {
    if (!_universityAdmissionsCache.containsKey(universityId)) {
      final admissions = await _localDataSource.getUniversityAdmissions(universityId);
      _universityAdmissionsCache[universityId] = admissions;
    }
  }

  // ==================== CACHE MANAGEMENT ====================

  /// Clear all caches
  void clearCache() {
    _programCache.clear();
    _universityCache.clear();
    _branchCache.clear();
    _programAdmissionsCache.clear();
    _universityAdmissionsCache.clear();
    _universityBranchesCache.clear();

    debugPrint('🧹 Comparison repository cache cleared');
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    return {
      'programs': _programCache.length,
      'universities': _universityCache.length,
      'branches': _branchCache.length,
      'program_admissions': _programAdmissionsCache.length,
      'university_admissions': _universityAdmissionsCache.length,
      'university_branches': _universityBranchesCache.length,
    };
  }

  void _validateUserCache(String userId) {
    if (_currentCachedUserId != userId) {
      debugPrint('🔄 User changed from $_currentCachedUserId to $userId - clearing cache');
      clearCache();
      _currentCachedUserId = userId;
    }
  }
}