import 'package:cloud_firestore/cloud_firestore.dart';

/// ===== Helpers ===================================================================

DateTime? _tsToDate(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  return null;
}

Timestamp? _dateToTs(DateTime? d) => d == null ? null : Timestamp.fromDate(d);

List<T> _listFrom<T>(dynamic v, T Function(dynamic) mapItem) {
  if (v == null) return <T>[];
  if (v is List) return v.map(mapItem).toList();
  return <T>[];
}

Map<String, dynamic>? _mapOrNull(dynamic v) {
  if (v == null) return null;
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return null;
}

/// ===== Value Objects ==============================================================

class LocationVO {
  final String? city;
  final String? state;
  final String? country;

  const LocationVO({this.city, this.state, this.country});

  factory LocationVO.fromMap(Map<String, dynamic>? map) {
    map ??= const {};
    return LocationVO(
      city: map['city'] as String?,
      state: map['state'] as String?,
      country: map['country'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'city': city,
    'state': state,
    'country': country,
  }..removeWhere((_, v) => v == null);

  LocationVO copyWith({String? city, String? state, String? country}) =>
      LocationVO(
        city: city ?? this.city,
        state: state ?? this.state,
        country: country ?? this.country,
      );
}

class PersonalInfo {
  final String? name;
  final String? email; // non-editable if synced from Firebase Auth
  final String? phone;
  final DateTime? dob;
  final String? gender; // Male/Female/PreferNotToSay
  final LocationVO? location;
  final String? profilePictureUrl;
  final Map<String, dynamic>? pictureMeta; // {w,h,format,sizeBytes}

  const PersonalInfo({
    this.name,
    this.email,
    this.phone,
    this.dob,
    this.gender,
    this.location,
    this.profilePictureUrl,
    this.pictureMeta,
  });

  factory PersonalInfo.fromMap(Map<String, dynamic>? map) {
    map ??= const {};
    return PersonalInfo(
      name: map['name'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      dob: _tsToDate(map['dob']),
      gender: map['gender'] as String?,
      location: LocationVO.fromMap(_mapOrNull(map['location'])),
      profilePictureUrl: map['profilePictureUrl'] as String?,
      pictureMeta: _mapOrNull(map['pictureMeta']),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'phone': phone,
    'dob': _dateToTs(dob),
    'gender': gender,
    'location': location?.toMap(),
    'profilePictureUrl': profilePictureUrl,
    'pictureMeta': pictureMeta,
  }..removeWhere((_, v) => v == null);

  PersonalInfo copyWith({
    String? name,
    String? email,
    String? phone,
    DateTime? dob,
    String? gender,
    LocationVO? location,
    String? profilePictureUrl,
    Map<String, dynamic>? pictureMeta,
  }) {
    return PersonalInfo(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      location: location ?? this.location,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      pictureMeta: pictureMeta ?? this.pictureMeta,
    );
  }
}

class Personality {
  final String? mbti;
  final List<String> riasec; // e.g., ["Investigative", "Artistic"]
  final DateTime? updatedAt;

  const Personality({this.mbti, this.riasec = const [], this.updatedAt});

  factory Personality.fromMap(Map<String, dynamic>? map) {
    map ??= const {};
    return Personality(
      mbti: map['mbti'] as String?,
      riasec: _listFrom<String>(map['riasec'], (e) => e?.toString() ?? ''),
      updatedAt: _tsToDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'mbti': mbti,
    'riasec': riasec,
    'updatedAt': _dateToTs(updatedAt),
  }..removeWhere((_, v) => v == null || (v is List && v.isEmpty));
}

class Preferences {
  final List<String> desiredJobTitles;
  final List<String> industries;
  final String? companySize; // Startup/SME/Medium/Large/Any
  final List<String> workEnvironment; // Office/Remote/Hybrid/Any
  final List<String> preferredLocations; // e.g., "Kuala Lumpur"
  final bool? willingToRelocate;
  final String? remoteAcceptance; // Yes/No/HybridOnly
  final SalaryPref? salary;

  const Preferences({
    this.desiredJobTitles = const [],
    this.industries = const [],
    this.companySize,
    this.workEnvironment = const [],
    this.preferredLocations = const [],
    this.willingToRelocate,
    this.remoteAcceptance,
    this.salary,
  });

  factory Preferences.fromMap(Map<String, dynamic>? map) {
    map ??= const {};
    return Preferences(
      desiredJobTitles:
      _listFrom<String>(map['desiredJobTitles'], (e) => e?.toString() ?? ''),
      industries: _listFrom<String>(map['industries'], (e) => e?.toString() ?? ''),
      companySize: map['companySize'] as String?,
      workEnvironment:
      _listFrom<String>(map['workEnvironment'], (e) => e?.toString() ?? ''),
      preferredLocations:
      _listFrom<String>(map['preferredLocations'], (e) => e?.toString() ?? ''),
      willingToRelocate: map['willingToRelocate'] as bool?,
      remoteAcceptance: map['remoteAcceptance'] as String?,
      salary: SalaryPref.fromMap(_mapOrNull(map['salary'])),
    );
  }

  Map<String, dynamic> toMap() => {
    'desiredJobTitles': desiredJobTitles,
    'industries': industries,
    'companySize': companySize,
    'workEnvironment': workEnvironment,
    'preferredLocations': preferredLocations,
    'willingToRelocate': willingToRelocate,
    'remoteAcceptance': remoteAcceptance,
    'salary': salary?.toMap(),
  }..removeWhere((_, v) => v == null || (v is List && v.isEmpty));

  Preferences copyWith({
    List<String>? desiredJobTitles,
    List<String>? industries,
    String? companySize,
    List<String>? workEnvironment,
    List<String>? preferredLocations,
    bool? willingToRelocate,
    String? remoteAcceptance,
    SalaryPref? salary,
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

class SalaryPref {
  final num? min;
  final num? max;
  final String? type; // Monthly/Annual
  final List<String> benefitsPriority;

  const SalaryPref({
    this.min,
    this.max,
    this.type,
    this.benefitsPriority = const [],
  });

  factory SalaryPref.fromMap(Map<String, dynamic>? map) {
    map ??= const {};
    return SalaryPref(
      min: map['min'] as num?,
      max: map['max'] as num?,
      type: map['type'] as String?,
      benefitsPriority:
      _listFrom<String>(map['benefitsPriority'], (e) => e?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toMap() => {
    'min': min,
    'max': max,
    'type': type,
    'benefitsPriority': benefitsPriority,
  }..removeWhere((_, v) => v == null || (v is List && v.isEmpty));
}

/// ===== Subcollection Models =======================================================

class Skill {
  final String id;
  final String name;
  final String category; // Technical/Soft/Language/Industry
  /// Technical/Soft -> 1..5; Language -> store text also in levelText if needed.
  final num? level;
  final String? levelText; // e.g., "Intermediate" for languages
  final num? yearsExperience;
  final Map<String, dynamic>? verification; // {certificateUrl?, portfolioUrl?}
  final int order;
  final DateTime? updatedAt;

  Skill({
    required this.id,
    required this.name,
    required this.category,
    this.level,
    this.levelText,
    this.yearsExperience,
    this.verification,
    this.order = 0,
    this.updatedAt,
  });

  factory Skill.fromDoc(DocumentSnapshot doc) {
    final data = Map<String, dynamic>.from(doc.data() as Map);
    return Skill(
      id: doc.id,
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? 'Technical',
      level: data['level'] as num?,
      levelText: data['levelText'] as String?,
      yearsExperience: data['yearsExperience'] as num?,
      verification: _mapOrNull(data['verification']),
      order: (data['order'] as num?)?.toInt() ?? 0,
      updatedAt: _tsToDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category,
    'level': level,
    'levelText': levelText,
    'yearsExperience': yearsExperience,
    'verification': verification,
    'order': order,
    'updatedAt': _dateToTs(updatedAt),
  }..removeWhere((_, v) => v == null);
}

class Education {
  final String id;
  final String institution;
  final String degreeLevel; // HighSchool/Diploma/Bachelor/Master/PhD/Other
  final String fieldOfStudy;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final String? gpa;
  final LocationVO? location;
  final int order;
  final DateTime? updatedAt;

  Education({
    required this.id,
    required this.institution,
    required this.degreeLevel,
    required this.fieldOfStudy,
    this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.gpa,
    this.location,
    this.order = 0,
    this.updatedAt,
  });

  factory Education.fromDoc(DocumentSnapshot doc) {
    final data = Map<String, dynamic>.from(doc.data() as Map);
    return Education(
      id: doc.id,
      institution: data['institution'] as String? ?? '',
      degreeLevel: data['degreeLevel'] as String? ?? 'Bachelor',
      fieldOfStudy: data['fieldOfStudy'] as String? ?? '',
      startDate: _tsToDate(data['startDate']),
      endDate: _tsToDate(data['endDate']),
      isCurrent: data['isCurrent'] as bool? ?? false,
      gpa: data['gpa'] as String?,
      location: LocationVO.fromMap(_mapOrNull(data['location'])),
      order: (data['order'] as num?)?.toInt() ?? 0,
      updatedAt: _tsToDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'institution': institution,
    'degreeLevel': degreeLevel,
    'fieldOfStudy': fieldOfStudy,
    'startDate': _dateToTs(startDate),
    'endDate': _dateToTs(endDate),
    'isCurrent': isCurrent,
    'gpa': gpa,
    'location': location?.toMap(),
    'order': order,
    'updatedAt': _dateToTs(updatedAt),
  }..removeWhere((_, v) => v == null);
}

class Experience {
  final String id;
  final String jobTitle;
  final String company;
  final String employmentType; // Full-time/Part-time/Contract/Internship/Freelance
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final LocationVO? location;
  final String? industry;
  final String? description;
  final List<Map<String, dynamic>> achievements; // [{description, metrics?, skillsUsed?}]
  final num? yearsInRole; // can be computed
  final int order;
  final DateTime? updatedAt;

  Experience({
    required this.id,
    required this.jobTitle,
    required this.company,
    required this.employmentType,
    this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.location,
    this.industry,
    this.description,
    this.achievements = const [],
    this.yearsInRole,
    this.order = 0,
    this.updatedAt,
  });

  factory Experience.fromDoc(DocumentSnapshot doc) {
    final data = Map<String, dynamic>.from(doc.data() as Map);
    return Experience(
      id: doc.id,
      jobTitle: data['jobTitle'] as String? ?? '',
      company: data['company'] as String? ?? '',
      employmentType: data['employmentType'] as String? ?? 'Full-time',
      startDate: _tsToDate(data['startDate']),
      endDate: _tsToDate(data['endDate']),
      isCurrent: data['isCurrent'] as bool? ?? false,
      location: LocationVO.fromMap(_mapOrNull(data['location'])),
      industry: data['industry'] as String?,
      description: data['description'] as String?,
      achievements: _listFrom<Map<String, dynamic>>(
          data['achievements'], (e) => Map<String, dynamic>.from(e ?? {})),
      yearsInRole: data['yearsInRole'] as num?,
      order: (data['order'] as num?)?.toInt() ?? 0,
      updatedAt: _tsToDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'jobTitle': jobTitle,
    'company': company,
    'employmentType': employmentType,
    'startDate': _dateToTs(startDate),
    'endDate': _dateToTs(endDate),
    'isCurrent': isCurrent,
    'location': location?.toMap(),
    'industry': industry,
    'description': description,
    'achievements': achievements,
    'yearsInRole': yearsInRole,
    'order': order,
    'updatedAt': _dateToTs(updatedAt),
  }..removeWhere((_, v) => v == null);
}

/// ===== Root Document Model ========================================================

class UserProfile {
  /// Firebase Auth UID document key
  final String uid;

  /// Custom display/user code like "U0001"
  final String? appUserId;

  final double? completionPercent;
  final DateTime? createdAt;
  final DateTime? lastUpdated;
  final num? profileFreshnessMonths;

  final PersonalInfo? personalInfo;
  final Personality? personality; // without `source`
  final Preferences? preferences;

  /// Validation summary stored at root (optional)
  final Map<String, dynamic>? validation;

  const UserProfile({
    required this.uid,
    this.appUserId,
    this.completionPercent,
    this.createdAt,
    this.lastUpdated,
    this.profileFreshnessMonths,
    this.personalInfo,
    this.personality,
    this.preferences,
    this.validation,
  });

  /// Build from a Firestore doc snapshot (users/{uid})
  factory UserProfile.fromDoc(DocumentSnapshot doc) {
    final data = Map<String, dynamic>.from(doc.data() as Map? ?? {});
    return UserProfile(
      uid: doc.id,
      appUserId: data['appUserId'] as String?,
      completionPercent: (data['completionPercent'] as num?)?.toDouble(),
      createdAt: _tsToDate(data['createdAt']),
      lastUpdated: _tsToDate(data['lastUpdated']),
      profileFreshnessMonths: data['profileFreshnessMonths'] as num?,
      personalInfo: PersonalInfo.fromMap(_mapOrNull(data['personalInfo'])),
      personality: data['personality'] != null
          ? Personality.fromMap(_mapOrNull(data['personality']))
          : null,
      preferences:
      Preferences.fromMap(_mapOrNull(data['preferences'])),
      validation: _mapOrNull(data['validation']),
    );
  }

  /// Serialize for Firestore
  Map<String, dynamic> toMap() => {
    'appUserId': appUserId,
    'completionPercent': completionPercent,
    'createdAt': _dateToTs(createdAt),
    'lastUpdated': _dateToTs(lastUpdated),
    'profileFreshnessMonths': profileFreshnessMonths,
    'personalInfo': personalInfo?.toMap(),
    'personality': personality?.toMap(),
    'preferences': preferences?.toMap(),
    'validation': validation,
  }..removeWhere((_, v) => v == null);

  UserProfile copyWith({
    String? uid,
    String? appUserId,
    double? completionPercent,
    DateTime? createdAt,
    DateTime? lastUpdated,
    num? profileFreshnessMonths,
    PersonalInfo? personalInfo,
    Personality? personality,
    Preferences? preferences,
    Map<String, dynamic>? validation,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      appUserId: appUserId ?? this.appUserId,
      completionPercent: completionPercent ?? this.completionPercent,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      profileFreshnessMonths:
      profileFreshnessMonths ?? this.profileFreshnessMonths,
      personalInfo: personalInfo ?? this.personalInfo,
      personality: personality ?? this.personality,
      preferences: preferences ?? this.preferences,
      validation: validation ?? this.validation,
    );
  }
}
