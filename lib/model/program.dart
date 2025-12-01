class ProgramModel {
  final String programId;
  final String branchId;
  final String programName;
  final String programUrl;
  final String progDescription;
  final String? durationMonths;
  final String? subjectArea;
  final String? studyLevel;
  final String? studyMode;
  final List<String> intakePeriod;
  final String? minDomesticTuitionFee;
  final String? minInternationalTuitionFee;
  final String? entryRequirement;
  final int? minSubjectRanking;
  final int? maxSubjectRanking;
  final String universityId;

  ProgramModel({
    required this.programId,
    required this.branchId,
    required this.programName,
    required this.programUrl,
    required this.progDescription,
    this.durationMonths,
    this.subjectArea,
    this.studyLevel,
    this.studyMode,
    this.intakePeriod = const [],
    this.minDomesticTuitionFee,
    this.minInternationalTuitionFee,
    this.entryRequirement,
    this.minSubjectRanking,
    this.maxSubjectRanking,
    required this.universityId,
  });

  factory ProgramModel.fromJson(Map<String, dynamic> json) {
    return ProgramModel(
      programId: json['program_id'] ?? '',
      branchId: json['branch_id'] ?? '',
      programName: json['program_name'] ?? '',
      programUrl: json['program_url'] ?? '',
      progDescription: json['prog_description'] ?? '',
      durationMonths: json['duration_months']?.toString(),
      subjectArea: json['subject_area'],
      studyLevel: json['study_level'],
      studyMode: json['study_mode'],
      intakePeriod: json['intake_period'] != null
          ? List<String>.from(json['intake_period'])
          : [],
      minDomesticTuitionFee: json['min_domestic_tuition_fee'],
      minInternationalTuitionFee: json['min_international_tuition_fee'],
      entryRequirement: json['entry_requirement'],
      minSubjectRanking: json['min_subject_ranking'],
      maxSubjectRanking: json['max_subject_ranking'],
      universityId: json['university_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'program_id': programId,
      'branch_id': branchId,
      'program_name': programName,
      'program_url': programUrl,
      'prog_description': progDescription,
      'duration_months': durationMonths,
      'subject_area': subjectArea,
      'study_level': studyLevel,
      'study_mode': studyMode,
      'intake_period': intakePeriod,
      'min_domestic_tuition_fee': minDomesticTuitionFee,
      'min_international_tuition_fee': minInternationalTuitionFee,
      'entry_requirement': entryRequirement,
      'min_subject_ranking': minSubjectRanking,
      'max_subject_ranking': maxSubjectRanking,
      'university_id': universityId,
    };
  }

  /// Convert duration from months to years
  double? get durationYears {
    if (durationMonths == null) return null;
    final months = int.tryParse(durationMonths!);
    if (months == null) return null;
    return months / 12.0;
  }

  /// Get formatted duration display
  String get formattedDuration {
    final years = durationYears;
    if (years == null) return 'Duration not specified';

    if (years == years.toInt()) {
      return '${years.toInt()} ${years.toInt() == 1 ? "year" : "years"}';
    } else {
      return '${years.toStringAsFixed(1)} years';
    }
  }

  /// Check if program has subject ranking
  bool get hasSubjectRanking => minSubjectRanking != null;

  /// Get formatted subject ranking
  String get formattedSubjectRanking {
    if (minSubjectRanking == null) return 'Unranked';

    if (maxSubjectRanking == null || minSubjectRanking == maxSubjectRanking) {
      return '#$minSubjectRanking';
    }

    return '#$minSubjectRanking - #$maxSubjectRanking';
  }

  /// Check if program is top 3 in subject area
  bool get isTopRanked {
    if (minSubjectRanking == null) return false;
    return minSubjectRanking! <= 3;
  }

  /// Check if program is top 100
  bool get isTop100 {
    if (minSubjectRanking == null) return false;
    return minSubjectRanking! <= 100;
  }
}