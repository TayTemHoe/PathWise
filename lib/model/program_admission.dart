// lib/model/program_admission.dart
class ProgramAdmissionModel {
  final String progAdmissionId;
  final String programId;
  final String? progAdmissionLabel;
  final String? progAdmissionValue;

  ProgramAdmissionModel({
    required this.progAdmissionId,
    required this.programId,
    this.progAdmissionLabel,
    this.progAdmissionValue,
  });

  factory ProgramAdmissionModel.fromJson(Map<String, dynamic> json) {
    return ProgramAdmissionModel(
      progAdmissionId: json['prog_admission_id'] ?? '',
      programId: json['program_id'] ?? '',
      progAdmissionLabel: json['prog_admission_label'],
      progAdmissionValue: json['prog_admission_value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prog_admission_id': progAdmissionId,
      'program_id': programId,
      'prog_admission_label': progAdmissionLabel,
      'prog_admission_value': progAdmissionValue,
    };
  }
}