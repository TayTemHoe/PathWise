import 'package:flutter/material.dart';
import '../repository/program_filter_repository.dart';
import '../utils/currency_utils.dart';

class ProgramFilterViewModel extends ChangeNotifier {
  final ProgramFilterRepository _repository = ProgramFilterRepository();

  // Filter Options
  List<String> _availableSubjectAreas = [];
  List<String> _availableStudyModes = [];
  List<String> _availableStudyLevels = [];
  List<String> _availableIntakeMonths = [];
  List<Map<String, String>> _availableUniversities = [];

  // Ranges
  int _minRankingRange = 1;
  int _maxRankingRange = 500;
  double _minDurationRange = 1.0;
  double _maxDurationRange = 6.0;
  double _minTuitionRange = 0;
  double _maxTuitionRange = 500000;

  // Loading states
  bool _isLoadingOptions = false;
  bool _isLoadingRanges = false;
  bool _hasError = false;
  String? _errorMessage;

  // Currency rates status
  bool _currencyRatesLoaded = false;

  // Getters
  List<String> get availableSubjectAreas => _availableSubjectAreas;
  List<String> get availableStudyModes => _availableStudyModes;
  List<String> get availableStudyLevels => _availableStudyLevels;
  List<String> get availableIntakeMonths => _availableIntakeMonths;
  List<Map<String, String>> get availableUniversities => _availableUniversities;

  int get minRankingRange => _minRankingRange;
  int get maxRankingRange => _maxRankingRange;
  double get minDurationRange => _minDurationRange;
  double get maxDurationRange => _maxDurationRange;
  double get minTuitionRange => _minTuitionRange;
  double get maxTuitionRange => _maxTuitionRange;

  bool get isLoadingOptions => _isLoadingOptions;
  bool get isLoadingRanges => _isLoadingRanges;
  bool get isLoading => _isLoadingOptions || _isLoadingRanges;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  bool get currencyRatesLoaded => _currencyRatesLoaded;

  /// Initialize currency rates in background
  Future<void> _initializeCurrencyRates() async {
    try {
      await CurrencyUtils.fetchExchangeRates();
      _currencyRatesLoaded = true;
      debugPrint('✅ Currency rates initialized');
    } catch (e) {
      debugPrint('⚠️ Currency rates initialization failed: $e');
      _currencyRatesLoaded = false;
    }
  }

  /// Load all filter options
  Future<void> loadFilterOptions() async {
    if (_isLoadingOptions) return;

    _isLoadingOptions = true;
    _isLoadingRanges = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🔄 Loading filter options...');

      // Ensure currency rates are loaded first
      if (!_currencyRatesLoaded) {
        await CurrencyUtils.fetchExchangeRates();
        _currencyRatesLoaded = true;
      }

      // Load all metadata at once
      final metadata = await _repository.loadAllFilterMetadata();

      // Extract all data
      _availableUniversities = metadata['universities'] as List<Map<String, String>>;
      _availableSubjectAreas = metadata['subjectAreas'] as List<String>;
      _availableStudyModes = metadata['studyModes'] as List<String>;
      _availableStudyLevels = metadata['studyLevels'] as List<String>;
      _availableIntakeMonths = metadata['intakeMonths'] as List<String>;

      final rankingRange = metadata['rankingRange'] as (int, int);
      _minRankingRange = rankingRange.$1;
      _maxRankingRange = rankingRange.$2;

      final durationRange = metadata['durationRange'] as (double, double);
      _minDurationRange = durationRange.$1;
      _maxDurationRange = durationRange.$2;

      final tuitionRange = metadata['tuitionRange'] as (double, double);
      _minTuitionRange = tuitionRange.$1;
      _maxTuitionRange = tuitionRange.$2;

      debugPrint('✅ Filter options loaded successfully');
      debugPrint('   - ${_availableUniversities.length} universities');
      debugPrint('   - ${_availableSubjectAreas.length} subject areas');
      debugPrint('   - ${_availableStudyModes.length} study modes');
      debugPrint('   - ${_availableStudyLevels.length} study levels');
      debugPrint('   - ${_availableIntakeMonths.length} intake months');
      debugPrint('   - Ranking range: $_minRankingRange - $_maxRankingRange');
      debugPrint('   - Duration range: $_minDurationRange - $_maxDurationRange years');
      debugPrint('   - Tuition range: ${CurrencyUtils.formatMYR(_minTuitionRange)} - ${CurrencyUtils.formatMYR(_maxTuitionRange)}');
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

  /// Refresh all filter data
  Future<void> refreshFilterData() async {
    debugPrint('🔄 Refreshing all filter data...');

    // Clear cache
    ProgramFilterRepository.clearCache();
    CurrencyUtils.clearCache();

    // Reload everything
    await loadFilterOptions();

    debugPrint('✅ Filter data refreshed');
  }

  /// Get formatted ranges for display
  String getRankingRangeText() {
    return 'Rank #$_minRankingRange - #$_maxRankingRange';
  }

  String getDurationRangeText() {
    return '${_minDurationRange.toStringAsFixed(1)} - ${_maxDurationRange.toStringAsFixed(1)} years';
  }

  String getTuitionRangeText() {
    return '${CurrencyUtils.formatMYR(_minTuitionRange)} - ${CurrencyUtils.formatMYR(_maxTuitionRange)}';
  }

  /// Validate filter values before applying
  bool validateFilterValues({
    required double minRanking,
    required double maxRanking,
    required double minDuration,
    required double maxDuration,
    required double minTuition,
    required double maxTuition,
  }) {
    if (minRanking > maxRanking) {
      _errorMessage = 'Minimum ranking cannot be greater than maximum ranking';
      _hasError = true;
      notifyListeners();
      return false;
    }

    if (minDuration > maxDuration) {
      _errorMessage = 'Minimum duration cannot be greater than maximum duration';
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

  @override
  void dispose() {
    debugPrint('🗑️ ProgramFilterViewModel disposed');
    super.dispose();
  }
}