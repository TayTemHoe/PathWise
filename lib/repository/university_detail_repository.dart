// lib/repository/university_detail_repository_v2.dart
import 'package:flutter/foundation.dart';
import '../model/branch.dart';
import '../model/program.dart';
import '../model/university.dart';
import '../model/university_admission.dart';
import '../services/local_data_source.dart';

class UniversityDetailRepository {
  final LocalDataSource _localDataSource = LocalDataSource.instance;

  // Memory cache for current detail view
  UniversityModel? _cachedUniversity;
  List<BranchModel>? _cachedBranches;
  Map<String, List<ProgramModel>>? _cachedProgramsByLevel;
  List<UniversityAdmissionModel>? _cachedAdmissions;

  /// Get complete university details
  Future<UniversityModel?> getCompleteUniversityDetails(String universityId) async {
    try {
      debugPrint('📥 Loading complete university details for $universityId...');

      // Load university
      final university = await _localDataSource.getUniversityById(universityId);
      if (university == null) {
        throw Exception('University not found');
      }

      // Cache for quick access
      _cachedUniversity = university;

      debugPrint('✅ University details loaded');
      return university;
    } catch (e) {
      debugPrint('❌ Error loading university details: $e');
      return null;
    }
  }

  /// Get branches for university
  Future<List<BranchModel>> getBranchesByUniversity(String universityId) async {
    // Return cached if available
    if (_cachedBranches != null) {
      debugPrint('📦 Cache HIT: Branches');
      return _cachedBranches!;
    }

    try {
      debugPrint('📥 Loading branches for $universityId...');

      final branches = await _localDataSource.getBranchesByUniversity(universityId);
      _cachedBranches = branches;

      debugPrint('✅ Loaded ${branches.length} branches');
      return branches;
    } catch (e) {
      debugPrint('❌ Error loading branches: $e');
      return [];
    }
  }

  /// Get admissions for university
  Future<List<UniversityAdmissionModel>> getAdmissionsByUniversity(String universityId) async {
    // Return cached if available
    if (_cachedAdmissions != null) {
      debugPrint('📦 Cache HIT: Admissions');
      return _cachedAdmissions!;
    }

    try {
      debugPrint('📥 Loading admissions for $universityId...');

      final admissions = await _localDataSource.getUniversityAdmissions(universityId);
      _cachedAdmissions = admissions;

      debugPrint('✅ Loaded ${admissions.length} admissions');
      return admissions;
    } catch (e) {
      debugPrint('❌ Error loading admissions: $e');
      return [];
    }
  }

  /// Get programs grouped by study level
  Future<Map<String, List<ProgramModel>>> getProgramsByStudyLevel(String universityId) async {
    // Return cached if available
    if (_cachedProgramsByLevel != null) {
      debugPrint('📦 Cache HIT: Programs by level');
      return _cachedProgramsByLevel!;
    }

    try {
      debugPrint('📥 Loading programs by level for $universityId...');

      final programsByLevel = await _localDataSource.getProgramsByStudyLevel(universityId);
      _cachedProgramsByLevel = programsByLevel;

      final totalPrograms = programsByLevel.values.fold(0, (sum, list) => sum + list.length);
      debugPrint('✅ Loaded $totalPrograms programs in ${programsByLevel.length} levels');

      return programsByLevel;
    } catch (e) {
      debugPrint('❌ Error loading programs by level: $e');
      return {};
    }
  }

  /// Clear cache
  void clearCache() {
    _cachedUniversity = null;
    _cachedBranches = null;
    _cachedProgramsByLevel = null;
    _cachedAdmissions = null;
    debugPrint('🧹 University detail cache cleared');
  }
}