class FilterModel {
  final String? searchQuery;
  final String? country;
  final String? city;

  // RANKING RANGE: Filter universities by ranking overlap
  // Example: minRanking=1, maxRanking=100 shows universities ranked 1-100
  // Independent from ranking sort order
  final int? minRanking;
  final int? maxRanking;

  // RANKING SORT ORDER: Sort display order of results
  // 'asc' = Best rankings first (1, 2, 3...)
  // 'desc' = Worst rankings first (...998, 999, 1000)
  // Independent from ranking range filter
  final String? rankingSortOrder;

  final int? minStudents;
  final int? maxStudents;
  final double? minTuitionFeeMYR;
  final double? maxTuitionFeeMYR;
  final String? institutionType;

  FilterModel({
    this.searchQuery,
    this.country,
    this.city,
    this.minRanking,
    this.maxRanking,
    this.rankingSortOrder,
    this.minStudents,
    this.maxStudents,
    this.minTuitionFeeMYR,
    this.maxTuitionFeeMYR,
    this.institutionType,
  });

  /// Check if any filters are active
  bool get hasActiveFilters =>
      searchQuery != null ||
          country != null ||
          city != null ||
          minRanking != null ||
          maxRanking != null ||
          rankingSortOrder != null ||
          minStudents != null ||
          maxStudents != null ||
          minTuitionFeeMYR != null ||
          maxTuitionFeeMYR != null ||
          institutionType != null;

  /// Count active filters (each category counts as 1)
  int get activeFilterCount {
    int count = 0;
    if (searchQuery != null && searchQuery!.isNotEmpty) count++;
    if (country != null) count++;
    if (city != null) count++;

    // Ranking range and sort are separate filters
    if (minRanking != null || maxRanking != null) count++;
    if (rankingSortOrder != null) count++;

    if (minStudents != null || maxStudents != null) count++;
    if (minTuitionFeeMYR != null || maxTuitionFeeMYR != null) count++;
    if (institutionType != null) count++;
    return count;
  }

  /// RULE 1: Default to Malaysian universities when no location/ranking filters
  /// This affects Total Students and Tuition Fee filters
  bool get shouldDefaultToMalaysia {
    return country == null &&
        city == null &&
        minRanking == null &&
        maxRanking == null &&
        rankingSortOrder == null &&
        searchQuery == null;
  }

  FilterModel copyWith({
    String? searchQuery,
    String? country,
    String? city,
    int? minRanking,
    int? maxRanking,
    String? rankingSortOrder,
    int? minStudents,
    int? maxStudents,
    double? minTuitionFeeMYR,
    double? maxTuitionFeeMYR,
    String? institutionType,
    bool clearSearch = false,
    bool clearCountry = false,
    bool clearCity = false,
    bool clearRanking = false,
    bool clearRankingSort = false,
    bool clearStudents = false,
    bool clearTuition = false,
    bool clearInstitutionType = false,
  }) {
    return FilterModel(
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      country: clearCountry ? null : (country ?? this.country),
      city: clearCity ? null : (city ?? this.city),
      minRanking: clearRanking ? null : (minRanking ?? this.minRanking),
      maxRanking: clearRanking ? null : (maxRanking ?? this.maxRanking),
      rankingSortOrder: clearRankingSort ? null : (rankingSortOrder ?? this.rankingSortOrder),
      minStudents: clearStudents ? null : (minStudents ?? this.minStudents),
      maxStudents: clearStudents ? null : (maxStudents ?? this.maxStudents),
      minTuitionFeeMYR: clearTuition ? null : (minTuitionFeeMYR ?? this.minTuitionFeeMYR),
      maxTuitionFeeMYR: clearTuition ? null : (maxTuitionFeeMYR ?? this.maxTuitionFeeMYR),
      institutionType: clearInstitutionType ? null : (institutionType ?? this.institutionType),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'searchQuery': searchQuery,
      'country': country,
      'city': city,
      'minRanking': minRanking,
      'maxRanking': maxRanking,
      'rankingSortOrder': rankingSortOrder,
      'minStudents': minStudents,
      'maxStudents': maxStudents,
      'minTuitionFeeMYR': minTuitionFeeMYR,
      'maxTuitionFeeMYR': maxTuitionFeeMYR,
      'institutionType': institutionType,
      'shouldDefaultToMalaysia': shouldDefaultToMalaysia,
    }..removeWhere((key, value) => value == null);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FilterModel &&
        other.searchQuery == searchQuery &&
        other.country == country &&
        other.city == city &&
        other.minRanking == minRanking &&
        other.maxRanking == maxRanking &&
        other.rankingSortOrder == rankingSortOrder &&
        other.minStudents == minStudents &&
        other.maxStudents == maxStudents &&
        other.minTuitionFeeMYR == minTuitionFeeMYR &&
        other.maxTuitionFeeMYR == maxTuitionFeeMYR &&
        other.institutionType == institutionType;
  }

  @override
  int get hashCode {
    return searchQuery.hashCode ^
    country.hashCode ^
    city.hashCode ^
    minRanking.hashCode ^
    maxRanking.hashCode ^
    rankingSortOrder.hashCode ^
    minStudents.hashCode ^
    maxStudents.hashCode ^
    minTuitionFeeMYR.hashCode ^
    maxTuitionFeeMYR.hashCode ^
    institutionType.hashCode;
  }

  @override
  String toString() {
    return 'FilterModel('
        'searchQuery: $searchQuery, '
        'country: $country, '
        'city: $city, '
        'minRanking: $minRanking, '
        'maxRanking: $maxRanking, '
        'rankingSortOrder: $rankingSortOrder, '
        'minStudents: $minStudents, '
        'maxStudents: $maxStudents, '
        'minTuitionFeeMYR: $minTuitionFeeMYR, '
        'maxTuitionFeeMYR: $maxTuitionFeeMYR, '
        'institutionType: $institutionType, '
        'shouldDefaultToMalaysia: $shouldDefaultToMalaysia)';
  }
}