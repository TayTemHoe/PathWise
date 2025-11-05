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
    this.branches = const [],
    this.programCount = 0,
  });

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
    if (minRanking == null) return false;
    final rank = minRanking;
    return rank! <= 3;
  }

  String get institutionType => 'Private'; // Can be enhanced
}