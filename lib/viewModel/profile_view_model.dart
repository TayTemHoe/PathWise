import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// ✅ CHANGED: Imported UserModel (formerly UserProfile)
import 'package:path_wise/model/user_profile.dart'; // Ensure this file exports 'UserModel'
import 'package:path_wise/services/profile_service.dart';
import 'package:path_wise/services/shared_preference_services.dart'; // ✅ Added

import '../model/ai_match_model.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({
    ProfileService? service,
    FirebaseAuth? auth,
  })  : _service = service ?? ProfileService(),
        _auth = auth ?? FirebaseAuth.instance;

  final ProfileService _service;
  final FirebaseAuth _auth;
  // ✅ Added: Reference to SharedPreferenceService
  final SharedPreferenceService _sharedPrefs = SharedPreferenceService.instance;

  // ------------- State -------------
  // ✅ CHANGED: UserProfile -> UserModel
  UserModel? _profile;

  // Firestore Subcollections
  List<Skill> _skills = const [];
  List<AcademicRecord> _education = const [];
  List<Experience> _experience = const [];

  // ✅ NEW: AI Match / Shared Preference Data
  List<EnglishTest> _englishTests = const [];
  List<String> _interests = const [];
  PersonalityProfile? _aiPersonality;
  UserPreferences? _aiPreferences;

  bool _isLoading = false;
  bool _savingRoot = false;
  bool _savingSkill = false;
  bool _savingEducation = false;
  bool _savingExperience = false;

  String? _error;

  // ------------- Getters -------------
  UserModel? get profile => _profile;
  List<Skill> get skills => _skills;
  List<AcademicRecord> get education => _education;
  List<Experience> get experience => _experience;

  // ✅ NEW Getters for AI Data
  List<EnglishTest> get englishTests => _englishTests;
  List<String> get interests => _interests;
  PersonalityProfile? get aiPersonality => _aiPersonality;
  UserPreferences? get aiPreferences => _aiPreferences;

  bool get isLoading => _isLoading;
  bool get savingRoot => _savingRoot;
  bool get savingSkill => _savingSkill;
  bool get savingEducation => _savingEducation;
  bool get savingExperience => _savingExperience;

  String? get error => _error;

  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  UserModel? _user;

  UserModel? get user => _user; // <= needed by the view

  // ------------- Internal setters -------------
  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(Object? e) {
    _error = e?.toString();
    notifyListeners();
  }

  void _setSavingRoot(bool v) {
    _savingRoot = v;
    notifyListeners();
  }

  void _setSavingSkill(bool v) {
    _savingSkill = v;
    notifyListeners();
  }

  void _setSavingEducation(bool v) {
    _savingEducation = v;
    notifyListeners();
  }

  void _setSavingExperience(bool v) {
    _savingExperience = v;
    notifyListeners();
  }

  // ------------- Loaders -------------
  Future<void> loadAll() async {
    if (uid.isEmpty) {
      debugPrint('⚠️ ProfileViewModel: loadAll skipped - No User ID');
      return;
    }
    debugPrint('🔄 ProfileViewModel: Starting loadAll() for uid=$uid');
    _setLoading(true);
    _setError(null);
    try {
      // 1. Load Firestore Data (Core Profile)
      final up = await _service.getUserWithSubcollections(uid);

      if (up == null) {
        debugPrint('⚠️ ProfileViewModel: No profile found, creating new one');
        // First-time bootstrap minimal doc
        await _service.createOrMergeUser(
          uid,
          const UserModel(
            completionPercent: 0, userId: '', firstName: '', lastName: '', email: '',
          ),
        );
        final created = await _service.getUserWithSubcollections(uid);
        _applyBundle(created);
      } else {
        _applyBundle(up);
      }

      // 2. ✅ NEW: Load SharedPreference Data (AI Match Data)
      debugPrint('🔄 ProfileViewModel: Loading AI Match data from SharedPrefs...');
      final spData = await _sharedPrefs.loadProgressWithPrograms(userId: uid);

      if (spData != null) {
        _englishTests = spData.englishTests;
        _interests = spData.interests;
        _aiPersonality = spData.personality;
        _aiPreferences = spData.preferences;

        debugPrint('✅ ProfileViewModel: Loaded ${_englishTests.length} English tests, ${_interests.length} interests');
      } else {
        _englishTests = [];
        _interests = [];
        _aiPersonality = null;
        _aiPreferences = null;
      }

      // 3. Recalculate Completion with combined data
      await _recalcAndPatchCompletion();
    } catch (e, stackTrace) {
      debugPrint('❌ ProfileViewModel: Error in loadAll(): $e');
      debugPrint('Stack trace: $stackTrace');
      _setError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadUserProfile() async {
    debugPrint('🔄 ProfileViewModel: Reloading user profile');
    await loadAll();
  }

  Future<void> refresh() => loadAll();

  void _applyBundle(UserModel? up) {
    _profile = up;
    _skills = up?.skills ?? const [];
    _education = up?.education ?? const [];
    _experience = up?.experience ?? const [];
    notifyListeners();
  }

  // ------------- Update: Personal Info -------------
  Future<bool> updatePersonalInfo({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    Timestamp? dob,
    String? city,
    String? state,
    String? country,
    String? zipCode,
    String? addressLine1,
    String? addressLine2,
  }) async {
    _setSavingRoot(true);
    _setError(null);
    try {
      await _service.updatePersonalInfo(
        uid: uid,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        dob: dob,
        city: city,
        state: state,
        country: country,
        zipCode: zipCode,
        addressLine1: addressLine1,
        addressLine2: addressLine2,
      );
      // Update local cache
      _profile = (_profile ?? const UserModel(userId: '', firstName: '', lastName: '', email: '')).copyWith(
        firstName: firstName, // Adapting to new UserModel structure if split first/last, or name
        lastName: lastName,
        email: email ?? _profile?.email,
        phone: phone ?? _profile?.phone,
        dob: dob ?? _profile?.dob,
        city: city ?? _profile?.city,
        state: state ?? _profile?.state,
        country: country ?? _profile?.country,
        zipCode: zipCode ?? _profile?.zipCode,
        addressLine1: addressLine1 ?? _profile?.addressLine1,
        addressLine2: addressLine2 ?? _profile?.addressLine2,
        lastUpdated: Timestamp.now(),
      );
      notifyListeners();

      await _recalcAndPatchCompletion();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _setSavingRoot(false);
    }
  }

  // ------------- Update: Personality (Firestore Sync) -------------
  // Note: This updates the Firestore record. The AI Match VM updates SharedPrefs.
  // Ideally, these should be synced, but for completion calculation, we check both/either.
  Future<bool> updatePersonality({
    String? mbti,
    String? riasec,
  }) async {
    _setSavingRoot(true);
    _setError(null);
    try {
      await _service.updatePersonality(uid: uid, mbti: mbti, riasec: riasec);
      _profile = (_profile ?? const UserModel(userId: '', firstName: '', lastName: '', email: '')).copyWith(
        mbti: mbti ?? _profile?.mbti,
        riasec: riasec ?? _profile?.riasec,
        personalityUpdatedAt: Timestamp.now(),
        lastUpdated: Timestamp.now(),
      );
      notifyListeners();

      await _recalcAndPatchCompletion();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _setSavingRoot(false);
    }
  }

  // ------------- Update: Preferences -------------
  Future<bool> updatePreferences(Preferences prefs) async {
    _setSavingRoot(true);
    _setError(null);

    try {
      await _service.updatePreferences(uid, prefs.toFirestore());

      _profile = (_profile ?? const UserModel(userId: '', firstName: '', lastName: '', email: '')).copyWith(
        preferences: prefs,
        lastUpdated: Timestamp.now(),
      );

      notifyListeners();
      await _recalcAndPatchCompletion();
      return true;
    } catch (e) {
      _setError(e);
      debugPrint('❌ Error updating preferences: $e');
      return false;
    } finally {
      _setSavingRoot(false);
    }
  }

  // ------------- Upload Profile Picture -------------
  Future<String?> uploadProfilePicture(File file, {String? fileExt}) async {
    _setSavingRoot(true);
    _setError(null);
    try {
      final url = await _service.uploadProfilePicture(uid: uid, file: file, fileExt: fileExt);
      if (url != null) {
        _profile = (_profile ?? const UserModel(userId: '', firstName: '', lastName: '', email: '')).copyWith(
          profilePictureUrl: url,
          lastUpdated: Timestamp.now(),
        );
        notifyListeners();
        await _recalcAndPatchCompletion();
      }
      return url;
    } catch (e) {
      debugPrint('viewModel Upload Error: $e');
      _setError(e.toString());
      return null;
    } finally {
      _setSavingRoot(false);
    }
  }

  Future<bool> updateUserRole(String newRole) async {
    _setSavingRoot(true);
    _setError(null);
    try {
      // Update Firestore with the new role
      await _service.updateUserRole(uid: uid, userRole: newRole);

      // Update local cache
      _profile = (_profile ?? const UserModel(
          userId: '',
          firstName: '',
          lastName: '',
          email: ''
      )).copyWith(
        userRole: newRole,
        lastUpdated: Timestamp.now(),
      );

      notifyListeners();

      // No need to recalculate completion as role doesn't affect it
      return true;
    } catch (e) {
      debugPrint('❌ Error updating user role: $e');
      _setError(e);
      return false;
    } finally {
      _setSavingRoot(false);
    }
  }
  // ------------- Skills CRUD -------------
  Future<bool> addSkill(Skill draft) async {
    _setSavingSkill(true);
    _setError(null);
    try {
      final created = await _service.createSkill(uid: uid, skill: draft);
      _skills = [..._skills, created]..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
      notifyListeners();
      await _recalcAndPatchCompletion();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _setSavingSkill(false);
    }
  }

  Future<bool> saveSkill(Skill skill) async {
    _setSavingSkill(true);
    _setError(null);
    try {
      await _service.updateSkill(uid: uid, skill: skill);
      _skills = _skills.map((s) => s.id == skill.id ? skill : s).toList()
        ..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
      notifyListeners();
      await _recalcAndPatchCompletion();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _setSavingSkill(false);
    }
  }

  Future<bool> deleteSkill(String skillId) async {
    _setSavingSkill(true);
    _setError(null);
    try {
      await _service.deleteSkill(uid: uid, skillId: skillId);
      _skills = _skills.where((s) => s.id != skillId).toList();
      notifyListeners();
      await _recalcAndPatchCompletion();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _setSavingSkill(false);
    }
  }

  // ------------- Education CRUD -------------
  Future<bool> addEducation(AcademicRecord draft) async {
    _setSavingEducation(true);
    try {
      final created = await _service.createEducation(uid: uid, education: draft);
      _education = [..._education, created];

      if (draft.isCurrent == true) {
        await _service.setCurrentEducation(uid: uid, eduId: created.id);
        _education = _education.map((e) {
          return e.copyWith(isCurrent: e.id == created.id);
        }).toList();
      }

      notifyListeners();
      await _recalcAndPatchCompletion();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _setSavingEducation(false);
    }
  }

  Future<bool> saveEducation(AcademicRecord edu) async {
    _setSavingEducation(true);
    try {
      await _service.updateEducation(uid: uid, education: edu);
      if (edu.isCurrent == true) {
        await _service.setCurrentEducation(uid: uid, eduId: edu.id);
        _education = _education.map((e) {
          return e.copyWith(isCurrent: e.id == edu.id);
        }).toList();
      } else {
        _education = _education.map((e) => e.id == edu.id ? edu : e).toList();
      }
      notifyListeners();
      await _recalcAndPatchCompletion();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _setSavingEducation(false);
    }
  }

  Future<bool> setCurrentEducation(String eduId) async {
    _setSavingEducation(true);
    try {
      await _service.setCurrentEducation(uid: uid, eduId: eduId);
      _education = _education.map((e) {
        return e.copyWith(isCurrent: e.id == eduId);
      }).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _setSavingEducation(false);
    }
  }

  AcademicRecord? get currentEducation {
    try {
      return _education.firstWhere((e) => e.isCurrent == true);
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteEducation(String eduId) async {
    _setSavingEducation(true);
    try {
      await _service.deleteEducation(uid: uid, eduId: eduId);
      _education = _education.where((e) => e.id != eduId).toList();
      notifyListeners();
      await _recalcAndPatchCompletion();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _setSavingEducation(false);
    }
  }

  // ------------- Experience CRUD -------------
  Future<bool> addExperience(Experience draft) async {
    _setSavingExperience(true);
    try {
      final created = await _service.createExperience(uid: uid, experience: draft);
      _experience = [..._experience, created]..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
      notifyListeners();
      await _recalcAndPatchCompletion();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _setSavingExperience(false);
    }
  }

  Future<bool> saveExperience(Experience exp) async {
    _setSavingExperience(true);
    try {
      await _service.updateExperience(uid: uid, experience: exp);
      _experience = _experience.map((e) => e.id == exp.id ? exp : e).toList()
        ..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
      notifyListeners();
      await _recalcAndPatchCompletion();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _setSavingExperience(false);
    }
  }

  Future<bool> deleteExperience(String expId) async {
    _setSavingExperience(true);
    try {
      await _service.deleteExperience(uid: uid, expId: expId);
      _experience = _experience.where((e) => e.id != expId).toList();
      notifyListeners();
      await _recalcAndPatchCompletion();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _setSavingExperience(false);
    }
  }

  // ------------- Completion % (weighted) -------------
  // ✅ RE-DESIGNED: Weighted calculation including AI Match Data
  Future<void> _recalcAndPatchCompletion() async {
    final pct = _computeCompletionPercent();

    // Update remote only if changed significantly
    final prev = _profile?.completionPercent ?? -1;
    final roundedPrev = (prev.isNaN ? -1 : prev).toStringAsFixed(1);
    final roundedNew = pct.toStringAsFixed(1);

    if (roundedPrev != roundedNew) {
      try {
        await _service.updateCompletionPercent(uid, pct);
        _profile = (_profile ?? const UserModel(userId: '', firstName: '', lastName: '', email: '')).copyWith(
          completionPercent: pct,
          lastUpdated: Timestamp.now(),
        );
        notifyListeners();
      } catch (e) {
        _setError(e);
      }
    } else {
      _profile = (_profile ?? const UserModel(userId: '', firstName: '', lastName: '', email: '')).copyWith(
        completionPercent: pct,
        lastUpdated: Timestamp.now(),
      );
      notifyListeners();
    }
  }

  /// ✅ New Calculation Logic
  /// Total = 100%
  /// 1. Personal Info (15%) - Name, Email, Phone, DOB, Loc, Photo
  /// 2. Education (15%) - At least one record
  /// 3. Experience (15%) - At least one record
  /// 4. Skills (10%) - At least one skill
  /// 5. English Tests (10%) - From SharedPrefs
  /// 6. Interests (10%) - From SharedPrefs
  /// 7. Personality (15%) - From SharedPrefs OR Firestore
  /// 8. Preferences (10%) - From SharedPrefs OR Firestore
  double _computeCompletionPercent() {
    final p = _profile;

    // 1. Personal Info (15%)
    int personalScore = 0;
    int personalTotal = 6;
    if ((p?.firstName ?? p?.name ?? '').trim().isNotEmpty) personalScore++;
    if ((p?.email ?? '').trim().isNotEmpty) personalScore++;
    if ((p?.phone ?? '').trim().isNotEmpty) personalScore++;
    if (p?.dob != null) personalScore++;
    if (((p?.city ?? '').isNotEmpty) || ((p?.country ?? '').isNotEmpty)) personalScore++;
    if ((p?.profilePictureUrl ?? '').isNotEmpty) personalScore++;
    final personalPct = personalTotal == 0 ? 0.0 : (personalScore / personalTotal) * 100.0;

    // 2. Education (15%)
    final educationPct = _education.isNotEmpty ? 100.0 : 0.0;

    // 3. Experience (15%)
    final experiencePct = _experience.isNotEmpty ? 100.0 : 0.0;

    // 4. Skills (10%)
    final skillsPct = _skills.isNotEmpty ? 100.0 : 0.0;

    // 5. English Tests (10%) - Data from SharedPrefs
    final englishPct = _englishTests.isNotEmpty ? 100.0 : 0.0;

    // 6. Interests (10%) - Data from SharedPrefs
    final interestsPct = _interests.isNotEmpty ? 100.0 : 0.0;

    // 7. Personality (15%) - Check both Firestore & SharedPrefs
    final hasFirestorePersonality = (p?.mbti?.isNotEmpty == true) || (p?.riasec?.isNotEmpty == true);
    final hasAiPersonality = _aiPersonality != null && _aiPersonality!.hasData;
    final personalityPct = (hasFirestorePersonality || hasAiPersonality) ? 100.0 : 0.0;

    // 8. Preferences (10%) - Check both Firestore & SharedPrefs
    final pPrefs = p?.preferences;
    final hasFirestorePrefs = (pPrefs?.desiredJobTitles?.isNotEmpty == true) ||
        (pPrefs?.industries?.isNotEmpty == true) ||
        (pPrefs?.preferredLocations?.isNotEmpty == true);

    final hasAiPrefs = _aiPreferences != null && (
        _aiPreferences!.studyLevel.isNotEmpty ||
            _aiPreferences!.locations.isNotEmpty
    );

    final preferencesPct = (hasFirestorePrefs || hasAiPrefs) ? 100.0 : 0.0;

    // Weights
    const wPersonal = 0.15;
    const wEducation = 0.15;
    const wExperience = 0.15;
    const wSkills = 0.10;
    const wEnglish = 0.10;
    const wInterests = 0.10;
    const wPersonality = 0.15;
    const wPreferences = 0.10;

    final total = (personalPct * wPersonal) +
        (educationPct * wEducation) +
        (experiencePct * wExperience) +
        (skillsPct * wSkills) +
        (englishPct * wEnglish) +
        (interestsPct * wInterests) +
        (personalityPct * wPersonality) +
        (preferencesPct * wPreferences);

    final clamped = total.clamp(0.0, 100.0);
    return double.parse(clamped.toStringAsFixed(1));
  }
}