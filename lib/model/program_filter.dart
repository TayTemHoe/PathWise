class ProgramFilterModel {
  final String? searchQuery;
  final List<String> subjectArea;
  final List<String> studyModes;
  final List<String> studyLevels;
  final List<String> intakeMonths;
  final List<String> universityIds;
  final String? universityName;

  // ✅ CHANGED: Replaced min/max ranking with topN
  final int? topN; // NEW: Single value for "Top N" programs by subject ranking
  final String? rankingSortOrder; // 'asc' or 'desc'

  final double? minDurationYears;
  final double? maxDurationYears;
  final double? minTuitionFeeMYR;
  final double? maxTuitionFeeMYR;
  final Set<String>? malaysianBranchIds;
  final List<String> countries;

  ProgramFilterModel({
    this.searchQuery,
    this.subjectArea = const [],
    this.studyModes = const [],
    this.studyLevels = const [],
    this.intakeMonths = const [],
    this.universityIds = const [],
    this.universityName,
    this.topN, // ✅ NEW
    this.rankingSortOrder,
    this.minDurationYears,
    this.maxDurationYears,
    this.minTuitionFeeMYR,
    this.maxTuitionFeeMYR,
    this.malaysianBranchIds,
    this.countries = const [],
  });

  bool get hasActiveFilters {
    return searchQuery != null ||
        subjectArea.isNotEmpty ||
        studyModes.isNotEmpty ||
        studyLevels.isNotEmpty ||
        intakeMonths.isNotEmpty ||
        universityIds.isNotEmpty ||
        topN != null || // ✅ CHANGED
        rankingSortOrder != null ||
        minDurationYears != null ||
        maxDurationYears != null ||
        minTuitionFeeMYR != null ||
        maxTuitionFeeMYR != null ||
        countries.isNotEmpty;
  }

  int get activeFilterCount {
    int count = 0;
    if (searchQuery != null && searchQuery!.isNotEmpty) count++;
    if (subjectArea.isNotEmpty) count++;
    if (studyModes.isNotEmpty) count++;
    if (studyLevels.isNotEmpty) count++;
    if (intakeMonths.isNotEmpty) count++;
    if (universityIds.isNotEmpty) count++;
    if (topN != null) count++; // ✅ CHANGED
    if (rankingSortOrder != null) count++;
    if (minDurationYears != null || maxDurationYears != null) count++;
    if (minTuitionFeeMYR != null || maxTuitionFeeMYR != null) count++;
    if (countries.isNotEmpty) count++;
    return count;
  }

  ProgramFilterModel copyWith({
    String? searchQuery,
    List<String>? subjectArea,
    List<String>? studyModes,
    List<String>? studyLevels,
    List<String>? intakeMonths,
    List<String>? universityIds,
    String? universityName,
    int? topN, // ✅ CHANGED
    String? rankingSortOrder,
    double? minDurationYears,
    double? maxDurationYears,
    double? minTuitionFeeMYR,
    double? maxTuitionFeeMYR,
    Set<String>? malaysianBranchIds,
    List<String>? countries,
    bool clearSearch = false,
    bool clearSubjectArea = false,
    bool clearStudyModes = false,
    bool clearStudyLevels = false,
    bool clearIntakeMonths = false,
    bool clearUniversity = false,
    bool clearTopN = false, // ✅ CHANGED from clearRanking
    bool clearRankingSort = false,
    bool clearDuration = false,
    bool clearTuition = false,
    bool clearCountries = false,
  }) {
    return ProgramFilterModel(
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      subjectArea: clearSubjectArea ? [] : (subjectArea ?? this.subjectArea),
      studyModes: clearStudyModes ? [] : (studyModes ?? this.studyModes),
      studyLevels: clearStudyLevels ? [] : (studyLevels ?? this.studyLevels),
      intakeMonths: clearIntakeMonths ? [] : (intakeMonths ?? this.intakeMonths),
      universityIds: clearUniversity ? [] : (universityIds ?? this.universityIds),
      universityName: clearUniversity ? null : (universityName ?? this.universityName),
      topN: clearTopN ? null : (topN ?? this.topN), // ✅ CHANGED
      rankingSortOrder: clearRankingSort ? null : (rankingSortOrder ?? this.rankingSortOrder),
      minDurationYears: clearDuration ? null : (minDurationYears ?? this.minDurationYears),
      maxDurationYears: clearDuration ? null : (maxDurationYears ?? this.maxDurationYears),
      minTuitionFeeMYR: clearTuition ? null : (minTuitionFeeMYR ?? this.minTuitionFeeMYR),
      maxTuitionFeeMYR: clearTuition ? null : (maxTuitionFeeMYR ?? this.maxTuitionFeeMYR),
      malaysianBranchIds: malaysianBranchIds ?? this.malaysianBranchIds,
      countries: clearCountries ? [] : (countries ?? this.countries),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'searchQuery': searchQuery,
      'subjectArea': subjectArea,
      'studyModes': studyModes,
      'studyLevels': studyLevels,
      'intakeMonths': intakeMonths,
      'universityIds': universityIds,
      'universityName': universityName,
      'topN': topN, // ✅ CHANGED
      'rankingSortOrder': rankingSortOrder,
      'minDurationYears': minDurationYears,
      'maxDurationYears': maxDurationYears,
      'minTuitionFeeMYR': minTuitionFeeMYR,
      'maxTuitionFeeMYR': maxTuitionFeeMYR,
      'malaysianBranchIds': malaysianBranchIds?.toList(),
      'countries': countries,
      'hasActiveFilters': hasActiveFilters,
      'activeFilterCount': activeFilterCount,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProgramFilterModel &&
        other.searchQuery == searchQuery &&
        _listEquals(other.subjectArea, subjectArea) &&
        _listEquals(other.studyModes, studyModes) &&
        _listEquals(other.studyLevels, studyLevels) &&
        _listEquals(other.intakeMonths, intakeMonths) &&
        _listEquals(other.universityIds, universityIds) &&
        other.universityName == universityName &&
        other.topN == topN && // ✅ CHANGED
        other.rankingSortOrder == rankingSortOrder &&
        other.minDurationYears == minDurationYears &&
        other.maxDurationYears == maxDurationYears &&
        other.minTuitionFeeMYR == minTuitionFeeMYR &&
        other.maxTuitionFeeMYR == maxTuitionFeeMYR &&
        _listEquals(other.countries, countries);
  }

  @override
  int get hashCode {
    return Object.hash(
      searchQuery,
      Object.hashAll(subjectArea),
      Object.hashAll(studyModes),
      Object.hashAll(studyLevels),
      Object.hashAll(intakeMonths),
      Object.hashAll(universityIds),
      universityName,
      topN, // ✅ CHANGED
      rankingSortOrder,
      minDurationYears,
      maxDurationYears,
      minTuitionFeeMYR,
      maxTuitionFeeMYR,
      Object.hashAll(countries),
    );
  }

  bool _listEquals(List a, List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}