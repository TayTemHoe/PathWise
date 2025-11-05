import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../model/program.dart';
import '../model/program_filter.dart';
import '../repository/program_repository.dart';
import '../services/firebase_service.dart';

class ProgramListViewModel extends ChangeNotifier {
  late final ProgramRepository _repository;

  ProgramListViewModel() {
    final firebaseService = FirebaseService();
    _repository = ProgramRepository(firebaseService);
  }

  List<ProgramModel> _programs = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  ProgramFilterModel _filter = ProgramFilterModel();
  List<ProgramModel> _compareList = [];

  // Performance tracking
  bool _initialLoadComplete = false;
  String? _lastSearchQuery;
  int _currentPage = 0;
  bool _isSuggestionLoading = false;
  List<String> _suggestions = [];

  bool get isSuggestionLoading => _isSuggestionLoading;
  List<String> get suggestions => _suggestions;
  List<ProgramModel> get programs => _programs;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  ProgramFilterModel get filter => _filter;
  List<ProgramModel> get compareList => _compareList;
  bool get canCompare => _compareList.length < 3;
  int get currentPage => _currentPage;

  /// Load programs with optimized pagination
  Future<void> loadPrograms({bool refresh = false}) async {
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
      _lastDocument = null;
      _hasMore = true;
      _initialLoadComplete = false;
      _currentPage = 0;
    }

    if (refresh || _programs.isEmpty) {
      notifyListeners();
    }

    try {
      debugPrint('🔥 Loading page ${_currentPage + 1}...');

      final (programs, lastDoc) = await _repository.getPrograms(
        limit: 10,
        lastDocument: _lastDocument,
        filter: _filter.hasActiveFilters ? _filter : null,
      );

      if (!_initialLoadComplete) {
        _initialLoadComplete = true;
      }

      if (programs.isEmpty) {
        _hasMore = false;
        debugPrint('🏁 No more programs to load');
      } else {
        // Filter out duplicates
        final existingIds = _programs.map((p) => p.programId).toSet();
        final newPrograms = programs
            .where((p) => !existingIds.contains(p.programId))
            .toList();

        if (newPrograms.isNotEmpty) {
          _programs.addAll(newPrograms);
          _lastDocument = lastDoc;
          _currentPage++;

          _hasMore = programs.length >= 10 && lastDoc != null;
        } else {
          _hasMore = false;
        }

        debugPrint('✅ Loaded ${newPrograms.length} new programs. Total: ${_programs.length}. Has more: $_hasMore');
      }
    } catch (e) {
      debugPrint('❌ Error loading programs: $e');
      _hasMore = false;

      if (_programs.isEmpty) {
        debugPrint('🚨 Critical: No programs loaded');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void applyUniversityFilter({
    required String universityId,
    required String universityName,
  }) {
    _filter = _filter.copyWith(
      universityIds: [universityId],
      universityName: universityName,
    );
    loadPrograms(refresh: true);
  }

  /// Apply filter and reload from scratch
  void applyFilter(ProgramFilterModel filter) {
    debugPrint('🔍 Applying filter: ${filter.toJson()}');

    if (_filter == filter) {
      debugPrint('⏸️ Filter unchanged, skipping reload');
      return;
    }

    _filter = filter;
    _lastSearchQuery = null;
    _initialLoadComplete = false;

    _programs.clear();
    _lastDocument = null;
    _hasMore = true;
    _currentPage = 0;

    loadPrograms(refresh: true);
  }

  /// Clear all filters and reload
  void clearFilter() {
    debugPrint('🧹 Clearing all filters');

    _filter = ProgramFilterModel();
    _lastSearchQuery = null;
    _initialLoadComplete = false;

    loadPrograms(refresh: true);
  }

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
      debugPrint('🔍 Fetching suggestions for "$query"');

      final List<ProgramModel> suggestions =
      await _repository.searchPrograms(query, limit: 5);

      _suggestions = suggestions
          .map((program) => program.programName)
          .toList();
    } catch (e) {
      debugPrint('Error fetching search suggestions: $e');
      _suggestions = [];
    } finally {
      _isSuggestionLoading = false;
      notifyListeners();
    }
  }

  /// Apply search query
  void applySearch(String query) {
    if (query.trim().isEmpty) {
      clearSearch();
      return;
    }

    if (_lastSearchQuery == query.trim()) {
      debugPrint('⏸️ Same search query, skipping...');
      return;
    }

    debugPrint('🔎 Applying search: "$query"');
    _lastSearchQuery = query.trim();
    _filter = _filter.copyWith(searchQuery: _lastSearchQuery);
    _initialLoadComplete = false;

    loadPrograms(refresh: true);
  }

  /// Clear search query
  void clearSearch() {
    debugPrint('🧹 Clearing search');

    if (_lastSearchQuery == null) {
      return;
    }

    _lastSearchQuery = null;
    _filter = _filter.copyWith(clearSearch: true);
    _initialLoadComplete = false;

    loadPrograms(refresh: true);
  }

  /// Remove individual filters
  void removeSearchFilter() {
    debugPrint('🧹 Removing search filter');
    _filter = _filter.copyWith(clearSearch: true);
    _initialLoadComplete = false;
    loadPrograms(refresh: true);
  }

  void removeSubjectAreaFilter() {
    debugPrint('🧹 Removing subject area filter');
    _filter = _filter.copyWith(clearSubjectArea: true);
    _initialLoadComplete = false;
    loadPrograms(refresh: true);
  }

  void removeStudyModesFilter() {
    debugPrint('🧹 Removing study modes filter');
    _filter = _filter.copyWith(clearStudyModes: true);
    _initialLoadComplete = false;
    loadPrograms(refresh: true);
  }

  void removeStudyLevelsFilter() {
    debugPrint('🧹 Removing study levels filter');
    _filter = _filter.copyWith(clearStudyLevels: true);
    _initialLoadComplete = false;
    loadPrograms(refresh: true);
  }

  void removeIntakeMonthsFilter() {
    debugPrint('🧹 Removing intake months filter');
    _filter = _filter.copyWith(clearIntakeMonths: true);
    _initialLoadComplete = false;
    loadPrograms(refresh: true);
  }

  void removeRankingFilter() {
    debugPrint('🧹 Removing ranking filter');
    _filter = _filter.copyWith(clearRanking: true);
    _initialLoadComplete = false;
    loadPrograms(refresh: true);
  }

  void removeRankingSortFilter() {
    debugPrint('🧹 Removing ranking sort filter');
    _filter = _filter.copyWith(clearRankingSort: true);
    _initialLoadComplete = false;
    loadPrograms(refresh: true);
  }

  void removeDurationFilter() {
    debugPrint('🧹 Removing duration filter');
    _filter = _filter.copyWith(clearDuration: true);
    _initialLoadComplete = false;
    loadPrograms(refresh: true);
  }

  void removeUniversityFilter() {
    debugPrint('🧹 Removing university filter');
    _filter = _filter.copyWith(clearUniversity: true);
    _initialLoadComplete = false;
    loadPrograms(refresh: true);
  }

  void removeTuitionFilter() {
    debugPrint('🧹 Removing tuition filter');
    _filter = _filter.copyWith(clearTuition: true);
    _initialLoadComplete = false;
    loadPrograms(refresh: true);
  }

  /// Compare list management (max 3 programs)
  void toggleCompare(ProgramModel program) {
    final index = _compareList.indexWhere((p) => p.programId == program.programId);

    if (index != -1) {
      _compareList.removeAt(index);
      debugPrint('➖ Removed ${program.programName} from compare list');
    } else if (_compareList.length < 3) {
      _compareList.add(program);
      debugPrint('➕ Added ${program.programName} to compare list');
    } else {
      debugPrint('⚠️ Compare list is full (3 programs)');
    }

    notifyListeners();
  }

  void clearCompare() {
    debugPrint('🧹 Clearing compare list');
    _compareList.clear();
    notifyListeners();
  }

  bool isInCompareList(String programId) {
    return _compareList.any((p) => p.programId == programId);
  }

  /// Force refresh - useful for pull-to-refresh
  Future<void> forceRefresh() async {
    debugPrint('🔄 Force refresh triggered');
    _initialLoadComplete = false;
    await loadPrograms(refresh: true);
  }

  /// Get loading progress text
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

  @override
  void dispose() {
    debugPrint('🗑️ ProgramListViewModel disposed');
    _programs.clear();
    _compareList.clear();
    super.dispose();
  }
}