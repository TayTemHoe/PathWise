import 'package:cloud_firestore/cloud_firestore.dart';

/// Can replace this with FirebaseAuth.instance.currentUser!.uid in production.
String get uid => 'U0001';

/// Root document model: users/{uid}
class UserProfile {
  // --- meta / progress ---
  final double? completionPercent;           // e.g., 0..100
  final Timestamp? createdAt;
  final Timestamp? lastUpdated;
  final int? profileFreshnessMonths;

  // --- personalInfo ---
  final String? name;
  final String? email;                       // non-editable if synced from Auth
  final String? phone;
  final Timestamp? dob;                      // store as Firestore Timestamp
  final String? gender;                      // Male/Female/PreferNotToSay
  final String? city;
  final String? state;
  final String? country;
  final String? profilePictureUrl;
  final PictureMeta? pictureMeta;            // optional meta: w,h,format,sizeBytes

  // --- personality (no 'source', as requested) ---
  final String? mbti;                        // e.g., "INTJ"
  final List<String>? riasec;                // e.g., ["Investigative","Artistic"]
  final Timestamp? personalityUpdatedAt;

  // --- preferences (without relocationDistanceKm) ---
  final List<String>? desiredJobTitles;
  final List<String>? industries;
  final String? companySize;                 // Startup/SME/Medium/Large/Any
  final List<String>? workEnvironment;       // Office/Remote/Hybrid/Any
  final List<String>? preferredLocations;    // e.g., ["Kuala Lumpur","Selangor"]
  final bool? willingToRelocate;
  final String? remoteAcceptance;            // Yes/No/HybridOnly
  final SalaryPref? salary;                  // min/max/type + benefitsPriority

  // NOTE: Subcollections are modeled here for convenience but are not stored
  // inside the root doc. Load/save them via separate service calls.
  final List<Skill>? skills;                 // users/{uid}/skills/*
  final List<Education>? education;          // users/{uid}/education/*
  final List<Experience>? experience;        // users/{uid}/experience/*

  const UserProfile({
    // meta
    this.completionPercent,
    this.createdAt,
    this.lastUpdated,
    this.profileFreshnessMonths,
    // personal
    this.name,
    this.email,
    this.phone,
    this.dob,
    this.gender,
    this.city,
    this.state,
    this.country,
    this.profilePictureUrl,
    this.pictureMeta,
    // personality (no 'source')
    this.mbti,
    this.riasec,
    this.personalityUpdatedAt,
    // preferences (no relocationDistanceKm)
    this.desiredJobTitles,
    this.industries,
    this.companySize,
    this.workEnvironment,
    this.preferredLocations,
    this.willingToRelocate,
    this.remoteAcceptance,
    this.salary,
    // subcollections (loaded separately)
    this.skills,
    this.education,
    this.experience,
  });

  // ------------------ Factory: from Firestore document ------------------
  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    // --- nested maps (prefer) + flat fallbacks ---
    final personal = (data['personalInfo'] as Map<String, dynamic>?) ?? {};
    final loc = (personal['location'] as Map<String, dynamic>?) ?? {};
    final personality = (data['personality'] as Map<String, dynamic>?) ?? {};
    final prefs = (data['preferences'] as Map<String, dynamic>?) ?? {};
    final picMetaMap = (personal['pictureMeta'] as Map<String, dynamic>?) ?? {};
    final salaryMap = (prefs['salary'] as Map<String, dynamic>?) ?? {};

    // helpers flat fallback
    String? _s(Object? v) => v?.toString();

    return UserProfile(
      // meta
      completionPercent: (data['completionPercent'] is int)
          ? (data['completionPercent'] as int).toDouble()
          : (data['completionPercent'] as num?)?.toDouble(),
      createdAt: data['createdAt'] as Timestamp?,
      lastUpdated: data['lastUpdated'] as Timestamp?,
      profileFreshnessMonths: data['profileFreshnessMonths'] as int?,

      // personal (nested → flat fallback)
      name: _s(personal['name']) ?? _s(data['name']),
      email: _s(personal['email']) ?? _s(data['email']),
      phone: _s(personal['phone']) ?? _s(data['phone']),
      dob: (personal['dob'] as Timestamp?) ?? (data['dob'] as Timestamp?),
      gender: _s(personal['gender']) ?? _s(data['gender']),
      city: _s(loc['city']) ?? _s(data['city']),
      state: _s(loc['state']) ?? _s(data['state']),
      country: _s(loc['country']) ?? _s(data['country']),
      profilePictureUrl:
      _s(personal['profilePictureUrl']) ?? _s(data['profilePictureUrl']),
      pictureMeta: picMetaMap.isEmpty ? null : PictureMeta.fromMap(picMetaMap),

      // personality (nested → flat fallback, no `source`)
      mbti: _s(personality['mbti']) ?? _s(data['mbti']),
      riasec: (personality['riasec'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          (data['riasec'] is List
              ? (data['riasec'] as List).map((e) => e.toString()).toList()
              : null),
      personalityUpdatedAt:
      (personality['updatedAt'] as Timestamp?) ??
          (data['personalityUpdatedAt'] as Timestamp?),

      // preferences (nested → flat fallback, NO relocationDistanceKm)
      desiredJobTitles: (prefs['desiredJobTitles'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          (data['desiredJobTitles'] is List
              ? (data['desiredJobTitles'] as List)
              .map((e) => e.toString())
              .toList()
              : null),
      industries: (prefs['industries'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          (data['industries'] is List
              ? (data['industries'] as List).map((e) => e.toString()).toList()
              : null),
      companySize: _s(prefs['companySize']) ?? _s(data['companySize']),
      workEnvironment: (prefs['workEnvironment'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          (data['workEnvironment'] is List
              ? (data['workEnvironment'] as List)
              .map((e) => e.toString())
              .toList()
              : null),
      preferredLocations: (prefs['preferredLocations'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          (data['preferredLocations'] is List
              ? (data['preferredLocations'] as List)
              .map((e) => e.toString())
              .toList()
              : null),
      willingToRelocate: (prefs['willingToRelocate'] as bool?) ??
          (data['willingToRelocate'] as bool?),
      remoteAcceptance:
      _s(prefs['remoteAcceptance']) ?? _s(data['remoteAcceptance']),
      salary: salaryMap.isEmpty
          ? null
          : SalaryPref.fromMap(salaryMap),

      // subcollections (not parsed here)
      skills: null,
      education: null,
      experience: null,
    );
  }


  // ------------------ To Firestore (root doc only) ------------------
  Map<String, dynamic> toMap() {
    return {
      // meta
      if (completionPercent != null) 'completionPercent': completionPercent,
      if (createdAt != null) 'createdAt': createdAt,
      if (lastUpdated != null) 'lastUpdated': lastUpdated,
      if (profileFreshnessMonths != null)
        'profileFreshnessMonths': profileFreshnessMonths,

      // personalInfo
      'personalInfo': {
        'name': name,
        'email': email,
        'phone': phone,
        'dob': dob,
        'gender': gender,
        'location': {
          'city': city,
          'state': state,
          'country': country,
        },
        'profilePictureUrl': profilePictureUrl,
        if (pictureMeta != null) 'pictureMeta': pictureMeta!.toMap(),
      },

      // personality (no 'source')
      'personality': {
        'mbti': mbti,
        'riasec': riasec,
        'updatedAt': personalityUpdatedAt,
      },

      // preferences (no relocationDistanceKm)
      'preferences': {
        'desiredJobTitles': desiredJobTitles,
        'industries': industries,
        'companySize': companySize,
        'workEnvironment': workEnvironment,
        'preferredLocations': preferredLocations,
        'willingToRelocate': willingToRelocate,
        'remoteAcceptance': remoteAcceptance,
        if (salary != null) 'salary': salary!.toMap(),
      },

      // NOTE: subcollections (skills/education/experience) are NOT embedded here.
    };
  }

  // ------------------ copyWith ------------------
  UserProfile copyWith({
    double? completionPercent,
    Timestamp? createdAt,
    Timestamp? lastUpdated,
    int? profileFreshnessMonths,
    String? name,
    String? email,
    String? phone,
    Timestamp? dob,
    String? gender,
    String? city,
    String? state,
    String? country,
    String? profilePictureUrl,
    PictureMeta? pictureMeta,
    String? mbti,
    List<String>? riasec,
    Timestamp? personalityUpdatedAt,
    List<String>? desiredJobTitles,
    List<String>? industries,
    String? companySize,
    List<String>? workEnvironment,
    List<String>? preferredLocations,
    bool? willingToRelocate,
    String? remoteAcceptance,
    SalaryPref? salary,
    List<Skill>? skills,
    List<Education>? education,
    List<Experience>? experience,
  }) {
    return UserProfile(
      completionPercent: completionPercent ?? this.completionPercent,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      profileFreshnessMonths:
      profileFreshnessMonths ?? this.profileFreshnessMonths,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      pictureMeta: pictureMeta ?? this.pictureMeta,
      mbti: mbti ?? this.mbti,
      riasec: riasec ?? this.riasec,
      personalityUpdatedAt:
      personalityUpdatedAt ?? this.personalityUpdatedAt,
      desiredJobTitles: desiredJobTitles ?? this.desiredJobTitles,
      industries: industries ?? this.industries,
      companySize: companySize ?? this.companySize,
      workEnvironment: workEnvironment ?? this.workEnvironment,
      preferredLocations: preferredLocations ?? this.preferredLocations,
      willingToRelocate: willingToRelocate ?? this.willingToRelocate,
      remoteAcceptance: remoteAcceptance ?? this.remoteAcceptance,
      salary: salary ?? this.salary,
      skills: skills ?? this.skills,
      education: education ?? this.education,
      experience: experience ?? this.experience,
    );
  }
}

/// ---- Value objects ----
class PictureMeta {
  final int? w;
  final int? h;
  final String? format;     // "jpg" | "png" | "gif"
  final int? sizeBytes;     // <= 5MB (enforced in Storage rules / app)

  const PictureMeta({this.w, this.h, this.format, this.sizeBytes});

  factory PictureMeta.fromMap(Map<String, dynamic> map) => PictureMeta(
    w: (map['w'] as num?)?.toInt(),
    h: (map['h'] as num?)?.toInt(),
    format: map['format'] as String?,
    sizeBytes: (map['sizeBytes'] as num?)?.toInt(),
  );

  Map<String, dynamic> toMap() => {
    'w': w,
    'h': h,
    'format': format,
    'sizeBytes': sizeBytes,
  };
}

class SalaryPref {
  final num? min;
  final num? max;
  final String? type;                  // "Monthly" | "Annual"
  final List<String>? benefitsPriority;

  const SalaryPref({this.min, this.max, this.type, this.benefitsPriority});

  factory SalaryPref.fromMap(Map<String, dynamic> map) => SalaryPref(
    min: map['min'] as num?,
    max: map['max'] as num?,
    type: map['type'] as String?,
    benefitsPriority: (map['benefitsPriority'] as List?)
        ?.map((e) => e.toString())
        .toList(),
  );

  Map<String, dynamic> toMap() => {
    'min': min,
    'max': max,
    'type': type,
    'benefitsPriority': benefitsPriority,
  };
}

/// ---- Subcollection models (stored under users/{uid}/...) ----
/// NOTE: Not included in root toMap(). Handle via separate service methods.

class Skill {
  final String id;
  final String name;
  final String category;               // Technical/Soft/Language/Industry
  final int? level;                    // 1..5 (or map text in UI)
  final num? yearsExperience;
  final String? certificateUrl;
  final String? portfolioUrl;
  final int? order;
  final Timestamp? updatedAt;

  Skill({
    required this.id,
    required this.name,
    required this.category,
    this.level,
    this.yearsExperience,
    this.certificateUrl,
    this.portfolioUrl,
    this.order,
    this.updatedAt,
  });

  factory Skill.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final d = doc.data() ?? {};
    return Skill(
      id: doc.id,
      name: d['name'] as String? ?? '',
      category: d['category'] as String? ?? 'Technical',
      level: (d['level'] as num?)?.toInt(),
      yearsExperience: d['yearsExperience'] as num?,
      certificateUrl: (d['verification'] as Map<String, dynamic>?)?['certificateUrl'] as String?,
      portfolioUrl: (d['verification'] as Map<String, dynamic>?)?['portfolioUrl'] as String?,
      order: (d['order'] as num?)?.toInt(),
      updatedAt: d['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category,
    'level': level,
    'yearsExperience': yearsExperience,
    'verification': {
      'certificateUrl': certificateUrl,
      'portfolioUrl': portfolioUrl,
    },
    'order': order,
    'updatedAt': updatedAt,
  };
}

class Education {
  final String id;
  final String institution;
  final String degreeLevel;            // HighSchool/Diploma/Bachelor/...
  final String? fieldOfStudy;
  final Timestamp? startDate;
  final Timestamp? endDate;
  final bool? isCurrent;
  final String? gpa;
  final String? city;
  final String? country;
  final int? order;
  final Timestamp? updatedAt;

  Education({
    required this.id,
    required this.institution,
    required this.degreeLevel,
    this.fieldOfStudy,
    this.startDate,
    this.endDate,
    this.isCurrent,
    this.gpa,
    this.city,
    this.country,
    this.order,
    this.updatedAt,
  });

  factory Education.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final d = doc.data() ?? {};
    final loc = (d['location'] as Map<String, dynamic>?) ?? {};
    return Education(
      id: doc.id,
      institution: d['institution'] as String? ?? '',
      degreeLevel: d['degreeLevel'] as String? ?? 'Bachelor',
      fieldOfStudy: d['fieldOfStudy'] as String?,
      startDate: d['startDate'] as Timestamp?,
      endDate: d['endDate'] as Timestamp?,
      isCurrent: d['isCurrent'] as bool?,
      gpa: d['gpa'] as String?,
      city: loc['city'] as String?,
      country: loc['country'] as String?,
      order: (d['order'] as num?)?.toInt(),
      updatedAt: d['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() => {
    'institution': institution,
    'degreeLevel': degreeLevel,
    'fieldOfStudy': fieldOfStudy,
    'startDate': startDate,
    'endDate': endDate,
    'isCurrent': isCurrent,
    'gpa': gpa,
    'location': {'city': city, 'country': country},
    'order': order,
    'updatedAt': updatedAt,
  };
}

class Experience {
  final String id;
  final String jobTitle;
  final String company;
  final String employmentType;        // Full-time/Part-time/Contract/Internship/Freelance
  final Timestamp? startDate;
  final Timestamp? endDate;
  final bool? isCurrent;
  final String? city;
  final String? country;
  final String? industry;
  final String? description;
  final List<Achievement>? achievements; // compact bullets
  final num? yearsInRole;                 // optional derived
  final int? order;
  final Timestamp? updatedAt;

  Experience({
    required this.id,
    required this.jobTitle,
    required this.company,
    required this.employmentType,
    this.startDate,
    this.endDate,
    this.isCurrent,
    this.city,
    this.country,
    this.industry,
    this.description,
    this.achievements,
    this.yearsInRole,
    this.order,
    this.updatedAt,
  });

  factory Experience.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final d = doc.data() ?? {};
    final loc = (d['location'] as Map<String, dynamic>?) ?? {};
    final ach = (d['achievements'] as List?) ?? [];

    return Experience(
      id: doc.id,
      jobTitle: d['jobTitle'] as String? ?? '',
      company: d['company'] as String? ?? '',
      employmentType: d['employmentType'] as String? ?? 'Full-time',
      startDate: d['startDate'] as Timestamp?,
      endDate: d['endDate'] as Timestamp?,
      isCurrent: d['isCurrent'] as bool?,
      city: loc['city'] as String?,
      country: loc['country'] as String?,
      industry: d['industry'] as String?,
      description: d['description'] as String?,
      achievements: ach
          .map((e) => Achievement.fromMap(Map<String, dynamic>.from(e)))
          .toList()
          .cast<Achievement>(),
      yearsInRole: d['yearsInRole'] as num?,
      order: (d['order'] as num?)?.toInt(),
      updatedAt: d['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() => {
    'jobTitle': jobTitle,
    'company': company,
    'employmentType': employmentType,
    'startDate': startDate,
    'endDate': endDate,
    'isCurrent': isCurrent,
    'location': {'city': city, 'country': country},
    'industry': industry,
    'description': description,
    'achievements': achievements?.map((e) => e.toMap()).toList(),
    'yearsInRole': yearsInRole,
    'order': order,
    'updatedAt': updatedAt,
  };
}

class Achievement {
  final String description;
  final String? metrics;              // e.g., "-35% frame jank"
  final List<String>? skillsUsed;

  Achievement({
    required this.description,
    this.metrics,
    this.skillsUsed,
  });

  factory Achievement.fromMap(Map<String, dynamic> map) => Achievement(
    description: map['description'] as String? ?? '',
    metrics: map['metrics'] as String?,
    skillsUsed:
    (map['skillsUsed'] as List?)?.map((e) => e.toString()).toList(),
  );

  Map<String, dynamic> toMap() => {
    'description': description,
    'metrics': metrics,
    'skillsUsed': skillsUsed,
  };
}
