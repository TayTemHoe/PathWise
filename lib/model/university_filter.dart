// lib/model/university_filter.dart
class UniversityFilterModel {
  final String? searchQuery;
  final String? country;
  final String? city;
  final int? topN; // NEW: Single value for "Top N" universities
  final int? minStudents;
  final int? maxStudents;
  final double? minTuitionFeeMYR;
  final double? maxTuitionFeeMYR;
  final String? institutionType;
  final String? rankingSortOrder; // 'asc', 'desc', or null
  final bool shouldDefaultToMalaysia;

  const UniversityFilterModel({
    this.searchQuery,
    this.country,
    this.city,
    this.topN, // NEW: Replaces minRanking/maxRanking
    this.minStudents,
    this.maxStudents,
    this.minTuitionFeeMYR,
    this.maxTuitionFeeMYR,
    this.institutionType,
    this.rankingSortOrder,
    this.shouldDefaultToMalaysia = true,
  });

  /// Check if any filters are active (excluding search and Malaysian default)
  bool get hasActiveFilters {
    return (searchQuery?.isNotEmpty ?? false) ||
        country != null ||
        city != null ||
        topN != null ||
        minStudents != null ||
        maxStudents != null ||
        minTuitionFeeMYR != null ||
        maxTuitionFeeMYR != null ||
        institutionType != null ||
        rankingSortOrder != null;
  }

  /// Count active filters (for UI badge)
  int get activeFilterCount {
    int count = 0;
    if (searchQuery?.isNotEmpty ?? false) count++;
    if (country != null) count++;
    if (city != null) count++;
    if (topN != null) count++;
    if (minStudents != null || maxStudents != null) count++;
    if (minTuitionFeeMYR != null || maxTuitionFeeMYR != null) count++;
    if (institutionType != null) count++;
    if (rankingSortOrder != null) count++;
    return count;
  }

  /// Copy with support for clearing individual filters
  UniversityFilterModel copyWith({
    String? searchQuery,
    String? country,
    String? city,
    int? topN,
    int? minStudents,
    int? maxStudents,
    double? minTuitionFeeMYR,
    double? maxTuitionFeeMYR,
    String? institutionType,
    String? rankingSortOrder,
    bool? shouldDefaultToMalaysia,
    bool clearSearch = false,
    bool clearCountry = false,
    bool clearCity = false,
    bool clearTopN = false,
    bool clearStudents = false,
    bool clearTuition = false,
    bool clearInstitutionType = false,
    bool clearRankingSort = false,
  }) {
    bool newShouldDefaultToMalaysia;
    if (shouldDefaultToMalaysia != null) {
      newShouldDefaultToMalaysia = shouldDefaultToMalaysia;
    } else if (clearCountry) {
      newShouldDefaultToMalaysia = true;
    } else if (country != null) {
      newShouldDefaultToMalaysia = false;
    } else {
      newShouldDefaultToMalaysia = this.shouldDefaultToMalaysia;
    }

    return UniversityFilterModel(
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      country: clearCountry ? null : (country ?? this.country),
      city: clearCity ? null : (city ?? this.city),
      topN: clearTopN ? null : (topN ?? this.topN),
      minStudents: clearStudents ? null : (minStudents ?? this.minStudents),
      maxStudents: clearStudents ? null : (maxStudents ?? this.maxStudents),
      minTuitionFeeMYR: clearTuition ? null : (minTuitionFeeMYR ?? this.minTuitionFeeMYR),
      maxTuitionFeeMYR: clearTuition ? null : (maxTuitionFeeMYR ?? this.maxTuitionFeeMYR),
      institutionType: clearInstitutionType ? null : (institutionType ?? this.institutionType),
      rankingSortOrder: clearRankingSort ? null : (rankingSortOrder ?? this.rankingSortOrder),
      shouldDefaultToMalaysia: newShouldDefaultToMalaysia,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'searchQuery': searchQuery,
      'country': country,
      'city': city,
      'topN': topN,
      'minStudents': minStudents,
      'maxStudents': maxStudents,
      'minTuitionFeeMYR': minTuitionFeeMYR,
      'maxTuitionFeeMYR': maxTuitionFeeMYR,
      'institutionType': institutionType,
      'rankingSortOrder': rankingSortOrder,
      'shouldDefaultToMalaysia': shouldDefaultToMalaysia,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UniversityFilterModel &&
        other.searchQuery == searchQuery &&
        other.country == country &&
        other.city == city &&
        other.topN == topN &&
        other.minStudents == minStudents &&
        other.maxStudents == maxStudents &&
        other.minTuitionFeeMYR == minTuitionFeeMYR &&
        other.maxTuitionFeeMYR == maxTuitionFeeMYR &&
        other.institutionType == institutionType &&
        other.rankingSortOrder == rankingSortOrder &&
        other.shouldDefaultToMalaysia == shouldDefaultToMalaysia;
  }

  @override
  int get hashCode {
    return Object.hash(
      searchQuery,
      country,
      city,
      topN,
      minStudents,
      maxStudents,
      minTuitionFeeMYR,
      maxTuitionFeeMYR,
      institutionType,
      rankingSortOrder,
      shouldDefaultToMalaysia,
    );
  }
}