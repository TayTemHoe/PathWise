// lib/viewmodel/job_view_model.dart
import 'package:flutter/foundation.dart';
import 'package:path_wise/model/job_models.dart';
import 'package:path_wise/service/job_service.dart';

/// ViewModel for managing job search and bookmarks
/// Follows MVVM architecture pattern with ChangeNotifier
class JobViewModel extends ChangeNotifier {
  final JobService _jobService = JobService();

  // State variables
  List<JobModel> _allSearchResults = []; // All results from API
  List<JobModel> _filteredResults = []; // Filtered results (after local filters)
  List<JobModel> _savedJobs = [];
  JobFilters _currentFilters = JobFilters.empty();
  String? _errorMessage;
  bool _isLoading = false;
  bool _isSearching = false;
  String _lastSearchQuery = '';
  String _lastSearchCountry = 'my'; // Last used country code

  // Getters
  List<JobModel> get searchResults => _filteredResults;
  List<JobModel> get allResults => _allSearchResults;
  List<JobModel> get savedJobs => _savedJobs;
  JobFilters get currentFilters => _currentFilters;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  bool get hasSearchResults => _filteredResults.isNotEmpty;
  bool get hasSavedJobs => _savedJobs.isNotEmpty;
  bool get hasError => _errorMessage != null;
  int get totalSearchResults => _filteredResults.length;
  int get totalAllResults => _allSearchResults.length;
  int get totalSavedJobs => _savedJobs.length;
  String get lastSearchCountry => _lastSearchCountry;

  /// Check if a job is saved by its job ID
  bool isJobSaved(String jobId) {
    return _savedJobs.any((job) => job.jobId == jobId);
  }

  /// Get bookmark ID for a job
  String? getBookmarkId(String jobId) {
    try {
      final job = _savedJobs.firstWhere((job) => job.jobId == jobId);
      return job.bookmarkId;
    } catch (e) {
      return null;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Set searching state
  void _setSearching(bool value) {
    _isSearching = value;
    notifyListeners();
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    _isSearching = false;
    notifyListeners();
  }

  /// Search jobs with query and country
  /// This fetches ALL results from API and stores them
  Future<bool> searchJobs({
    required String query,
    required String country,
    String? datePosted,
  }) async {
    try {
      _setSearching(true);
      _errorMessage = null;

      _lastSearchQuery = query;
      _lastSearchCountry = country;

      debugPrint('🔍 Searching jobs: "$query" in country "$country"');

      // Fetch all jobs from API (with automatic multi-page fetching)
      final results = await _jobService.fetchJobs(
        query: query,
        country: country,
        datePosted: datePosted ?? _currentFilters.dateRange,
        maxResults: 500, // Fetch up to 500 jobs
      );

      _allSearchResults = results;

      // Apply local filters if any are active
      if (_currentFilters.hasActiveFilters) {
        _filteredResults = _jobService.applyLocalFilters(
          _allSearchResults,
          _currentFilters,
        );
      } else {
        _filteredResults = _allSearchResults;
      }

      _setSearching(false);

      debugPrint('✅ Found ${_allSearchResults.length} total jobs');
      debugPrint('✅ After filters: ${_filteredResults.length} jobs');
      return true;
    } catch (e) {
      debugPrint('❌ Error searching jobs: $e');
      _setError('Failed to search jobs: ${e.toString()}');
      return false;
    }
  }

  /// Apply filters to existing search results
  Future<bool> applyFilters(JobFilters filters) async {
    try {
      _currentFilters = filters;

      debugPrint('🔧 Applying filters: ${filters.activeFilterCount} active');

      // If we have search results, apply filters to them
      if (_allSearchResults.isNotEmpty) {
        // Check if filters require re-fetching from API
        // (query, country, or dateRange changed)
        final needsRefetch =
            (filters.query != null && filters.query != _lastSearchQuery) ||
                (filters.country != null && filters.country != _lastSearchCountry) ||
                (filters.dateRange != null && filters.dateRange != _currentFilters.dateRange);

        if (needsRefetch) {
          // Re-search with new API parameters
          return await searchJobs(
            query: filters.query ?? _lastSearchQuery,
            country: filters.country ?? _lastSearchCountry,
            datePosted: filters.dateRange,
          );
        }

        // Otherwise, just apply local filters to existing results
        _filteredResults = _jobService.applyLocalFilters(
          _allSearchResults,
          _currentFilters,
        );

        notifyListeners();
        debugPrint('✅ Filtered results: ${_filteredResults.length} jobs');
        return true;
      } else {
        // No search results yet, do nothing
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error applying filters: $e');
      _setError('Failed to apply filters: ${e.toString()}');
      return false;
    }
  }

  /// Clear all filters and show all search results
  Future<bool> clearFilters() async {
    _currentFilters = JobFilters.empty();
    debugPrint('🧹 Cleared all filters');

    // Show all search results without filters
    _filteredResults = _allSearchResults;
    notifyListeners();
    return true;
  }

  /// Clear search results
  void clearSearchResults() {
    _allSearchResults = [];
    _filteredResults = [];
    _lastSearchQuery = '';
    _lastSearchCountry = 'my';
    notifyListeners();
    debugPrint('🧹 Cleared search results');
  }

  /// Save/bookmark a job
  Future<bool> saveJob(String uid, JobModel job) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      // Check if already saved
      if (isJobSaved(job.jobId)) {
        _setError('Job is already saved');
        return false;
      }

      debugPrint('💾 Saving job: ${job.jobTitle}');

      final bookmarkId = await _jobService.saveJobToFirestore(uid, job);

      // Add to local saved jobs list
      final savedJob = job.copyWith(
        bookmarkId: bookmarkId,
        savedAt: DateTime.now(),
      );
      _savedJobs.insert(0, savedJob);

      _setLoading(false);
      debugPrint('✅ Job saved with ID: $bookmarkId');
      return true;
    } catch (e) {
      debugPrint('❌ Error saving job: $e');
      _setError('Failed to save job: ${e.toString()}');
      return false;
    }
  }

  /// Remove saved job
  Future<bool> removeSavedJob(String uid, String jobId) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final bookmarkId = getBookmarkId(jobId);
      if (bookmarkId == null) {
        _setError('Job not found in saved list');
        return false;
      }

      debugPrint('🗑️ Removing saved job: $bookmarkId');

      await _jobService.removeSavedJob(uid, bookmarkId);

      // Remove from local list
      _savedJobs.removeWhere((job) => job.jobId == jobId);

      _setLoading(false);
      debugPrint('✅ Job removed from saved list');
      return true;
    } catch (e) {
      debugPrint('❌ Error removing saved job: $e');
      _setError('Failed to remove job: ${e.toString()}');
      return false;
    }
  }

  /// Toggle job save status
  Future<bool> toggleJobSave(String uid, JobModel job) async {
    if (isJobSaved(job.jobId)) {
      return removeSavedJob(uid, job.jobId);
    } else {
      return saveJob(uid, job);
    }
  }

  /// Fetch all saved jobs
  Future<void> fetchSavedJobs(String uid) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      debugPrint('📚 Fetching saved jobs for user $uid');

      final jobs = await _jobService.fetchSavedJobs(uid);
      _savedJobs = jobs;

      _setLoading(false);
      debugPrint('✅ Fetched ${jobs.length} saved jobs');
    } catch (e) {
      debugPrint('❌ Error fetching saved jobs: $e');
      _setError('Failed to fetch saved jobs: ${e.toString()}');
    }
  }

  /// Initialize ViewModel
  Future<void> initialize(String uid) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await fetchSavedJobs(uid);

      _setLoading(false);
      debugPrint('✅ JobViewModel initialized');
    } catch (e) {
      debugPrint('❌ Error initializing JobViewModel: $e');
      _setError('Failed to initialize: ${e.toString()}');
    }
  }

  /// Refresh saved jobs
  Future<void> refreshSavedJobs(String uid) async {
    await fetchSavedJobs(uid);
  }


  /// Search in saved jobs
  List<JobModel> searchSavedJobs(String query) {
    if (query.isEmpty) return _savedJobs;

    final lowerQuery = query.toLowerCase();
    return _savedJobs.where((job) {
      return job.jobTitle.toLowerCase().contains(lowerQuery) ||
          job.companyName.toLowerCase().contains(lowerQuery) ||
          job.jobDescription.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get job statistics
  Map<String, dynamic> getStatistics() {
    return {
      'totalAllResults': _allSearchResults.length,
      'totalFilteredResults': _filteredResults.length,
      'totalSavedJobs': _savedJobs.length,
      'remoteJobs': _filteredResults.where((j) => j.isRemote).length,
      'hasActiveFilters': _currentFilters.hasActiveFilters,
      'activeFilterCount': _currentFilters.activeFilterCount,
    };
  }

  /// Listen to real-time saved jobs updates
  void startListeningToSavedJobs(String uid) {
    _jobService.streamSavedJobs(uid).listen(
          (jobs) {
        _savedJobs = jobs;
        notifyListeners();
        debugPrint('🔄 Real-time update: ${jobs.length} saved jobs');
      },
      onError: (error) {
        debugPrint('❌ Stream error: $error');
        _setError('Real-time update error: $error');
      },
    );
  }

  @override
  void dispose() {
    debugPrint('🧹 JobViewModel disposed');
    super.dispose();
  }
}