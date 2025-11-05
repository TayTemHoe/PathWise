// lib/viewModel/university_list_view_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path_wise/services/firebase_service.dart';

import '../model/university_filter.dart';
import '../model/university.dart';
import '../repository/university_repository.dart';

class UniversityListViewModel extends ChangeNotifier {
  late final UniversityRepository _repository;

  UniversityListViewModel() {
    final firebaseService = FirebaseService();
    _repository = UniversityRepository(firebaseService);
  }

  List<UniversityModel> _universities = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  FilterModel _filter = FilterModel();
  List<UniversityModel> _compareList = [];

  // Performance tracking
  bool _initialLoadComplete = false;
  String? _lastSearchQuery;
  int _currentPage = 0;
  bool _isSuggestionLoading = false;
  List<String> _suggestions = [];

  bool get isSuggestionLoading => _isSuggestionLoading;
  List<String> get suggestions => _suggestions;
  List<UniversityModel> get universities => _universities;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  FilterModel get filter => _filter;
  List<UniversityModel> get compareList => _compareList;
  bool get canCompare => _compareList.length < 3;
  int get currentPage => _currentPage;

  /// Load universities with optimized pagination
  Future<void> loadUniversities({bool refresh = false}) async {
    // Prevent duplicate loading
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
      _lastDocument = null;
      _hasMore = true;
      _initialLoadComplete = false;
      _currentPage = 0;
    }

    // Notify on refresh or first load
    if (refresh || _universities.isEmpty) {
      notifyListeners();
    }

    try {
      debugPrint('📥 Loading page ${_currentPage + 1}...');

      final (universities, lastDoc) = await _repository.getUniversities(
        limit: 10,
        lastDocument: _lastDocument,
        filter: _filter.hasActiveFilters ? _filter : null,
      );

      if (!_initialLoadComplete) {
        _initialLoadComplete = true;
      }

      if (universities.isEmpty) {
        _hasMore = false;
        debugPrint('🏁 No more universities to load');
      } else {
        // Filter out duplicates
        final existingIds = _universities.map((u) => u.universityId).toSet();
        final newUniversities = universities
            .where((u) => !existingIds.contains(u.universityId))
            .toList();

        if (newUniversities.isNotEmpty) {
          _universities.addAll(newUniversities);
          _lastDocument = lastDoc;
          _currentPage++;

          // Check if there are more results
          _hasMore = universities.length >= 10 && lastDoc != null;
        } else {
          _hasMore = false;
        }

        debugPrint('✅ Loaded ${newUniversities.length} new universities. Total: ${_universities.length}. Has more: $_hasMore');
      }
    } catch (e) {
      debugPrint('❌ Error loading universities: $e');
      _hasMore = false;

      // Show error but don't crash
      if (_universities.isEmpty) {
        // Critical error
        debugPrint('🚨 Critical: No universities loaded');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Apply filter and reload from scratch
  void applyFilter(FilterModel filter) {
    debugPrint('🔍 Applying filter: ${filter.toJson()}');

    // Check if filter actually changed
    if (_filter == filter) {
      debugPrint('⏸️ Filter unchanged, skipping reload');
      return;
    }

    _filter = filter;
    _lastSearchQuery = null;
    _initialLoadComplete = false;

    // Reset pagination
    _universities.clear();
    _lastDocument = null;
    _hasMore = true;
    _currentPage = 0;

    loadUniversities(refresh: true);
  }

  /// Clear all filters and reload
  void clearFilter() {
    debugPrint('🧹 Clearing all filters');

    _filter = FilterModel();
    _lastSearchQuery = null;
    _initialLoadComplete = false;

    loadUniversities(refresh: true);
  }

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

      final List<UniversityModel> suggestions =
      await _repository.searchUniversities(query, limit: 5);

      _suggestions = suggestions
          .map((university) => university.universityName)
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

    // Prevent duplicate searches
    if (_lastSearchQuery == query.trim()) {
      debugPrint('⏸️ Same search query, skipping...');
      return;
    }

    debugPrint('🔎 Applying search: "$query"');
    _lastSearchQuery = query.trim();
    _filter = _filter.copyWith(searchQuery: _lastSearchQuery);
    _initialLoadComplete = false;

    loadUniversities(refresh: true);
  }

  /// Clear search query
  void clearSearch() {
    debugPrint('🧹 Clearing search');

    if (_lastSearchQuery == null) {
      return; // Already cleared
    }

    _lastSearchQuery = null;
    _filter = _filter.copyWith(clearSearch: true);
    _initialLoadComplete = false;

    loadUniversities(refresh: true);
  }

  /// Remove individual filters
  void removeSearchFilter() {
    debugPrint('🧹 Removing search filter');
    _filter = _filter.copyWith(clearSearch: true);
    _initialLoadComplete = false;

    loadUniversities(refresh: true);
  }

  void removeRankingFilter() {
    debugPrint('🧹 Removing ranking filter');
    _filter = _filter.copyWith(clearRanking: true);
    _initialLoadComplete = false;

    loadUniversities(refresh: true);
  }

  void removeStudentFilter() {
    debugPrint('🧹 Removing total student filter');
    _filter = _filter.copyWith(clearStudents: true);
    _initialLoadComplete = false;

    loadUniversities(refresh: true);
  }

  void removeFeesFilter() {
    debugPrint('🧹 Removing tuition fees filter');
    _filter = _filter.copyWith(clearTuition: true);
    _initialLoadComplete = false;

    loadUniversities(refresh: true);
  }

  void removeCountryFilter() {
    debugPrint('🧹 Removing country filter');
    _filter = _filter.copyWith(clearCountry: true, clearCity: true);
    _initialLoadComplete = false;

    loadUniversities(refresh: true);
  }

  void removeCityFilter() {
    debugPrint('🧹 Removing city filter');
    _filter = _filter.copyWith(clearCity: true);
    _initialLoadComplete = false;

    loadUniversities(refresh: true);
  }

  void removeInstitutionTypeFilter() {
    debugPrint('🧹 Removing institution type filter');
    _filter = _filter.copyWith(clearInstitutionType: true);
    _initialLoadComplete = false;

    loadUniversities(refresh: true);
  }

  void removeRankingSortFilter() {
    debugPrint('🧹 Removing ranking sort filter');
    _filter = _filter.copyWith(clearRankingSort: true);
    _initialLoadComplete = false;

    loadUniversities(refresh: true);
  }

  /// Compare list management (max 3 universities)
  void toggleCompare(UniversityModel university) {
    final index = _compareList.indexWhere((u) => u.universityId == university.universityId);

    if (index != -1) {
      _compareList.removeAt(index);
      debugPrint('➖ Removed ${university.universityName} from compare list');
    } else if (_compareList.length < 3) {
      _compareList.add(university);
      debugPrint('➕ Added ${university.universityName} to compare list');
    } else {
      debugPrint('⚠️ Compare list is full (3 universities)');
    }

    notifyListeners();
  }

  void clearCompare() {
    debugPrint('🧹 Clearing compare list');
    _compareList.clear();
    notifyListeners();
  }

  bool isInCompareList(String universityId) {
    return _compareList.any((u) => u.universityId == universityId);
  }

  /// Force refresh - useful for pull-to-refresh
  Future<void> forceRefresh() async {
    debugPrint('🔄 Force refresh triggered');
    _initialLoadComplete = false;
    await loadUniversities(refresh: true);
  }

  /// Get loading progress text
  String getLoadingStatus() {
    if (_isLoading && _universities.isEmpty) {
      return 'Loading Universities...';
    } else if (_isLoading) {
      return 'Loading more universities...';
    } else if (!_hasMore && _universities.isNotEmpty) {
      return 'All universities loaded';
    } else {
      return '${_universities.length} universities loaded';
    }
  }

  @override
  void dispose() {
    debugPrint('🗑️ UniversityListViewModel disposed');
    _universities.clear();
    _compareList.clear();
    super.dispose();
  }
}