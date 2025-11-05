// lib/repository/program_detail_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../model/branch.dart';
import '../model/program.dart';
import '../model/program_admission.dart';
import '../model/university.dart';
import '../services/firebase_service.dart';

class ProgramDetailRepository {
  final FirebaseService _firebaseService;

  // Local caching
  static final Map<String, ProgramModel> _programCache = {};
  static final Map<String, UniversityModel> _universityCache = {};
  static final Map<String, BranchModel> _branchCache = {};
  static final Map<String, List<ProgramAdmissionModel>> _admissionCache = {};

  ProgramDetailRepository(this._firebaseService);

  /// Get program details
  Future<ProgramModel?> getProgramDetails(String programId) async {
    // Check cache
    if (_programCache.containsKey(programId)) {
      debugPrint('📦 Cache HIT: Program $programId');
      return _programCache[programId];
    }

    try {
      debugPrint('🔥 Fetching program $programId...');

      DocumentSnapshot doc;
      try {
        doc = await FirebaseFirestore.instance
            .collection('programs')
            .doc(programId)
            .get(const GetOptions(source: Source.cache));

        if (!doc.exists) throw Exception('No cache');
      } catch (e) {
        doc = await FirebaseFirestore.instance
            .collection('programs')
            .doc(programId)
            .get(const GetOptions(source: Source.server));
      }

      if (doc.exists && doc.data() != null) {
        final program = ProgramModel.fromJson(doc.data() as Map<String, dynamic>);
        _programCache[programId] = program;
        return program;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting program: $e');
      return null;
    }
  }

  /// Get university for program
  Future<UniversityModel?> getUniversityForProgram(String universityId) async {
    if (_universityCache.containsKey(universityId)) {
      debugPrint('📦 Cache HIT: University $universityId');
      return _universityCache[universityId];
    }

    try {
      final uni = await _firebaseService.getUniversity(universityId);
      if (uni != null) {
        _universityCache[universityId] = uni;
      }
      return uni;
    } catch (e) {
      debugPrint('❌ Error getting university: $e');
      return null;
    }
  }

  /// Get branch for program
  Future<BranchModel?> getBranchForProgram(String branchId, String universityId) async {
    if (_branchCache.containsKey(branchId)) {
      debugPrint('📦 Cache HIT: Branch $branchId');
      return _branchCache[branchId];
    }

    try {
      final branches = await _firebaseService.getBranchesByUniversity(universityId);

      // Cache all branches
      for (var branch in branches) {
        _branchCache[branch.branchId] = branch;
      }

      return _branchCache[branchId];
    } catch (e) {
      debugPrint('❌ Error getting branch: $e');
      return null;
    }
  }

  /// Get admissions for program
  Future<List<ProgramAdmissionModel>> getAdmissionsByProgram(String programId) async {
    if (_admissionCache.containsKey(programId)) {
      debugPrint('📦 Cache HIT: Admissions for $programId');
      return _admissionCache[programId]!;
    }

    try {
      debugPrint('🔥 Fetching admissions for $programId...');

      QuerySnapshot snapshot;
      try {
        snapshot = await FirebaseFirestore.instance
            .collection('prog_admissions')
            .where('program_id', isEqualTo: programId)
            .get(const GetOptions(source: Source.cache));

        if (snapshot.docs.isEmpty) throw Exception('No cache');
      } catch (e) {
        snapshot = await FirebaseFirestore.instance
            .collection('prog_admissions')
            .where('program_id', isEqualTo: programId)
            .get(const GetOptions(source: Source.server));
      }

      final admissions = snapshot.docs
          .map((doc) {
        try {
          return ProgramAdmissionModel.fromJson(doc.data() as Map<String, dynamic>);
        } catch (e) {
          debugPrint('⚠️ Error parsing admission: $e');
          return null;
        }
      })
          .whereType<ProgramAdmissionModel>()
          .toList();

      _admissionCache[programId] = admissions;
      return admissions;
    } catch (e) {
      debugPrint('❌ Error getting admissions: $e');
      return [];
    }
  }

  /// Get related programs by study level
  Future<Map<String, List<ProgramModel>>> getRelatedProgramsByLevel(
      String universityId,
      String studyLevel,
      String currentProgramId,
      ) async {
    try {
      debugPrint('🔥 Fetching related programs for level: $studyLevel');

      // Get all branches for this university
      final branches = await _firebaseService.getBranchesByUniversity(universityId);
      final branchIds = branches.map((b) => b.branchId).toList();

      if (branchIds.isEmpty) return {};

      final Map<String, List<ProgramModel>> programsByLevel = {};
      final allPrograms = <ProgramModel>[];

      // Fetch programs in batches
      for (int i = 0; i < branchIds.length; i += 10) {
        final batch = branchIds.skip(i).take(10).toList();

        QuerySnapshot snapshot;
        try {
          snapshot = await FirebaseFirestore.instance
              .collection('programs')
              .where('branch_id', whereIn: batch)
              .where('study_level', isEqualTo: studyLevel)
              .limit(50)
              .get(const GetOptions(source: Source.cache));

          if (snapshot.docs.isEmpty) throw Exception('No cache');
        } catch (e) {
          snapshot = await FirebaseFirestore.instance
              .collection('programs')
              .where('branch_id', whereIn: batch)
              .where('study_level', isEqualTo: studyLevel)
              .limit(50)
              .get(const GetOptions(source: Source.server));
        }

        for (var doc in snapshot.docs) {
          try {
            final program = ProgramModel.fromJson(doc.data() as Map<String, dynamic>);

            // Exclude current program
            if (program.programId != currentProgramId) {
              allPrograms.add(program);
            }
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

      debugPrint('✅ Found ${allPrograms.length} related programs');
      return programsByLevel;
    } catch (e) {
      debugPrint('❌ Error getting related programs: $e');
      return {};
    }
  }

  /// Clear caches
  static void clearCaches() {
    _programCache.clear();
    _universityCache.clear();
    _branchCache.clear();
    _admissionCache.clear();
    debugPrint('🧹 Program detail repository caches cleared');
  }
}