// lib/repository/university_detail_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../model/branch.dart';
import '../model/program.dart';
import '../model/university.dart';
import '../model/university_admission.dart';
import '../services/firebase_service.dart';

class UniversityDetailRepository {
  final FirebaseService _firebaseService;

  // Local caching
  static final Map<String, UniversityModel> _universityCache = {};
  static final Map<String, List<BranchModel>> _branchesCache = {};
  static final Map<String, List<UniversityAdmissionModel>> _admissionsCache = {};
  static final Map<String, Map<String, List<ProgramModel>>> _programsByLevelCache = {};

  UniversityDetailRepository(this._firebaseService);

  /// Get university details with enhanced data
  Future<UniversityModel?> getUniversityDetails(String universityId) async {
    // Check cache
    if (_universityCache.containsKey(universityId)) {
      debugPrint('📦 Cache HIT: University $universityId');
      return _universityCache[universityId];
    }

    try {
      debugPrint('🔥 Fetching university $universityId...');

      // Try cache first
      DocumentSnapshot doc;
      try {
        doc = await FirebaseFirestore.instance
            .collection('universities')
            .doc(universityId)
            .get(const GetOptions(source: Source.cache));

        if (!doc.exists) throw Exception('No cache');
      } catch (e) {
        doc = await FirebaseFirestore.instance
            .collection('universities')
            .doc(universityId)
            .get(const GetOptions(source: Source.server));
      }

      if (doc.exists && doc.data() != null) {
        final university = UniversityModel.fromJson(doc.data() as Map<String, dynamic>);
        _universityCache[universityId] = university;
        return university;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting university: $e');
      return null;
    }
  }

  /// Get branches for university
  Future<List<BranchModel>> getBranchesByUniversity(String universityId) async {
    if (_branchesCache.containsKey(universityId)) {
      debugPrint('📦 Cache HIT: Branches for $universityId');
      return _branchesCache[universityId]!;
    }

    try {
      debugPrint('🔥 Fetching branches for $universityId...');

      final branches = await _firebaseService.getBranchesByUniversity(universityId);
      _branchesCache[universityId] = branches;

      return branches;
    } catch (e) {
      debugPrint('❌ Error getting branches: $e');
      return [];
    }
  }

  /// Get admissions for university
  Future<List<UniversityAdmissionModel>> getAdmissionsByUniversity(String universityId) async {
    if (_admissionsCache.containsKey(universityId)) {
      debugPrint('📦 Cache HIT: Admissions for $universityId');
      return _admissionsCache[universityId]!;
    }

    try {
      debugPrint('🔥 Fetching admissions for $universityId...');

      QuerySnapshot snapshot;
      try {
        snapshot = await FirebaseFirestore.instance
            .collection('university_admissions')
            .where('university_id', isEqualTo: universityId)
            .get(const GetOptions(source: Source.cache));

        if (snapshot.docs.isEmpty) throw Exception('No cache');
      } catch (e) {
        snapshot = await FirebaseFirestore.instance
            .collection('university_admissions')
            .where('university_id', isEqualTo: universityId)
            .get(const GetOptions(source: Source.server));
      }

      final admissions = snapshot.docs
          .map((doc) {
        try {
          return UniversityAdmissionModel.fromJson(doc.data() as Map<String, dynamic>);
        } catch (e) {
          debugPrint('⚠️ Error parsing admission: $e');
          return null;
        }
      })
          .whereType<UniversityAdmissionModel>()
          .toList();

      _admissionsCache[universityId] = admissions;
      return admissions;
    } catch (e) {
      debugPrint('❌ Error getting admissions: $e');
      return [];
    }
  }

  /// Get programs grouped by study level (optimized for details screen)
  Future<Map<String, List<ProgramModel>>> getProgramsByStudyLevel(String universityId) async {
    if (_programsByLevelCache.containsKey(universityId)) {
      debugPrint('📦 Cache HIT: Programs by level for $universityId');
      return _programsByLevelCache[universityId]!;
    }

    try {
      debugPrint('🔥 Fetching programs by level for $universityId...');

      // Get branches first (limited to first 3 for performance)
      final branches = await getBranchesByUniversity(universityId);
      final branchIds = branches.take(3).map((b) => b.branchId).toList();

      if (branchIds.isEmpty) return {};

      final Map<String, List<ProgramModel>> programsByLevel = {};
      final allPrograms = <ProgramModel>[];

      // Fetch programs in batches (Firestore 'in' limit is 10)
      for (int i = 0; i < branchIds.length; i += 10) {
        final batch = branchIds.skip(i).take(10).toList();

        QuerySnapshot snapshot;
        try {
          snapshot = await FirebaseFirestore.instance
              .collection('programs')
              .where('branch_id', whereIn: batch)
              .limit(100) // Limit per branch for performance
              .get(const GetOptions(source: Source.cache));

          if (snapshot.docs.isEmpty) throw Exception('No cache');
        } catch (e) {
          snapshot = await FirebaseFirestore.instance
              .collection('programs')
              .where('branch_id', whereIn: batch)
              .limit(100)
              .get(const GetOptions(source: Source.server));
        }

        for (var doc in snapshot.docs) {
          try {
            final program = ProgramModel.fromJson(doc.data() as Map<String, dynamic>);
            allPrograms.add(program);
          } catch (e) {
            debugPrint('⚠️ Error parsing program: $e');
          }
        }
      }

      // Group by study level
      for (var program in allPrograms) {
        final level = program.studyLevel ?? 'Other';
        if (!programsByLevel.containsKey(level)) {
          programsByLevel[level] = [];
        }
        programsByLevel[level]!.add(program);
      }

      _programsByLevelCache[universityId] = programsByLevel;
      debugPrint('✅ Found ${allPrograms.length} programs in ${programsByLevel.length} levels');

      return programsByLevel;
    } catch (e) {
      debugPrint('❌ Error getting programs by level: $e');
      return {};
    }
  }

  /// Get program count for university (efficient count query)
  Future<int> getProgramCount(String universityId) async {
    try {
      // Get branches first
      final branches = await getBranchesByUniversity(universityId);
      final branchIds = branches.map((b) => b.branchId).toList();

      if (branchIds.isEmpty) return 0;

      int totalCount = 0;

      // Count programs in batches
      for (int i = 0; i < branchIds.length; i += 10) {
        final batch = branchIds.skip(i).take(10).toList();

        final snapshot = await FirebaseFirestore.instance
            .collection('programs')
            .where('branch_id', whereIn: batch)
            .count()
            .get();

        totalCount += snapshot.count ?? 0;
      }

      return totalCount;
    } catch (e) {
      debugPrint('❌ Error getting program count: $e');
      return 0;
    }
  }

  /// Get complete university details with all related data
  Future<UniversityModel?> getCompleteUniversityDetails(String universityId) async {
    try {
      // Load university
      final university = await getUniversityDetails(universityId);
      if (university == null) {
        throw Exception('University not found');
      }

      // Load branches
      final branches = await getBranchesByUniversity(universityId);

      // Get program count
      final programCount = await getProgramCount(universityId);

      // Return enhanced university model
      return UniversityModel(
        universityId: university.universityId,
        universityName: university.universityName,
        universityLogo: university.universityLogo,
        minRanking: university.minRanking,
        maxRanking: university.maxRanking,
        universityUrl: university.universityUrl,
        uniDescription: university.uniDescription,
        domesticTuitionFee: university.domesticTuitionFee,
        internationalTuitionFee: university.internationalTuitionFee,
        totalStudents: university.totalStudents,
        internationalStudents: university.internationalStudents,
        totalFacultyStaff: university.totalFacultyStaff,
        branches: branches,
        programCount: programCount,
      );
    } catch (e) {
      debugPrint('❌ Error getting complete details: $e');
      throw Exception('Failed to load university details: $e');
    }
  }

  /// Clear all caches
  static void clearCaches() {
    _universityCache.clear();
    _branchesCache.clear();
    _admissionsCache.clear();
    _programsByLevelCache.clear();
    debugPrint('🧹 University detail repository caches cleared');
  }

  /// Clear cache for specific university
  static void clearUniversityCache(String universityId) {
    _universityCache.remove(universityId);
    _branchesCache.remove(universityId);
    _admissionsCache.remove(universityId);
    _programsByLevelCache.remove(universityId);
    debugPrint('🧹 Cache cleared for university: $universityId');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'universityCacheSize': _universityCache.length,
      'branchesCacheSize': _branchesCache.length,
      'admissionsCacheSize': _admissionsCache.length,
      'programsByLevelCacheSize': _programsByLevelCache.length,
    };
  }
}