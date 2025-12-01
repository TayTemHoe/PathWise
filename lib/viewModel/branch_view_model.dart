// lib/viewModel/branch_view_model_v2.dart
import 'package:flutter/material.dart';
import '../model/branch.dart';
import '../repository/branch_repository.dart';

class BranchViewModel extends ChangeNotifier {
  final BranchRepository _repository = BranchRepository();

  // Store branches grouped by universityId
  final Map<String, List<BranchModel>> _branchesByUniversity = {};

  // Track IDs that are currently being fetched
  final Set<String> _loadingIds = {};

  // Track IDs that have been requested
  final Set<String> _requestedIds = {};

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<BranchModel> getBranches(String universityId) =>
      _branchesByUniversity[universityId] ?? [];

  bool isLoadingBranches(String universityId) =>
      _loadingIds.contains(universityId);

  bool hasRequestedBranches(String universityId) =>
      _requestedIds.contains(universityId);

  /// Load branches for a university
  Future<void> loadBranches(String universityId) async {
    // Check if already loaded, loading, or requested
    if (_branchesByUniversity.containsKey(universityId)) {
      debugPrint('✅ Branches already loaded for $universityId');
      return;
    }

    if (_loadingIds.contains(universityId)) {
      debugPrint('⏸️ Already loading branches for $universityId');
      return;
    }

    if (_requestedIds.contains(universityId)) {
      debugPrint('⏸️ Already requested branches for $universityId');
      return;
    }

    // Mark as requested IMMEDIATELY
    _requestedIds.add(universityId);
    _loadingIds.add(universityId);
    _isLoading = true;

    debugPrint('📥 Loading branches for $universityId...');

    try {
      final branches = await _repository.getBranchesByUniversity(universityId);

      _branchesByUniversity[universityId] = branches;
      _errorMessage = null;

      debugPrint('✅ Loaded ${branches.length} branches for $universityId');
    } catch (e) {
      _errorMessage = e.toString();
      _branchesByUniversity[universityId] = [];

      debugPrint('❌ Error loading branches for $universityId: $e');
    } finally {
      _isLoading = false;
      _loadingIds.remove(universityId);

      // Notify listeners after the current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isLoading == false) {
          notifyListeners();
        }
      });
    }
  }

  /// Load multiple universities' branches in batch
  Future<void> loadBranchesBatch(List<String> universityIds) async {
    // Filter out already loaded/loading/requested IDs
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
      // Load all branches in parallel (max 5 at a time)
      const batchSize = 5;
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

  /// Clear branch data
  void clearBranches() {
    debugPrint('🧹 Clearing all branches');
    _branchesByUniversity.clear();
    _loadingIds.clear();
    _requestedIds.clear();
    _repository.clearCache();
    notifyListeners();
  }

  /// Clear branches for a specific university
  void clearBranchesFor(String universityId) {
    debugPrint('🧹 Clearing branches for $universityId');
    _branchesByUniversity.remove(universityId);
    _loadingIds.remove(universityId);
    _requestedIds.remove(universityId);
    _repository.clearCacheFor(universityId);
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
    _repository.clearCache();
    super.dispose();
  }
}