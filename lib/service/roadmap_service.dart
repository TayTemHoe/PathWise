// lib/service/roadmap_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:path_wise/model/careerroadmap_model.dart';

/// Service for managing Career Roadmap, Skill Gap, and Learning Resources in Firestore
class RoadmapService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== CAREER ROADMAP OPERATIONS ====================

  /// Get a career roadmap by job title
  Future<Map<String, dynamic>?> getCareerRoadmapByJobTitle(String uid, String jobTitle) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('careerroadmap')
          .where('jobTitle', isEqualTo: jobTitle)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final roadmapData = CareerRoadmap.fromMap(doc.data());

      return {
        'id': doc.id,
        'roadmap': roadmapData,
      };
    } catch (e) {
      debugPrint('❌ Error fetching career roadmap by job title: $e');
      rethrow;
    }
  }

  /// Get a career roadmap by ID
  Future<CareerRoadmap?> getCareerRoadmap(String uid, String roadmapId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('careerroadmap')
          .doc(roadmapId)
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return CareerRoadmap.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('❌ Error fetching career roadmap: $e');
      rethrow;
    }
  }

  /// Get all career roadmaps for a user
  Future<List<Map<String, dynamic>>> getAllCareerRoadmaps(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('careerroadmap')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID to data
        return data;
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching all career roadmaps: $e');
      rethrow;
    }
  }

  /// Stream career roadmap in real-time
  Stream<CareerRoadmap?> streamCareerRoadmap(String uid, String roadmapId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('careerroadmap')
        .doc(roadmapId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return CareerRoadmap.fromMap(snapshot.data()!);
    });
  }

  /// Delete a career roadmap
  Future<void> deleteCareerRoadmap(String uid, String roadmapId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('careerroadmap')
          .doc(roadmapId)
          .delete();

      debugPrint('🗑️ Deleted career roadmap: $roadmapId');
    } catch (e) {
      debugPrint('❌ Error deleting career roadmap: $e');
      rethrow;
    }
  }

  // ==================== SKILL GAP OPERATIONS ====================

  /// Get a skill gap by ID
  Future<SkillGap?> getSkillGap(String uid, String skillGapId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('skillgap')
          .doc(skillGapId)
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return SkillGap.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('❌ Error fetching skill gap: $e');
      rethrow;
    }
  }

  /// Get skill gap by career roadmap ID
  Future<SkillGap?> getSkillGapByRoadmapId(String uid, String roadmapId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('skillgap')
          .where('careerRoadmapId', isEqualTo: roadmapId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return SkillGap.fromMap(snapshot.docs.first.data());
    } catch (e) {
      debugPrint('❌ Error fetching skill gap by roadmap ID: $e');
      rethrow;
    }
  }

  /// Get all skill gaps for a user
  Future<List<Map<String, dynamic>>> getAllSkillGaps(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('skillgap')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching all skill gaps: $e');
      rethrow;
    }
  }

  /// Stream skill gap in real-time
  Stream<SkillGap?> streamSkillGap(String uid, String skillGapId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('skillgap')
        .doc(skillGapId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return SkillGap.fromMap(snapshot.data()!);
    });
  }

  /// Delete a skill gap
  Future<void> deleteSkillGap(String uid, String skillGapId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('skillgap')
          .doc(skillGapId)
          .delete();

      debugPrint('🗑️ Deleted skill gap: $skillGapId');
    } catch (e) {
      debugPrint('❌ Error deleting skill gap: $e');
      rethrow;
    }
  }

  // ==================== LEARNING RESOURCES OPERATIONS ====================

  /// Get latest learning resources for a skill gap
  Future<LearningResource?> getLatestLearningResources(String uid, String skillGapId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('learningresources')
          .where('skillGapId', isEqualTo: skillGapId)
          .where('isLatest', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return LearningResource.fromMap(snapshot.docs.first.data());
    } catch (e) {
      debugPrint('❌ Error fetching latest learning resources: $e');
      rethrow;
    }
  }

  /// Get all learning resources for a skill gap (including history)
  Future<List<Map<String, dynamic>>> getAllLearningResourcesForSkillGap(
      String uid, String skillGapId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('learningresources')
          .where('skillGapId', isEqualTo: skillGapId)
          .orderBy('isLatest', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching all learning resources: $e');
      rethrow;
    }
  }

  /// Get a learning resource by ID
  Future<LearningResource?> getLearningResource(String uid, String resourceId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('learningresources')
          .doc(resourceId)
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return LearningResource.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('❌ Error fetching learning resource: $e');
      rethrow;
    }
  }

  /// Stream latest learning resources in real-time
  Stream<LearningResource?> streamLatestLearningResources(String uid, String skillGapId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('learningresources')
        .where('skillGapId', isEqualTo: skillGapId)
        .where('isLatest', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return LearningResource.fromMap(snapshot.docs.first.data());
    });
  }

  /// Delete a learning resource
  Future<void> deleteLearningResource(String uid, String resourceId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('learningresources')
          .doc(resourceId)
          .delete();

      debugPrint('🗑️ Deleted learning resource: $resourceId');
    } catch (e) {
      debugPrint('❌ Error deleting learning resource: $e');
      rethrow;
    }
  }

  /// Delete all learning resources for a skill gap
  Future<void> deleteAllLearningResourcesForSkillGap(String uid, String skillGapId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('learningresources')
          .where('skillGapId', isEqualTo: skillGapId)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      debugPrint('🗑️ Deleted all learning resources for skill gap: $skillGapId');
    } catch (e) {
      debugPrint('❌ Error deleting all learning resources: $e');
      rethrow;
    }
  }

  // ==================== COMBINED OPERATIONS ====================

  /// Delete complete roadmap with associated skill gaps and learning resources
  Future<void> deleteCompleteRoadmap(String uid, String roadmapId) async {
    try {
      // Find associated skill gap
      final skillGapSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('skillgap')
          .where('careerRoadmapId', isEqualTo: roadmapId)
          .get();

      // Delete associated learning resources and skill gaps
      for (var skillGapDoc in skillGapSnapshot.docs) {
        await deleteAllLearningResourcesForSkillGap(uid, skillGapDoc.id);
        await deleteSkillGap(uid, skillGapDoc.id);
      }

      // Delete the roadmap
      await deleteCareerRoadmap(uid, roadmapId);

      debugPrint('🗑️ Deleted complete roadmap and associated data: $roadmapId');
    } catch (e) {
      debugPrint('❌ Error deleting complete roadmap: $e');
      rethrow;
    }
  }

  /// Get complete roadmap data (roadmap + skill gap + learning resources)
  Future<Map<String, dynamic>?> getCompleteRoadmapData(String uid, String roadmapId) async {
    try {
      final roadmap = await getCareerRoadmap(uid, roadmapId);
      if (roadmap == null) return null;

      final skillGap = await getSkillGapByRoadmapId(uid, roadmapId);

      LearningResource? learningResources;
      String? skillGapId;

      if (skillGap != null) {
        // Find skill gap ID
        final skillGapSnapshot = await _firestore
            .collection('users')
            .doc(uid)
            .collection('skillgap')
            .where('careerRoadmapId', isEqualTo: roadmapId)
            .limit(1)
            .get();

        if (skillGapSnapshot.docs.isNotEmpty) {
          skillGapId = skillGapSnapshot.docs.first.id;
          learningResources = await getLatestLearningResources(uid, skillGapId);
        }
      }

      return {
        'roadmapId': roadmapId,
        'roadmap': roadmap,
        'skillGapId': skillGapId,
        'skillGap': skillGap,
        'learningResources': learningResources,
      };
    } catch (e) {
      debugPrint('❌ Error fetching complete roadmap data: $e');
      rethrow;
    }
  }

  /// Get roadmap summary for a user (all roadmaps with basic info)
  Future<List<Map<String, dynamic>>> getRoadmapSummary(String uid) async {
    try {
      final roadmaps = await getAllCareerRoadmaps(uid);

      List<Map<String, dynamic>> summaries = [];

      for (var roadmapData in roadmaps) {
        final roadmapId = roadmapData['id'];
        final roadmap = CareerRoadmap.fromMap(roadmapData);

        // Get skill gap count
        final skillGap = await getSkillGapByRoadmapId(uid, roadmapId);

        summaries.add({
          'roadmapId': roadmapId,
          'jobTitle': roadmap.jobTitle,
          'stageCount': roadmap.roadmap.length,
          'skillGapCount': skillGap?.skillgaps.length ?? 0,
          'hasLearningResources': false, // You can add logic to check this
        });
      }

      return summaries;
    } catch (e) {
      debugPrint('❌ Error fetching roadmap summary: $e');
      rethrow;
    }
  }
}