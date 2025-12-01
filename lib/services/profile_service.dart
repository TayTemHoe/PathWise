import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_wise/model/user_profile.dart';

class ProfileService {
  ProfileService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  // =============================
  // Core refs
  // =============================
  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _skillsCol(String uid) =>
      _userDoc(uid).collection('skills');

  CollectionReference<Map<String, dynamic>> _educationCol(String uid) =>
      _userDoc(uid).collection('education');

  CollectionReference<Map<String, dynamic>> _experienceCol(String uid) =>
      _userDoc(uid).collection('experience');

  // =============================
  // Helpers
  // =============================

  /// Timestamp with date-only (00:00:00) in local time.
  Timestamp _dateOnly([DateTime? d]) {
    final now = d ?? DateTime.now();
    final dateOnly = DateTime(now.year, now.month, now.day);
    return Timestamp.fromDate(dateOnly);
  }

  /// Generate next ID with prefix e.g. SK0001, ED0001, EX0001
  Future<String> _nextId(CollectionReference col, String prefix) async {
    final snap = await col.get();
    int maxNum = 0;
    for (final d in snap.docs) {
      final id = d.id; // expecting like SK0001
      if (id.startsWith(prefix)) {
        final tail = id.substring(prefix.length);
        final n = int.tryParse(tail) ?? 0;
        if (n > maxNum) maxNum = n;
      }
    }
    final next = maxNum + 1;
    return '$prefix${next.toString().padLeft(4, '0')}';
  }

  // =============================
  // Root user
  // =============================

  Future<UserProfile?> getUser(String uid) async {
    try {
      final doc = await _userDoc(uid).get();
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
    } catch (e, st) {
      print('[services] getUser error: $e\n$st');
      rethrow;
    }
  }

  Future<UserProfile?> getUserWithSubcollections(String uid) async {
    try {
      final doc = await _userDoc(uid).get();
      if (!doc.exists) return null;

      final root = UserProfile.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);

      final results = await Future.wait<List<dynamic>>([
        listSkills(uid: uid),
        listEducation(uid: uid),
        listExperience(uid: uid),
      ]);

      return root.copyWith(
        skills: results[0].cast<Skill>(),
        education: results[1].cast<Education>(),
        experience: results[2].cast<Experience>(),
      );
    } catch (e, st) {
      print('[services] getUserWithSubcollections error: $e\n$st');
      rethrow;
    }
  }

  Future<void> createOrMergeUser(String uid, UserProfile profile) async {
    try {
      final exists = (await _userDoc(uid).get()).exists;
      final nowDate = _dateOnly();
      final data = profile.toMap();

      if (!exists && data['createdAt'] == null) {
        data['createdAt'] = nowDate;
      }
      data['lastUpdated'] = nowDate;

      await _userDoc(uid).set(data, SetOptions(merge: true));
    } catch (e, st) {
      print('[services] createOrMergeUser error: $e\n$st');
      rethrow;
    }
  }

  Future<void> patchRoot(String uid, Map<String, dynamic> patch) async {
    try {
      final m = <String, dynamic>{...patch, 'lastUpdated': _dateOnly()};
      await _userDoc(uid).update(m);
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        await _userDoc(uid).set({'lastUpdated': _dateOnly()}, SetOptions(merge: true));
        if (patch.isNotEmpty) {
          await _userDoc(uid).update(patch);
        }
      } else {
        rethrow;
      }
    } catch (e, st) {
      print('[services] patchRoot error: $e\n$st');
      rethrow;
    }
  }

  Future<void> updatePersonalInfo({
    required String uid,
    String? name,
    String? email,
    String? phone,
    Timestamp? dob,
    String? gender,
    String? city,
    String? state,
    String? country,
    String? profilePictureUrl,
  }) async {
    final p = <String, dynamic>{
      if (name != null) 'personalInfo.name': name,
      if (email != null) 'personalInfo.email': email,
      if (phone != null) 'personalInfo.phone': phone,
      if (dob != null) 'personalInfo.dob': dob,
      if (gender != null) 'personalInfo.gender': gender,
      if (city != null) 'personalInfo.location.city': city,
      if (state != null) 'personalInfo.location.state': state,
      if (country != null) 'personalInfo.location.country': country,
      if (profilePictureUrl != null) 'personalInfo.profilePictureUrl': profilePictureUrl,
    };
    await patchRoot(uid, p);
  }

  Future<void> updatePersonality({
    required String uid,
    String? mbti,
    String? riasec,
  }) async {
    final p = <String, dynamic>{
      if (mbti != null) 'personality.mbti': mbti,
      if (riasec != null) 'personality.riasec': riasec,
      'personality.updatedAt': _dateOnly(),
    };
    await patchRoot(uid, p);
  }

  Future<void> updatePreferences(String uid, Map<String, dynamic> prefs) async {
    await _db.collection('users').doc(uid).update({
      'preferences': prefs,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCompletionPercent(String uid, double value) async {
    await patchRoot(uid, {'completionPercent': value});
  }

  // =============================
  // Storage (profile picture)
  // =============================

  Future<String?> uploadProfilePicture({
    required String uid,
    required File file,
    String? fileExt,
  }) async {
    try {
      final ext = (fileExt ?? 'jpg').toLowerCase();
      final fileName = 'profile_$uid.${DateTime.now().millisecondsSinceEpoch}.$ext';
      final path = '$uid/$fileName';

      // 1. Upload to Supabase Storage
      // Make sure you created a bucket named 'profiles' in Supabase Dashboard
      await Supabase.instance.client.storage
          .from('profiles')
          .upload(
        path,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      // 2. Get Public URL
      final url = Supabase.instance.client.storage
          .from('profiles')
          .getPublicUrl(path);

      // 3. Save URL to Firestore (Your existing logic)
      await updatePersonalInfo(uid: uid, profilePictureUrl: url);

      return url;
    } catch (e, st) {
      print('[services] uploadProfilePicture error: $e\n$st');
      // Rethrow to let viewModel handle the UI error message
      throw Exception('Supabase Upload Failed: $e');
    }
  }

  // =============================
  // Skills, Education, Experience...
  // (Left unchanged as they were correct)
  // =============================

  Future<List<Skill>> listSkills({required String uid, int limit = 100}) async {
    final snap = await _skillsCol(uid).orderBy('order', descending: false).limit(limit).get();
    return snap.docs.map((d) => Skill.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>)).toList();
  }

  Future<Skill> createSkill({required String uid, required Skill skill}) async {
    final id = await _nextId(_skillsCol(uid), 'SK');
    final data = skill.copyWith(id: id, updatedAt: _dateOnly()).toMap();
    await _skillsCol(uid).doc(id).set(data, SetOptions(merge: true));
    final doc = await _skillsCol(uid).doc(id).get();
    return Skill.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
  }

  Future<void> updateSkill({required String uid, required Skill skill}) async {
    await _skillsCol(uid).doc(skill.id).set(skill.copyWith(updatedAt: _dateOnly()).toMap(), SetOptions(merge: true));
  }

  Future<void> deleteSkill({required String uid, required String skillId}) async {
    await _skillsCol(uid).doc(skillId).delete();
  }

  Future<List<Education>> listEducation({required String uid, int limit = 100}) async {
    final snap = await _educationCol(uid).orderBy('order', descending: false).limit(limit).get();
    return snap.docs.map((d) => Education.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>)).toList();
  }

  Future<Education> createEducation({required String uid, required Education education}) async {
    final id = await _nextId(_educationCol(uid), 'ED');
    final data = education.copyWith(id: id, updatedAt: _dateOnly()).toMap();
    await _educationCol(uid).doc(id).set(data, SetOptions(merge: true));
    final doc = await _educationCol(uid).doc(id).get();
    return Education.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
  }

  Future<void> updateEducation({required String uid, required Education education}) async {
    await _educationCol(uid).doc(education.id).set(education.copyWith(updatedAt: _dateOnly()).toMap(), SetOptions(merge: true));
  }

  Future<void> deleteEducation({required String uid, required String eduId}) async {
    await _educationCol(uid).doc(eduId).delete();
  }

  Future<List<Experience>> listExperience({required String uid, int limit = 100}) async {
    final snap = await _experienceCol(uid).orderBy('order', descending: false).limit(limit).get();
    return snap.docs.map((d) => Experience.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>)).toList();
  }

  Future<Experience> createExperience({required String uid, required Experience experience}) async {
    final id = await _nextId(_experienceCol(uid), 'EX');
    final data = experience.copyWith(id: id, updatedAt: _dateOnly()).toMap();
    await _experienceCol(uid).doc(id).set(data, SetOptions(merge: true));
    final doc = await _experienceCol(uid).doc(id).get();
    return Experience.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
  }

  Future<void> updateExperience({required String uid, required Experience experience}) async {
    await _experienceCol(uid).doc(experience.id).set(experience.copyWith(updatedAt: _dateOnly()).toMap(), SetOptions(merge: true));
  }

  Future<void> deleteExperience({required String uid, required String expId}) async {
    await _experienceCol(uid).doc(expId).delete();
  }
}