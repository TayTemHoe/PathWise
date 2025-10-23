import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_wise/model/user_profile.dart';
import 'package:path_wise/service/profile_service.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({ProfileService? service})
      : _service = service ?? ProfileService();

  final ProfileService _service;

  // ========================= Root (users/{uid}) ================================

  UserProfile? _profile;
  UserProfile? get profile => _profile;

  bool _loading = false;
  bool get isLoading => _loading;

  String? _error;
  String? get errorMessage => _error;

  //String get uid => FirebaseAuth.instance.currentUser!.uid;
  String get uid => 'U0001';

  // ========================= Subcollections (cache) ============================

  List<Skill> _skills = [];
  List<Skill> get skills => List.unmodifiable(_skills);

  List<Education> _education = [];
  List<Education> get education => List.unmodifiable(_education);

  List<Experience> _experience = [];
  List<Experience> get experience => List.unmodifiable(_experience);

  StreamSubscription? _skillsSub;
  StreamSubscription? _eduSub;
  StreamSubscription? _expSub;

  // ========================= Lifecycle ========================================

  Future<void> init({String? appUserIdIfNew}) async {
    _setLoading(true);
    _error = null;
    try {
      // Ensure root doc exists (first time user)
      await _service.createOrInitUser(uid, appUserId: appUserIdIfNew);

      // Fetch root profile once
      await _fetchRoot();

      // Start listening to subcollections
      _listenSkills();
      _listenEducation();
      _listenExperience();

      // Ensure completion + validation always in sync (optional on init)
      await recomputeCompletionAndValidation();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _skillsSub?.cancel();
    _eduSub?.cancel();
    _expSub?.cancel();
    super.dispose();
  }

  // ========================= Root helpers =====================================

  Future<void> _fetchRoot() async {
    final p = await _service.getUserProfile(uid);
    _profile = p ??
        UserProfile(
          uid: uid,
          appUserId: null,
          completionPercent: 0,
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
          personalInfo: const PersonalInfo(),
          preferences: const Preferences(),
          personality: const Personality(),
          validation: const {},
        );
    notifyListeners();
  }

  Future<void> refreshAll() async {
    _setLoading(true);
    try {
      await _fetchRoot();
      // subcollections already streaming
    } finally {
      _setLoading(false);
    }
  }

  // Update partial fields at root (e.g., personalInfo / preferences / personality)
  Future<void> updateRootPartial(Map<String, dynamic> partial) async {
    await _service.updateUserProfileFields(uid, partial);
    await _fetchRoot();
    await recomputeCompletionAndValidation();
  }

  // Convenience setters
  Future<void> updatePersonalInfo(PersonalInfo info) async {
    await updateRootPartial({'personalInfo': info.toMap()});
  }

  Future<void> updatePreferences(Preferences pref) async {
    await updateRootPartial({'preferences': pref.toMap()});
  }

  Future<void> updatePersonality(Personality p) async {
    await updateRootPartial({'personality': p.toMap()});
  }

  // Upload profile picture
  Future<void> uploadProfilePicture(File image) async {
    _setLoading(true);
    _error = null;
    try {
      await _service.uploadProfilePicture(uid, image);
      await _fetchRoot();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ========================= Streams (subcollections) ==========================

  void _listenSkills() {
    _skillsSub?.cancel();
    _skillsSub = _service.watchSkills(uid).listen((items) {
      _skills = items;
      notifyListeners();
    });
  }

  void _listenEducation() {
    _eduSub?.cancel();
    _eduSub = _service.watchEducation(uid).listen((items) {
      _education = items;
      notifyListeners();
    });
  }

  void _listenExperience() {
    _expSub?.cancel();
    _expSub = _service.watchExperience(uid).listen((items) {
      _experience = items;
      notifyListeners();
    });
  }

  // ========================= CRUD: Skills =====================================

  Future<String?> addSkill({
    required String name,
    required String category, // Technical/Soft/Language/Industry
    num? level,
    String? levelText,
    num? years,
    Map<String, dynamic>? verification,
  }) async {
    try {
      final id = await _service.addSkill(
        uid,
        Skill(
          id: 'new', // will be replaced by Firestore id
          name: name,
          category: category,
          level: level,
          levelText: levelText,
          yearsExperience: years,
          verification: verification,
          order: _skills.length,
          updatedAt: DateTime.now(),
        ),
      );
      await recomputeCompletionAndValidation();
      return id;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> updateSkill(Skill s) async {
    await _service.updateSkill(uid, s);
    await recomputeCompletionAndValidation();
  }

  Future<void> deleteSkill(String skillId) async {
    await _service.deleteSkill(uid, skillId);
    await recomputeCompletionAndValidation();
  }

  Future<void> reorderSkills(List<Skill> ordered) async {
    await _service.reorderSkills(uid, ordered);
  }

  // ========================= CRUD: Education ===================================

  Future<String?> addEducation({
    required String institution,
    required String degreeLevel,
    required String fieldOfStudy,
    DateTime? startDate,
    DateTime? endDate,
    bool isCurrent = false,
    String? gpa,
    LocationVO? location,
  }) async {
    try {
      final id = await _service.addEducation(
        uid,
        Education(
          id: 'new',
          institution: institution,
          degreeLevel: degreeLevel,
          fieldOfStudy: fieldOfStudy,
          startDate: startDate,
          endDate: endDate,
          isCurrent: isCurrent,
          gpa: gpa,
          location: location,
          order: _education.length,
          updatedAt: DateTime.now(),
        ),
      );
      await recomputeCompletionAndValidation();
      return id;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> updateEducation(Education e) async {
    await _service.updateEducation(uid, e);
    await recomputeCompletionAndValidation();
  }

  Future<void> deleteEducation(String eduId) async {
    await _service.deleteEducation(uid, eduId);
    await recomputeCompletionAndValidation();
  }

  Future<void> reorderEducation(List<Education> ordered) async {
    await _service.reorderEducation(uid, ordered);
  }

  // ========================= CRUD: Experience ==================================

  Future<String?> addExperience({
    required String jobTitle,
    required String company,
    required String employmentType, // Full-time/Part-time/Contract/Internship/Freelance
    DateTime? startDate,
    DateTime? endDate,
    bool isCurrent = false,
    LocationVO? location,
    String? industry,
    String? description,
    List<Map<String, dynamic>> achievements = const [],
    num? yearsInRole,
  }) async {
    try {
      final id = await _service.addExperience(
        uid,
        Experience(
          id: 'new',
          jobTitle: jobTitle,
          company: company,
          employmentType: employmentType,
          startDate: startDate,
          endDate: endDate,
          isCurrent: isCurrent,
          location: location,
          industry: industry,
          description: description,
          achievements: achievements,
          yearsInRole: yearsInRole,
          order: _experience.length,
          updatedAt: DateTime.now(),
        ),
      );
      await recomputeCompletionAndValidation();
      return id;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> updateExperience(Experience x) async {
    await _service.updateExperience(uid, x);
    await recomputeCompletionAndValidation();
  }

  Future<void> deleteExperience(String expId) async {
    await _service.deleteExperience(uid, expId);
    await recomputeCompletionAndValidation();
  }

  Future<void> reorderExperience(List<Experience> ordered) async {
    await _service.reorderExperience(uid, ordered);
  }

  // ========================= Completion & Validation ===========================

  Future<void> recomputeCompletionAndValidation() async {
    if (_profile == null) {
      await _fetchRoot();
      if (_profile == null) return;
    }

    final sections = _calcSectionPercents(
      personal: _profile!.personalInfo,
      skills: _skills,
      education: _education,
      experience: _experience,
      preferences: _profile!.preferences,
    );

    final completion =
        (sections['personal']! * 0.20) +
            (sections['skills']! * 0.25) +
            (sections['education']! * 0.20) +
            (sections['experience']! * 0.25) +
            (sections['preferences']! * 0.10);

    final issues = _collectIssues(_profile!, _skills, _education, _experience);

    final validation = {
      'requiredOk': issues.isEmpty,
      'issues': issues,
      'sections': sections,
    };

    await _service.updateCompletionAndValidation(
      uid,
      completionPercent: double.parse(completion.toStringAsFixed(1)),
      validation: validation,
    );

    await _fetchRoot();
  }

  Map<String, double> _calcSectionPercents({
    required PersonalInfo? personal,
    required List<Skill> skills,
    required List<Education> education,
    required List<Experience> experience,
    required Preferences? preferences,
  }) {
    // Personal: name, email, phone, dob, gender, location.city/state/country, picture
    int filled = 0;
    int total = 8;
    if (personal?.name?.isNotEmpty == true) filled++;
    if (personal?.email?.isNotEmpty == true) filled++;
    if (personal?.phone?.isNotEmpty == true) filled++;
    if (personal?.dob != null) filled++;
    if (personal?.gender?.isNotEmpty == true) filled++;
    if (personal?.location?.city?.isNotEmpty == true) filled++;
    if (personal?.location?.state?.isNotEmpty == true) filled++;
    if (personal?.location?.country?.isNotEmpty == true) filled++;
    final personalPct = (filled / total) * 100.0;

    // Skills: >= 1 skill = 50%; >= 5 skill = 80%; >= 10 skill = 100%
    double skillsPct = 0;
    if (skills.isNotEmpty) skillsPct = 50;
    if (skills.length >= 5) skillsPct = 80;
    if (skills.length >= 10) skillsPct = 100;

    // Education: >=1 = 60%; +20 if ada fieldOfStudy & degreeLevel filled; +20 jika ada tanggal valid
    double eduPct = 0;
    if (education.isNotEmpty) {
      eduPct = 60;
      final good = education.where((e) =>
      (e.fieldOfStudy.isNotEmpty) && (e.degreeLevel.isNotEmpty)).isNotEmpty;
      if (good) eduPct += 20;
      final dated = education.where((e) => e.startDate != null).isNotEmpty;
      if (dated) eduPct += 20;
      if (eduPct > 100) eduPct = 100;
    }

    // Experience: >=1 = 60%; +20 jika ada description/achievements; +20 jika tanggal valid
    double expPct = 0;
    if (experience.isNotEmpty) {
      expPct = 60;
      final goodDesc = experience.where((x) =>
      (x.description?.isNotEmpty == true) || (x.achievements.isNotEmpty)).isNotEmpty;
      if (goodDesc) expPct += 20;
      final dated = experience.where((x) => x.startDate != null).isNotEmpty;
      if (dated) expPct += 20;
      if (expPct > 100) expPct = 100;
    }

    // Preferences: desiredJobTitles/industries/workEnvironment/locations/salary
    int pFilled = 0;
    int pTotal = 5;
    if ((preferences?.desiredJobTitles.isNotEmpty ?? false)) pFilled++;
    if ((preferences?.industries.isNotEmpty ?? false)) pFilled++;
    if ((preferences?.workEnvironment.isNotEmpty ?? false)) pFilled++;
    if ((preferences?.preferredLocations.isNotEmpty ?? false)) pFilled++;
    if (preferences?.salary != null) pFilled++;
    final prefPct = (pFilled / pTotal) * 100.0;

    return {
      'personal': double.parse(personalPct.toStringAsFixed(1)),
      'skills': skillsPct,
      'education': eduPct,
      'experience': expPct,
      'preferences': double.parse(prefPct.toStringAsFixed(1)),
    };
  }

  List<String> _collectIssues(
      UserProfile p,
      List<Skill> skills,
      List<Education> edus,
      List<Experience> exps,
      ) {
    final issues = <String>[];

    // Personal
    final pi = p.personalInfo;
    if (pi == null || (pi.name == null || pi.name!.isEmpty)) {
      issues.add('Personal: name is required');
    }
    if (pi == null || (pi.email == null || pi.email!.isEmpty)) {
      issues.add('Personal: email is required');
    }

    // Education dates sanity
    for (final e in edus) {
      if (e.endDate != null && e.startDate != null && e.endDate!.isBefore(e.startDate!)) {
        issues.add('Education: endDate before startDate in "${e.institution}"');
      }
    }

    // Experience dates sanity
    for (final x in exps) {
      if (x.endDate != null && x.startDate != null && x.endDate!.isBefore(x.startDate!)) {
        issues.add('Experience: endDate before startDate in "${x.company}"');
      }
    }

    // Skills cap (UI should enforce, but keep guard)
    if (skills.length > 50) {
      issues.add('Skills: more than 50 items');
    }

    // Experience cap
    if (exps.length > 15) {
      issues.add('Experience: more than 15 items');
    }

    return issues;
  }

  // ========================= UI helpers ========================================

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }
}
