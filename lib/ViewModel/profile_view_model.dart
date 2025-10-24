import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/user_profile.dart';
import '../service/profile_service.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({ProfileService? service})
      : _service = service ?? ProfileService();

  final ProfileService _service;

  // ===== Root state =====
  UserProfile? _profile;
  UserProfile? get profile => _profile;

  // Subcollections (loaded terpisah)
  List<Skill> _skills = [];
  List<Skill> get skills => List.unmodifiable(_skills);

  List<Education> _education = [];
  List<Education> get education => List.unmodifiable(_education);

  List<Experience> _experience = [];
  List<Experience> get experience => List.unmodifiable(_experience);

  // ===== UI flags =====
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _savingRoot = false;
  bool get savingRoot => _savingRoot;

  bool _loadingSkills = false;
  bool get loadingSkills => _loadingSkills;

  bool _loadingEdu = false;
  bool get loadingEdu => _loadingEdu;

  bool _loadingExp = false;
  bool get loadingExp => _loadingExp;

  String? _error;
  String? get error => _error;

  // ====== Helpers ======
  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(Object e) {
    _error = e.toString();
    notifyListeners();
  }

  // =========================
  // Loaders
  // =========================

  /// Load root + subcollections in parallel (untuk Profile Overview).
  Future<void> loadAll() async {
    _setLoading(true);
    _error = null;
    try {
      final up = await _service.getUserWithSubcollections(uid);
      if (up == null) {
        // 🔴 STOP CREATING EMPTY USER HERE
        throw Exception("User profile not found for uid: $uid");
      } else {
        _profile = up;
        _skills = up.skills ?? [];
        _education = up.education ?? [];
        _experience = up.experience ?? [];
      }
      await _recalcAndPatchCompletion(); // jaga consistency meter
    } catch (e) {
      _setError(e);
    } finally {
      _setLoading(false);
    }
  }


  Future<void> refreshRootOnly() async {
    try {
      final up = await _service.getUser(uid);
      if (up != null) _profile = up;
      notifyListeners();
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> refreshSkills() async {
    _loadingSkills = true;
    notifyListeners();
    try {
      _skills = await _service.listSkills(uid: uid, limit: 200);
      notifyListeners();
    } catch (e) {
      _setError(e);
    } finally {
      _loadingSkills = false;
      notifyListeners();
    }
  }

  Future<void> refreshEducation() async {
    _loadingEdu = true;
    notifyListeners();
    try {
      _education = await _service.listEducation(uid: uid, limit: 100);
      notifyListeners();
    } catch (e) {
      _setError(e);
    } finally {
      _loadingEdu = false;
      notifyListeners();
    }
  }

  Future<void> refreshExperience() async {
    _loadingExp = true;
    notifyListeners();
    try {
      _experience = await _service.listExperience(uid: uid, limit: 100);
      notifyListeners();
    } catch (e) {
      _setError(e);
    } finally {
      _loadingExp = false;
      notifyListeners();
    }
  }

  // =========================
  // Root updates (users/{uid})
  // =========================

  /// Update full root doc menggunakan model (gunakan ini selepas edit besar).
  Future<bool> updateRoot(UserProfile updated) async {
    _savingRoot = true;
    _error = null;
    notifyListeners();
    try {
      await _service.updateUser(uid, updated.copyWith(
        lastUpdated: Timestamp.now(),
      ));
      _profile = updated;
      await _recalcAndPatchCompletion();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _savingRoot = false;
      notifyListeners();
    }
  }

  /// Patch sebagian field root doc. Contoh:
  /// patchRoot({'personalInfo.name': 'Aisyah'})
  Future<bool> patchRoot(Map<String, dynamic> patch) async {
    _savingRoot = true;
    _error = null;
    notifyListeners();
    try {
      await _service.patchUser(uid, patch);
      await refreshRootOnly();
      await _recalcAndPatchCompletion();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _savingRoot = false;
      notifyListeners();
    }
  }

  /// Update Personal Info (helper supaya UI simple).
  Future<bool> updatePersonalInfo({
    String? name,
    String? phone,
    Timestamp? dob,
    String? gender,
    String? city,
    String? state,
    String? country,
  }) {
    return patchRoot({
      if (name != null) 'personalInfo.name': name,
      if (phone != null) 'personalInfo.phone': phone,
      if (dob != null) 'personalInfo.dob': dob,
      if (gender != null) 'personalInfo.gender': gender,
      if (city != null) 'personalInfo.location.city': city,
      if (state != null) 'personalInfo.location.state': state,
      if (country != null) 'personalInfo.location.country': country,
    });
  }

  /// Update Preferences (tanpa relocationDistanceKm sesuai requirement).
  Future<bool> updatePreferences({
    List<String>? desiredJobTitles,
    List<String>? industries,
    String? companySize,
    List<String>? workEnvironment,
    List<String>? preferredLocations,
    bool? willingToRelocate,
    String? remoteAcceptance,
    SalaryPref? salary,
  }) {
    return patchRoot({
      if (desiredJobTitles != null)
        'preferences.desiredJobTitles': desiredJobTitles,
      if (industries != null) 'preferences.industries': industries,
      if (companySize != null) 'preferences.companySize': companySize,
      if (workEnvironment != null)
        'preferences.workEnvironment': workEnvironment,
      if (preferredLocations != null)
        'preferences.preferredLocations': preferredLocations,
      if (willingToRelocate != null)
        'preferences.willingToRelocate': willingToRelocate,
      if (remoteAcceptance != null)
        'preferences.remoteAcceptance': remoteAcceptance,
      if (salary != null) 'preferences.salary': salary.toMap(),
    });
  }

  /// Update Personality (tanpa `source`).
  Future<bool> updatePersonality({
    String? mbti,
    List<String>? riasec,
    Timestamp? updatedAt,
  }) {
    return patchRoot({
      if (mbti != null) 'personality.mbti': mbti,
      if (riasec != null) 'personality.riasec': riasec,
      'personality.updatedAt': updatedAt ?? Timestamp.now(),
    });
  }

  /// Upload gambar profil -> update URL di Firestore -> refresh local
  Future<String?> uploadProfilePicture(File file, {String fileExt = 'jpg'}) async {
    try {
      final url = await _service.uploadProfilePicture(uid: uid, file: file, fileExt: fileExt);
      // refresh root & local cache
      await refreshRootOnly();
      return url;
    } catch (e) {
      _setError(e);
      return null;
    }
  }

  // =========================
  // Skills CRUD
  // =========================

  Future<String?> addSkill(Skill skill) async {
    try {
      final id = await _service.addSkill(uid: uid, skill: skill);
      await refreshSkills();
      await _recalcAndPatchCompletion();
      return id;
    } catch (e) {
      _setError(e);
      return null;
    }
  }

  Future<bool> updateSkill(Skill skill) async {
    try {
      await _service.updateSkill(uid: uid, skill: skill);
      await refreshSkills();
      await _recalcAndPatchCompletion();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  Future<bool> deleteSkill(String skillId) async {
    try {
      await _service.deleteSkill(uid: uid, skillId: skillId);
      _skills.removeWhere((s) => s.id == skillId);
      notifyListeners();
      await _recalcAndPatchCompletion();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  Future<bool> reorderSkills(List<String> orderedIds) async {
    try {
      await _service.reorderSkills(uid: uid, orderedIds: orderedIds);
      await refreshSkills();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  // =========================
  // Education CRUD
  // =========================

  Future<String?> addEducation(Education edu) async {
    try {
      final id = await _service.addEducation(uid: uid, education: edu);
      await refreshEducation();
      await _recalcAndPatchCompletion();
      return id;
    } catch (e) {
      _setError(e);
      return null;
    }
  }

  Future<bool> updateEducation(Education edu) async {
    try {
      await _service.updateEducation(uid: uid, education: edu);
      await refreshEducation();
      await _recalcAndPatchCompletion();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  Future<bool> deleteEducation(String eduId) async {
    try {
      await _service.deleteEducation(uid: uid, eduId: eduId);
      _education.removeWhere((e) => e.id == eduId);
      notifyListeners();
      await _recalcAndPatchCompletion();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  Future<bool> reorderEducation(List<String> orderedIds) async {
    try {
      await _service.reorderEducation(uid: uid, orderedIds: orderedIds);
      await refreshEducation();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  // =========================
  // Experience CRUD
  // =========================

  Future<String?> addExperience(Experience exp) async {
    try {
      final id = await _service.addExperience(uid: uid, experience: exp);
      await refreshExperience();
      await _recalcAndPatchCompletion();
      return id;
    } catch (e) {
      _setError(e);
      return null;
    }
  }

  Future<bool> updateExperience(Experience exp) async {
    try {
      await _service.updateExperience(uid: uid, experience: exp);
      await refreshExperience();
      await _recalcAndPatchCompletion();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  Future<bool> deleteExperience(String expId) async {
    try {
      await _service.deleteExperience(uid: uid, expId: expId);
      _experience.removeWhere((x) => x.id == expId);
      notifyListeners();
      await _recalcAndPatchCompletion();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  Future<bool> reorderExperience(List<String> orderedIds) async {
    try {
      await _service.reorderExperience(uid: uid, orderedIds: orderedIds);
      await refreshExperience();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  // =========================
  // Validation + Completion
  // =========================

  /// Kira completion berdasarkan bobot:
  /// Personal (20), Skills (25), Education (20), Experience (25), Preferences (10)
  double _computeCompletion(UserProfile p, {
    required List<Skill> skills,
    required List<Education> edu,
    required List<Experience> exp,
  }) {
    double personal = 0;
    if ((p.name ?? '').isNotEmpty &&
        (p.email ?? '').isNotEmpty &&
        (p.phone ?? '').isNotEmpty &&
        p.dob != null &&
        (p.gender ?? '').isNotEmpty &&
        (p.city ?? '').isNotEmpty &&
        (p.country ?? '').isNotEmpty) {
      personal = 100;
    } else {
      int ticks = 0;
      if ((p.name ?? '').isNotEmpty) ticks++;
      if ((p.email ?? '').isNotEmpty) ticks++;
      if ((p.phone ?? '').isNotEmpty) ticks++;
      if (p.dob != null) ticks++;
      if ((p.gender ?? '').isNotEmpty) ticks++;
      if ((p.city ?? '').isNotEmpty) ticks++;
      if ((p.country ?? '').isNotEmpty) ticks++;
      personal = (ticks / 7.0) * 100.0;
    }

    final skillScore = skills.isEmpty
        ? 0.0
        : (skills.length >= 5 ? 100.0 : (skills.length / 5.0) * 100.0);

    final eduScore = edu.isEmpty ? 0.0 : 100.0;

    final expScore = exp.isEmpty
        ? 0.0
        : (exp.length >= 2 ? 100.0 : (exp.length / 2.0) * 100.0);

    double prefScore = 0.0;
    final hasPrefs = (p.desiredJobTitles?.isNotEmpty == true) ||
        (p.industries?.isNotEmpty == true) ||
        (p.workEnvironment?.isNotEmpty == true) ||
        (p.preferredLocations?.isNotEmpty == true) ||
        p.willingToRelocate != null ||
        (p.remoteAcceptance ?? '').isNotEmpty ||
        p.salary != null;
    if (hasPrefs) prefScore = 100.0;

    final total = (personal * 0.20) +
        (skillScore * 0.25) +
        (eduScore * 0.20) +
        (expScore * 0.25) +
        (prefScore * 0.10);

    return double.parse(total.toStringAsFixed(1));
  }

  /// Validasi minimum untuk UC009 (supaya Save bisa jalan).
  /// Return: list isu error (kosong berarti valid).
  List<String> validateProfile(UserProfile p) {
    final issues = <String>[];

    // Personal required minimal
    if ((p.name ?? '').isEmpty) issues.add('Name is required');
    if ((p.email ?? '').isEmpty) issues.add('Email is required');
    if ((p.phone ?? '').isEmpty) issues.add('Phone is required');

    // Tanggal masuk akal (contoh: DOB tidak di masa depan)
    if (p.dob != null) {
      final now = DateTime.now();
      if (p.dob!.toDate().isAfter(now)) {
        issues.add('Date of birth cannot be in the future');
      }
    }

    // Optional: format email/phone bisa ditambah regex di UI.

    return issues;
  }

  /// Recalculate completion & patch ke Firestore.
  Future<void> _recalcAndPatchCompletion() async {
    if (_profile == null) return;
    final cp = _computeCompletion(
      _profile!,
      skills: _skills,
      edu: _education,
      exp: _experience,
    );
    _profile = _profile!.copyWith(completionPercent: cp);
    await _service.patchUser(uid, {
      'completionPercent': cp,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
    notifyListeners();
  }
}
