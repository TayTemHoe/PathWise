// lib/viewModel/filter_view_model_v2.dart
import 'package:flutter/material.dart';
import '../model/university_filter.dart';
import '../repository/filter_repository.dart';
import '../utils/currency_utils.dart';

class FilterViewModel extends ChangeNotifier {
  final FilterRepository _repository = FilterRepository();

  // Filter Options
  List<String> _availableCountries = [];
  List<String> _availableCities = [];
  List<String> _institutionTypes = [];

  // Ranges
  int _minStudentsRange = 0;
  int _maxStudentsRange = 100000;
  double _minTuitionRange = 0;
  double _maxTuitionRange = 500000;
  int _minRankingRange = 1;
  int _maxRankingRange = 2000;

  // Loading states
  bool _isLoadingOptions = false;
  bool _isLoadingCities = false;
  bool _isLoadingRanges = false;
  bool _hasError = false;
  String? _errorMessage;

  // Currency rates status
  bool _currencyRatesLoaded = false;

  // Getters
  List<String> get availableCountries => _availableCountries;
  List<String> get availableCities => _availableCities;
  List<String> get institutionTypes => _institutionTypes;

  int get minStudentsRange => _minStudentsRange;
  int get maxStudentsRange => _maxStudentsRange;
  double get minTuitionRange => _minTuitionRange;
  double get maxTuitionRange => _maxTuitionRange;
  int get minRankingRange => _minRankingRange;
  int get maxRankingRange => _maxRankingRange;

  bool get isLoadingOptions => _isLoadingOptions;
  bool get isLoadingCities => _isLoadingCities;
  bool get isLoadingRanges => _isLoadingRanges;
  bool get isLoading => _isLoadingOptions || _isLoadingCities || _isLoadingRanges;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  bool get currencyRatesLoaded => _currencyRatesLoaded;

  /// Initialize and load filter options
  Future<void> initialize() async {
    await loadFilterOptions();
    await _repository.warmUpCache(); // Preload all metadata
  }

  /// Load filter options
  Future<void> loadFilterOptions() async {
    _isLoadingOptions = true;
    _isLoadingRanges = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🔄 Loading university filter options...');

      // Ensure currency rates are loaded first
      if (!_currencyRatesLoaded) {
        try {
          await CurrencyUtils.fetchExchangeRates();
          _currencyRatesLoaded = true;
        } catch (e) {
          debugPrint('⚠️ Currency rates unavailable: $e');
        }
      }

      // Load all metadata at once
      final metadata = await _repository.loadUniversityFilterMetadata();

      // Extract all data
      _availableCountries = metadata['countries'] as List<String>? ?? [];
      _institutionTypes = metadata['institutionTypes'] as List<String>? ?? [];

      final studentRange = metadata['studentRange'] as (int, int)?;
      if (studentRange != null) {
        _minStudentsRange = studentRange.$1;
        _maxStudentsRange = studentRange.$2;
      }

      final tuitionRange = metadata['tuitionRange'] as (double, double)?;
      if (tuitionRange != null) {
        _minTuitionRange = tuitionRange.$1;
        _maxTuitionRange = tuitionRange.$2;
      }

      final rankingRange = metadata['rankingRange'] as (int, int)?;
      if (rankingRange != null) {
        _minRankingRange = rankingRange.$1;
        _maxRankingRange = rankingRange.$2;
      }

      debugPrint('✅ Filter options loaded successfully');
      debugPrint('   - ${_availableCountries.length} countries');
      debugPrint('   - ${_institutionTypes.length} institution types');
      debugPrint('   - Student range: $_minStudentsRange - $_maxStudentsRange');
      debugPrint('   - Tuition range: ${CurrencyUtils.formatMYR(_minTuitionRange)} - ${CurrencyUtils.formatMYR(_maxTuitionRange)}');
      debugPrint('   - Ranking range: $_minRankingRange - $_maxRankingRange');

    } catch (e) {
      _hasError = true;
      _errorMessage = e.toString();
      debugPrint('❌ Error loading filter options: $e');
    } finally {
      _isLoadingOptions = false;
      _isLoadingRanges = false;
      notifyListeners();
    }
  }

  /// Load cities for selected country
  Future<void> loadCitiesForCountry(String country) async {
    if (_isLoadingCities) return;

    _isLoadingCities = true;
    _availableCities = [];
    notifyListeners();

    try {
      debugPrint('🔄 Loading cities for $country...');

      _availableCities = await _repository.getCitiesForCountry(country);

      debugPrint('✅ Loaded ${_availableCities.length} cities for $country');
    } catch (e) {
      debugPrint('❌ Error loading cities: $e');
      _availableCities = [];
    } finally {
      _isLoadingCities = false;
      notifyListeners();
    }
  }

  /// Clear cities when country changes or is deselected
  void clearCities() {
    _availableCities = [];
    notifyListeners();
  }

  /// Search universities (for autocomplete)
  Future<List<String>> searchUniversities(String query) async {
    if (query.isEmpty) return [];

    try {
      return await _repository.searchUniversities(query, limit: 5);
    } catch (e) {
      debugPrint('❌ Error searching universities: $e');
      return [];
    }
  }

  /// Refresh all filter data
  Future<void> refreshFilterData() async {
    debugPrint('🔄 Refreshing all filter data...');

    // Clear caches
    _repository.clearCache();
    CurrencyUtils.clearCache();

    // Reload everything
    await loadFilterOptions();

    debugPrint('✅ Filter data refreshed');
  }

  /// Get formatted ranges for display
  String getStudentRangeText() {
    return '${_formatNumber(_minStudentsRange)} - ${_formatNumber(_maxStudentsRange)} students';
  }

  String getTuitionRangeText() {
    return '${CurrencyUtils.formatMYR(_minTuitionRange)} - ${CurrencyUtils.formatMYR(_maxTuitionRange)}';
  }

  String getRankingRangeText() {
    return 'Rank #$_minRankingRange - #$_maxRankingRange';
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toString();
  }

  /// Validate filter values before applying
  bool validateFilterValues({
    required double minRanking,
    required double maxRanking,
    required double minStudents,
    required double maxStudents,
    required double minTuition,
    required double maxTuition,
  }) {
    if (minRanking > maxRanking) {
      _errorMessage = 'Minimum ranking cannot be greater than maximum ranking';
      _hasError = true;
      notifyListeners();
      return false;
    }

    if (minStudents > maxStudents) {
      _errorMessage = 'Minimum students cannot be greater than maximum students';
      _hasError = true;
      notifyListeners();
      return false;
    }

    if (minTuition > maxTuition) {
      _errorMessage = 'Minimum tuition cannot be greater than maximum tuition';
      _hasError = true;
      notifyListeners();
      return false;
    }

    _hasError = false;
    _errorMessage = null;
    return true;
  }

  /// Clear error state
  void clearError() {
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Get currency update status
  String getCurrencyUpdateStatus() {
    if (!_currencyRatesLoaded) {
      return 'Using fallback rates';
    }

    final lastUpdate = CurrencyUtils.lastUpdateTime;
    if (lastUpdate == null) {
      return 'Rates not loaded';
    }

    final difference = DateTime.now().difference(lastUpdate);
    if (difference.inMinutes < 60) {
      return 'Updated ${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return 'Updated ${difference.inHours} hours ago';
    } else {
      return 'Updated ${difference.inDays} days ago';
    }
  }

  /// Force refresh currency rates
  Future<void> refreshCurrencyRates() async {
    try {
      debugPrint('🔄 Refreshing currency rates...');
      await CurrencyUtils.refreshRates();
      _currencyRatesLoaded = true;

      // Reload tuition range with new rates
      final tuitionRange = await _repository.getTuitionFeeRange();
      _minTuitionRange = tuitionRange.$1;
      _maxTuitionRange = tuitionRange.$2;

      notifyListeners();
      debugPrint('✅ Currency rates refreshed');
    } catch (e) {
      debugPrint('❌ Error refreshing currency rates: $e');
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return _repository.getCacheStats();
  }

  @override
  void dispose() {
    debugPrint('🗑️ FilterViewModel disposed');
    super.dispose();
  }
}