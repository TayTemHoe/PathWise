import 'package:cloud_firestore/cloud_firestore.dart';

// Helper functions to handle different types of data conversion
T? _as<T>(dynamic v) => v is T ? v : null;

String _s(dynamic v) => v?.toString() ?? '';

int? _i(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

double? _d(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

List<String> _ls(dynamic v) {
  if (v is List) return v.map((e) => e.toString()).toList();
  return const <String>[];
}

List<Map<String, dynamic>> _lm(dynamic v) {
  if (v == null) return [];
  if (v is List) {
    return v.map((e) {
      if (e is Map<String, dynamic>) return e;
      if (e is Map) return Map<String, dynamic>.from(e);
      return <String, dynamic>{};
    }).toList();
  }
  return [];
}

Map<String, num> _salaryMap(dynamic v) {
  if (v is Map) {
    final out = <String, num>{};
    if (v.containsKey('min')) {
      final mn = _d(v['min']);
      if (mn != null) out['min'] = mn;
    }
    if (v.containsKey('max')) {
      final mx = _d(v['max']);
      if (mx != null) out['max'] = mx;
    }
    return out;
  }
  return <String, num>{};
}

/// Helper method to parse Timestamp to DateTime
DateTime? _dt(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  try {
    return DateTime.parse(v.toString());
  } catch (_) {
    return null;
  }
}

/// Helper method to parse boolean values
bool _b(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  return false;
}

/// Representing career suggestions fetched from Firestore
class CareerSuggestion {
  final String id;
  final DateTime createdAt;
  final String modelVersion;
  final bool isLatest;
  final int profileCompletionPercent;
  final List<CareerMatch> matches;

  CareerSuggestion({
    required this.id,
    required this.createdAt,
    required this.modelVersion,
    required this.isLatest,
    required this.profileCompletionPercent,
    required this.matches,
  });

  /// Factory constructor to create CareerSuggestion from Firestore document
  factory CareerSuggestion.fromFirestore(DocumentSnapshot<Map<String, dynamic>> data, String id) {
    return CareerSuggestion(
      id: id,
      createdAt: _dt(data['createdAt']) ?? DateTime.now(),
      modelVersion: _s(data['modelVersion']),
      isLatest: _b(data['isLatest']),
      profileCompletionPercent: _i(data['profileCompletionPercent']) ?? 0,
      matches: (_lm(data['matches']) as List)
          .map((e) => CareerMatch.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Method to convert CareerSuggestion object to Firestore map for storage
  Map<String, dynamic> toMap() {
    return {
      'createdAt': Timestamp.fromDate(createdAt),
      'modelVersion': modelVersion,
      'isLatest': isLatest,
      'profileCompletionPercent': profileCompletionPercent,
      'matches': matches.map((e) => e.toMap()).toList(),
    };
  }

  CareerSuggestion copyWith({
    String? id,
    DateTime? createdAt,
    String? modelVersion,
    bool? isLatest,
    int? profileCompletionPercent,
    List<CareerMatch>? matches,
  }) {
    return CareerSuggestion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      modelVersion: modelVersion ?? this.modelVersion,
      isLatest: isLatest ?? this.isLatest,
      profileCompletionPercent:
      profileCompletionPercent ?? this.profileCompletionPercent,
      matches: matches ?? this.matches,
    );
  }
}

/// Representing individual career match details
class CareerMatch {
  final String jobTitle;
  final String shortDescription;
  final int fitScore;
  final Map<String, num> avgSalaryMYR;
  final String jobGrowth;
  final String jobsDescription;
  final List<String> reasons;
  final List<String> topSkillsNeeded;
  final List<String> suggestedNextSteps;

  CareerMatch({
    required this.jobTitle,
    required this.shortDescription,
    required this.fitScore,
    required this.avgSalaryMYR,
    required this.jobGrowth,
    required this.jobsDescription,
    required this.reasons,
    required this.topSkillsNeeded,
    required this.suggestedNextSteps,
  });

  /// Factory constructor to create CareerMatch from Firestore data
  factory CareerMatch.fromMap(Map<String, dynamic> data) {
    return CareerMatch(
      jobTitle: _s(data['job_title']),
      shortDescription: _s(data['short_description']),
      fitScore: _i(data['fit_score']) ?? 0,
      avgSalaryMYR: _salaryMap(data['avg_salary_MYR']),
      jobGrowth: _s(data['job_growth']),
      jobsDescription: _s(data['jobsDescription']),
      reasons: _ls(data['reasons']),
      topSkillsNeeded: _ls(data['top_skills_needed']),
      suggestedNextSteps: _ls(data['suggested_next_steps']),
    );
  }

  /// Convert CareerMatch to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'job_title': jobTitle,
      'short_description': shortDescription,
      'fit_score': fitScore,
      'avg_salary_MYR': avgSalaryMYR,
      'job_growth': jobGrowth,
      'jobsDescription': jobsDescription,
      'reasons': reasons,
      'top_skills_needed': topSkillsNeeded,
      'suggested_next_steps': suggestedNextSteps,
    };
  }

  CareerMatch copyWith({
    String? jobTitle,
    String? shortDescription,
    int? fitScore,
    Map<String, num>? avgSalaryMYR,
    String? jobGrowth,
    String? jobsDescription,
    List<String>? reasons,
    List<String>? topSkillsNeeded,
    List<String>? suggestedNextSteps,
  }) {
    return CareerMatch(
      jobTitle: jobTitle ?? this.jobTitle,
      shortDescription: shortDescription ?? this.shortDescription,
      fitScore: fitScore ?? this.fitScore,
      avgSalaryMYR: avgSalaryMYR ?? this.avgSalaryMYR,
      jobGrowth: jobGrowth ?? this.jobGrowth,
      jobsDescription: jobsDescription ?? this.jobsDescription,
      reasons: reasons ?? this.reasons,
      topSkillsNeeded: topSkillsNeeded ?? this.topSkillsNeeded,
      suggestedNextSteps: suggestedNextSteps ?? this.suggestedNextSteps,
    );
  }
}