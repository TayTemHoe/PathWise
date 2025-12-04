import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:path_wise/model/user_profile.dart';
import 'package:path_wise/services/profile_service.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({
    ProfileService? service,
    FirebaseAuth? auth,
  })  : _service = service ?? ProfileService(),
        _auth = auth ?? FirebaseAuth.instance;

  final ProfileService _service;
  final FirebaseAuth _auth;

  // ------------- State -------------
  UserProfile? _profile;
  List<Skill> _skills = const [];
  List<Education> _education = const [];
  List<Experience> _experience = const [];

  bool _isLoading = false;
  bool _savingRoot = false;
  bool _savingSkill = false;
  bool _savingEducation = false;
  bool _savingExperience = false;

  String? _error;

  // ------------- Getters -------------
  UserProfile? get profile => _profile;
  List<Skill> get skills => _skills;
  List<Education> get education => _education;
  List<Experience> get experience => _experience;

  bool get isLoading => _isLoading;
  bool get savingRoot => _savingRoot;
  bool get savingSkill => _savingSkill;
  bool get savingEducation => _savingEducation;
  bool get savingExperience => _savingExperience;

  String? get error => _error;

  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';


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
    debugPrint('🔄 ProfileViewModel: Starting loadAll() for uid=$uid');
    _setLoading(true);
    _setError(null);
    try {
      final up = await _service.getUserWithSubcollections(uid);

      // ✅ DEBUG: Print what we got from service
      debugPrint('📦 ProfileViewModel: Received profile=${up != null}');
      debugPrint('📦 ProfileViewModel: Skills count=${up?.skills?.length ?? 0}');
      debugPrint('📦 ProfileViewModel: Education count=${up?.education?.length ?? 0}');
      debugPrint('📦 ProfileViewModel: Experience count=${up?.experience?.length ?? 0}');

      if (up == null) {
        debugPrint('⚠️ ProfileViewModel: No profile found, creating new one');
        // First-time bootstrap minimal doc
        await _service.createOrMergeUser(
          uid,
          const UserProfile(
            completionPercent: 0,
          ),
        );
        final created = await _service.getUserWithSubcollections(uid);
        debugPrint('✅ ProfileViewModel: Created profile=${created != null}');
        _applyBundle(created);
      } else {
        _applyBundle(up);
      }

      // ✅ DEBUG: Print final state
      debugPrint('✅ ProfileViewModel: Final state - Skills=${_skills.length}, Education=${_education.length}, Experience=${_experience.length}');

      await _recalcAndPatchCompletion();
    } catch (e, stackTrace) {
      debugPrint('❌ ProfileViewModel: Error in loadAll(): $e');
      debugPrint('Stack trace: $stackTrace');
      _setError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() => loadAll();

  void _applyBundle(UserProfile? up) {
    debugPrint('📝 ProfileViewModel: _applyBundle called');
    debugPrint('📝 Skills before: ${_skills.length}');

    _profile = up;
    _skills = up?.skills ?? const [];
    _education = up?.education ?? const [];
    _experience = up?.experience ?? const [];

    debugPrint('📝 Skills after: ${_skills.length}');
    if (_skills.isNotEmpty) {
      for (var skill in _skills) {
        debugPrint('  - Skill: ${skill.name}, Category: "${skill.category}"');
      }
    }

    notifyListeners();
  }

  // ------------- Update: Personal Info -------------
  Future<bool> updatePersonalInfo({
    String? name,
    String? email, // editable if you want
    String? phone,
    Timestamp? dob,
    String? gender, // keep nullable; remove if not used in UI
    String? city,
    String? state,
    String? country,
  }) async {
    _setSavingRoot(true);
    _setError(null);
    try {
      await _service.updatePersonalInfo(
        uid: uid,
        name: name,
        email: email,
        phone: phone,
        dob: dob,
        gender: gender,
        city: city,
        state: state,
        country: country,
      );
      // Update local cache to keep UI snappy
      _profile = (_profile ?? const UserProfile()).copyWith(
        name: name ?? _profile?.name,
        email: email ?? _profile?.email,
        phone: phone ?? _profile?.phone,
        dob: dob ?? _profile?.dob,
        gender: gender ?? _profile?.gender,
        city: city ?? _profile?.city,
        state: state ?? _profile?.state,
        country: country ?? _profile?.country,
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

  // ------------- Update: Personality -------------
  Future<bool> updatePersonality({
    String? mbti,
    String? riasec, // string in your latest schema
  }) async {
    _setSavingRoot(true);
    _setError(null);
    try {
      await _service.updatePersonality(uid: uid, mbti: mbti, riasec: riasec);
      _profile = (_profile ?? const UserProfile()).copyWith(
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
  UserProfile? _user;

  UserProfile? get user => _user; // <= needed by the view

  Future<bool> updatePreferences(Preferences prefs) async {
    try {
      await _service.updatePreferences(uid, prefs.toFirestore());
      _user = _user?.copyWith(preferences: prefs);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }


  // ------------- Upload Profile Picture -------------
  Future<String?> uploadProfilePicture(File file, {String? fileExt}) async {
    _setSavingRoot(true);
    _setError(null);
    try {
      // Print debug info
      debugPrint('Attempting upload for user: $uid');

      final url = await _service.uploadProfilePicture(uid: uid, file: file, fileExt: fileExt);
      if (url != null) {
        _profile = (_profile ?? const UserProfile()).copyWith(
          profilePictureUrl: url,
          lastUpdated: Timestamp.now(),
        );
        notifyListeners();
        await _recalcAndPatchCompletion();
      }
      return url;
    } catch (e) {
      // Capture the full error string
      debugPrint('viewModel Upload Error: $e');
      _setError(e.toString());
      return null;
    } finally {
      _setSavingRoot(false);
    }
  }

  // ------------- Skills CRUD -------------
  Future<bool> addSkill(Skill draft) async {
    debugPrint('➕ Adding skill: ${draft.name}, Category: "${draft.category}"');
    _setSavingSkill(true);
    _setError(null);
    try {
      final created = await _service.createSkill(uid: uid, skill: draft);
      debugPrint('✅ Skill created with ID: ${created.id}');
      _skills = [..._skills, created]..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
      debugPrint('✅ Total skills now: ${_skills.length}');
      notifyListeners();
      await _recalcAndPatchCompletion();
      return true;
    } catch (e) {
      debugPrint('❌ Error adding skill: $e');
      _setError(e);
      return false;
    } finally {
      _setSavingSkill(false);
    }
  }

  Future<bool> saveSkill(Skill skill) async {
    debugPrint('💾 Updating skill: ${skill.name}, Category: "${skill.category}"');
    _setSavingSkill(true);
    _setError(null);
    try {
      await _service.updateSkill(uid: uid, skill: skill);
      _skills = _skills.map((s) => s.id == skill.id ? skill : s).toList()
        ..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
      debugPrint('✅ Skill updated successfully');
      notifyListeners();
      await _recalcAndPatchCompletion();
      return true;
    } catch (e) {
      debugPrint('❌ Error updating skill: $e');
      _setError(e);
      return false;
    } finally {
      _setSavingSkill(false);
    }
  }

  Future<bool> deleteSkill(String skillId) async {
    debugPrint('🗑️ Deleting skill: $skillId');
    _setSavingSkill(true);
    _setError(null);
    try {
      await _service.deleteSkill(uid: uid, skillId: skillId);
      _skills = _skills.where((s) => s.id != skillId).toList();
      debugPrint('✅ Skill deleted. Total skills now: ${_skills.length}');
      notifyListeners();
      await _recalcAndPatchCompletion();
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting skill: $e');
      _setError(e);
      return false;
    } finally {
      _setSavingSkill(false);
    }
  }

  // ------------- Education CRUD -------------
  Future<bool> addEducation(Education draft) async {
    debugPrint('➕ Adding education: ${draft.institution}');
    _setSavingEducation(true);
    _setError(null);
    try {
      final created = await _service.createEducation(uid: uid, education: draft);
      debugPrint('✅ Education created with ID: ${created.id}');
      _education = [..._education, created]..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
      debugPrint('✅ Total education entries now: ${_education.length}');
      notifyListeners();
      await _recalcAndPatchCompletion();
      return true;
    } catch (e) {
      debugPrint('❌ Error adding education: $e');
      _setError(e);
      return false;
    } finally {
      _setSavingEducation(false);
    }
  }

  Future<bool> saveEducation(Education edu) async {
    debugPrint('💾 Updating education: ${edu.institution}');
    _setSavingEducation(true);
    _setError(null);
    try {
      await _service.updateEducation(uid: uid, education: edu);
      _education = _education.map((e) => e.id == edu.id ? edu : e).toList()
        ..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
      debugPrint('✅ Education updated successfully');
      notifyListeners();
      await _recalcAndPatchCompletion();
      return true;
    } catch (e) {
      debugPrint('❌ Error updating education: $e');
      _setError(e);
      return false;
    } finally {
      _setSavingEducation(false);
    }
  }

  Future<bool> deleteEducation(String eduId) async {
    debugPrint('🗑️ Deleting education: $eduId');
    _setSavingEducation(true);
    _setError(null);
    try {
      await _service.deleteEducation(uid: uid, eduId: eduId);
      _education = _education.where((e) => e.id != eduId).toList();
      debugPrint('✅ Education deleted. Total entries now: ${_education.length}');
      notifyListeners();
      await _recalcAndPatchCompletion();
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting education: $e');
      _setError(e);
      return false;
    } finally {
      _setSavingEducation(false);
    }
  }

  // ------------- Experience CRUD -------------
  Future<bool> addExperience(Experience draft) async {
    debugPrint('➕ Adding experience: ${draft.company}');
    _setSavingExperience(true);
    _setError(null);
    try {
      final created = await _service.createExperience(uid: uid, experience: draft);
      debugPrint('✅ Experience created with ID: ${created.id}');
      _experience = [..._experience, created]..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
      debugPrint('✅ Total experience entries now: ${_experience.length}');
      notifyListeners();
      await _recalcAndPatchCompletion();
      return true;
    } catch (e) {
      debugPrint('❌ Error adding experience: $e');
      _setError(e);
      return false;
    } finally {
      _setSavingExperience(false);
    }
  }

  Future<bool> saveExperience(Experience exp) async {
    debugPrint('💾 Updating experience: ${exp.company}');
    _setSavingExperience(true);
    _setError(null);
    try {
      await _service.updateExperience(uid: uid, experience: exp);
      _experience = _experience.map((e) => e.id == exp.id ? exp : e).toList()
        ..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
      debugPrint('✅ Experience updated successfully');
      notifyListeners();
      await _recalcAndPatchCompletion();
      return true;
    } catch (e) {
      debugPrint('❌ Error updating experience: $e');
      _setError(e);
      return false;
    } finally {
      _setSavingExperience(false);
    }
  }

  Future<bool> deleteExperience(String expId) async {
    debugPrint('🗑️ Deleting experience: $expId');
    _setSavingExperience(true);
    _setError(null);
    try {
      await _service.deleteExperience(uid: uid, expId: expId);
      _experience = _experience.where((e) => e.id != expId).toList();
      debugPrint('✅ Experience deleted. Total entries now: ${_experience.length}');
      notifyListeners();
      await _recalcAndPatchCompletion();
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting experience: $e');
      _setError(e);
      return false;
    } finally {
      _setSavingExperience(false);
    }
  }

  // ------------- Completion % (weighted) -------------
  Future<void> _recalcAndPatchCompletion() async {
    final pct = _computeCompletionPercent();
    // Update remote only if changed significantly (avoid thrashing)
    final prev = _profile?.completionPercent ?? -1;
    final roundedPrev = (prev.isNaN ? -1 : prev).toStringAsFixed(1);
    final roundedNew = pct.toStringAsFixed(1);
    if (roundedPrev != roundedNew) {
      try {
        await _service.updateCompletionPercent(uid, pct);
        _profile = (_profile ?? const UserProfile()).copyWith(
          completionPercent: pct,
          lastUpdated: Timestamp.now(),
        );
        notifyListeners();
      } catch (e) {
        // not fatal; keep UI value
        _setError(e);
      }
    } else {
      // still update local
      _profile = (_profile ?? const UserProfile()).copyWith(
        completionPercent: pct,
        lastUpdated: Timestamp.now(),
      );
      notifyListeners();
    }
  }

  double _computeCompletionPercent() {
    final p = _profile;

    // --- Personal (20%) ---
    // choose a simple rubric (6 fields)
    int personalTotal = 6;
    int personalScore = 0;
    if ((p?.name ?? '').trim().isNotEmpty) personalScore++;
    if ((p?.email ?? '').trim().isNotEmpty) personalScore++;
    if ((p?.phone ?? '').trim().isNotEmpty) personalScore++;
    if (p?.dob != null) personalScore++;
    if (((p?.city ?? '').isNotEmpty) || ((p?.country ?? '').isNotEmpty)) personalScore++;
    if ((p?.profilePictureUrl ?? '').isNotEmpty) personalScore++;
    final personalPct = personalTotal == 0 ? 0.0 : (personalScore / personalTotal) * 100.0;

    // --- Skills (25%) ---
    final skillsPct = _skills.isNotEmpty ? 100.0 : 0.0;

    // --- Education (20%) ---
    final educationPct = _education.isNotEmpty ? 100.0 : 0.0;

    // --- Experience (25%) ---
    final experiencePct = _experience.isNotEmpty ? 100.0 : 0.0;

    // --- Preferences (10%) ---
    final prefs = p?.preferences;
    final hasPrefs = (prefs?.desiredJobTitles?.isNotEmpty == true) ||
        (prefs?.industries?.isNotEmpty == true) ||
        (prefs?.workEnvironment?.isNotEmpty == true) ||
        (prefs?.preferredLocations?.isNotEmpty == true) ||
        (prefs?.willingToRelocate != null) ||
        ((prefs?.remoteAcceptance ?? '').isNotEmpty) ||
        (prefs?.salary != null);
    final preferencesPct = hasPrefs ? 100.0 : 0.0;

    // weights
    const wPersonal = 0.20;
    const wSkills = 0.25;
    const wEducation = 0.20;
    const wExperience = 0.25;
    const wPreferences = 0.10;

    final total = (personalPct * wPersonal) +
        (skillsPct * wSkills) +
        (educationPct * wEducation) +
        (experiencePct * wExperience) +
        (preferencesPct * wPreferences);

    final clamped = total.clamp(0.0, 100.0);
    return double.parse(clamped.toStringAsFixed(1));
  }
}