import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:path_wise/model/user_profile.dart';

class ProfileService {
  ProfileService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  // ==== Firestore refs ==========================================================
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _users.doc(uid);

  CollectionReference<Map<String, dynamic>> _skillsCol(String uid) =>
      _userDoc(uid).collection('skills');

  CollectionReference<Map<String, dynamic>> _eduCol(String uid) =>
      _userDoc(uid).collection('education');

  CollectionReference<Map<String, dynamic>> _expCol(String uid) =>
      _userDoc(uid).collection('experience');

  // =============================================================================
  //                                ROOT DOCUMENT
  // =============================================================================

  /// Create or initialize a user root document (id: Firebase UID).
  /// Pass [appUserId] like "U0001" if you want to set it once.
  Future<void> createOrInitUser(
      String uid, {
        String? appUserId,
        DateTime? createdAt,
      }) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists) {
      await _userDoc(uid).set({
        if (appUserId != null) 'appUserId': appUserId,
        'createdAt': Timestamp.fromDate(createdAt ?? DateTime.now()),
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
        'completionPercent': 0.0,
      }, SetOptions(merge: true));
    }
  }

  /// Fetch a user profile (root doc only; subcollections use separate calls).
  Future<UserProfile?> getUserProfile(String uid) async {
    final snap = await _userDoc(uid).get();
    if (!snap.exists) return null;
    return UserProfile.fromDoc(snap);
  }

  /// Overwrite or create the whole root doc from [profile].
  Future<void> setUserProfile(UserProfile profile, {bool merge = true}) async {
    await _userDoc(profile.uid).set(profile.toMap(), SetOptions(merge: merge));
  }

  /// Update only some fields at root (e.g., updating personalInfo/preferences).
  Future<void> updateUserProfileFields(
      String uid,
      Map<String, dynamic> partial,
      ) async {
    await _userDoc(uid).update({
      ...partial,
      'lastUpdated': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Query by display ID (e.g., "U0001") → returns first match or null
  Future<UserProfile?> getUserByAppUserId(String appUserId) async {
    final q = await _users.where('appUserId', isEqualTo: appUserId).limit(1).get();
    if (q.docs.isEmpty) return null;
    return UserProfile.fromDoc(q.docs.first);
  }

  // =============================================================================
  //                            PROFILE PICTURE (STORAGE)
  // =============================================================================

  /// Upload profile picture to `profile_pictures/{uid}.jpg`
  /// Returns the public download URL.
  Future<String> uploadProfilePicture(
      String uid,
      File imageFile, {
        String contentType = 'image/jpeg',
      }) async {
    final ref = _storage.ref().child('profile_pictures/$uid.jpg');

    await ref.putFile(
      imageFile,
      SettableMetadata(contentType: contentType),
    );

    final url = await ref.getDownloadURL();

    // Save URL to root doc
    await updateUserProfileFields(uid, {
      'personalInfo.profilePictureUrl': url,
      'personalInfo.pictureMeta': {
        // optional: you can fill actual image metadata if known
        // 'w': 400, 'h': 400, 'format': 'jpg', 'sizeBytes': imageFile.lengthSync(),
      }
    });

    return url;
  }

  // =============================================================================
  //                                  SKILLS
  // =============================================================================

  /// Watch skills as a stream ordered by `order` asc.
  Stream<List<Skill>> watchSkills(String uid) {
    return _skillsCol(uid)
        .orderBy('order')
        .snapshots()
        .map((s) => s.docs.map((d) => Skill.fromDoc(d)).toList());
  }

  /// One-off fetch skills
  Future<List<Skill>> getSkills(String uid) async {
    final s = await _skillsCol(uid).orderBy('order').get();
    return s.docs.map((d) => Skill.fromDoc(d)).toList();
  }

  /// Add a skill (auto-assign `order` to end of list).
  Future<String> addSkill(String uid, Skill skill) async {
    // determine next order
    final current = await _skillsCol(uid).orderBy('order', descending: true).limit(1).get();
    final nextOrder = current.docs.isEmpty
        ? 0
        : ((current.docs.first.data()['order'] as num?)?.toInt() ?? 0) + 1;

    final ref = await _skillsCol(uid).add({
      ...skill.toMap(),
      'order': nextOrder,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
    return ref.id;
  }

  Future<void> updateSkill(String uid, Skill skill) async {
    await _skillsCol(uid).doc(skill.id).update({
      ...skill.toMap(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteSkill(String uid, String skillId) async {
    await _skillsCol(uid).doc(skillId).delete();
  }

  /// Batch reorder: pass list in the final order → updates `order` = index
  Future<void> reorderSkills(String uid, List<Skill> ordered) async {
    final batch = _db.batch();
    for (var i = 0; i < ordered.length; i++) {
      final ref = _skillsCol(uid).doc(ordered[i].id);
      batch.update(ref, {'order': i, 'updatedAt': Timestamp.fromDate(DateTime.now())});
    }
    await batch.commit();
  }

  // =============================================================================
  //                                 EDUCATION
  // =============================================================================

  Stream<List<Education>> watchEducation(String uid) {
    return _eduCol(uid)
        .orderBy('order', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => Education.fromDoc(d)).toList());
  }

  Future<List<Education>> getEducation(String uid) async {
    final s = await _eduCol(uid).orderBy('order').get();
    return s.docs.map((d) => Education.fromDoc(d)).toList();
  }

  Future<String> addEducation(String uid, Education edu) async {
    final current = await _eduCol(uid).orderBy('order', descending: true).limit(1).get();
    final nextOrder = current.docs.isEmpty
        ? 0
        : ((current.docs.first.data()['order'] as num?)?.toInt() ?? 0) + 1;

    final ref = await _eduCol(uid).add({
      ...edu.toMap(),
      'order': nextOrder,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
    return ref.id;
  }

  Future<void> updateEducation(String uid, Education edu) async {
    await _eduCol(uid).doc(edu.id).update({
      ...edu.toMap(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteEducation(String uid, String eduId) async {
    await _eduCol(uid).doc(eduId).delete();
  }

  Future<void> reorderEducation(String uid, List<Education> ordered) async {
    final batch = _db.batch();
    for (var i = 0; i < ordered.length; i++) {
      batch.update(_eduCol(uid).doc(ordered[i].id), {
        'order': i,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
    await batch.commit();
  }

  // =============================================================================
  //                                EXPERIENCE
  // =============================================================================

  Stream<List<Experience>> watchExperience(String uid) {
    return _expCol(uid)
        .orderBy('order')
        .snapshots()
        .map((s) => s.docs.map((d) => Experience.fromDoc(d)).toList());
  }

  Future<List<Experience>> getExperience(String uid) async {
    final s = await _expCol(uid).orderBy('order').get();
    return s.docs.map((d) => Experience.fromDoc(d)).toList();
  }

  Future<String> addExperience(String uid, Experience exp) async {
    final current = await _expCol(uid).orderBy('order', descending: true).limit(1).get();
    final nextOrder = current.docs.isEmpty
        ? 0
        : ((current.docs.first.data()['order'] as num?)?.toInt() ?? 0) + 1;

    final ref = await _expCol(uid).add({
      ...exp.toMap(),
      'order': nextOrder,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
    return ref.id;
  }

  Future<void> updateExperience(String uid, Experience exp) async {
    await _expCol(uid).doc(exp.id).update({
      ...exp.toMap(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteExperience(String uid, String expId) async {
    await _expCol(uid).doc(expId).delete();
  }

  Future<void> reorderExperience(String uid, List<Experience> ordered) async {
    final batch = _db.batch();
    for (var i = 0; i < ordered.length; i++) {
      batch.update(_expCol(uid).doc(ordered[i].id), {
        'order': i,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
    await batch.commit();
  }

  // =============================================================================
  //                              COMPLETION & VALIDATION
  // =============================================================================

  /// Update the completion percentage & validation map on root.
  /// You’ll compute these in ViewModel, then call this method.
  Future<void> updateCompletionAndValidation(
      String uid, {
        double? completionPercent,
        Map<String, dynamic>? validation,
      }) async {
    final data = <String, dynamic>{
      if (completionPercent != null) 'completionPercent': completionPercent,
      if (validation != null) 'validation': validation,
      'lastUpdated': Timestamp.fromDate(DateTime.now()),
    };
    await _userDoc(uid).update(data);
  }
}
