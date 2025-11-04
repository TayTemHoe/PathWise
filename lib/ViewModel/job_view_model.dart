// lib/viewmodel/job_view_model.dart
import 'package:flutter/foundation.dart';
import 'package:path_wise/model/job_models.dart';
import 'package:path_wise/service/job_service.dart';

/// ViewModel for managing job search and bookmarks
/// Follows MVVM architecture pattern with ChangeNotifier
class JobViewModel extends ChangeNotifier {
  final JobService _jobService = JobService();

  // State variables
  List<JobModel> _searchResults = [];
  List<JobModel> _savedJobs = [];
  JobFilters _currentFilters = JobFilters.empty();
  String? _errorMessage;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSearching = false;
  int _currentPage = 1;
  bool _hasMorePages = true;
  String _lastSearchQuery = '';
  String _lastSearchLocation = '';

  // Getters
  List<JobModel> get searchResults => _searchResults;
  List<JobModel> get savedJobs => _savedJobs;
  JobFilters get currentFilters => _currentFilters;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSearching => _isSearching;
  bool get hasSearchResults => _searchResults.isNotEmpty;
  bool get hasSavedJobs => _savedJobs.isNotEmpty;
  bool get hasError => _errorMessage != null;
  bool get hasMorePages => _hasMorePages;
  int get totalSearchResults => _searchResults.length;
  int get totalSavedJobs => _savedJobs.length;
  int get currentPage => _currentPage;

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
    _isLoadingMore = false;
    notifyListeners();
  }

  /// Search jobs with query and location
  Future<bool> searchJobs({
    required String query,
    String? location,
    bool clearPrevious = true,
  }) async {
    try {
      _setSearching(true);
      _errorMessage = null;

      if (clearPrevious) {
        _searchResults = [];
        _currentPage = 1;
        _hasMorePages = true;
      }

      _lastSearchQuery = query;
      _lastSearchLocation = location ?? 'my';

      debugPrint('🔍 Searching jobs: $query in $_lastSearchLocation');

      final results = await _jobService.fetchJobs(
        query: query,
        location: _lastSearchLocation,
        filters: _currentFilters,
        page: _currentPage,
      );

      if (clearPrevious) {
        _searchResults = results;
      } else {
        _searchResults.addAll(results);
      }

      _hasMorePages = results.isNotEmpty && results.length >= 10;
      _setSearching(false);

      debugPrint('✅ Found ${results.length} jobs');
      return true;
    } catch (e) {
      debugPrint('❌ Error searching jobs: $e');
      _setError('Failed to search jobs: ${e.toString()}');
      return false;
    }
  }

  /// Search jobs from career suggestion
  Future<bool> searchJobsByCareerSuggestion({
    required String jobTitle,
    String? location,
  }) async {
    debugPrint('🎯 Searching jobs for career suggestion: $jobTitle');
    return searchJobs(query: jobTitle, location: location);
  }

  /// Apply filters and search
  Future<bool> applyFilters(JobFilters filters) async {
    try {
      _setSearching(true);
      _errorMessage = null;
      _currentFilters = filters;
      _currentPage = 1;

      debugPrint('🔧 Applying filters: ${filters.activeFilterCount} active');

      // Re-search with new filters
      if (_lastSearchQuery.isNotEmpty) {
        final results = await _jobService.searchJobsWithFilters(
          query: _lastSearchQuery,
          location: _lastSearchLocation,
          filters: _currentFilters,
          page: _currentPage,
        );

        _searchResults = results;
        _hasMorePages = results.isNotEmpty && results.length >= 10;
        _setSearching(false);

        debugPrint('✅ Filtered results: ${results.length} jobs');
        return true;
      } else {
        _setSearching(false);
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error applying filters: $e');
      _setError('Failed to apply filters: ${e.toString()}');
      return false;
    }
  }

  /// Clear all filters
  Future<bool> clearFilters() async {
    _currentFilters = JobFilters.empty();
    debugPrint('🧹 Cleared all filters');

    // Re-search without filters
    if (_lastSearchQuery.isNotEmpty) {
      return searchJobs(query: _lastSearchQuery, location: _lastSearchLocation);
    }
    return true;
  }

  /// Load more jobs (pagination)
  Future<bool> loadMoreJobs() async {
    if (!_hasMorePages || _isLoadingMore) {
      return false;
    }

    try {
      _isLoadingMore = true;
      notifyListeners();

      _currentPage++;
      debugPrint('📄 Loading page $_currentPage');

      final results = await _jobService.fetchJobs(
        query: _lastSearchQuery,
        location: _lastSearchLocation,
        filters: _currentFilters,
        page: _currentPage,
      );

      if (results.isEmpty || results.length < 10) {
        _hasMorePages = false;
      }

      _searchResults.addAll(results);
      _isLoadingMore = false;
      notifyListeners();

      debugPrint('✅ Loaded ${results.length} more jobs');
      return true;
    } catch (e) {
      debugPrint('❌ Error loading more jobs: $e');
      _isLoadingMore = false;
      notifyListeners();
      return false;
    }
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

  /// Clear search results
  void clearSearchResults() {
    _searchResults = [];
    _currentPage = 1;
    _hasMorePages = true;
    _lastSearchQuery = '';
    _lastSearchLocation = '';
    notifyListeners();
    debugPrint('🧹 Cleared search results');
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

  /// Get jobs by company
  List<JobModel> getJobsByCompany(String companyName) {
    return _searchResults.where((job) {
      return job.companyName.toLowerCase() == companyName.toLowerCase();
    }).toList();
  }

  /// Get remote jobs only
  List<JobModel> getRemoteJobs() {
    return _searchResults.where((job) => job.isRemote).toList();
  }

  /// Get jobs by location
  List<JobModel> getJobsByLocation(String location) {
    final lowerLocation = location.toLowerCase();
    return _searchResults.where((job) {
      final jobLocation = '${job.jobLocation.city}, ${job.jobLocation.state}'.toLowerCase();
      return jobLocation.contains(lowerLocation);
    }).toList();
  }

  /// Get jobs by salary range
  List<JobModel> getJobsBySalaryRange(int min, int max) {
    return _searchResults.where((job) {
      if (job.jobMinSalary == null || job.jobMaxSalary == null) {
        return false;
      }

      final minSalary = double.tryParse(job.jobMinSalary!) ?? 0;
      final maxSalary = double.tryParse(job.jobMaxSalary!) ?? 0;

      return maxSalary >= min && minSalary <= max;
    }).toList();
  }

  /// Get job statistics
  Map<String, dynamic> getStatistics() {
    return {
      'totalSearchResults': _searchResults.length,
      'totalSavedJobs': _savedJobs.length,
      'remoteJobs': _searchResults.where((j) => j.isRemote).length,
      'hasActiveFilters': _currentFilters.hasActiveFilters,
      'activeFilterCount': _currentFilters.activeFilterCount,
      'currentPage': _currentPage,
      'hasMorePages': _hasMorePages,
    };
  }

  /// Get company list from search results
  List<String> getUniqueCompanies() {
    return _searchResults.map((job) => job.companyName).toSet().toList();
  }

  /// Get location list from search results
  List<String> getUniqueLocations() {
    return _searchResults
        .map((job) => '${job.jobLocation.city}, ${job.jobLocation.state}')
        .toSet()
        .toList();
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