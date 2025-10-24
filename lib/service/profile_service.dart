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

  // ----------------------------
  // Helpers
  // ----------------------------
  CollectionReference<Map<String, dynamic>> _usersCol() =>
      _db.collection('users');

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _usersCol().doc(uid);

  CollectionReference<Map<String, dynamic>> _skillsCol(String uid) =>
      _userDoc(uid).collection('skills');

  CollectionReference<Map<String, dynamic>> _eduCol(String uid) =>
      _userDoc(uid).collection('education');

  CollectionReference<Map<String, dynamic>> _expCol(String uid) =>
      _userDoc(uid).collection('experience');

  // ============================
  // Root: users/{uid}
  // ============================

  /// Create or merge a user root document.
  Future<void> createOrMergeUser(String uid, UserProfile profile) async {
    await _userDoc(uid).set(
      {
        ...profile.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Get user profile (root doc). Return null if not found.
  Future<UserProfile?> getUser(String uid) async {
    final snap = await _userDoc(uid).get();
    if (!snap.exists) return null;
    return UserProfile.fromFirestore(snap);
  }

  /// Update entire user document with model payload.
  Future<void> updateUser(String uid, UserProfile profile) async {
    final map = profile.toMap();
    map['lastUpdated'] = FieldValue.serverTimestamp();
    await _userDoc(uid).update(map);
  }

  /// Patch partial fields on user doc (e.g., only preferences or personalInfo).
  Future<void> patchUser(String uid, Map<String, dynamic> patch) async {
    await _userDoc(uid).update({
      ...patch,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Delete root user doc ONLY (does NOT delete subcollections).
  Future<void> deleteUserDocOnly(String uid) => _userDoc(uid).delete();

  /// Danger: delete ALL user data (root + subcollections).
  /// Use carefully; Firestore has no cascade delete, so we do it manually.
  Future<void> deleteAllUserData(String uid) async {
    // delete subcollections (batch per 400 ops safety)
    Future<void> deleteCol(
        CollectionReference<Map<String, dynamic>> col,
        ) async {
      const int pageSize = 300;
      Query<Map<String, dynamic>> q = col.limit(pageSize);
      while (true) {
        final snap = await q.get();
        if (snap.docs.isEmpty) break;
        final batch = _db.batch();
        for (final d in snap.docs) {
          batch.delete(d.reference);
        }
        await batch.commit();
        if (snap.docs.length < pageSize) break;
      }
    }

    await deleteCol(_skillsCol(uid));
    await deleteCol(_eduCol(uid));
    await deleteCol(_expCol(uid));

    await deleteUserDocOnly(uid);
  }

  // ============================
  // Profile Picture (Storage)
  // ============================

  /// Upload profile picture and return download URL.
  /// Enforce size/type di Storage Rules; app-side boleh validate juga.
  Future<String> uploadProfilePicture({
    required String uid,
    required File file,
    String fileExt = 'jpg', // 'jpg' | 'png' | 'gif'
  }) async {
    final ref = _storage.ref().child('profile_pictures/$uid.$fileExt');

    // Upload
    final task = await ref.putFile(file);
    // URL
    final url = await task.ref.getDownloadURL();

    // Update user doc with URL + lastUpdated
    await _userDoc(uid).update({
      'personalInfo.profilePictureUrl': url,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    return url;
  }

  // ============================
  // Subcollection: skills
  // ============================

  Future<List<Skill>> listSkills({
    required String uid,
    int limit = 100,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> q =
    _skillsCol(uid).orderBy('order').limit(limit);
    if (startAfter != null) {
      q = (q.startAfterDocument(startAfter));
    }
    final snap = await q.get();
    return snap.docs
        .map((d) => Skill.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>))
        .toList();
  }

  Future<Skill?> getSkill({
    required String uid,
    required String skillId,
  }) async {
    final snap = await _skillsCol(uid).doc(skillId).get();
    if (!snap.exists) return null;
    return Skill.fromFirestore(snap);
  }

  /// Create a skill; returns new doc id.
  Future<String> addSkill({
    required String uid,
    required Skill skill,
  }) async {
    final ref = await _skillsCol(uid).add({
      ...skill.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateSkill({
    required String uid,
    required Skill skill,
  }) async {
    await _skillsCol(uid).doc(skill.id).update({
      ...skill.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteSkill({
    required String uid,
    required String skillId,
  }) =>
      _skillsCol(uid).doc(skillId).delete();

  /// Reorder skill items by passing ordered ids list.
  Future<void> reorderSkills({
    required String uid,
    required List<String> orderedIds,
  }) async {
    final batch = _db.batch();
    for (int i = 0; i < orderedIds.length; i++) {
      batch.update(_skillsCol(uid).doc(orderedIds[i]), {'order': i});
    }
    await batch.commit();
  }

  // ============================
  // Subcollection: education
  // ============================

  Future<List<Education>> listEducation({
    required String uid,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> q =
    _eduCol(uid).orderBy('order', descending: false).limit(limit);
    if (startAfter != null) q = q.startAfterDocument(startAfter);
    final snap = await q.get();
    return snap.docs
        .map((d) => Education.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>))
        .toList();
  }

  Future<Education?> getEducation({
    required String uid,
    required String eduId,
  }) async {
    final snap = await _eduCol(uid).doc(eduId).get();
    if (!snap.exists) return null;
    return Education.fromFirestore(snap);
  }

  /// Create an education entry; returns new doc id.
  Future<String> addEducation({
    required String uid,
    required Education education,
  }) async {
    final ref = await _eduCol(uid).add({
      ...education.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateEducation({
    required String uid,
    required Education education,
  }) async {
    await _eduCol(uid).doc(education.id).update({
      ...education.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteEducation({
    required String uid,
    required String eduId,
  }) =>
      _eduCol(uid).doc(eduId).delete();

  Future<void> reorderEducation({
    required String uid,
    required List<String> orderedIds,
  }) async {
    final batch = _db.batch();
    for (int i = 0; i < orderedIds.length; i++) {
      batch.update(_eduCol(uid).doc(orderedIds[i]), {'order': i});
    }
    await batch.commit();
  }

  // ============================
  // Subcollection: experience
  // ============================

  Future<List<Experience>> listExperience({
    required String uid,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> q =
    _expCol(uid).orderBy('order', descending: false).limit(limit);
    if (startAfter != null) q = q.startAfterDocument(startAfter);
    final snap = await q.get();
    return snap.docs
        .map((d) => Experience.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>))
        .toList();
  }

  Future<Experience?> getExperience({
    required String uid,
    required String expId,
  }) async {
    final snap = await _expCol(uid).doc(expId).get();
    if (!snap.exists) return null;
    return Experience.fromFirestore(snap);
  }

  /// Create an experience entry; returns new doc id.
  Future<String> addExperience({
    required String uid,
    required Experience experience,
  }) async {
    final ref = await _expCol(uid).add({
      ...experience.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateExperience({
    required String uid,
    required Experience experience,
  }) async {
    await _expCol(uid).doc(experience.id).update({
      ...experience.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteExperience({
    required String uid,
    required String expId,
  }) =>
      _expCol(uid).doc(expId).delete();

  Future<void> reorderExperience({
    required String uid,
    required List<String> orderedIds,
  }) async {
    final batch = _db.batch();
    for (int i = 0; i < orderedIds.length; i++) {
      batch.update(_expCol(uid).doc(orderedIds[i]), {'order': i});
    }
    await batch.commit();
  }

  // ============================
  // Convenience: Load all subcollections (for overview screen)
  // ============================

  /// Load all subcollections in parallel (useful for overview page).
  Future<UserProfile?> getUserWithSubcollections(String uid) async {
    final user = await getUser(uid);
    if (user == null) return null;

    final results = await Future.wait([
      listSkills(uid: uid, limit: 200),
      listEducation(uid: uid, limit: 100),
      listExperience(uid: uid, limit: 100),
    ]);

    return user.copyWith(
      skills: results[0] as List<Skill>,
      education: results[1] as List<Education>,
      experience: results[2] as List<Experience>,
    );
  }
}
