import 'package:cloud_firestore/cloud_firestore.dart';

// Helper methods for safe parsing and conversion
String _s(dynamic v) => v?.toString() ?? '';
bool _b(dynamic v) => v is bool ? v : false;
int? _i(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is String) return int.tryParse(v);
  if (v is double) return v.toInt();
  return null;
}

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

List<String> _ls(dynamic v) {
  if (v is List) return v.map((e) => e.toString()).toList();
  return [];
}

Map<String, dynamic>? _map(dynamic v) {
  if (v == null) return null;
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return null;
}

/// JobLocation class to handle location details
class JobLocation {
  final String city;
  final String state;
  final String country;

  JobLocation({
    required this.city,
    required this.state,
    required this.country,
  });

  /// Create JobLocation from nested map (for Firestore)
  factory JobLocation.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return JobLocation(city: 'Unknown', state: 'Unknown', country: 'Unknown');
    }
    return JobLocation(
      city: _s(map['city']),
      state: _s(map['state']),
      country: _s(map['country']),
    );
  }

  /// Create JobLocation from JSearch API JSON response
  factory JobLocation.fromJson(Map<String, dynamic> json) {
    return JobLocation(
      city: _s(json['job_city']),
      state: _s(json['job_state']),
      country: _s(json['job_country']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'city': city,
      'state': state,
      'country': country,
    };
  }

  @override
  String toString() => '$city, $state, $country';
}

/// JobRequiredExperience class to handle job experience details
class JobRequiredExperience {
  final bool noExperienceRequired;
  final String? requiredExperienceInMonths;
  final String? experienceLevel; // Internship, Entry level, Associate, Mid-Senior level, Director, Executive

  JobRequiredExperience({
    required this.noExperienceRequired,
    this.requiredExperienceInMonths,
    this.experienceLevel,
  });

  /// Create JobRequiredExperience from map with null safety
  factory JobRequiredExperience.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return JobRequiredExperience(noExperienceRequired: false);
    }
    return JobRequiredExperience(
      noExperienceRequired: _b(map['no_experience_required']),
      requiredExperienceInMonths: map['required_experience_in_months']?.toString(),
      experienceLevel: _s(map['experience_level']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'no_experience_required': noExperienceRequired,
      if (requiredExperienceInMonths != null)
        'required_experience_in_months': requiredExperienceInMonths,
      if (experienceLevel != null) 'experience_level': experienceLevel,
    };
  }

  @override
  String toString() {
    if (noExperienceRequired) return 'No experience required';
    if (experienceLevel != null) return experienceLevel!;
    if (requiredExperienceInMonths != null) {
      return '$requiredExperienceInMonths months experience';
    }
    return 'Experience required';
  }
}

/// JobModel class to represent a job listing
class JobModel {
  final String jobId; // Unique ID from JSearch API
  final String jobTitle;
  final String companyName;
  final JobLocation jobLocation;
  final String jobApplyLink;
  final String jobDescription;
  final bool isRemote;
  final DateTime postedAt;
  final List<String> jobBenefits;
  final JobRequiredExperience requiredExperience;
  final String? jobSalary;
  final String? jobMinSalary;
  final String? jobMaxSalary;
  final String? jobSalaryCurrency;
  final String? jobSalaryPeriod;
  final List<String> jobHighlightsQualifications;
  final List<String> jobHighlightsResponsibilities;
  final String? employerWebsite;
  final String? employerCompanyType;
  final String? employerLogo;
  final String? jobPublisher;
  final List<String> jobEmploymentTypes;

  // Bookmark metadata (only present when loaded from Firestore)
  final String? bookmarkId;
  final DateTime? savedAt;

  JobModel({
    required this.jobId,
    required this.jobTitle,
    required this.companyName,
    required this.jobLocation,
    required this.jobApplyLink,
    required this.jobDescription,
    required this.isRemote,
    required this.postedAt,
    required this.jobBenefits,
    required this.requiredExperience,
    this.jobSalary,
    this.jobMinSalary,
    this.jobMaxSalary,
    this.jobSalaryCurrency,
    this.jobSalaryPeriod,
    required this.jobHighlightsQualifications,
    required this.jobHighlightsResponsibilities,
    this.employerWebsite,
    this.employerCompanyType,
    this.employerLogo,
    this.jobPublisher,
    required this.jobEmploymentTypes,
    this.bookmarkId,
    this.savedAt,
  });

  /// Create JobModel from Firestore document (saved/bookmarked job)
  factory JobModel.fromFirestore(Map<String, dynamic> data, String docId) {
    final locationData = _map(data['job_location']);
    final experienceData = _map(data['job_required_experience']);
    final highlightsData = _map(data['job_highlights']);

    return JobModel(
      jobId: _s(data['job_id']),
      jobTitle: _s(data['job_title']),
      companyName: _s(data['employer_name']),
      jobLocation: JobLocation.fromMap(locationData),
      jobApplyLink: _s(data['job_apply_link']),
      jobDescription: _s(data['job_description']),
      isRemote: _b(data['job_is_remote']),
      postedAt: _dt(data['job_posted_at_datetime_utc']) ?? DateTime.now(),
      jobBenefits: _ls(data['job_benefits']),
      requiredExperience: JobRequiredExperience.fromMap(experienceData),
      jobSalary: data['job_salary']?.toString(),
      jobMinSalary: data['job_min_salary']?.toString(),
      jobMaxSalary: data['job_max_salary']?.toString(),
      jobSalaryCurrency: _s(data['job_salary_currency']),
      jobSalaryPeriod: _s(data['job_salary_period']),
      jobHighlightsQualifications: _ls(highlightsData?['Qualifications']),
      jobHighlightsResponsibilities: _ls(highlightsData?['Responsibilities']),
      employerWebsite: data['employer_website']?.toString(),
      employerCompanyType: _s(data['employer_company_type']),
      employerLogo: _s(data['employer_logo']),
      jobPublisher: _s(data['job_publisher']),
      jobEmploymentTypes: _ls(data['job_employment_types']),
      bookmarkId: _s(data['bookmarkId']),
      savedAt: _dt(data['savedAt']),
    );
  }

  /// Convert JobModel to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'job_id': jobId,
      'job_title': jobTitle,
      'employer_name': companyName,
      'job_location': jobLocation.toMap(),
      'job_apply_link': jobApplyLink,
      'job_description': jobDescription,
      'job_is_remote': isRemote,
      'job_posted_at_datetime_utc': postedAt.toIso8601String(),
      'job_benefits': jobBenefits,
      'job_required_experience': requiredExperience.toMap(),
      if (jobSalary != null) 'job_salary': jobSalary,
      if (jobMinSalary != null) 'job_min_salary': jobMinSalary,
      if (jobMaxSalary != null) 'job_max_salary': jobMaxSalary,
      if (jobSalaryCurrency != null) 'job_salary_currency': jobSalaryCurrency,
      if (jobSalaryPeriod != null) 'job_salary_period': jobSalaryPeriod,
      'job_highlights': {
        'Qualifications': jobHighlightsQualifications,
        'Responsibilities': jobHighlightsResponsibilities,
      },
      if (employerWebsite != null) 'employer_website': employerWebsite,
      if (employerCompanyType != null) 'employer_company_type': employerCompanyType,
      if (employerLogo != null) 'employer_logo': employerLogo,
      if (jobPublisher != null) 'job_publisher': jobPublisher,
      'job_employment_types': jobEmploymentTypes,
    };
  }

  /// Create JobModel from JSearch API JSON response
  factory JobModel.fromJson(Map<String, dynamic> json) {
    final highlightsData = _map(json['job_highlights']);
    final experienceData = _map(json['job_required_experience']);

    return JobModel(
      jobId: _s(json['job_id']), // Important: JSearch provides unique job_id
      jobTitle: _s(json['job_title']),
      companyName: _s(json['employer_name']),
      jobLocation: JobLocation.fromJson(json),
      jobApplyLink: _s(json['job_apply_link']),
      jobDescription: _s(json['job_description']),
      isRemote: _b(json['job_is_remote']),
      postedAt: _dt(json['job_posted_at_datetime_utc']) ?? DateTime.now(),
      jobBenefits: _ls(json['job_benefits']),
      requiredExperience: JobRequiredExperience.fromMap(experienceData),
      jobSalary: json['job_salary']?.toString(),
      jobMinSalary: json['job_min_salary']?.toString(),
      jobMaxSalary: json['job_max_salary']?.toString(),
      jobSalaryCurrency: _s(json['job_salary_currency']),
      jobSalaryPeriod: _s(json['job_salary_period']),
      jobHighlightsQualifications: _ls(highlightsData?['Qualifications']),
      jobHighlightsResponsibilities: _ls(highlightsData?['Responsibilities']),
      employerWebsite: json['employer_website']?.toString(),
      employerCompanyType: _s(json['employer_company_type']),
      employerLogo: _s(json['employer_logo']),
      jobPublisher: _s(json['job_publisher']),
      jobEmploymentTypes: _ls(json['job_employment_type']),
    );
  }

  /// Get formatted salary string
  String getFormattedSalary() {
    if (jobSalary != null && jobSalary!.isNotEmpty && jobSalary != 'null') {
      return jobSalary!;
    }

    if (jobMinSalary != null && jobMaxSalary != null) {
      final currency = jobSalaryCurrency ?? 'MYR';
      final period = jobSalaryPeriod ?? 'year';
      return '$currency $jobMinSalary - $jobMaxSalary / $period';
    }

    return 'Salary not specified';
  }

  /// Get time since posted
  String getTimeSincePosted() {
    final now = DateTime.now();
    final difference = now.difference(postedAt);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Just posted';
    }
  }

  /// Check if job is saved
  bool get isSaved => bookmarkId != null;

  /// Copy with method for updating fields
  JobModel copyWith({
    String? jobId,
    String? jobTitle,
    String? companyName,
    JobLocation? jobLocation,
    String? jobApplyLink,
    String? jobDescription,
    bool? isRemote,
    DateTime? postedAt,
    List<String>? jobBenefits,
    JobRequiredExperience? requiredExperience,
    String? jobSalary,
    String? jobMinSalary,
    String? jobMaxSalary,
    String? jobSalaryCurrency,
    String? jobSalaryPeriod,
    List<String>? jobHighlightsQualifications,
    List<String>? jobHighlightsResponsibilities,
    String? employerWebsite,
    String? employerCompanyType,
    String? employerLogo,
    String? jobPublisher,
    List<String>? jobEmploymentTypes,
    String? bookmarkId,
    DateTime? savedAt,
  }) {
    return JobModel(
      jobId: jobId ?? this.jobId,
      jobTitle: jobTitle ?? this.jobTitle,
      companyName: companyName ?? this.companyName,
      jobLocation: jobLocation ?? this.jobLocation,
      jobApplyLink: jobApplyLink ?? this.jobApplyLink,
      jobDescription: jobDescription ?? this.jobDescription,
      isRemote: isRemote ?? this.isRemote,
      postedAt: postedAt ?? this.postedAt,
      jobBenefits: jobBenefits ?? this.jobBenefits,
      requiredExperience: requiredExperience ?? this.requiredExperience,
      jobSalary: jobSalary ?? this.jobSalary,
      jobMinSalary: jobMinSalary ?? this.jobMinSalary,
      jobMaxSalary: jobMaxSalary ?? this.jobMaxSalary,
      jobSalaryCurrency: jobSalaryCurrency ?? this.jobSalaryCurrency,
      jobSalaryPeriod: jobSalaryPeriod ?? this.jobSalaryPeriod,
      jobHighlightsQualifications: jobHighlightsQualifications ?? this.jobHighlightsQualifications,
      jobHighlightsResponsibilities: jobHighlightsResponsibilities ?? this.jobHighlightsResponsibilities,
      employerWebsite: employerWebsite ?? this.employerWebsite,
      employerCompanyType: employerCompanyType ?? this.employerCompanyType,
      employerLogo: employerLogo ?? this.employerLogo,
      jobPublisher: jobPublisher ?? this.jobPublisher,
      jobEmploymentTypes: jobEmploymentTypes ?? this.jobEmploymentTypes,
      bookmarkId: bookmarkId ?? this.bookmarkId,
      savedAt: savedAt ?? this.savedAt,
    );
  }
}

/// JobFilters class for search filtering
/// JobFilters class for search filtering
class JobFilters {
  final String? query; // keyword (title/company/skills)
  final String? location; // "Kuala Lumpur, Malaysia"
  final String? country; // NEW: Country code (my, us, uk, sg, etc.)
  final String? remote; // "Remote" | "Hybrid" | "On-site"
  final int? minSalary; // MYR or other currency
  final int? maxSalary; // MYR or other currency
  final List<String>? industries; // Company types/industries
  final List<String>? employmentTypes; // "FULLTIME", "CONTRACTOR", "PARTTIME", "INTERN"
  final String? experienceLevel; // "Internship", "Entry level", "Associate", "Mid-Senior level"
  final int page; // pagination
  final String? dateRange; // "all", "today", "3days", "week", "month"

  JobFilters({
    this.query,
    this.location,
    this.country, // NEW
    this.remote,
    this.minSalary,
    this.maxSalary,
    this.industries,
    this.employmentTypes,
    this.experienceLevel,
    this.page = 1,
    this.dateRange,
  });

  /// Create empty filters
  factory JobFilters.empty() => JobFilters();

  /// Copy with method for updating filters
  JobFilters copyWith({
    String? query,
    String? location,
    String? country, // NEW
    String? remote,
    int? minSalary,
    int? maxSalary,
    List<String>? industries,
    List<String>? employmentTypes,
    String? experienceLevel,
    int? page,
    String? dateRange,
  }) {
    return JobFilters(
      query: query ?? this.query,
      location: location ?? this.location,
      country: country ?? this.country, // NEW
      remote: remote ?? this.remote,
      minSalary: minSalary ?? this.minSalary,
      maxSalary: maxSalary ?? this.maxSalary,
      industries: industries ?? this.industries,
      employmentTypes: employmentTypes ?? this.employmentTypes,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      page: page ?? this.page,
      dateRange: dateRange ?? this.dateRange,
    );
  }

  /// Convert to query parameters map
  Map<String, String> toQueryParams() {
    final map = <String, String>{};

    if (query != null && query!.isNotEmpty) map['q'] = query!;
    if (location != null && location!.isNotEmpty) map['location'] = location!;
    if (country != null && country!.isNotEmpty) map['country'] = country!; // NEW
    if (remote != null && remote!.isNotEmpty) map['remote'] = remote!;
    if (minSalary != null) map['minSalary'] = minSalary.toString();
    if (maxSalary != null) map['maxSalary'] = maxSalary.toString();
    if (industries != null && industries!.isNotEmpty) {
      map['industries'] = industries!.join(',');
    }
    if (employmentTypes != null && employmentTypes!.isNotEmpty) {
      map['employmentTypes'] = employmentTypes!.join(',');
    }
    if (experienceLevel != null && experienceLevel!.isNotEmpty) {
      map['experienceLevel'] = experienceLevel!;
    }
    if (dateRange != null && dateRange!.isNotEmpty) {
      map['date_range'] = dateRange!;
    }

    map['page'] = page.toString();

    return map;
  }

  /// Check if any filters are active
  bool get hasActiveFilters {
    return (query != null && query!.isNotEmpty) ||
        (location != null && location!.isNotEmpty) ||
        (country != null && country!.isNotEmpty) || // NEW
        remote != null ||
        minSalary != null ||
        maxSalary != null ||
        (industries != null && industries!.isNotEmpty) ||
        (employmentTypes != null && employmentTypes!.isNotEmpty) ||
        experienceLevel != null ||
        dateRange != null;
  }

  /// Get count of active filters
  int get activeFilterCount {
    int count = 0;
    if (query != null && query!.isNotEmpty) count++;
    if (location != null && location!.isNotEmpty) count++;
    if (country != null && country!.isNotEmpty) count++; // NEW
    if (remote != null) count++;
    if (minSalary != null || maxSalary != null) count++;
    if (industries != null && industries!.isNotEmpty) count++;
    if (employmentTypes != null && employmentTypes!.isNotEmpty) count++;
    if (experienceLevel != null) count++;
    if (dateRange != null) count++;
    return count;
  }
}