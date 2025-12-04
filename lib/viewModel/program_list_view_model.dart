// lib/viewModel/program_list_view_model_v2.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path_wise/viewModel/comparison_view_model.dart';
import '../model/ai_match_model.dart';
import '../model/branch.dart';
import '../model/comparison.dart';
import '../model/program.dart';
import '../model/program_filter.dart';
import '../model/university.dart';
import '../repository/program_repository.dart';
import '../repository/comparison_repository.dart';
import '../services/local_data_source.dart';

class ProgramListViewModel extends ChangeNotifier {
  final ProgramRepository _repository = ProgramRepository();
  final LocalDataSource _localDataSource = LocalDataSource.instance;
  final ComparisonRepository _comparisonRepo = ComparisonRepository.instance;

  List<ProgramModel> _programs = [];
  bool _isLoading = false;
  bool _hasMore = true;
  ProgramFilterModel _filter = ProgramFilterModel();
  bool _isAIFilterActive = false;
  Set<String>? _matchedProgramIds; // AI matched program IDs

  // Track comparison items in memory for quick access
  Set<String> _compareSet = {};
  String? _userId;

  // Track Malaysian branch IDs for initial filter
  Set<String>? _malaysianBranchIds;
  bool _isInitialLoad = true;

  // Pagination
  int _currentPage = 0;
  static const int PAGE_SIZE = 10;

  // Search
  bool _isSuggestionLoading = false;
  List<String> _suggestions = [];

  // Getters
  List<ProgramModel> get programs => _programs;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  ProgramFilterModel get filter => _filter;
  bool get isAIFilterActive => _isAIFilterActive;

  /// Get comparison list
  List<ProgramModel> get compareList =>
      _programs.where((p) => _compareSet.contains(p.programId)).toList();
  int get compareCount => _compareSet.length;

  bool get canCompare => _compareSet.length < 3;
  int get currentPage => _currentPage;
  bool get isSuggestionLoading => _isSuggestionLoading;
  List<String> get suggestions => _suggestions;

  // ==================== INITIALIZATION ====================

  ProgramListViewModel() {
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
      await loadComparisonState();
      notifyListeners();
    }
  }

  /// Load comparison state from SQLite
  Future<void> loadComparisonState() async {
    if (_userId == null) return;

    try {
      final items = await _comparisonRepo.getComparisonItems(
        userId: _userId!,
        type: ComparisonType.programs,
      );

      _compareSet = items.map((item) => item.id).toSet();
      debugPrint('✅ Loaded ${_compareSet.length} programs in comparison');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading comparison state: $e');
    }
  }

  /// Initialize Malaysian branch IDs
  Future<void> _initializeMalaysianBranches() async {
    if (_malaysianBranchIds != null) return;

    try {
      debugPrint('🔄 Loading Malaysian branch IDs...');
      _malaysianBranchIds = await _localDataSource.getMalaysianBranchIds();
      debugPrint('✅ Loaded ${_malaysianBranchIds!.length} Malaysian branches');
    } catch (e) {
      debugPrint('❌ Error loading Malaysian branches: $e');
      _malaysianBranchIds = {};
    }
  }

  // ==================== DATA LOADING ====================
  Future<Set<String>> getMalaysianBranchIds() async {
    if (_malaysianBranchIds != null) {
      return _malaysianBranchIds!;
    }
    await _initializeMalaysianBranches();
    return _malaysianBranchIds!;
  }

  /// ✅ NEW: Load programs by AI matched IDs
  Future<void> loadProgramsByIds(List<String> programIds, {bool refresh = false}) async {
    if (_isLoading) {
      debugPrint('⏸️ Already loading, skipping...');
      return;
    }

    _isLoading = true;

    if (refresh) {
      debugPrint('🔄 Refresh triggered - clearing existing programs');
      _programs.clear();
      _currentPage = 0;
      _hasMore = true;
    }

    notifyListeners();

    try {
      debugPrint('🎯 Loading AI-matched programs (Total: ${programIds.length}, Current: ${_programs.length})');

      // Calculate pagination
      final startIndex = _currentPage * PAGE_SIZE;
      final endIndex = (startIndex + PAGE_SIZE).clamp(0, programIds.length);

      if (startIndex >= programIds.length) {
        debugPrint('🛑 No more programs to load (startIndex: $startIndex >= total: ${programIds.length})');
        _hasMore = false;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final pageIds = programIds.sublist(startIndex, endIndex);
      debugPrint('📄 Loading page $_currentPage: IDs ${startIndex + 1} to $endIndex');
      debugPrint('📋 Program IDs to fetch: $pageIds');

      // Fetch programs by ID
      final List<ProgramModel> fetchedPrograms = [];
      for (final programId in pageIds) {
        final program = await _repository.getProgramById(programId);
        if (program != null) {
          fetchedPrograms.add(program);
          debugPrint('  ✓ Loaded: ${program.programName}');
        } else {
          debugPrint('  ✗ Program $programId not found in database');
        }
      }

      if (fetchedPrograms.isNotEmpty) {
        _programs.addAll(fetchedPrograms);
        _currentPage++;
        _hasMore = endIndex < programIds.length;

        debugPrint('✅ Loaded ${fetchedPrograms.length} programs. Total: ${_programs.length}/${programIds.length}');
        debugPrint('📊 Has more: $_hasMore (endIndex: $endIndex < total: ${programIds.length})');
      } else {
        debugPrint('⚠️ No programs were fetched');
        _hasMore = false;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading programs by IDs: $e');
      debugPrint('Stack trace: $stackTrace');
      _hasMore = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load programs with pagination (existing method)
  Future<void> loadPrograms({bool refresh = false}) async {
    // ✅ If AI matched IDs are set, use loadProgramsByIds instead
    if (_matchedProgramIds != null && _matchedProgramIds!.isNotEmpty) {
      await loadProgramsByIds(_matchedProgramIds!.toList(), refresh: refresh);
      return;
    }

    if (_isLoading) {
      debugPrint('⏸️ Already loading, skipping...');
      return;
    }

    if (!refresh && !_hasMore) {
      debugPrint('⏸️ No more programs to load');
      return;
    }

    _isLoading = true;

    if (refresh) {
      _programs.clear();
      _currentPage = 0;
      _hasMore = true;
    }

    notifyListeners();

    try {
      // Initialize Malaysian branches on first load
      if (_malaysianBranchIds == null) {
        await _initializeMalaysianBranches();
      }

      // Build the effective filter
      ProgramFilterModel effectiveFilter = _filter;

      final hasLocationFilter = _filter.countries.isNotEmpty ||
          _filter.universityIds.isNotEmpty ||
          _filter.universityName != null;

      if (_isAIFilterActive) {
        // AI filter takes priority
        debugPrint('Using AI-generated filter');
        effectiveFilter = _filter;
      } else if (_isInitialLoad && !_filter.hasActiveFilters) {
        // First load: show Malaysian programs only
        debugPrint('🇲🇾 Initial load: Malaysian programs only');
        effectiveFilter = ProgramFilterModel(
          malaysianBranchIds: _malaysianBranchIds,
          rankingSortOrder: 'asc',
        );
      } else if (_filter.hasActiveFilters) {
        // User applied filters
        if (hasLocationFilter || _filter.countries.isNotEmpty) {
          // Location-specific: respect user's choice
          debugPrint('📍 User-defined location filter');
          effectiveFilter = _filter;
        } else {
          // Non-location filters should show ALL programs
          debugPrint('🌍 Showing all programs with user filters');
          effectiveFilter = _filter.copyWith(
            malaysianBranchIds: null,
          );
        }
      } else {
        // After clearing: return to Malaysian default
        debugPrint('🇲🇾 Reset to Malaysian programs');
        effectiveFilter = ProgramFilterModel(
          malaysianBranchIds: _malaysianBranchIds,
          rankingSortOrder: 'asc',
        );
      }

      debugPrint('🔥 Loading programs page $_currentPage...');
      debugPrint('📊 Filter: ${effectiveFilter.toJson()}');

      final (programs, hasMore) = await _repository.getPrograms(
        page: _currentPage,
        pageSize: PAGE_SIZE,
        filter: effectiveFilter,
      );

      if (programs.isNotEmpty) {
        final existingIds = _programs.map((p) => p.programId).toSet();
        final newPrograms = programs
            .where((p) => !existingIds.contains(p.programId))
            .toList();

        if (newPrograms.isNotEmpty) {
          _programs.addAll(newPrograms);
          _currentPage++;
          _hasMore = hasMore;

          debugPrint('✅ Loaded ${newPrograms.length} programs. Total: ${_programs.length}');
        } else {
          _hasMore = false;
        }
      } else {
        _hasMore = false;
        debugPrint('🛑 No more programs to load');
      }

      // Mark initial load as complete
      if (_isInitialLoad) {
        _isInitialLoad = false;
      }
    } catch (e) {
      debugPrint('❌ Error loading programs: $e');
      _hasMore = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UniversityModel?> getUniversityForProgram(String universityId) async {
    try {
      return await _repository.getUniversityForProgram(universityId);
    } catch (e) {
      debugPrint('❌ Error loading university $universityId: $e');
      return null;
    }
  }

  /// Get branch details for a program
  Future<BranchModel?> getBranchForProgram(String branchId) async {
    try {
      return await _repository.getBranchForProgram(branchId);
    } catch (e) {
      debugPrint('❌ Error loading branch $branchId: $e');
      return null;
    }
  }

  // ==================== FILTERS ====================

  /// Apply filter
  void applyFilter(ProgramFilterModel filter) {
    debugPrint('🔍 Applying filter: ${filter.toJson()}');

    if (_filter == filter) {
      debugPrint('⏸️ Filter unchanged, skipping reload');
      return;
    }

    _filter = filter;
    _isInitialLoad = false;
    _isAIFilterActive = false;
    _matchedProgramIds = null; // Clear AI matched IDs when applying manual filter
    loadPrograms(refresh: true);
  }

  Future<void> applyAIRecommendationFilter({
    required List<String> subjectAreas,
    required UserPreferences preferences,
  }) async {
    try {
      debugPrint('🎯 Applying AI recommendation filter...');

      // Get branch IDs based on user's country preferences
      Set<String>? countryBranchIds;
      if (preferences.locations.isNotEmpty) {
        countryBranchIds = await _repository.getBranchIdsByCountries(preferences.locations);
        debugPrint('🌍 Filtering ${countryBranchIds.length} branches from ${preferences.locations.join(", ")}');
      }

      final aiFilter = ProgramFilterModel(
        subjectArea: subjectAreas,
        studyLevels: preferences.studyLevel,
        studyModes: preferences.mode,
        minTuitionFeeMYR: preferences.tuitionMin,
        maxTuitionFeeMYR: preferences.tuitionMax,
        topN: preferences.maxRanking,
        malaysianBranchIds: countryBranchIds,
        countries: preferences.locations,
        rankingSortOrder: 'asc',
      );

      _isAIFilterActive = true;
      _isInitialLoad = false;

      applyFilter(aiFilter);

      debugPrint('✅ AI filter applied successfully');
    } catch (e) {
      debugPrint('❌ Error applying AI filter: $e');
      rethrow;
    }
  }

  /// ✅ NEW: Reset state for AI mode
  void resetToAIMode() {
    debugPrint('🔄 Resetting ViewModel to AI mode');
    _programs.clear();
    _currentPage = 0;
    _hasMore = true;
    _isLoading = false;
    _filter = ProgramFilterModel();
    _isAIFilterActive = true;
    _isInitialLoad = false;
    _matchedProgramIds = null;
    notifyListeners();
  }

  /// ✅ NEW: Set AI matched program IDs and trigger load
  void setAIMatchedPrograms(List<String> programIds) {
    _matchedProgramIds = programIds.toSet();
    _isAIFilterActive = true;
    _isInitialLoad = false;
    debugPrint('📌 Set ${_matchedProgramIds!.length} AI-matched program IDs');

    // Immediately load the first page
    loadPrograms(refresh: true);
  }

  void removeCountriesFilter() {
    _filter = _filter.copyWith(clearCountries: true);
    _checkIfShouldReturnToInitialState();
    loadPrograms(refresh: true);
  }

  /// Apply university filter (from University Card)
  void applyUniversityFilter({
    required String universityId,
    required String universityName,
  }) {
    debugPrint('🏛️ Filtering programs for university: $universityName');

    _filter = ProgramFilterModel(
      universityIds: [universityId],
      universityName: universityName,
    );
    _isInitialLoad = false;
    _matchedProgramIds = null; // Clear AI matched IDs
    loadPrograms(refresh: true);
  }

  /// Clear all filters and return to Malaysian programs
  void clearFilter() {
    debugPrint('🧹 Clearing all filters - returning to Malaysian programs');

    _filter = ProgramFilterModel();
    _isInitialLoad = true;
    _isAIFilterActive = false;
    _matchedProgramIds = null; // Clear AI matched IDs
    loadPrograms(refresh: true);
  }

  /// Remove individual filters
  void removeSearchFilter() {
    _filter = _filter.copyWith(clearSearch: true);
    _checkIfShouldReturnToInitialState();
    loadPrograms(refresh: true);
  }

  void removeSubjectAreaFilter() {
    _filter = _filter.copyWith(clearSubjectArea: true);
    _checkIfShouldReturnToInitialState();
    loadPrograms(refresh: true);
  }

  void removeStudyModesFilter() {
    _filter = _filter.copyWith(clearStudyModes: true);
    _checkIfShouldReturnToInitialState();
    loadPrograms(refresh: true);
  }

  void removeStudyLevelsFilter() {
    _filter = _filter.copyWith(clearStudyLevels: true);
    _checkIfShouldReturnToInitialState();
    loadPrograms(refresh: true);
  }

  void removeIntakeMonthsFilter() {
    _filter = _filter.copyWith(clearIntakeMonths: true);
    _checkIfShouldReturnToInitialState();
    loadPrograms(refresh: true);
  }

  void removeTopNFilter() {
    _filter = _filter.copyWith(clearTopN: true);
    _checkIfShouldReturnToInitialState();
    loadPrograms(refresh: true);
  }

  void removeRankingSortFilter() {
    _filter = _filter.copyWith(clearRankingSort: true);
    _checkIfShouldReturnToInitialState();
    loadPrograms(refresh: true);
  }

  void removeDurationFilter() {
    _filter = _filter.copyWith(clearDuration: true);
    _checkIfShouldReturnToInitialState();
    loadPrograms(refresh: true);
  }

  void removeUniversityFilter() {
    _filter = _filter.copyWith(clearUniversity: true);
    _checkIfShouldReturnToInitialState();
    loadPrograms(refresh: true);
  }

  void removeTuitionFilter() {
    _filter = _filter.copyWith(clearTuition: true);
    _checkIfShouldReturnToInitialState();
    loadPrograms(refresh: true);
  }

  /// Check if we should return to initial Malaysian state
  void _checkIfShouldReturnToInitialState() {
    if (!_filter.hasActiveFilters && _matchedProgramIds == null) {
      debugPrint('🇲🇾 No active filters - returning to Malaysian programs');
      _isInitialLoad = true;
    } else {
      debugPrint('📍 Active filters present - maintaining current state');
    }
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
      final programs = await _repository.searchPrograms(query, limit: 5);
      _suggestions = programs.map((p) => p.programName).toList();
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
    _isInitialLoad = false;
    _matchedProgramIds = null; // Clear AI matched IDs when searching
    loadPrograms(refresh: true);
  }

  /// Clear search
  void clearSearch() {
    debugPrint('🧹 Clearing search');
    _filter = _filter.copyWith(clearSearch: true);
    _checkIfShouldReturnToInitialState();
    loadPrograms(refresh: true);
  }

  // ==================== COMPARE ====================

  List<ComparisonItem> getComparisonItems() {
    return compareList.map((program) {
      return ComparisonItem(
        id: program.programId,
        name: program.programName,
        logoUrl: null,
        type: ComparisonType.programs,
      );
    }).toList();
  }

  Future<void> toggleCompare(ProgramModel program) async {
    if (_userId == null) {
      debugPrint('⚠️ User not logged in');
      return;
    }

    final isInList = _compareSet.contains(program.programId);

    if (isInList) {
      await _comparisonRepo.removeFromComparison(
        userId: _userId!,
        itemId: program.programId,
      );

      _compareSet.remove(program.programId);
      debugPrint('➖ Removed ${program.programName} from compare');
    } else if (_compareSet.length < 3) {
      final item = ComparisonItem(
        id: program.programId,
        name: program.programName,
        logoUrl: program.programUrl,
        type: ComparisonType.programs,
      );

      final success = await _comparisonRepo.addToComparison(
        userId: _userId!,
        item: item,
      );

      if (success) {
        _compareSet.add(program.programId);
        debugPrint('➕ Added ${program.programName} to compare');
      }
    } else {
      debugPrint('⚠️ Compare list is full (max 3)');
    }

    notifyListeners();
  }

  void clearCompare() async {
    if (_userId == null) return;

    await _comparisonRepo.clearComparisonByType(
      userId: _userId!,
      type: ComparisonType.programs,
    );

    _compareSet.clear();
    notifyListeners();
  }

  bool isInCompareList(String programId) {
    return _compareSet.contains(programId);
  }

  // ==================== UTILITY ====================

  /// Force refresh
  Future<void> forceRefresh() async {
    debugPrint('🔄 Force refresh triggered');
    await loadComparisonState();
    await loadPrograms(refresh: true);
  }

  /// Get loading status
  String getLoadingStatus() {
    if (_isLoading && _programs.isEmpty) {
      return 'Loading Programs...';
    } else if (_isLoading) {
      return 'Loading more programs...';
    } else if (!_hasMore && _programs.isNotEmpty) {
      return 'All programs loaded';
    } else {
      return '${_programs.length} programs loaded';
    }
  }

  void resetUserSpecificData() {
    _compareSet.clear();
    _userId = null;
    _matchedProgramIds = null;
    _isAIFilterActive = false;
    notifyListeners();
    debugPrint('🧹 ProgramList ViewModel user data reset');
  }

  @override
  void dispose() {
    debugPrint('🗑️ ProgramListViewModel disposed');
    _repository.clearMemoryCache();
    _programs.clear();
    _compareSet.clear();
    super.dispose();
  }
}