import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_wise/model/ai_match_model.dart';

/// ===============================
/// Safe parsers (resilient to type drift)
/// ===============================
String get uid {
  return 'U0001'; // fallback for local testing
}

String? _s(Object? v) => v == null ? null : v.toString();

double? _d(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int? _i(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is String) return int.tryParse(v);
  if (v is double) return v.round();
  return null;
}

bool? _b(Object? v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final t = v.toLowerCase().trim();
    if (t == 'true' || t == '1' || t == 'yes') return true;
    if (t == 'false' || t == '0' || t == 'no') return false;
  }
  return null;
}

List<String>? _list(Object? v) {
  if (v == null) return null;
  if (v is List) return v.map((e) => e.toString()).toList();
  if (v is String && v.isNotEmpty) {
    // Support "A, B, C" → ["A","B","C"]
    return v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }
  return null;
}

Map<String, dynamic>? _map(Object? v) {
  if (v == null) return null;
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return null;
}

/// ===============================
/// Root: users/{uid}
/// ===============================

class UserProfile {
  // Meta
  final double? completionPercent; // computed
  final Timestamp? lastUpdated;    // date only (you can store date-only)
  final Timestamp? createdAt;      // date only
  final int? profileFreshnessMonths;

  // Personality (map)
  final String? mbti;
  final String? riasec; // NOTE: per your spec this is now a single string
  final Timestamp? personalityUpdatedAt;

  // Preferences (map)
  final Preferences? preferences;

  // Personal Info (map)
  final String? name;
  final String? email;
  final String? phone;
  final Timestamp? dob; // date only
  final String? gender; // Male/Female/PreferNotToSay
  final String? city;
  final String? state;
  final String? country;
  final String? profilePictureUrl;

  // Subcollections: loaded separately (optional cache)
  final List<Skill>? skills;
  final List<AcademicRecord>? education;
  final List<Experience>? experience;

  const UserProfile({
    // meta
    this.completionPercent,
    this.lastUpdated,
    this.createdAt,
    this.profileFreshnessMonths,

    // personality
    this.mbti,
    this.riasec,
    this.personalityUpdatedAt,

    // preferences
    this.preferences,

    // personal info
    this.name,
    this.email,
    this.phone,
    this.dob,
    this.gender,
    this.city,
    this.state,
    this.country,
    this.profilePictureUrl,

    // subcollections
    this.skills,
    this.education,
    this.experience,
  });
  /// Robust reader for nested OR legacy-flat docs.
  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    // Nested maps
    final personal    = _map(data['personalInfo']) ?? {};
    final loc         = _map(personal['location']) ?? {};
    final prefs = Preferences.fromAny(data);
    final personality = _map(data['personality']) ?? {};

    // Helper to safely cast to Timestamp (handles both Timestamp and String)
    Timestamp? _timestamp(Object? value) {
      if (value == null) return null;
      if (value is Timestamp) return value;
      if (value is String) {
        try {
          // Try parsing ISO 8601 string to DateTime, then convert to Timestamp
          final dateTime = DateTime.parse(value);
          return Timestamp.fromDate(dateTime);
        } catch (e) {
          debugPrint('⚠️ Could not parse timestamp string: $value');
          return null;
        }
      }
      return null;
    }

    return UserProfile(
      // meta
      completionPercent: _d(data['completionPercent']),
      lastUpdated: _timestamp(data['lastUpdated']),
      createdAt: _timestamp(data['createdAt']),
      profileFreshnessMonths: _i(data['profileFreshnessMonths']),

      // personality
      mbti: _s(personality['mbti']) ?? _s(data['mbti']),
      riasec: _s(personality['riasec']) ?? _s(data['riasec']), // STRING per spec
      personalityUpdatedAt:
      _timestamp(personality['updatedAt']) ?? _timestamp(data['personalityUpdatedAt']),

      // preferences
      preferences: prefs,


      // personalInfo (nested → flat fallback)
      name: _s(personal['name']) ?? _s(data['name']),
      email: _s(personal['email']) ?? _s(data['email']),
      phone: _s(personal['phone']) ?? _s(data['phone']),
      dob: _timestamp(personal['dob']) ?? _timestamp(data['dob']),
      gender: _s(personal['gender']) ?? _s(data['gender']),
      city: _s(loc['city']) ?? _s(data['city']),
      state: _s(loc['state']) ?? _s(data['state']),
      country: _s(loc['country']) ?? _s(data['country']),
      profilePictureUrl:
      _s(personal['profilePictureUrl']) ?? _s(data['profilePictureUrl']),

      // subcollections: not loaded here
      skills: null,
      education: null,
      experience: null,
    );
  }

  /// Serialize to Firestore (nested, per your schema)
  Map<String, dynamic> toMap() {
    return {
      if (completionPercent != null) 'completionPercent': completionPercent,
      if (lastUpdated != null) 'lastUpdated': lastUpdated,
      if (createdAt != null) 'createdAt': createdAt,
      if (profileFreshnessMonths != null) 'profileFreshnessMonths': profileFreshnessMonths,

      'personality': {
        if (mbti != null) 'mbti': mbti,
        if (riasec != null) 'riasec': riasec, // string
        if (personalityUpdatedAt != null) 'updatedAt': personalityUpdatedAt,
      },

      'preferences': preferences?.toFirestore() ?? {},

      'personalInfo': {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (dob != null) 'dob': dob,
        if (gender != null) 'gender': gender,
        'location': {
          if (city != null) 'city': city,
          if (state != null) 'state': state,
          if (country != null) 'country': country,
        },
        if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
      },
    };
  }

  UserProfile copyWith({
    double? completionPercent,
    Timestamp? lastUpdated,
    Timestamp? createdAt,
    int? profileFreshnessMonths,

    String? mbti,
    String? riasec,
    Timestamp? personalityUpdatedAt,

    Preferences? preferences,

    String? name,
    String? email,
    String? phone,
    Timestamp? dob,
    String? gender,
    String? city,
    String? state,
    String? country,
    String? profilePictureUrl,

    List<Skill>? skills,
    List<AcademicRecord>? education,
    List<Experience>? experience,
    String? currentEducationId,
  }) {
    return UserProfile(
      completionPercent: completionPercent ?? this.completionPercent,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
      profileFreshnessMonths: profileFreshnessMonths ?? this.profileFreshnessMonths,

      mbti: mbti ?? this.mbti,
      riasec: riasec ?? this.riasec,
      personalityUpdatedAt: personalityUpdatedAt ?? this.personalityUpdatedAt,

      preferences: preferences ?? this.preferences,

      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,

      skills: skills ?? this.skills,
      education: education ?? this.education,
      experience: experience ?? this.experience,
    );
  }
}

/// Preferences.salary
class SalaryPref {
  final double? min;
  final double? max;
  final String? type; // "Monthly"/"Annual"
  final List<String>? benefitsPriority; // drag-order

  const SalaryPref({
    this.min,
    this.max,
    this.type,
    this.benefitsPriority,
  });

  factory SalaryPref.fromMap(Map<String, dynamic> map) {
    return SalaryPref(
      min: _d(map['min']),
      max: _d(map['max']),
      type: _s(map['type']),
      benefitsPriority: _list(map['benefitsPriority']),
    );
  }

  Map<String, dynamic> toMap() => {
    if (min != null) 'min': min,
    if (max != null) 'max': max,
    if (type != null) 'type': type,
    if (benefitsPriority != null) 'benefitsPriority': benefitsPriority,
  };

  SalaryPref copyWith({
    double? min,
    double? max,
    String? type,
    List<String>? benefitsPriority,
  }) =>
      SalaryPref(
        min: min ?? this.min,
        max: max ?? this.max,
        type: type ?? this.type,
        benefitsPriority: benefitsPriority ?? this.benefitsPriority,
      );
}

/// ===============================
/// Subcollection: users/{uid}/skills/{skillId}
/// ===============================
class Skill {
  final String id;
  final String? name;
  final String? category; // Technical/Soft/Language/Industry
  final int? level;       // 1–5 (for Technical/Soft); Language uses levelText
  final String? levelText; // e.g., Basic/Intermediate/Advanced/Native
  final Verification? verification;
  final int? order;
  final Timestamp? updatedAt; // date only

  const Skill({
    required this.id,
    this.name,
    this.category,
    this.level,
    this.levelText,
    this.verification,
    this.order,
    this.updatedAt,
  });

  factory Skill.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ver = _map(data['verification']) ?? {};
    return Skill(
      id: doc.id,
      name: _s(data['name']),
      category: _s(data['category']),
      level: _i(data['level']),
      levelText: _s(data['levelText']),
      verification: ver.isEmpty ? null : Verification.fromMap(ver),
      order: _i(data['order']),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() => {
    if (name != null) 'name': name,
    if (category != null) 'category': category,
    if (level != null) 'level': level,
    if (levelText != null) 'levelText': levelText,
    if (verification != null) 'verification': verification!.toMap(),
    if (order != null) 'order': order,
    if (updatedAt != null) 'updatedAt': updatedAt,
  };

  Skill copyWith({
    String? id,
    String? name,
    String? category,
    int? level,
    String? levelText,
    Verification? verification,
    int? order,
    Timestamp? updatedAt,
  }) =>
      Skill(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        level: level ?? this.level,
        levelText: levelText ?? this.levelText,
        verification: verification ?? this.verification,
        order: order ?? this.order,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class Verification {
  final String? certificateUrl;
  final String? portfolioUrl;

  const Verification({this.certificateUrl, this.portfolioUrl});

  factory Verification.fromMap(Map<String, dynamic> map) => Verification(
    certificateUrl: _s(map['certificateUrl']),
    portfolioUrl: _s(map['portfolioUrl']),
  );

  Map<String, dynamic> toMap() => {
    if (certificateUrl != null) 'certificateUrl': certificateUrl,
    if (portfolioUrl != null) 'portfolioUrl': portfolioUrl,
  };
}

/// ===============================
/// Subcollection: users/{uid}/education/{eduId}
/// ===============================
// class Education {
//   final String id;
//   final String? institution;
//   final String? degreeLevel;  // HighSchool/Diploma/Bachelor/Master/PhD/Other
//   final String? fieldOfStudy;
//   final Timestamp? startDate; // date only
//   final Timestamp? endDate;   // date only
//   final bool? isCurrent;
//   final String? gpa;          // string per spec
//   final String? city;
//   final String? country;
//   final int? order;           // most recent first
//   final Timestamp? updatedAt; // date only
//
//   const Education({
//     required this.id,
//     this.institution,
//     this.degreeLevel,
//     this.fieldOfStudy,
//     this.startDate,
//     this.endDate,
//     this.isCurrent,
//     this.gpa,
//     this.city,
//     this.country,
//     this.order,
//     this.updatedAt,
//   });
//
//   factory Education.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
//     final data = doc.data() ?? {};
//     final loc = _map(data['location']) ?? {};
//     return Education(
//       id: doc.id,
//       institution: _s(data['institution']),
//       degreeLevel: _s(data['degreeLevel']),
//       fieldOfStudy: _s(data['fieldOfStudy']),
//       startDate: data['startDate'] as Timestamp?,
//       endDate: data['endDate'] as Timestamp?,
//       isCurrent: _b(data['isCurrent']),
//       gpa: _s(data['gpa']),
//       city: _s(loc['city']),
//       country: _s(loc['country']),
//       order: _i(data['order']),
//       updatedAt: data['updatedAt'] as Timestamp?,
//     );
//   }
//
//   Map<String, dynamic> toMap() => {
//     if (institution != null) 'institution': institution,
//     if (degreeLevel != null) 'degreeLevel': degreeLevel,
//     if (fieldOfStudy != null) 'fieldOfStudy': fieldOfStudy,
//     if (startDate != null) 'startDate': startDate,
//     if (endDate != null) 'endDate': endDate,
//     if (isCurrent != null) 'isCurrent': isCurrent,
//     if (gpa != null) 'gpa': gpa,
//     'location': {
//       if (city != null) 'city': city,
//       if (country != null) 'country': country,
//     },
//     if (order != null) 'order': order,
//     if (updatedAt != null) 'updatedAt': updatedAt,
//   };
//
//   Education copyWith({
//     String? id,
//     String? institution,
//     String? degreeLevel,
//     String? fieldOfStudy,
//     Timestamp? startDate,
//     Timestamp? endDate,
//     bool? isCurrent,
//     String? gpa,
//     String? city,
//     String? country,
//     int? order,
//     Timestamp? updatedAt,
//   }) =>
//       Education(
//         id: id ?? this.id,
//         institution: institution ?? this.institution,
//         degreeLevel: degreeLevel ?? this.degreeLevel,
//         fieldOfStudy: fieldOfStudy ?? this.fieldOfStudy,
//         startDate: startDate ?? this.startDate,
//         endDate: endDate ?? this.endDate,
//         isCurrent: isCurrent ?? this.isCurrent,
//         gpa: gpa ?? this.gpa,
//         city: city ?? this.city,
//         country: country ?? this.country,
//         order: order ?? this.order,
//         updatedAt: updatedAt ?? this.updatedAt,
//       );
// }

/// ===============================
/// Subcollection: users/{uid}/experience/{expId}
/// ===============================
class Experience {
  final String id;
  final String? jobTitle;
  final String? company;
  final String? employmentType; // Full-time/Part-time/Contract/Internship/Freelance
  final Timestamp? startDate;   // date only
  final Timestamp? endDate;     // date only
  final bool? isCurrent;
  final String? city;
  final String? country;
  final String? industry;
  final String? description;
  final ExpAchievements? achievements; // map
  final int? order;
  final Timestamp? updatedAt;         // date only

  const Experience({
    required this.id,
    this.jobTitle,
    this.company,
    this.employmentType,
    this.startDate,
    this.endDate,
    this.isCurrent,
    this.city,
    this.country,
    this.industry,
    this.description,
    this.achievements,
    this.order,
    this.updatedAt,
  });

  factory Experience.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final loc = _map(data['location']) ?? {};
    final ach = _map(data['achievements']) ?? {};
    return Experience(
      id: doc.id,
      jobTitle: _s(data['jobTitle']),
      company: _s(data['company']),
      employmentType: _s(data['employmentType']),
      startDate: data['startDate'] as Timestamp?,
      endDate: data['endDate'] as Timestamp?,
      isCurrent: _b(data['isCurrent']),
      city: _s(loc['city']),
      country: _s(loc['country']),
      industry: _s(data['industry']),
      description: _s(data['description']),
      achievements: ach.isEmpty ? null : ExpAchievements.fromMap(ach),
      order: _i(data['order']),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() => {
    if (jobTitle != null) 'jobTitle': jobTitle,
    if (company != null) 'company': company,
    if (employmentType != null) 'employmentType': employmentType,
    if (startDate != null) 'startDate': startDate,
    if (endDate != null) 'endDate': endDate,
    if (isCurrent != null) 'isCurrent': isCurrent,
    'location': {
      if (city != null) 'city': city,
      if (country != null) 'country': country,
    },
    if (industry != null) 'industry': industry,
    if (description != null) 'description': description,
    if (achievements != null) 'achievements': achievements!.toMap(),
    if (order != null) 'order': order,
    if (updatedAt != null) 'updatedAt': updatedAt,
  };

  Experience copyWith({
    String? id,
    String? jobTitle,
    String? company,
    String? employmentType,
    Timestamp? startDate,
    Timestamp? endDate,
    bool? isCurrent,
    String? city,
    String? country,
    String? industry,
    String? description,
    ExpAchievements? achievements,
    int? order,
    Timestamp? updatedAt,
  }) =>
      Experience(
        id: id ?? this.id,
        jobTitle: jobTitle ?? this.jobTitle,
        company: company ?? this.company,
        employmentType: employmentType ?? this.employmentType,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        isCurrent: isCurrent ?? this.isCurrent,
        city: city ?? this.city,
        country: country ?? this.country,
        industry: industry ?? this.industry,
        description: description ?? this.description,
        achievements: achievements ?? this.achievements,
        order: order ?? this.order,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class ExpAchievements {
  final String? description;
  final List<String>? skillsUsed;

  const ExpAchievements({this.description, this.skillsUsed});

  factory ExpAchievements.fromMap(Map<String, dynamic> map) => ExpAchievements(
    description: _s(map['description']),
    skillsUsed: _list(map['skillsUsed']),
  );

  Map<String, dynamic> toMap() => {
    if (description != null) 'description': description,
    if (skillsUsed != null) 'skillsUsed': skillsUsed,
  };

  ExpAchievements copyWith({
    String? description,
    List<String>? skillsUsed,
  }) =>
      ExpAchievements(
        description: description ?? this.description,
        skillsUsed: skillsUsed ?? this.skillsUsed,
      );
}

class Preferences {
  final List<String>? desiredJobTitles;
  final List<String>? industries;
  final String? companySize;                 // Startup/Small/Medium/Large/Any
  final List<String>? workEnvironment;       // Office/Remote/Hybrid/Any
  final List<String>? preferredLocations;    // e.g. "Kuala Lumpur"
  final bool? willingToRelocate;
  final String? remoteAcceptance;            // Yes / No / HybridOnly
  final PrefSalary? salary;                  // {min,max,type,currency?,benefitsPriority[]}

  const Preferences({
    this.desiredJobTitles,
    this.industries,
    this.companySize,
    this.workEnvironment,
    this.preferredLocations,
    this.willingToRelocate,
    this.remoteAcceptance,
    this.salary,
  });

  factory Preferences.empty() => const Preferences();

  // Build from nested map (preferred) OR from flattened top-level structure.
  static Preferences fromAny(Map<String, dynamic> root) {
    // If nested exists, use it.
    final prefRaw = root['preferences'];
    if (prefRaw is Map<String, dynamic>) {
      return Preferences.fromMap(prefRaw);
    }
    // Otherwise, try read flattened keys from root.
    return Preferences(
      desiredJobTitles: _ls(root['desiredJobTitles']),
      industries: _ls(root['industries']),
      companySize: _s(root['companySize']),
      workEnvironment: _ls(root['workEnvironment']),
      preferredLocations: _ls(root['preferredLocations']),
      willingToRelocate: root['willingToRelocate'] is bool ? root['willingToRelocate'] as bool : null,
      remoteAcceptance: _s(root['remoteAcceptance']),
      salary: PrefSalary.fromMap(root['salary'] as Map<String, dynamic>?),
    );
  }

  factory Preferences.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const Preferences();
    return Preferences(
      desiredJobTitles: _ls(m['desiredJobTitles']),
      industries: _ls(m['industries']),
      companySize: _s(m['companySize']),
      workEnvironment: _ls(m['workEnvironment']),
      preferredLocations: _ls(m['preferredLocations']),
      willingToRelocate: m['willingToRelocate'] is bool ? m['willingToRelocate'] as bool : null,
      remoteAcceptance: _s(m['remoteAcceptance']),
      salary: PrefSalary.fromMap(m['salary'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{};

    // only add each field if not null (clean map)
    if (desiredJobTitles != null && desiredJobTitles!.isNotEmpty) {
      map['desiredJobTitles'] = desiredJobTitles;
    }
    if (industries != null && industries!.isNotEmpty) {
      map['industries'] = industries;
    }
    if (companySize != null && companySize!.isNotEmpty) {
      map['companySize'] = companySize;
    }
    if (workEnvironment != null && workEnvironment!.isNotEmpty) {
      map['workEnvironment'] = workEnvironment;
    }
    if (preferredLocations != null && preferredLocations!.isNotEmpty) {
      map['preferredLocations'] = preferredLocations;
    }
    if (willingToRelocate != null) {
      map['willingToRelocate'] = willingToRelocate;
    }
    if (remoteAcceptance != null && remoteAcceptance!.isNotEmpty) {
      map['remoteAcceptance'] = remoteAcceptance;
    }

    // safely serialize nested salary object
    if (salary != null) {
      map['salary'] = salary!.toFirestore();
    }

    return map;
  }


  Preferences copyWith({
    List<String>? desiredJobTitles,
    List<String>? industries,
    String? companySize,
    List<String>? workEnvironment,
    List<String>? preferredLocations,
    bool? willingToRelocate,
    String? remoteAcceptance,
    PrefSalary? salary,
  }) {
    return Preferences(
      desiredJobTitles: desiredJobTitles ?? this.desiredJobTitles,
      industries: industries ?? this.industries,
      companySize: companySize ?? this.companySize,
      workEnvironment: workEnvironment ?? this.workEnvironment,
      preferredLocations: preferredLocations ?? this.preferredLocations,
      willingToRelocate: willingToRelocate ?? this.willingToRelocate,
      remoteAcceptance: remoteAcceptance ?? this.remoteAcceptance,
      salary: salary ?? this.salary,
    );
  }
}

class PrefSalary {
  final int? min;
  final int? max;
  final String? type;                 // Monthly / Annual
  final String? currency;
  final List<String>? benefitsPriority;

  const PrefSalary({
    this.min,
    this.max,
    this.type,
    this.currency,
    this.benefitsPriority,
  });

  factory PrefSalary.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const PrefSalary();
    return PrefSalary(
      min: _i(m['min']),
      max: _i(m['max']),
      type: _s(m['type']),
      currency: _s(m['currency']),
      benefitsPriority: _ls(m['benefitsPriority']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    if (min != null) 'min': min,
    if (max != null) 'max': max,
    if (type != null) 'type': type,
    if (currency != null) 'currency': currency,
    if (benefitsPriority != null) 'benefitsPriority': benefitsPriority,
  };

  PrefSalary copyWith({
    int? min,
    int? max,
    String? type,
    String? currency,
    List<String>? benefitsPriority,
  }) {
    return PrefSalary(
      min: min ?? this.min,
      max: max ?? this.max,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      benefitsPriority: benefitsPriority ?? this.benefitsPriority,
    );
  }
}

// Small helpers for safe casting.
List<String>? _ls(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : null;


