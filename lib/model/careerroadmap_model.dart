import 'package:cloud_firestore/cloud_firestore.dart';

/// Root model for Career Roadmap — handles Firestore + Gemini JSON conversion.
class CareerRoadmap {
  final String jobTitle;
  final List<RoadmapStage> roadmap;

  CareerRoadmap({
    required this.jobTitle,
    required this.roadmap,
  });

  /// Convert Firestore / JSON → CareerRoadmap
  factory CareerRoadmap.fromMap(Map<String, dynamic> map) {
    return CareerRoadmap(
      jobTitle: map['jobTitle'] ?? '',
      roadmap: (map['roadmap'] as List<dynamic>? ?? [])
          .map((e) => RoadmapStage.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  /// Convert CareerRoadmap → Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'jobTitle': jobTitle,
      'roadmap': roadmap.map((e) => e.toMap()).toList(),
    };
  }
}

/// A single stage within a career roadmap (e.g., Junior → Senior → Lead).
class RoadmapStage {
  final String jobTitle;
  final List<String> requiredSkills;
  final String estimatedTimeframe;
  final List<String> progressionMilestones;
  final String responsibilities;
  final String salaryRange;

  RoadmapStage({
    required this.jobTitle,
    required this.requiredSkills,
    required this.estimatedTimeframe,
    required this.progressionMilestones,
    required this.responsibilities,
    required this.salaryRange,
  });

  factory RoadmapStage.fromMap(Map<String, dynamic> map) {
    return RoadmapStage(
      jobTitle: map['jobTitle'] ?? '',
      requiredSkills: List<String>.from(map['requiredSkills'] ?? []),
      estimatedTimeframe: map['estimatedTimeframe'] ?? '',
      progressionMilestones: List<String>.from(map['progressionMilestones'] ?? []),
      responsibilities: map['responsibilities'] ?? '',
      salaryRange: map['salaryRange'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobTitle': jobTitle,
      'requiredSkills': requiredSkills,
      'estimatedTimeframe': estimatedTimeframe,
      'progressionMilestones': progressionMilestones,
      'responsibilities': responsibilities,
      'salaryRange': salaryRange,
    };
  }
}

/// SkillGap model — stores multiple skill gaps in a single document.
class SkillGap {
  final String careerRoadmapId;
  final List<SkillGapEntry> skillgaps;

  SkillGap({
    required this.careerRoadmapId,
    required this.skillgaps,
  });

  factory SkillGap.fromMap(Map<String, dynamic> map) {
    return SkillGap(
      careerRoadmapId: map['careerRoadmapId'] ?? '',
      skillgaps: (map['skillgaps'] as List<dynamic>? ?? [])
          .map((e) => SkillGapEntry.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'careerRoadmapId': careerRoadmapId,
      'skillgaps': skillgaps.map((e) => e.toMap()).toList(),
    };
  }
}

/// A single skill gap entry inside SkillGap
class SkillGapEntry {
  final String skillName;
  final int userProficiencyLevel;
  final int requiredProficiencyLevel;
  final String priorityLevel;

  SkillGapEntry({
    required this.skillName,
    required this.userProficiencyLevel,
    required this.requiredProficiencyLevel,
    required this.priorityLevel,
  });

  factory SkillGapEntry.fromMap(Map<String, dynamic> map) {
    return SkillGapEntry(
      skillName: map['skillName'] ?? '',
      userProficiencyLevel: map['userProficiencyLevel'] ?? 0,
      requiredProficiencyLevel: map['requiredProficiencyLevel'] ?? 0,
      priorityLevel: map['priorityLevel'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'skillName': skillName,
      'userProficiencyLevel': userProficiencyLevel,
      'requiredProficiencyLevel': requiredProficiencyLevel,
      'priorityLevel': priorityLevel,
    };
  }
}

/// LearningResource model — stores multiple learning resource suggestions.
class LearningResource {
  final String skillGapId;
  final bool isLatest;
  final List<LearningResourceEntry> resources;

  LearningResource({
    required this.skillGapId,
    required this.isLatest,
    required this.resources,
  });

  factory LearningResource.fromMap(Map<String, dynamic> map) {
    return LearningResource(
      skillGapId: map['skillGapId'] ?? '',
      isLatest: map['isLatest'] ?? false,
      resources: (map['resources'] as List<dynamic>? ?? [])
          .map((e) => LearningResourceEntry.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'skillGapId': skillGapId,
      'isLatest': isLatest,
      'resources': resources.map((e) => e.toMap()).toList(),
    };
  }
}

/// A single learning resource item inside LearningResource
class LearningResourceEntry {
  final String courseName;
  final String provider;
  final String courseLink;
  final int cost;
  final String certification;

  LearningResourceEntry({
    required this.courseName,
    required this.provider,
    required this.courseLink,
    required this.cost,
    required this.certification,
  });

  factory LearningResourceEntry.fromMap(Map<String, dynamic> map) {
    return LearningResourceEntry(
      courseName: map['courseName'] ?? '',
      provider: map['provider'] ?? '',
      courseLink: map['courseLink'] ?? '',
      cost: map['cost'] ?? 0,
      certification: map['certification'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseName': courseName,
      'provider': provider,
      'courseLink': courseLink,
      'cost': cost,
      'certification': certification,
    };
  }
}
