// lib/model/ai_match_models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Education levels enum
enum EducationLevel {
  spm('SPM / IGCSE / O-Level'),
  stpm('STPM / A-Level / IB / UEC'),
  foundation('Foundation / Matriculation'),
  diploma('Diploma'),
  bachelor('Bachelor'),
  master('Master'),
  phd('PhD'),
  other('Other');

  final String label;

  const EducationLevel(this.label);
}

/// Academic record model - ENHANCED VERSION
class AcademicRecord {
  final String id;
  final int? order;
  final String level;
  final List<SubjectGrade> subjects;
  final String? programName;
  final String? institution;
  final double? cgpa;
  final String? major;
  final String? examType; // For SPM/STPM: SPM, IGCSE, STPM, A-Level, etc.
  final String? stream; // For SPM/STPM: Science, Arts, Commerce, etc.
  final String? classOfAward; // For Diploma: High Distinction, Distinction, etc.
  final String? honors; // For Bachelor: First Class, Second Upper, etc.
  final String? classification; // For Master: Distinction, Merit, Pass
  final String? researchArea; // For Master/PhD
  final String? thesisTitle; // For Master/PhD
  final double? totalScore; // For IB/UEC scores
  final Timestamp? startDate;
  final Timestamp? endDate; // date only
  final bool? isCurrent;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  AcademicRecord({
    this.id = '',
    this.order,
    required this.level,
    this.subjects = const [],
    this.programName,
    this.institution,
    this.cgpa,
    this.major,
    this.examType,
    this.stream,
    this.classOfAward,
    this.honors,
    this.classification,
    this.researchArea,
    this.thesisTitle,
    this.totalScore,
    this.startDate,
    this.endDate,
    this.isCurrent,
    this.createdAt,
    this.updatedAt,
  });

  factory AcademicRecord.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return AcademicRecord(
      id: doc.id,
      level: data['level'],
      order: data['order'] as int?,
      subjects: (data['subjects'] as List<dynamic>? ?? [])
          .map((e) => SubjectGrade.fromMap(e as Map<String, dynamic>))
          .toList(),
      programName: data['program_name'],
      institution: data['institution'],
      cgpa: (data['cgpa'] as num?)?.toDouble(),
      major: data['major'],
      examType: data['exam_type'],
      stream: data['stream'],
      classOfAward: data['class_of_award'],
      honors: data['honors'],
      classification: data['classification'],
      researchArea: data['research_area'],
      thesisTitle: data['thesis_title'],
      totalScore: (data['total_score'] as num?)?.toDouble(),
      startDate: data['startDate'] as Timestamp?,
      endDate: data['endDate'] as Timestamp?,
      isCurrent: data['is_current'] as bool?,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'level': level,
      if (order != null) 'order': order,
      'subjects': subjects.map((s) => s.toJson()).toList(),
      if (programName != null) 'program_name': programName,
      if (institution != null) 'institution': institution,
      if (cgpa != null) 'cgpa': cgpa,
      if (major != null) 'major': major,
      if (examType != null) 'exam_type': examType,
      if (stream != null) 'stream': stream,
      if (classOfAward != null) 'class_of_award': classOfAward,
      if (honors != null) 'honors': honors,
      if (classification != null) 'classification': classification,
      if (researchArea != null) 'research_area': researchArea,
      if (thesisTitle != null) 'thesis_title': thesisTitle,
      if (totalScore != null) 'total_score': totalScore,
      // ✅ Convert Timestamp to milliseconds for JSON serialization
      if (startDate != null) 'start_date': startDate!.millisecondsSinceEpoch,
      if (endDate != null) 'end_date': endDate!.millisecondsSinceEpoch,
      if (isCurrent != null) 'is_current': isCurrent,
      if (createdAt != null) 'createdAt': createdAt!.millisecondsSinceEpoch,
      if (updatedAt != null) 'updatedAt': updatedAt!.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (id.isNotEmpty) 'id': id,
      'level': level,
      if (order != null) 'order': order,
      'subjects': subjects.map((s) => s.toJson()).toList(),

      // ✅ USE CAMELCASE FOR FIRESTORE (not snake_case like toJson)
      if (programName != null) 'program_name': programName,
      if (institution != null) 'institution': institution,
      if (cgpa != null) 'cgpa': cgpa,
      if (major != null) 'major': major,
      if (examType != null) 'exam_type': examType,
      if (stream != null) 'stream': stream,
      if (classOfAward != null) 'class_of_award': classOfAward,
      if (honors != null) 'honors': honors,
      if (classification != null) 'classification': classification,
      if (researchArea != null) 'research_area': researchArea,
      if (thesisTitle != null) 'thesis_title': thesisTitle,
      if (totalScore != null) 'total_score': totalScore,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (isCurrent != null) 'is_current': isCurrent,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  factory AcademicRecord.fromJson(Map<String, dynamic> json) {
    // Helper to parse Timestamp from either milliseconds (int) or Timestamp object
    Timestamp? parseTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value;
      if (value is int) return Timestamp.fromMillisecondsSinceEpoch(value);
      return null;
    }

    return AcademicRecord(
      id: json['id'] as String? ?? '',
      level: json['level'] as String,
      order: json['order'] as int?,
      subjects: (json['subjects'] as List<dynamic>?)
          ?.map((s) => SubjectGrade.fromJson(s as Map<String, dynamic>))
          .toList() ??
          [],
      programName: json['program_name'] as String?,
      institution: json['institution'] as String?,
      cgpa: (json['cgpa'] as num?)?.toDouble(),
      major: json['major'] as String?,
      examType: json['exam_type'] as String?,
      stream: json['stream'] as String?,
      classOfAward: json['class_of_award'] as String?,
      honors: json['honors'] as String?,
      classification: json['classification'] as String?,
      researchArea: json['research_area'] as String?,
      thesisTitle: json['thesis_title'] as String?,
      totalScore: (json['total_score'] as num?)?.toDouble(),
      // ✅ Handle both int (milliseconds) and Timestamp
      startDate: parseTimestamp(json['start_date']),
      endDate: parseTimestamp(json['end_date']),
      isCurrent: json['is_current'] as bool?,
      createdAt: parseTimestamp(json['createdAt']),
      updatedAt: parseTimestamp(json['updatedAt']),
    );
  }

  AcademicRecord copyWith({
    String? id,
    String? level,
    int? order,
    List<SubjectGrade>? subjects,
    String? programName,
    String? institution,
    double? cgpa,
    String? major,
    String? examType,
    String? stream,
    String? classOfAward,
    String? honors,
    String? classification,
    String? researchArea,
    String? thesisTitle,
    double? totalScore,
    Timestamp? startDate,
    Timestamp? endDate,
    bool? isCurrent,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return AcademicRecord(
      id: id ?? this.id,
      level: level ?? this.level,
      order: order ?? this.order,
      subjects: subjects ?? this.subjects,
      programName: programName ?? this.programName,
      institution: institution ?? this.institution,
      cgpa: cgpa ?? this.cgpa,
      major: major ?? this.major,
      examType: examType ?? this.examType,
      stream: stream ?? this.stream,
      classOfAward: classOfAward ?? this.classOfAward,
      honors: honors ?? this.honors,
      classification: classification ?? this.classification,
      researchArea: researchArea ?? this.researchArea,
      thesisTitle: thesisTitle ?? this.thesisTitle,
      totalScore: totalScore ?? this.totalScore,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Subject grade model
class SubjectGrade {
  final String name;
  final String grade;
  final int? year;

  SubjectGrade({required this.name, required this.grade, this.year});

  factory SubjectGrade.fromMap(Map<String, dynamic> map) {
    return SubjectGrade(
      name: map['name'] ?? '',
      grade: map['grade'] ?? '',
      year: map['year'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'grade': grade,
      if (year != null) 'assessment_year': year,
    };
  }

  factory SubjectGrade.fromJson(Map<String, dynamic> json) {
    return SubjectGrade(
      name: json['name'] as String,
      grade: json['grade'] as String,
      year: json['assessment_year'] as int?,
    );
  }
}

/// English test model
class EnglishTest {
  final String type;
  final dynamic result;
  final Map<String, dynamic>? bands;
  final int? year;

  EnglishTest({
    required this.type,
    required this.result,
    this.bands,
    this.year,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'result': result,
      if (bands != null) 'bands': bands,
      if (year != null) 'year': year,
    };
  }

  factory EnglishTest.fromJson(Map<String, dynamic> json) {
    return EnglishTest(
      type: json['type'] as String,
      result: json['result'],
      bands: json['bands'] as Map<String, dynamic>?,
      year: json['year'] as int?,
    );
  }
}

/// Personality profile model
class PersonalityProfile {
  final Map<String, double>? riasec;
  final String? mbti;
  final Map<String, double>? ocean;

  PersonalityProfile({this.riasec, this.mbti, this.ocean});

  Map<String, dynamic> toJson() {
    return {
      if (riasec != null) 'RIASEC': riasec,
      if (mbti != null) 'MBTI': mbti,
      if (ocean != null) 'OCEAN': ocean,
    };
  }

  factory PersonalityProfile.fromJson(Map<String, dynamic> json) {
    return PersonalityProfile(
      riasec: (json['RIASEC'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      mbti: json['MBTI'] as String?,
      ocean: (json['OCEAN'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
    );
  }

  bool get hasData => riasec != null || mbti != null || ocean != null;
}

/// User preferences model
class UserPreferences {
  final List<String> studyLevel;
  final double? tuitionMin;
  final double? tuitionMax;
  final List<String> locations;
  final List<String> mode;
  final bool scholarshipRequired;
  final int? minRanking;
  final int? maxRanking;
  final bool workStudyImportant;
  final bool hasSpecialNeeds;
  final String? specialNeedsDetails;

  UserPreferences({
    this.studyLevel = const [],
    this.tuitionMin,
    this.tuitionMax,
    this.locations = const [],
    this.mode = const [],
    this.scholarshipRequired = false,
    this.minRanking,
    this.maxRanking,
    this.workStudyImportant = false,
    this.hasSpecialNeeds = false,
    this.specialNeedsDetails,
  });

  Map<String, dynamic> toJson() {
    return {
      'study_level': studyLevel,
      if (tuitionMin != null) 'tuition_min': tuitionMin,
      if (tuitionMax != null) 'tuition_max': tuitionMax,
      'locations': locations,
      'mode': mode,
      'scholarship_required': scholarshipRequired,
      if (minRanking != null) 'min_ranking': minRanking,
      if (maxRanking != null) 'max_ranking': maxRanking,
      'work_study_important': workStudyImportant,
      'has_special_needs': hasSpecialNeeds,
      if (specialNeedsDetails != null)
        'special_needs_details': specialNeedsDetails,
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      studyLevel: (json['study_level'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          [],
      tuitionMin: (json['tuition_min'] as num?)?.toDouble(),
      tuitionMax: (json['tuition_max'] as num?)?.toDouble(),
      locations: (json['locations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          [],
      mode: (json['mode'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      scholarshipRequired: json['scholarship_required'] as bool? ?? false,
      minRanking: json['min_ranking'] as int?,
      maxRanking: json['max_ranking'] as int?,
      workStudyImportant: json['work_study_important'] as bool? ?? false,
      hasSpecialNeeds: json['has_special_needs'] as bool? ?? false,
      specialNeedsDetails: json['special_needs_details'] as String?,
    );
  }
}

/// AI match request model
class AIMatchRequest {
  final List<AcademicRecord> academicRecords;
  final List<EnglishTest> englishTests;
  final PersonalityProfile? personality;
  final List<String> interests;
  final UserPreferences preferences;

  AIMatchRequest({
    required this.academicRecords,
    required this.englishTests,
    this.personality,
    required this.interests,
    required this.preferences,
  });

  Map<String, dynamic> toJson() {
    return {
      'academic_records': academicRecords.map((r) => r.toJson()).toList(),
      'english_tests': englishTests.map((t) => t.toJson()).toList(),
      if (personality != null) 'personality': personality!.toJson(),
      'interests': interests,
      'preferences': preferences.toJson(),
    };
  }

  factory AIMatchRequest.fromJson(Map<String, dynamic> json) {
    return AIMatchRequest(
      academicRecords: (json['academic_records'] as List<dynamic>)
          .map((r) => AcademicRecord.fromJson(r as Map<String, dynamic>))
          .toList(),
      englishTests: (json['english_tests'] as List<dynamic>)
          .map((t) => EnglishTest.fromJson(t as Map<String, dynamic>))
          .toList(),
      personality: json['personality'] != null
          ? PersonalityProfile.fromJson(
        json['personality'] as Map<String, dynamic>,
      )
          : null,
      interests:
      (json['interests'] as List<dynamic>).map((i) => i as String).toList(),
      preferences: UserPreferences.fromJson(
        json['preferences'] as Map<String, dynamic>,
      ),
    );
  }
}

/// Recommended subject area model
class RecommendedSubjectArea {
  final String subjectArea;
  final double matchScore;
  final String reason;
  final List<String> topSkills;
  final List<String> relatedInterests;
  final PersonalityProfile? personalityFit;
  final String difficultyLevel;
  final List<String> studyModes;
  final List<String> careerPaths;

  RecommendedSubjectArea({
    required this.subjectArea,
    required this.matchScore,
    required this.reason,
    required this.topSkills,
    required this.relatedInterests,
    this.personalityFit,
    required this.difficultyLevel,
    required this.studyModes,
    required this.careerPaths,
  });

  factory RecommendedSubjectArea.fromJson(Map<String, dynamic> json) {
    return RecommendedSubjectArea(
      subjectArea: json['subject_area'] as String,
      matchScore: (json['match_score'] as num).toDouble(),
      reason: json['reason'] as String,
      topSkills: (json['top_skills'] as List<dynamic>)
          .map((s) => s as String)
          .toList(),
      relatedInterests: (json['related_interests'] as List<dynamic>)
          .map((i) => i as String)
          .toList(),
      personalityFit: json['personality_fit'] != null
          ? PersonalityProfile.fromJson(
        json['personality_fit'] as Map<String, dynamic>,
      )
          : null,
      difficultyLevel: json['difficulty_level'] as String,
      studyModes: (json['study_modes'] as List<dynamic>)
          .map((m) => m as String)
          .toList(),
      careerPaths: (json['career_paths'] as List<dynamic>)
          .map((c) => c as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject_area': subjectArea,
      'match_score': matchScore,
      'reason': reason,
      'top_skills': topSkills,
      'related_interests': relatedInterests,
      if (personalityFit != null) 'personality_fit': personalityFit!.toJson(),
      'difficulty_level': difficultyLevel,
      'study_modes': studyModes,
      'career_paths': careerPaths,
    };
  }
}

/// AI match response model
class AIMatchResponse {
  final List<RecommendedSubjectArea> recommendedSubjectAreas;

  AIMatchResponse({required this.recommendedSubjectAreas});

  factory AIMatchResponse.fromJson(Map<String, dynamic> json) {
    return AIMatchResponse(
      recommendedSubjectAreas: (json['recommended_subject_areas'] as List<dynamic>)
          .map(
            (area) => RecommendedSubjectArea.fromJson(
          area as Map<String, dynamic>,
        ),
      )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recommended_subject_areas':
      recommendedSubjectAreas.map((area) => area.toJson()).toList(),
    };
  }
}

/// Data class for loaded progress
class AIMatchProgressData {
  final EducationLevel? educationLevel;
  final String? otherEducationText;
  final List<AcademicRecord> academicRecords;
  final List<EnglishTest> englishTests;
  final PersonalityProfile? personality;
  final List<String> interests;
  final UserPreferences preferences;
  final AIMatchResponse? matchResponse;
  final List<String>? matchedProgramIds;
  final DateTime? matchTimestamp;

  AIMatchProgressData({
    this.educationLevel,
    this.otherEducationText,
    required this.academicRecords,
    required this.englishTests,
    this.personality,
    required this.interests,
    required this.preferences,
    this.matchResponse,
    this.matchedProgramIds,
    this.matchTimestamp,
  });
}