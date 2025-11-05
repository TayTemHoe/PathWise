import 'package:flutter/material.dart';
import 'package:path_wise/model/branch.dart';
import 'package:path_wise/repository/branch_repository.dart';

/// CRITICAL FIX: Prevents multiple simultaneous branch loading calls
/// This was causing crashes when scrolling through university lists
class BranchViewModel extends ChangeNotifier {
  final BranchRepository _repository = BranchRepository();

  // Store branches grouped by universityId
  final Map<String, List<BranchModel>> _branchesByUniversity = {};

  // Track IDs that are currently being fetched (CRITICAL: prevents duplicate calls)
  final Set<String> _loadingIds = {};

  // Track IDs that have been requested (prevents reload loops)
  final Set<String> _requestedIds = {};

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<BranchModel> getBranches(String universityId) =>
      _branchesByUniversity[universityId] ?? [];

  // Check if a specific university's branches are loading
  bool isLoadingBranches(String universityId) =>
      _loadingIds.contains(universityId);

  // Check if branches have been requested (loaded or loading)
  bool hasRequestedBranches(String universityId) =>
      _requestedIds.contains(universityId);

  /// CRITICAL FIX: Prevents duplicate loading calls that cause crashes
  Future<void> loadBranches(String universityId) async {
    // STEP 1: Check if already loaded, loading, or requested
    if (_branchesByUniversity.containsKey(universityId)) {
      debugPrint('✅ Branches already loaded for $universityId');
      return; // Already have data
    }

    if (_loadingIds.contains(universityId)) {
      debugPrint('⏸️ Already loading branches for $universityId');
      return; // Currently loading
    }

    if (_requestedIds.contains(universityId)) {
      debugPrint('⏸️ Already requested branches for $universityId');
      return; // Already requested (loading or failed)
    }

    // STEP 2: Mark as requested IMMEDIATELY to prevent duplicate calls
    _requestedIds.add(universityId);
    _loadingIds.add(universityId);
    _isLoading = true;

    debugPrint('📥 Loading branches for $universityId...');

    try {
      final branches = await _repository.getBranchesByUniversity(universityId);

      // Store the result
      _branchesByUniversity[universityId] = branches;
      _errorMessage = null;

      debugPrint('✅ Loaded ${branches.length} branches for $universityId');
    } catch (e) {
      _errorMessage = e.toString();

      // IMPORTANT: Add empty list on failure to prevent reload loops
      _branchesByUniversity[universityId] = [];

      debugPrint('❌ Error loading branches for $universityId: $e');
    } finally {
      _isLoading = false;
      _loadingIds.remove(universityId);

      // CRITICAL: Notify listeners AFTER the current frame to avoid build errors
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isLoading == false) { // Double-check we're not loading
          notifyListeners();
        }
      });
    }
  }

  /// Load multiple universities' branches in batch (optimized for performance)
  Future<void> loadBranchesBatch(List<String> universityIds) async {
    // Filter out IDs that are already loaded, loading, or requested
    final idsToLoad = universityIds
        .where((id) =>
    !_branchesByUniversity.containsKey(id) &&
        !_loadingIds.contains(id) &&
        !_requestedIds.contains(id))
        .toList();

    if (idsToLoad.isEmpty) {
      debugPrint('⏸️ No new branches to load in batch');
      return;
    }

    debugPrint('📥 Batch loading branches for ${idsToLoad.length} universities...');

    // Mark all as requested
    _requestedIds.addAll(idsToLoad);
    _loadingIds.addAll(idsToLoad);

    try {
      // Load all branches in parallel (max 5 at a time to avoid overload)
      final batchSize = 5;
      for (var i = 0; i < idsToLoad.length; i += batchSize) {
        final batch = idsToLoad.skip(i).take(batchSize).toList();

        final results = await Future.wait(
          batch.map((id) => _repository.getBranchesByUniversity(id)),
        );

        // Store results
        for (int j = 0; j < batch.length; j++) {
          _branchesByUniversity[batch[j]] = results[j];
        }
      }

      debugPrint('✅ Batch loaded branches for ${idsToLoad.length} universities');
    } catch (e) {
      debugPrint('❌ Error in batch loading: $e');

      // Add empty lists for failed loads
      for (var id in idsToLoad) {
        if (!_branchesByUniversity.containsKey(id)) {
          _branchesByUniversity[id] = [];
        }
      }
    } finally {
      _loadingIds.removeAll(idsToLoad);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  /// Clear branch data (e.g., when switching university or refreshing)
  void clearBranches() {
    debugPrint('🧹 Clearing all branches');
    _branchesByUniversity.clear();
    _loadingIds.clear();
    _requestedIds.clear();
    notifyListeners();
  }

  /// Clear branches for a specific university
  void clearBranchesFor(String universityId) {
    debugPrint('🧹 Clearing branches for $universityId');
    _branchesByUniversity.remove(universityId);
    _loadingIds.remove(universityId);
    _requestedIds.remove(universityId);
    notifyListeners();
  }

  /// Refresh branches for a specific university
  Future<void> refreshBranches(String universityId) async {
    debugPrint('🔄 Refreshing branches for $universityId');
    clearBranchesFor(universityId);
    await loadBranches(universityId);
  }

  @override
  void dispose() {
    debugPrint('🗑️ BranchViewModel disposed');
    _branchesByUniversity.clear();
    _loadingIds.clear();
    _requestedIds.clear();
    super.dispose();
  }
}