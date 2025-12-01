import 'branch.dart';

class UniversityModel {
  final String universityId;
  final String universityName;
  final String universityLogo;
  final String universityUrl;
  final String uniDescription;
  final String? domesticTuitionFee;
  final String? internationalTuitionFee;
  final int? totalStudents;
  final int? internationalStudents;
  final int? totalFacultyStaff;
  final int? minRanking;
  final int? maxRanking;
  final int? countryRank;
  final List<BranchModel> branches;
  final int programCount;

  UniversityModel({
    required this.universityId,
    required this.universityName,
    required this.universityLogo,
    required this.universityUrl,
    required this.uniDescription,
    this.domesticTuitionFee,
    this.internationalTuitionFee,
    this.totalStudents,
    this.internationalStudents,
    this.totalFacultyStaff,
    this.minRanking,
    this.maxRanking,
    this.countryRank,
    this.branches = const [],
    this.programCount = 0,
  });

  UniversityModel copyWith({
    String? universityId,
    String? universityName,
    String? universityLogo,
    String? universityUrl,
    String? uniDescription,
    String? domesticTuitionFee,
    String? internationalTuitionFee,
    int? totalStudents,
    int? internationalStudents,
    int? totalFacultyStaff,
    int? minRanking,
    int? maxRanking,
    int? countryRank, // <-- ADD HERE
    List<BranchModel>? branches,
    int? programCount,
  }) {
    return UniversityModel(
      universityId: universityId ?? this.universityId,
      universityName: universityName ?? this.universityName,
      universityLogo: universityLogo ?? this.universityLogo,
      universityUrl: universityUrl ?? this.universityUrl,
      uniDescription: uniDescription ?? this.uniDescription,
      domesticTuitionFee: domesticTuitionFee ?? this.domesticTuitionFee,
      internationalTuitionFee: internationalTuitionFee ?? this.internationalTuitionFee,
      totalStudents: totalStudents ?? this.totalStudents,
      internationalStudents: internationalStudents ?? this.internationalStudents,
      totalFacultyStaff: totalFacultyStaff ?? this.totalFacultyStaff,
      minRanking: minRanking ?? this.minRanking,
      maxRanking: maxRanking ?? this.maxRanking,
      countryRank: countryRank, // <-- Use the new value (important not to use ?? this.countryRank here
      // if you explicitly pass null to clear the rank)
      branches: branches ?? this.branches,
      programCount: programCount ?? this.programCount,
    );
  }

  factory UniversityModel.fromJson(Map<String, dynamic> json) {
    return UniversityModel(
      universityId: json['university_id'] ?? '',
      universityName: json['university_name'] ?? '',
      universityLogo: json['university_logo'] ?? '',
      universityUrl: json['university_url'] ?? '',
      uniDescription: json['uni_description'] ?? '',
      domesticTuitionFee: json['domestic_tuition_fee'],
      internationalTuitionFee: json['international_tuition_fee'],
      totalStudents: json['total_students'],
      internationalStudents: json['international_students'],
      totalFacultyStaff: json['total_faculty_staff'],
      minRanking: json['min_ranking'],
      maxRanking: json['max_ranking'],
      branches: [],
      programCount: json['program_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'university_id': universityId,
      'university_name': universityName,
      'university_logo': universityLogo,
      'university_url': universityUrl,
      'uni_description': uniDescription,
      'domestic_tuition_fee': domesticTuitionFee,
      'international_tuition_fee': internationalTuitionFee,
      'total_students': totalStudents,
      'international_students': internationalStudents,
      'total_faculty_staff': totalFacultyStaff,
      'min_ranking' : minRanking,
      'max_ranking' : maxRanking,
      'program_count': programCount,
    };
  }

  bool get isTopRanked {
    // Only true if the repository has actively assigned a countryRank for ranking/country filter.
    return countryRank != null && countryRank! <= 3;
  }

  String get institutionType => 'Private'; // Can be enhanced
}