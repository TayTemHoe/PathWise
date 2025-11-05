class ProgramFilterModel {
  final String? searchQuery;
  final String? subjectArea;
  final List<String> studyModes;
  final List<String> studyLevels;
  final List<String> intakeMonths;
  final String? universityName;
  final List<String> universityIds;

  // Subject Ranking Range
  final int? minSubjectRanking;
  final int? maxSubjectRanking;
  final String? rankingSortOrder; // 'asc' or 'desc'

  // Duration Range (in years)
  final double? minDurationYears;
  final double? maxDurationYears;

  // Tuition Fee Range (in MYR)
  final double? minTuitionFeeMYR;
  final double? maxTuitionFeeMYR;

  ProgramFilterModel({
    this.searchQuery,
    this.subjectArea,
    this.studyModes = const [],
    this.studyLevels = const [],
    this.intakeMonths = const [],
    this.minSubjectRanking,
    this.maxSubjectRanking,
    this.rankingSortOrder,
    this.minDurationYears,
    this.maxDurationYears,
    this.minTuitionFeeMYR,
    this.maxTuitionFeeMYR,
    this.universityName,
    this.universityIds = const [],
  });

  /// Check if any filters are active
  bool get hasActiveFilters =>
      searchQuery != null ||
          subjectArea != null ||
          universityName != null ||
          universityIds.isNotEmpty ||
          studyModes.isNotEmpty ||
          studyLevels.isNotEmpty ||
          intakeMonths.isNotEmpty ||
          minSubjectRanking != null ||
          maxSubjectRanking != null ||
          rankingSortOrder != null ||
          minDurationYears != null ||
          maxDurationYears != null ||
          minTuitionFeeMYR != null ||
          maxTuitionFeeMYR != null;

  /// Count active filters
  int get activeFilterCount {
    int count = 0;
    if (searchQuery != null && searchQuery!.isNotEmpty) count++;
    if (subjectArea != null) count++;
    if (studyModes.isNotEmpty) count++;
    if (studyLevels.isNotEmpty) count++;
    if (intakeMonths.isNotEmpty) count++;
    if (minSubjectRanking != null || maxSubjectRanking != null) count++;
    if (rankingSortOrder != null) count++;
    if (minDurationYears != null || maxDurationYears != null) count++;
    if (minTuitionFeeMYR != null || maxTuitionFeeMYR != null) count++;
    if (universityName != null || universityIds.isNotEmpty) count++;
    return count;
  }

  ProgramFilterModel copyWith({
    String? searchQuery,
    String? subjectArea,
    List<String>? studyModes,
    List<String>? studyLevels,
    List<String>? intakeMonths,
    int? minSubjectRanking,
    int? maxSubjectRanking,
    String? rankingSortOrder,
    double? minDurationYears,
    double? maxDurationYears,
    double? minTuitionFeeMYR,
    double? maxTuitionFeeMYR,
    String? universityName,
    List<String>? universityIds,
    bool clearUniversity = false,
    bool clearSearch = false,
    bool clearSubjectArea = false,
    bool clearStudyModes = false,
    bool clearStudyLevels = false,
    bool clearIntakeMonths = false,
    bool clearRanking = false,
    bool clearRankingSort = false,
    bool clearDuration = false,
    bool clearTuition = false,
  }) {
    return ProgramFilterModel(
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      subjectArea: clearSubjectArea ? null : (subjectArea ?? this.subjectArea),
      studyModes: clearStudyModes ? [] : (studyModes ?? this.studyModes),
      studyLevels: clearStudyLevels ? [] : (studyLevels ?? this.studyLevels),
      intakeMonths: clearIntakeMonths ? [] : (intakeMonths ?? this.intakeMonths),
      minSubjectRanking: clearRanking ? null : (minSubjectRanking ?? this.minSubjectRanking),
      maxSubjectRanking: clearRanking ? null : (maxSubjectRanking ?? this.maxSubjectRanking),
      rankingSortOrder: clearRankingSort ? null : (rankingSortOrder ?? this.rankingSortOrder),
      minDurationYears: clearDuration ? null : (minDurationYears ?? this.minDurationYears),
      maxDurationYears: clearDuration ? null : (maxDurationYears ?? this.maxDurationYears),
      minTuitionFeeMYR: clearTuition ? null : (minTuitionFeeMYR ?? this.minTuitionFeeMYR),
      maxTuitionFeeMYR: clearTuition ? null : (maxTuitionFeeMYR ?? this.maxTuitionFeeMYR),
      universityName: clearUniversity ? null : (universityName ?? this.universityName),
      universityIds: clearUniversity ? [] : (universityIds ?? this.universityIds),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'searchQuery': searchQuery,
      'subjectArea': subjectArea,
      'studyModes': studyModes,
      'studyLevels': studyLevels,
      'intakeMonths': intakeMonths,
      'minSubjectRanking': minSubjectRanking,
      'maxSubjectRanking': maxSubjectRanking,
      'rankingSortOrder': rankingSortOrder,
      'minDurationYears': minDurationYears,
      'maxDurationYears': maxDurationYears,
      'minTuitionFeeMYR': minTuitionFeeMYR,
      'maxTuitionFeeMYR': maxTuitionFeeMYR,
      'universityName': universityName,
      'universityIds': universityIds,
    }..removeWhere((key, value) =>
    value == null || (value is List && value.isEmpty));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProgramFilterModel &&
        other.searchQuery == searchQuery &&
        other.subjectArea == subjectArea &&
        _listEquals(other.studyModes, studyModes) &&
        _listEquals(other.studyLevels, studyLevels) &&
        _listEquals(other.intakeMonths, intakeMonths) &&
        other.minSubjectRanking == minSubjectRanking &&
        other.maxSubjectRanking == maxSubjectRanking &&
        other.rankingSortOrder == rankingSortOrder &&
        other.minDurationYears == minDurationYears &&
        other.maxDurationYears == maxDurationYears &&
        other.minTuitionFeeMYR == minTuitionFeeMYR &&
        other.maxTuitionFeeMYR == maxTuitionFeeMYR &&
        other.universityName == universityName &&
        _listEquals(other.universityIds, universityIds);
  }

  bool _listEquals(List a, List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return searchQuery.hashCode ^
    subjectArea.hashCode ^
    studyModes.hashCode ^
    studyLevels.hashCode ^
    intakeMonths.hashCode ^
    minSubjectRanking.hashCode ^
    maxSubjectRanking.hashCode ^
    rankingSortOrder.hashCode ^
    minDurationYears.hashCode ^
    maxDurationYears.hashCode ^
    minTuitionFeeMYR.hashCode ^
    maxTuitionFeeMYR.hashCode ^
    universityName.hashCode ^
    universityIds.hashCode;
  }

  @override
  String toString() {
    return 'ProgramFilterModel('
        'searchQuery: $searchQuery, '
        'subjectArea: $subjectArea, '
        'studyModes: $studyModes, '
        'studyLevels: $studyLevels, '
        'intakeMonths: $intakeMonths, '
        'minSubjectRanking: $minSubjectRanking, '
        'maxSubjectRanking: $maxSubjectRanking, '
        'rankingSortOrder: $rankingSortOrder, '
        'minDurationYears: $minDurationYears, '
        'maxDurationYears: $maxDurationYears, '
        'minTuitionFeeMYR: $minTuitionFeeMYR, '
        'maxTuitionFeeMYR: $maxTuitionFeeMYR)';
  }
}