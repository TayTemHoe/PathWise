import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:path_wise/model/ai_match_model.dart'; // Ensure this file exists for AcademicRecord

/// ===============================
/// Safe Parsers (Resilient to type drift)
/// ===============================

String? _s(Object? v) => v?.toString();

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
    return ['true', '1', 'yes'].contains(t);
  }
  return null;
}

List<String>? _list(Object? v) {
  if (v == null) return null;
  if (v is List) return v.map((e) => e.toString()).toList();
  if (v is String && v.isNotEmpty) {
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

/// Helper to safely cast to Timestamp (handles String ISO8601 & Timestamp)
Timestamp? _timestamp(Object? value) {
  if (value == null) return null;
  if (value is Timestamp) return value;
  if (value is String && value.isNotEmpty) {
    try {
      return Timestamp.fromDate(DateTime.parse(value));
    } catch (e) {
      debugPrint('⚠️ Could not parse timestamp string: $value');
    }
  }
  return null;
}

/// ===============================
/// Unified UserModel Model
/// ===============================

class UserModel {
  // -- Identifiers & Role --
  final String userId;
  final String userRole;

  // -- Personal Info --
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final Timestamp? dob; // Stored as Timestamp, parsed from String if needed
  final String? profilePictureUrl;

  // -- Location / Address --
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? country;
  final String? zipCode;

  // -- Meta Data --
  final double? completionPercent;
  final Timestamp? lastUpdated;
  final Timestamp? createdAt;
  final int? profileFreshnessMonths;

  // -- Personality & Assessments --
  final String? mbti;
  final String? riasec;
  final Timestamp? personalityUpdatedAt;

  // -- Complex Sub-structures --
  final Preferences? preferences;

  // Subcollections loaded separately (optional cache)
  final List<Skill>? skills;
  final List<AcademicRecord>? education;
  final List<Experience>? experience;

  const UserModel({
    required this.userId,
    this.userRole = 'education',
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.dob,
    this.profilePictureUrl,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.country,
    this.zipCode,
    this.completionPercent,
    this.lastUpdated,
    this.createdAt,
    this.profileFreshnessMonths,
    this.mbti,
    this.riasec,
    this.personalityUpdatedAt,
    this.preferences,
    this.skills,
    this.education,
    this.experience,
  });

  /// Getter for full name
  String get name => [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');

  /// Robust reader for Firestore docs (handles nested & flat structures)
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserModel.fromMap(data, userId: doc.id);
  }

  /// General purpose Map parser
  factory UserModel.fromMap(Map<String, dynamic> data, {String? userId}) {
    // Handle nested structures if they exist (UserModel style)
    final personal = _map(data['personalInfo']) ?? {};
    final loc = _map(personal['location']) ?? _map(data['location']) ?? {}; // Check nested then flat
    final personality = _map(data['personality']) ?? {};
    final prefs = Preferences.fromAny(data);

    // Resolve fields (Priority: Direct Key -> Nested Key)
    return UserModel(
      userId: userId ?? _s(data['userId']) ?? _s(data['uid']) ?? '',
      userRole: _s(data['user_role']) ?? _s(data['userRole']) ?? 'education',

      // Name
      firstName: _s(data['first_name']) ?? _s(data['firstName']) ?? _s(personal['firstName']),
      lastName: _s(data['last_name']) ?? _s(data['lastName']) ?? _s(personal['lastName']),

      // Contact
      email: _s(data['email']) ?? _s(personal['email']),
      phone: _s(data['phone']) ?? _s(personal['phone']),
      profilePictureUrl: _s(data['profilePictureUrl']) ?? _s(personal['profilePictureUrl']),

      // Dates
      dob: _timestamp(data['dob']) ?? _timestamp(personal['dob']),
      createdAt: _timestamp(data['createdAt']),
      lastUpdated: _timestamp(data['lastUpdated']),

      // Location (Flattened from UserModel logic + UserModel specific fields)
      // FIX: Added lookups in `loc` for address fields and zipCode to ensure they load initially
      addressLine1: _s(data['address_line1']) ?? _s(data['addressLine1']) ?? _s(data['address']) ?? _s(loc['addressLine1']),
      addressLine2: _s(data['address_line2']) ?? _s(data['addressLine2']) ?? _s(loc['addressLine2']),
      city: _s(data['city']) ?? _s(loc['city']),
      state: _s(data['state']) ?? _s(loc['state']),
      country: _s(data['country']) ?? _s(loc['country']),
      zipCode: _s(data['zip_code']) ?? _s(data['zipCode']) ?? _s(loc['zipCode']),

      // Meta
      completionPercent: _d(data['completionPercent']),
      profileFreshnessMonths: _i(data['profileFreshnessMonths']),

      // Personality
      mbti: _s(data['mbti']) ?? _s(personality['mbti']),
      riasec: _s(data['riasec']) ?? _s(personality['riasec']),
      personalityUpdatedAt: _timestamp(data['personalityUpdatedAt']) ?? _timestamp(personality['updatedAt']),

      // Preferences
      preferences: prefs,

      // Sub-lists are usually loaded via separate collection queries
      skills: null,
      education: null,
      experience: null,
    );
  }

  /// Serialize to Map (Supports Firestore nested structure preference)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userRole': userRole,
      'completionPercent': completionPercent,
      'lastUpdated': lastUpdated,
      'createdAt': createdAt,
      'profileFreshnessMonths': profileFreshnessMonths,

      'personality': {
        'mbti': mbti,
        'riasec': riasec,
        'updatedAt': personalityUpdatedAt,
      },

      'preferences': preferences?.toFirestore() ?? {},

      'personalInfo': {
        'firstName': firstName,
        'lastName': lastName,
        'name': name, // Redundant but useful
        'email': email,
        'phone': phone,
        'dob': dob,
        'profilePictureUrl': profilePictureUrl,
        'location': {
          'addressLine1': addressLine1,
          'addressLine2': addressLine2,
          'city': city,
          'state': state,
          'country': country,
          'zipCode': zipCode,
        },
      },

      // Flattened keys for backward compatibility if needed:
      // 'first_name': firstName,
      // 'last_name': lastName,
      // 'city': city,
    };
  }

  UserModel copyWith({
    String? userId,
    String? userRole,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    Timestamp? dob,
    String? profilePictureUrl,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? country,
    String? zipCode,
    double? completionPercent,
    Timestamp? lastUpdated,
    Timestamp? createdAt,
    int? profileFreshnessMonths,
    String? mbti,
    String? riasec,
    Timestamp? personalityUpdatedAt,
    Preferences? preferences,
    List<Skill>? skills,
    List<AcademicRecord>? education,
    List<Experience>? experience,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      userRole: userRole ?? this.userRole,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dob: dob ?? this.dob,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      zipCode: zipCode ?? this.zipCode,
      completionPercent: completionPercent ?? this.completionPercent,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
      profileFreshnessMonths: profileFreshnessMonths ?? this.profileFreshnessMonths,
      mbti: mbti ?? this.mbti,
      riasec: riasec ?? this.riasec,
      personalityUpdatedAt: personalityUpdatedAt ?? this.personalityUpdatedAt,
      preferences: preferences ?? this.preferences,
      skills: skills ?? this.skills,
      education: education ?? this.education,
      experience: experience ?? this.experience,
    );
  }

    @override
    String toString() {
      return 'UserModel(userId: $userId, firstName: $firstName, lastName: $lastName, phone: $phone, email: $email, dob: $dob, addressLine1: $addressLine1, addressLine2: $addressLine2, city: $city, state: $state, country: $country, zipCode: $zipCode, userRole: $userRole)';
    }

    @override
    bool operator ==(Object other) {
      if (identical(this, other)) return true;

      return other is UserModel &&
          other.userId == userId &&
          other.firstName == firstName &&
          other.lastName == lastName &&
          other.phone == phone &&
          other.email == email &&
          other.dob == dob &&
          other.addressLine1 == addressLine1 &&
          other.addressLine2 == addressLine2 &&
          other.city == city &&
          other.state == state &&
          other.country == country &&
          other.zipCode == zipCode;
    }

    @override
    int get hashCode {
      return Object.hash(
        userId,
        firstName,
        lastName,
        phone,
        email,
        dob,
        addressLine1,
        addressLine2,
        city,
        state,
        country,
        zipCode,
      );
    }
}

/// ===============================
/// Helper Classes (Preferences, Salary, Skill, Experience)
/// ===============================

class Preferences {
  final List<String>? desiredJobTitles;
  final List<String>? industries;
  final String? companySize;
  final List<String>? workEnvironment;
  final List<String>? preferredLocations;
  final bool? willingToRelocate;
  final String? remoteAcceptance;
  final PrefSalary? salary;

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

  static Preferences fromAny(Map<String, dynamic> root) {
    final prefRaw = root['preferences'];
    if (prefRaw is Map<String, dynamic>) {
      return Preferences.fromMap(prefRaw);
    }
    return Preferences.fromMap(root); // Attempt to read flat structure
  }

  factory Preferences.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const Preferences();
    return Preferences(
      desiredJobTitles: _list(m['desiredJobTitles']),
      industries: _list(m['industries']),
      companySize: _s(m['companySize']),
      workEnvironment: _list(m['workEnvironment']),
      preferredLocations: _list(m['preferredLocations']),
      willingToRelocate: _b(m['willingToRelocate']),
      remoteAcceptance: _s(m['remoteAcceptance']),
      salary: PrefSalary.fromMap(m['salary'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{};
    if (desiredJobTitles?.isNotEmpty == true) map['desiredJobTitles'] = desiredJobTitles;
    if (industries?.isNotEmpty == true) map['industries'] = industries;
    if (companySize?.isNotEmpty == true) map['companySize'] = companySize;
    if (workEnvironment?.isNotEmpty == true) map['workEnvironment'] = workEnvironment;
    if (preferredLocations?.isNotEmpty == true) map['preferredLocations'] = preferredLocations;
    if (willingToRelocate != null) map['willingToRelocate'] = willingToRelocate;
    if (remoteAcceptance?.isNotEmpty == true) map['remoteAcceptance'] = remoteAcceptance;
    if (salary != null) map['salary'] = salary!.toFirestore();
    return map;
  }
}

class PrefSalary {
  final int? min;
  final int? max;
  final String? type; // "Monthly" or "Annual"
  final String? currency;
  final List<String>? benefitsPriority;

  const PrefSalary({this.min, this.max, this.type, this.currency, this.benefitsPriority});

  factory PrefSalary.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const PrefSalary();
    return PrefSalary(
      min: _i(m['min']),
      max: _i(m['max']),
      type: _s(m['type']),
      currency: _s(m['currency']),
      benefitsPriority: _list(m['benefitsPriority']),
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

class Skill {
  final String id;
  final String? name;
  final String? category;
  final int? level;
  final String? levelText;
  final Verification? verification;
  final int? order;
  final Timestamp? updatedAt;

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
      updatedAt: _timestamp(data['updatedAt']),
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

class Experience {
  final String id;
  final String? jobTitle;
  final String? company;
  final String? employmentType;
  final Timestamp? startDate;
  final Timestamp? endDate;
  final bool? isCurrent;
  final String? city;
  final String? country;
  final String? industry;
  final String? description;
  final ExpAchievements? achievements;
  final int? order;
  final Timestamp? updatedAt;

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
      startDate: _timestamp(data['startDate']),
      endDate: _timestamp(data['endDate']),
      isCurrent: _b(data['isCurrent']),
      city: _s(loc['city']),
      country: _s(loc['country']),
      industry: _s(data['industry']),
      description: _s(data['description']),
      achievements: ach.isEmpty ? null : ExpAchievements.fromMap(ach),
      order: _i(data['order']),
      updatedAt: _timestamp(data['updatedAt']),
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