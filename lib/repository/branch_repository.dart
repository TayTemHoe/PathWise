// lib/repository/branch_repository_v2.dart
import 'package:flutter/foundation.dart';
import '../model/branch.dart';
import '../services/local_data_source.dart';

class BranchRepository {
  final LocalDataSource _localDataSource = LocalDataSource.instance;

  // Memory cache for branches by university
  final Map<String, List<BranchModel>> _branchesCache = {};

  /// Get branches by university
  Future<List<BranchModel>> getBranchesByUniversity(String universityId) async {
    // Check cache first
    if (_branchesCache.containsKey(universityId)) {
      debugPrint('📦 Cache HIT: Branches for $universityId');
      return _branchesCache[universityId]!;
    }

    try {
      debugPrint('📥 Loading branches for $universityId...');

      final branches = await _localDataSource.getBranchesByUniversity(universityId);

      // Cache the result
      _branchesCache[universityId] = branches;

      debugPrint('✅ Loaded ${branches.length} branches');
      return branches;
    } catch (e) {
      debugPrint('❌ Error loading branches: $e');
      return [];
    }
  }

  /// Clear cache
  void clearCache() {
    _branchesCache.clear();
    debugPrint('🧹 Branch cache cleared');
  }

  /// Clear cache for specific university
  void clearCacheFor(String universityId) {
    _branchesCache.remove(universityId);
    debugPrint('🧹 Branch cache cleared for $universityId');
  }
}