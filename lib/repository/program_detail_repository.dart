import 'package:flutter/foundation.dart';
import '../model/branch.dart';
import '../model/program.dart';
import '../model/program_admission.dart';
import '../model/university.dart';
import '../services/local_data_source.dart';

class ProgramDetailRepository {
  final LocalDataSource _localDataSource = LocalDataSource.instance;

  // Memory cache for current detail view
  ProgramModel? _cachedProgram;
  UniversityModel? _cachedUniversity;
  BranchModel? _cachedBranch;
  final Map<String, List<ProgramAdmissionModel>> _admissionsCache = {};
  Map<String, List<ProgramModel>>? _cachedRelatedPrograms;

  /// Get program details
  Future<ProgramModel?> getProgramDetails(String programId) async {
    try {
      debugPrint('📥 Loading program details for $programId...');

      final program = await _localDataSource.getProgramById(programId);
      if (program == null) {
        throw Exception('Program not found');
      }

      _cachedProgram = program;

      debugPrint('✅ Program details loaded');
      return program;
    } catch (e) {
      debugPrint('❌ Error loading program details: $e');
      return null;
    }
  }

  /// Get university for program
  Future<UniversityModel?> getUniversityForProgram(String universityId) async {
    if (_cachedUniversity != null && _cachedUniversity!.universityId == universityId) {
      debugPrint('📦 Cache HIT: University');
      return _cachedUniversity;
    }

    try {
      final university = await _localDataSource.getUniversityById(universityId);
      _cachedUniversity = university;
      return university;
    } catch (e) {
      debugPrint('❌ Error loading university: $e');
      return null;
    }
  }

  /// Get branch for program
  Future<BranchModel?> getBranchForProgram(String branchId) async {
    if (_cachedBranch != null && _cachedBranch!.branchId == branchId) {
      debugPrint('📦 Cache HIT: Branch');
      return _cachedBranch;
    }

    try {
      final branch = await _localDataSource.getBranchById(branchId);
      _cachedBranch = branch;
      return branch;
    } catch (e) {
      debugPrint('❌ Error loading branch: $e');
      return null;
    }
  }

  /// Get admissions for program
  Future<List<ProgramAdmissionModel>> getAdmissionsByProgram(String programId) async {
    if (_admissionsCache.containsKey(programId)) {
      debugPrint('📦 Cache HIT for $programId');
      return _admissionsCache[programId]!;
    }

    try {
      debugPrint('📥 Loading admissions for $programId...');

      final admissions = await _localDataSource.getProgramAdmissions(programId);

      // Store in cache
      _admissionsCache[programId] = admissions;

      debugPrint('✅ Loaded ${admissions.length} admissions for $programId');
      return admissions;
    } catch (e) {
      debugPrint('❌ Error loading admissions: $e');
      return [];
    }
  }

  /// Get related programs by level
  Future<Map<String, List<ProgramModel>>> getRelatedProgramsByLevel(
      String universityId,
      String studyLevel,
      String currentProgramId,
      ) async {
    if (_cachedRelatedPrograms != null) {
      debugPrint('📦 Cache HIT: Related programs');
      return _cachedRelatedPrograms!;
    }

    try {
      debugPrint('📥 Loading related programs...');

      final relatedPrograms = await _localDataSource.getRelatedProgramsByLevel(
        universityId,
        studyLevel,
        currentProgramId,
      );

      _cachedRelatedPrograms = relatedPrograms;

      final totalPrograms = relatedPrograms.values.fold(0, (sum, list) => sum + list.length);
      debugPrint('✅ Loaded $totalPrograms related programs');

      return relatedPrograms;
    } catch (e) {
      debugPrint('❌ Error loading related programs: $e');
      return {};
    }
  }

  /// Clear cache
  void clearCache() {
    _cachedProgram = null;
    _cachedUniversity = null;
    _cachedBranch = null;
    _admissionsCache.clear();
    _cachedRelatedPrograms = null;
    debugPrint('🧹 Program detail cache cleared');
  }
}
