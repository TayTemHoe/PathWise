// lib/model/university_admission.dart

class UniversityAdmissionModel {
  final String uniAdmissionId;
  final String universityId;
  final String? admissionType;
  final String? admissionLabel;
  final String? admissionValue;

  UniversityAdmissionModel({
    required this.uniAdmissionId,
    required this.universityId,
    this.admissionType,
    this.admissionLabel,
    this.admissionValue,
  });

  factory UniversityAdmissionModel.fromJson(Map<String, dynamic> json) {
    return UniversityAdmissionModel(
      uniAdmissionId: json['uni_admission_id'] ?? '',
      universityId: json['university_id'] ?? '',
      admissionType: json['admission_type'],
      admissionLabel: json['admission_label'],
      admissionValue: json['admission_value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uni_admission_id': uniAdmissionId,
      'university_id': universityId,
      'admission_type': admissionType,
      'admission_label': admissionLabel,
      'admission_value': admissionValue,
    };
  }

  UniversityAdmissionModel copyWith({
    String? uniAdmissionId,
    String? universityId,
    String? admissionType,
    String? admissionLabel,
    String? admissionValue,
  }) {
    return UniversityAdmissionModel(
      uniAdmissionId: uniAdmissionId ?? this.uniAdmissionId,
      universityId: universityId ?? this.universityId,
      admissionType: admissionType ?? this.admissionType,
      admissionLabel: admissionLabel ?? this.admissionLabel,
      admissionValue: admissionValue ?? this.admissionValue,
    );
  }

  @override
  String toString() {
    return 'UniversityAdmissionModel(uniAdmissionId: $uniAdmissionId, universityId: $universityId, admissionType: $admissionType, admissionLabel: $admissionLabel, admissionValue: $admissionValue)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UniversityAdmissionModel &&
        other.uniAdmissionId == uniAdmissionId &&
        other.universityId == universityId &&
        other.admissionType == admissionType &&
        other.admissionLabel == admissionLabel &&
        other.admissionValue == admissionValue;
  }

  @override
  int get hashCode {
    return uniAdmissionId.hashCode ^
    universityId.hashCode ^
    (admissionType?.hashCode ?? 0) ^
    (admissionLabel?.hashCode ?? 0) ^
    (admissionValue?.hashCode ?? 0);
  }
}