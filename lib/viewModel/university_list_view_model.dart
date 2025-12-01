// lib/viewModel/university_list_view_model_v2.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../model/comparison.dart';
import '../model/university_filter.dart';
import '../model/university.dart';
import '../repository/comparison_repository.dart';
import '../repository/university_repository.dart';

class UniversityListViewModel extends ChangeNotifier {
  final UniversityRepository _repository = UniversityRepository();
  final ComparisonRepository _comparisonRepo = ComparisonRepository.instance;

  List<UniversityModel> _universities = [];
  bool _isLoading = false;
  bool _hasMore = true;
  UniversityFilterModel _filter = const UniversityFilterModel(
    shouldDefaultToMalaysia: true,
  );
  Set<String> _compareSet = {};
  String _currentSyncTable = '';

  // Pagination
  int _currentPage = 0;
  static const int PAGE_SIZE = 10;

  // Search
  bool _isSuggestionLoading = false;
  List<String> _suggestions = [];

  // Sync status
  bool _needsInitialSync = false;
  bool _isSyncing = false;
  double _syncProgress = 0.0;

  //Compare
  String? _userId;

  // Getters
  List<UniversityModel> get universities => _universities;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  UniversityFilterModel get filter => _filter;
  List<UniversityModel> get compareList =>
      _universities.where((u) => _compareSet.contains(u.universityId)).toList();
  int get compareCount => _compareSet.length;

  bool get canCompare => _compareSet.length < 3;
  int get currentPage => _currentPage;
  bool get isSuggestionLoading => _isSuggestionLoading;
  List<String> get suggestions => _suggestions;
  bool get needsInitialSync => _needsInitialSync;
  bool get isSyncing => _isSyncing;
  double get syncProgress => _syncProgress;
  String get currentTable => _currentSyncTable;

  UniversityListViewModel() {
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
      await loadComparisonState();  // Load state immediately
      notifyListeners();  // CRITICAL: Notify listeners
    } else {
      debugPrint('⚠️ No user logged in during initialization');
      notifyListeners();  // Still notify even if no user
    }
  }

  // ==================== INITIALIZATION ====================

  /// Initialize and check sync status
  Future<void> initialize() async {
    try {
      debugPrint('🔧 Initializing UniversityListViewModel...');

      // Check if initial sync is needed
      _needsInitialSync = await _repository.needsInitialSync();

      if (_needsInitialSync) {
        debugPrint('⚠️ Initial sync required');
        notifyListeners();

        // Perform initial sync
        await performInitialSync();
      } else {
        debugPrint('✅ Data already synced, loading universities...');
        await loadUniversities(refresh: true);
      }
    } catch (e) {
      debugPrint('❌ Error during initialization: $e');
    }
  }

  // ==================== SYNC OPERATIONS ====================

  /// Perform initial sync from Firebase
  Future<void> performInitialSync() async {
    if (_isSyncing) return;

    _isSyncing = true;
    _syncProgress = 0.0;
    _currentSyncTable = '';
    notifyListeners();

    try {
      debugPrint('🔄 Starting initial sync...');

      await _repository.performInitialSync(
        onProgress: (table, progress) {
          _syncProgress = progress;
          _currentSyncTable = table;
          debugPrint('📊 Syncing $table: ${(progress * 100).toStringAsFixed(0)}%');
          notifyListeners();
        },
      );

      _needsInitialSync = false;
      _syncProgress = 1.0;

      debugPrint('✅ Initial sync completed');

      // Load data after sync
      await loadUniversities(refresh: true);
    } catch (e) {
      debugPrint('❌ Initial sync failed: $e');
    } finally {
      _isSyncing = false;
      _currentSyncTable = '';
      notifyListeners();
    }
  }

  /// Perform incremental sync
  Future<void> performIncrementalSync() async {
    if (_isSyncing) return;

    _isSyncing = true;
    _syncProgress = 0.0;
    _currentSyncTable = '';
    notifyListeners();

    try {
      debugPrint('🔄 Starting incremental sync...');

      await _repository.performIncrementalSync(
        onProgress: (table, progress) {
          _syncProgress = progress;
          _currentSyncTable = table;
          notifyListeners();
        },
      );

      _syncProgress = 1.0;

      debugPrint('✅ Incremental sync completed');

      // Refresh current view
      await loadUniversities(refresh: true);
    } catch (e) {
      debugPrint('❌ Incremental sync failed: $e');
    } finally {
      _isSyncing = false;
      _currentSyncTable = '';
      notifyListeners();
    }
  }

  // ==================== DATA LOADING ====================

  /// Load universities with pagination
  Future<void> loadUniversities({bool refresh = false}) async {
    if (_isLoading) {
      debugPrint('⏸️ Already loading, skipping...');
      return;
    }

    if (!refresh && !_hasMore) {
      debugPrint('⏸️ No more universities to load');
      return;
    }

    _isLoading = true;

    if (refresh) {
      _universities.clear();
      _currentPage = 0;
      _hasMore = true;
    }

    notifyListeners();

    try {
      debugPrint('🔥 Loading universities page $_currentPage...');
      debugPrint('   - Current filter: ${_filter.toJson()}');

      // Load universities from repository
      final (loadedUniversities, hasMore) = await _repository.getUniversities(
        page: _currentPage,
        pageSize: PAGE_SIZE,
        filter: _filter,
      );

      // ✅ CRITICAL: Assign country ranks based on filter context
      final processedUniversities = _assignCountryRanks(loadedUniversities);

      if (processedUniversities.isNotEmpty) {
        // Filter out duplicates
        final existingIds = _universities.map((u) => u.universityId).toSet();
        final newUniversities = processedUniversities
            .where((u) => !existingIds.contains(u.universityId))
            .toList();

        if (newUniversities.isNotEmpty) {
          _universities.addAll(newUniversities);
          _currentPage++;
          _hasMore = hasMore;

          debugPrint(
            '✅ Loaded ${newUniversities.length} universities. Total: ${_universities.length}',
          );
        } else {
          _hasMore = hasMore;
        }
      } else {
        _hasMore = false;
        debugPrint('🏁 No more universities to load');
      }
    } catch (e) {
      debugPrint('❌ Error loading universities: $e');
      _hasMore = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<UniversityModel> _assignCountryRanks(List<UniversityModel> universities) {
    // Check if BOTH country and Top N filters are active
    final isCountryFiltered = _filter.country != null && _filter.country!.isNotEmpty;
    final hasTopNFilter = _filter.topN != null;
    final isCityFiltered = _filter.city != null && _filter.city!.isNotEmpty;

    debugPrint('🔍 Country Filter: $isCountryFiltered, Top N Filter: $hasTopNFilter');

    // ✅ ONLY assign country ranks when BOTH filters are active
    if (hasTopNFilter && (isCountryFiltered || isCityFiltered)) {

      // Conditional debug prints to handle cases where one might be null
      if (isCountryFiltered) debugPrint('✅ Assigning country ranks for ${_filter.country}');
      if (isCityFiltered) debugPrint('✅ Assigning city ranks for ${_filter.city}');

      // Universities are already sorted by world ranking (min_ranking ASC)
      // Assign sequential ranks relative to this specific filtered list: 1, 2, 3...
      return universities.asMap().entries.map((entry) {
        final index = entry.key;
        final university = entry.value;

        // Calculate rank based on pagination
        final rank = (_currentPage * PAGE_SIZE) + index + 1;

        debugPrint(
          '   ${university.universityName}: World Rank ${university.minRanking} → Rank $rank',
        );

        // Reuse the 'countryRank' field to store this specific local rank
        return university.copyWith(countryRank: rank);
      }).toList();
    }

    // ✅ When ONLY Top N filter is active (no country), clear country ranks
    if (!isCountryFiltered && hasTopNFilter) {
      debugPrint('🌍 Global Top ${_filter.topN} mode - clearing country ranks');
      return universities.map((u) => u.copyWith(countryRank: null)).toList();
    }

    // ✅ No Top N filter - clear country ranks
    debugPrint('⚪ No Top N filter - clearing country ranks');
    return universities.map((u) => u.copyWith(countryRank: null)).toList();
  }

  Future<int> getProgramCount(String universityId) async {
    try {
      return await _repository.getProgramCount(universityId);
    } catch (e) {
      debugPrint('❌ Error getting program count from uni list view model: $e');
      return 0;
    }
  }

  // ==================== FILTERS ====================

  /// Apply filter
  void applyFilter(UniversityFilterModel newFilter) {
    debugPrint('🔍 Applying new filter: $newFilter');

    // --- CRITICAL FIX: The ViewModel uses the model's check to set the flag ---
    final isActive = newFilter.hasActiveFilters; // Get state from the model

    // If ACTIVE, shouldDefaultToMalaysia = false (show world/custom list).
    // If NOT ACTIVE (i.e., filter is empty/cleared), shouldDefaultToMalaysia = true (revert to Malaysia).
    _filter = newFilter.copyWith(
      shouldDefaultToMalaysia: isActive ? false : true,
    );
    // -----------------------------------------------------------------------

    _currentPage = 0;
    _universities = [];
    _hasMore = true;
    loadUniversities(refresh: true);
  }

  /// Clear all filters
  void clearFilter() {
    debugPrint('🧹 Clearing all filters');
    _filter = const UniversityFilterModel(
      shouldDefaultToMalaysia: true,
    );
    loadUniversities(refresh: true);
  }

  /// Remove individual filters
  void removeSearchFilter() {
    final newFilter = _filter.copyWith(clearSearch: true);
    applyFilter(newFilter);
  }

  void removeTopNFilter() {
    final newFilter = _filter.copyWith(clearTopN: true);
    applyFilter(newFilter);
  }

  void removeRankingSortFilter() {
    final newFilter = _filter.copyWith(clearRankingSort: true);
    applyFilter(newFilter);
  }

  void removeStudentFilter() {
    final newFilter = _filter.copyWith(clearStudents: true);
    applyFilter(newFilter);
  }

  void removeFeesFilter() {
    final newFilter = _filter.copyWith(clearTuition: true);
    applyFilter(newFilter);
  }

  void removeCountryFilter() {
    final newFilter = _filter.copyWith(clearCountry: true, clearCity: true);
    applyFilter(newFilter);
  }

  void removeCityFilter() {
    final newFilter = _filter.copyWith(clearCity: true);
    applyFilter(newFilter);
  }

  void removeInstitutionTypeFilter() {
    final newFilter = _filter.copyWith(clearInstitutionType: true);
    applyFilter(newFilter);
  }

  // ==================== SEARCH ====================

  /// Fetch search suggestions
  Future<void> fetchSearchSuggestions(String query) async {
    if (query.isEmpty) {
      _suggestions = [];
      notifyListeners();
      return;
    }

    _isSuggestionLoading = true;
    notifyListeners();

    try {
      final universities = await _repository.searchUniversities(query, limit: 5);
      _suggestions = universities.map((u) => u.universityName).toList();
    } catch (e) {
      debugPrint('❌ Error fetching suggestions: $e');
      _suggestions = [];
    } finally {
      _isSuggestionLoading = false;
      notifyListeners();
    }
  }

  /// Apply search
  void applySearch(String query) {
    if (query.trim().isEmpty) {
      clearSearch();
      return;
    }

    debugPrint('🔎 Applying search: "$query"');
    _filter = _filter.copyWith(searchQuery: query.trim());
    loadUniversities(refresh: true);
  }

  /// Clear search
  void clearSearch() {
    debugPrint('🧹 Clearing search');
    _filter = _filter.copyWith(clearSearch: true);
    loadUniversities(refresh: true);
  }

  // ==================== COMPARE ====================
  Future<void> toggleCompare(UniversityModel university) async {
    // ADD THIS BLOCK
    if (_userId == null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _userId = user.uid;
      } else {
        debugPrint('⚠️ User not logged in');
        return;
      }
    }

    final isInList = _compareSet.contains(university.universityId);

    if (isInList) {
      // Remove from comparison
      await _comparisonRepo.removeFromComparison(
        userId: _userId!,
        itemId: university.universityId,
      );

      _compareSet.remove(university.universityId);
      debugPrint('➖ Removed ${university.universityName} from compare');
    } else if (_compareSet.length < 3) {
      // Add to comparison
      final item = ComparisonItem(
        id: university.universityId,
        name: university.universityName,
        logoUrl: university.universityLogo,
        type: ComparisonType.universities,
      );

      final success = await _comparisonRepo.addToComparison(
        userId: _userId!,
        item: item,
      );

      if (success) {
        _compareSet.add(university.universityId);
        await _comparisonRepo.getUniversityDetails(university.universityId);
        debugPrint('➕ Added ${university.universityName} to compare');
      }
    } else {
      debugPrint('⚠️ Compare list is full (max 3)');
    }

    notifyListeners();
  }

  Future<void> loadComparisonState() async {
    if (_userId == null) return;

    try {
      final items = await _comparisonRepo.getComparisonItems(
        userId: _userId!,
        type: ComparisonType.universities,
      );

      // Store only IDs, not full models
      _compareSet = items.map((item) => item.id).toSet();

      debugPrint('✅ Loaded ${_compareSet.length} universities in comparison');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading university comparison state: $e');
    }
  }

  void clearCompare() async {
    if (_userId == null) return;

    await _comparisonRepo.clearComparisonByType(
      userId: _userId!,
      type: ComparisonType.universities,
    );

    _compareSet.clear();
    notifyListeners();
  }

  bool isInCompareList(String universityId) {
    return _compareSet.contains(universityId);
  }

  // ==================== UTILITY ====================

  /// Force refresh
  Future<void> forceRefresh() async {
    debugPrint('🔄 Force refresh triggered');
    await loadUniversities(refresh: true);
  }

  /// Get loading status
  String getLoadingStatus() {
    if (_isSyncing) {
      return 'Syncing data... ${(_syncProgress * 100).toStringAsFixed(0)}%';
    } else if (_isLoading && _universities.isEmpty) {
      return 'Loading Universities...';
    } else if (_isLoading) {
      return 'Loading more universities...';
    } else if (!_hasMore && _universities.isNotEmpty) {
      return 'All universities loaded';
    } else {
      return '${_universities.length} universities loaded';
    }
  }

  /// Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    return await _repository.getSyncStatus();
  }

  List<ComparisonItem> getComparisonItems() {
    // Fetch full details only for items in compare set
    return _universities
        .where((u) => _compareSet.contains(u.universityId))
        .map((university) {
      return ComparisonItem(
        id: university.universityId,
        name: university.universityName,
        logoUrl: university.universityLogo,
        type: ComparisonType.universities,
      );
    }).toList();
  }

  @override
  void dispose() {
    debugPrint('🗑️ UniversityListViewModel disposed');
    _repository.clearMemoryCache();
    _universities.clear();
    _compareSet.clear(); // Changed from _compareList
    super.dispose();
  }
}