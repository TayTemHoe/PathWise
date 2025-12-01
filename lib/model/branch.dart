class BranchModel {
  final String branchId;
  final String universityId;
  final String branchName;
  final String country;
  final String city;

  BranchModel({
    required this.branchId,
    required this.universityId,
    required this.branchName,
    required this.country,
    required this.city,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      branchId: json['branch_id'] ?? '',
      universityId: json['university_id'] ?? '',
      branchName: json['branch_name'] ?? '',
      country: json['country'] ?? '',
      city: json['city'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'branch_id': branchId,
      'university_id': universityId,
      'branch_name': branchName,
      'country': country,
      'city': city,
    };
  }
}