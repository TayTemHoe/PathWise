import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_wise/model/ai_match_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
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

  Future<UserModel?> getUser(String uid) async {
    try {
      debugPrint('🔍 ProfileService: Getting user document for uid=$uid');
      final doc = await _userDoc(uid).get();
      if (!doc.exists) {
        debugPrint('⚠️ ProfileService: User document does not exist');
        return null;
      }
      debugPrint('✅ ProfileService: User document found');
      return UserModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
    } catch (e, st) {
      debugPrint('❌ ProfileService: getUser error: $e');
      debugPrint('Stack trace: $st');
      rethrow;
    }
  }

  Future<UserModel?> getUserWithSubcollections(String uid) async {
    try {
      debugPrint('🔍 ProfileService: Getting user with subcollections for uid=$uid');

      final doc = await _userDoc(uid).get();
      if (!doc.exists) {
        debugPrint('⚠️ ProfileService: User document does not exist');
        return null;
      }

      debugPrint('✅ ProfileService: User document found, loading subcollections...');
      final root = UserModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);

      // Load subcollections with better error handling
      final results = await Future.wait<List<dynamic>>([
        listSkills(uid: uid).catchError((e) {
          debugPrint('❌ Error loading skills: $e');
          return <Skill>[];
        }),
        listEducation(uid: uid).catchError((e) {
          debugPrint('❌ Error loading education: $e');
          return <AcademicRecord>[];
        }),
        listExperience(uid: uid).catchError((e) {
          debugPrint('❌ Error loading experience: $e');
          return <Experience>[];
        }),
      ]);

      final skills = results[0].cast<Skill>();
      final education = results[1].cast<AcademicRecord>();
      final experience = results[2].cast<Experience>();

      debugPrint('📊 ProfileService: Loaded Skills=${skills.length}, Education=${education.length}, Experience=${experience.length}');

      if (skills.isNotEmpty) {
        for (var skill in skills) {
          debugPrint('  📌 Skill: ${skill.name}, Category: "${skill.category}", Level: ${skill.level}');
        }
      } else {
        debugPrint('  ⚠️ No skills found in subcollection');
      }

      return root.copyWith(
        skills: skills,
        education: education,
        experience: experience,
      );
    } catch (e, st) {
      debugPrint('❌ ProfileService: getUserWithSubcollections error: $e');
      debugPrint('Stack trace: $st');
      rethrow;
    }
  }

  Future<void> createOrMergeUser(String uid, UserModel profile) async {
    try {
      debugPrint('🔧 ProfileService: Creating/merging user uid=$uid');
      final exists = (await _userDoc(uid).get()).exists;
      final nowDate = _dateOnly();
      final data = profile.toMap();

      if (!exists && data['createdAt'] == null) {
        data['createdAt'] = nowDate;
      }
      data['lastUpdated'] = nowDate;

      await _userDoc(uid).set(data, SetOptions(merge: true));
      debugPrint('✅ ProfileService: User created/merged successfully');
    } catch (e, st) {
      debugPrint('❌ ProfileService: createOrMergeUser error: $e');
      debugPrint('Stack trace: $st');
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
      debugPrint('❌ ProfileService: patchRoot error: $e');
      debugPrint('Stack trace: $st');
      rethrow;
    }
  }

  Future<void> updatePersonalInfo({
    required String uid,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    Timestamp? dob,
    String? city,
    String? state,
    String? country,
    String? profilePictureUrl,
    String? zipCode,
    String? addressLine1,
    String? addressLine2,
  }) async {
    final p = <String, dynamic>{
      if (firstName!= null) 'first_name': firstName,
      if (lastName!= null) 'last_name': lastName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (dob != null) 'dob': dob,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      if (profilePictureUrl != null) 'personalInfo.profilePictureUrl': profilePictureUrl,
      if (zipCode != null) 'zip_code': zipCode,
      if (addressLine1 != null) 'address_line1': addressLine1,
      if (addressLine2 != null) 'address_line2': addressLine2,
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

      await Supabase.instance.client.storage
          .from('profiles')
          .upload(
        path,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      final url = Supabase.instance.client.storage
          .from('profiles')
          .getPublicUrl(path);

      await updatePersonalInfo(uid: uid, profilePictureUrl: url);

      return url;
    } catch (e, st) {
      debugPrint('❌ ProfileService: uploadProfilePicture error: $e');
      debugPrint('Stack trace: $st');
      throw Exception('Supabase Upload Failed: $e');
    }
  }

  // =============================
  // Skills CRUD
  // =============================

  Future<List<Skill>> listSkills({required String uid, int limit = 100}) async {
    try {
      debugPrint('🔍 ProfileService: Listing skills for uid=$uid');

      // ✅ FIXED: Get ALL documents without ordering first
      // Then sort in-memory to avoid Firestore index issues
      final snap = await _skillsCol(uid).limit(limit).get();

      debugPrint('📊 ProfileService: Found ${snap.docs.length} skill documents');

      if (snap.docs.isEmpty) {
        debugPrint('⚠️ ProfileService: No skills found. Check Firestore path: users/$uid/skills/');
        return [];
      }

      final skills = <Skill>[];
      for (var doc in snap.docs) {
        try {
          debugPrint('  🔍 Processing doc: ${doc.id}');
          debugPrint('  📄 Doc data: ${doc.data()}');

          final skill = Skill.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
          debugPrint('  ✅ Parsed skill: ${skill.name}, Category: "${skill.category}", Order: ${skill.order}');
          skills.add(skill);
        } catch (e) {
          debugPrint('  ❌ Error parsing skill doc ${doc.id}: $e');
        }
      }

      // ✅ Sort in-memory by order (handle nulls)
      skills.sort((a, b) {
        final orderA = a.order ?? 9999;
        final orderB = b.order ?? 9999;
        return orderA.compareTo(orderB);
      });

      debugPrint('✅ ProfileService: Returning ${skills.length} skills (sorted)');
      return skills;
    } catch (e, st) {
      debugPrint('❌ ProfileService: listSkills error: $e');
      debugPrint('Stack trace: $st');
      rethrow;
    }
  }

  Future<Skill> createSkill({required String uid, required Skill skill}) async {
    try {
      debugPrint('➕ ProfileService: Creating skill: ${skill.name}, Category: "${skill.category}"');

      final id = await _nextId(_skillsCol(uid), 'SK');
      debugPrint('  Generated ID: $id');

      // ✅ CRITICAL: Ensure order is set for new skills
      final orderValue = skill.order ?? await _getNextSkillOrder(uid);
      debugPrint('  Order value: $orderValue');

      final data = skill.copyWith(
        id: id,
        updatedAt: _dateOnly(),
        order: orderValue,  // ✅ Ensure order is always set
      ).toMap();

      debugPrint('  Skill data to save: $data');

      await _skillsCol(uid).doc(id).set(data, SetOptions(merge: true));

      final doc = await _skillsCol(uid).doc(id).get();
      final created = Skill.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);

      debugPrint('✅ ProfileService: Skill created successfully with ID: ${created.id}, Order: ${created.order}');
      return created;
    } catch (e, st) {
      debugPrint('❌ ProfileService: createSkill error: $e');
      debugPrint('Stack trace: $st');
      rethrow;
    }
  }

  // ✅ NEW: Helper to get next order value
  Future<int> _getNextSkillOrder(String uid) async {
    try {
      final snap = await _skillsCol(uid).get();
      int maxOrder = 0;
      for (var doc in snap.docs) {
        final data = doc.data();
        final order = data['order'] as int?;
        if (order != null && order > maxOrder) {
          maxOrder = order;
        }
      }
      return maxOrder + 1;
    } catch (e) {
      debugPrint('⚠️ Error getting next order: $e, defaulting to 1');
      return 1;
    }
  }

  Future<void> updateSkill({required String uid, required Skill skill}) async {
    try {
      debugPrint('💾 ProfileService: Updating skill: ${skill.name}, ID: ${skill.id}');

      // ✅ Ensure order exists when updating
      final orderValue = skill.order ?? await _getNextSkillOrder(uid);

      final data = skill.copyWith(
        updatedAt: _dateOnly(),
        order: orderValue,  // ✅ Preserve or set order
      ).toMap();

      await _skillsCol(uid).doc(skill.id).set(data, SetOptions(merge: true));

      debugPrint('✅ ProfileService: Skill updated successfully');
    } catch (e, st) {
      debugPrint('❌ ProfileService: updateSkill error: $e');
      debugPrint('Stack trace: $st');
      rethrow;
    }
  }

  Future<void> deleteSkill({required String uid, required String skillId}) async {
    try {
      debugPrint('🗑️ ProfileService: Deleting skill ID: $skillId');
      await _skillsCol(uid).doc(skillId).delete();
      debugPrint('✅ ProfileService: Skill deleted successfully');
    } catch (e, st) {
      debugPrint('❌ ProfileService: deleteSkill error: $e');
      debugPrint('Stack trace: $st');
      rethrow;
    }
  }

  // =============================
  // Education CRUD
  // =============================

  Future<List<AcademicRecord>> listEducation({required String uid, int limit = 100}) async {
    try {
      debugPrint('🔍 ProfileService: Listing education for uid=$uid');

      // ✅ FIXED: Same approach - get all, sort in-memory
      final snap = await _educationCol(uid).limit(limit).get();
      debugPrint('📊 ProfileService: Found ${snap.docs.length} education documents');

      final education = snap.docs
          .map((d) => AcademicRecord.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>))
          .toList();

      // Sort in-memory
      // education.sort((a, b) {
      //   final orderA = a.order ?? 9999;
      //   final orderB = b.order ?? 9999;
      //   return orderA.compareTo(orderB);
      // });

      return education;
    } catch (e, st) {
      debugPrint('❌ ProfileService: listEducation error: $e');
      debugPrint('Stack trace: $st');
      rethrow;
    }
  }

  Future<AcademicRecord> createEducation({
    required String uid,
    required AcademicRecord education
  }) async {
    try {
      debugPrint('➕ ProfileService: Creating education: ${education.institution}');
      final id = await _nextId(_educationCol(uid), 'ED');

      final order = education.order ?? await _getNextEducationOrder(uid);

      // ✅ USE toFirestore() instead of toJson()
      final data = education.copyWith(
        id: id,
        order: order,
        createdAt: _dateOnly(),
        updatedAt: _dateOnly(),
      ).toFirestore();

      debugPrint('📝 Education data to save: $data');

      await _educationCol(uid).doc(id).set(data, SetOptions(merge: true));

      final doc = await _educationCol(uid).doc(id).get();
      final created = AcademicRecord.fromFirestore(
          doc as DocumentSnapshot<Map<String, dynamic>>
      );

      debugPrint('✅ ProfileService: Education created with ID: $id');
      debugPrint('   - Level: ${created.level}');
      debugPrint('   - Program: ${created.programName}');
      debugPrint('   - Major: ${created.major}');
      debugPrint('   - Class of Award: ${created.classOfAward}');

      return created;
    } catch (e, st) {
      debugPrint('❌ ProfileService: createEducation error: $e');
      debugPrint('Stack trace: $st');
      rethrow;
    }
  }

  Future<int> _getNextEducationOrder(String uid) async {
    try {
      final snap = await _educationCol(uid).get();
      int maxOrder = 0;
      for (var doc in snap.docs) {
        final order = doc.data()['order'] as int?;
        if (order != null && order > maxOrder) maxOrder = order;
      }
      return maxOrder + 1;
    } catch (e) {
      return 1;
    }
  }

  Future<void> updateEducation({
    required String uid,
    required AcademicRecord education
  }) async {
    try {
      debugPrint('💾 ProfileService: Updating education: ${education.institution}');

      // ✅ USE toFirestore() instead of toJson()
      final data = education.copyWith(
        updatedAt: _dateOnly(),
      ).toFirestore();

      debugPrint('📝 Education data to update: $data');

      await _educationCol(uid).doc(education.id).set(data, SetOptions(merge: true));

      debugPrint('✅ ProfileService: Education updated successfully');
      debugPrint('   - ID: ${education.id}');
      debugPrint('   - Level: ${education.level}');
      debugPrint('   - Program: ${education.programName}');
      debugPrint('   - Class of Award: ${education.classOfAward}');
    } catch (e, st) {
      debugPrint('❌ ProfileService: updateEducation error: $e');
      debugPrint('Stack trace: $st');
      rethrow;
    }
  }

  Future<void> deleteEducation({required String uid, required String eduId}) async {
    try {
      debugPrint('🗑️ ProfileService: Deleting education ID: $eduId');
      await _educationCol(uid).doc(eduId).delete();
      debugPrint('✅ ProfileService: Education deleted successfully');
    } catch (e, st) {
      debugPrint('❌ ProfileService: deleteEducation error: $e');
      debugPrint('Stack trace: $st');
      rethrow;
    }
  }

  // ✅ NEW: Set education as current and unset others
  Future<void> setCurrentEducation({
    required String uid,
    required String eduId,
  }) async {
    try {
      debugPrint('⭐ Setting education $eduId as current');

      // Get all education records
      final snap = await _educationCol(uid).get();
      final batch = _db.batch();

      for (var doc in snap.docs) {
        final ref = _educationCol(uid).doc(doc.id);
        if (doc.id == eduId) {
          batch.update(ref, {
            'is_current': true,
            'updatedAt': _dateOnly(),
          });
        } else {
          // Unset any other record that might be marked as current
          batch.update(ref, {
            'is_current': false,
            'updatedAt': _dateOnly(),
          });
        }
      }

      await batch.commit();
      debugPrint('✅ ProfileService: Current education updated successfully');
    } catch (e, st) {
      debugPrint('❌ ProfileService: setCurrentEducation error: $e');
      debugPrint('Stack trace: $st');
      rethrow;
    }
  }

  Future<AcademicRecord?> getCurrentEducation({required String uid}) async {
    try {
      debugPrint('🔍 ProfileService: Getting current education for uid=$uid');

      final snap = await _educationCol(uid)
          .where('is_current', isEqualTo: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        debugPrint('⚠️ No current education found');
        return null;
      }

      final current = AcademicRecord.fromFirestore(
          snap.docs.first as DocumentSnapshot<Map<String, dynamic>>
      );

      debugPrint('✅ Found current education: ${current.level}');
      return current;
    } catch (e, st) {
      debugPrint('❌ ProfileService: getCurrentEducation error: $e');
      debugPrint('Stack trace: $st');
      rethrow;
    }
  }
  // =============================
  // Experience CRUD
  // =============================

  Future<List<Experience>> listExperience({required String uid, int limit = 100}) async {
    try {
      debugPrint('🔍 ProfileService: Listing experience for uid=$uid');

      final snap = await _experienceCol(uid).limit(limit).get();
      debugPrint('📊 ProfileService: Found ${snap.docs.length} experience documents');

      final experience = snap.docs
          .map((d) => Experience.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>))
          .toList();

      experience.sort((a, b) {
        final orderA = a.order ?? 9999;
        final orderB = b.order ?? 9999;
        return orderA.compareTo(orderB);
      });

      return experience;
    } catch (e, st) {
      debugPrint('❌ ProfileService: listExperience error: $e');
      debugPrint('Stack trace: $st');
      rethrow;
    }
  }

  Future<Experience> createExperience({required String uid, required Experience experience}) async {
    try {
      debugPrint('➕ ProfileService: Creating experience: ${experience.company}');
      final id = await _nextId(_experienceCol(uid), 'EX');

      final orderValue = experience.order ?? await _getNextExperienceOrder(uid);

      final data = experience.copyWith(
        id: id,
        updatedAt: _dateOnly(),
        order: orderValue,
      ).toMap();

      await _experienceCol(uid).doc(id).set(data, SetOptions(merge: true));
      final doc = await _experienceCol(uid).doc(id).get();
      debugPrint('✅ ProfileService: Experience created with ID: $id');
      return Experience.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
    } catch (e, st) {
      debugPrint('❌ ProfileService: createExperience error: $e');
      debugPrint('Stack trace: $st');
      rethrow;
    }
  }

  Future<int> _getNextExperienceOrder(String uid) async {
    try {
      final snap = await _experienceCol(uid).get();
      int maxOrder = 0;
      for (var doc in snap.docs) {
        final order = doc.data()['order'] as int?;
        if (order != null && order > maxOrder) maxOrder = order;
      }
      return maxOrder + 1;
    } catch (e) {
      return 1;
    }
  }

  Future<void> updateExperience({required String uid, required Experience experience}) async {
    try {
      debugPrint('💾 ProfileService: Updating experience: ${experience.company}, ID: ${experience.id}');
      final orderValue = experience.order ?? await _getNextExperienceOrder(uid);
      final data = experience.copyWith(updatedAt: _dateOnly(), order: orderValue).toMap();
      await _experienceCol(uid).doc(experience.id).set(data, SetOptions(merge: true));
      debugPrint('✅ ProfileService: Experience updated successfully');
    } catch (e, st) {
      debugPrint('❌ ProfileService: updateExperience error: $e');
      debugPrint('Stack trace: $st');
      rethrow;
    }
  }

  Future<void> deleteExperience({required String uid, required String expId}) async {
    try {
      debugPrint('🗑️ ProfileService: Deleting experience ID: $expId');
      await _experienceCol(uid).doc(expId).delete();
      debugPrint('✅ ProfileService: Experience deleted successfully');
    } catch (e, st) {
      debugPrint('❌ ProfileService: deleteExperience error: $e');
      debugPrint('Stack trace: $st');
      rethrow;
    }
  }
}