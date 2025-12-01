// lib/viewModel/program_detail_view_model_v2.dart
import 'package:flutter/material.dart';
import '../model/branch.dart';
import '../model/program.dart';
import '../model/program_admission.dart';
import '../model/university.dart';
import '../repository/program_detail_repository.dart';

class ProgramDetailViewModel extends ChangeNotifier {
  final ProgramDetailRepository _repository = ProgramDetailRepository();

  ProgramModel? _program;
  UniversityModel? _university;
  BranchModel? _branch;
  List<ProgramAdmissionModel> _admissions = [];
  Map<String, List<ProgramModel>> _relatedProgramsByLevel = {};
  bool _isLoading = false;
  String? _error;
  final Set<String> _expandedLevels = {};

  // Getters
  ProgramModel? get program => _program;
  UniversityModel? get university => _university;
  BranchModel? get branch => _branch;
  List<ProgramAdmissionModel> get admissions => _admissions;
  Map<String, List<ProgramModel>> get relatedProgramsByLevel => _relatedProgramsByLevel;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProgramDetails(String programId) async {
    _isLoading = true;
    _error = null;
    clearProgramData();
    notifyListeners();

    try {
      debugPrint('📥 Loading program details for $programId...');

      // Load program first
      _program = await _repository.getProgramDetails(programId);

      if (_program == null) {
        throw Exception('Program not found');
      }

      // Load related data concurrently
      final results = await Future.wait([
        _repository.getUniversityForProgram(_program!.universityId),
        _repository.getBranchForProgram(_program!.branchId),
        _repository.getAdmissionsByProgram(_program!.programId),
        _program!.studyLevel != null
            ? _repository.getRelatedProgramsByLevel(
          _program!.universityId,
          _program!.studyLevel!,
          _program!.programId,
        )
            : Future.value(<String, List<ProgramModel>>{}),
      ]);

      _university = results[0] as UniversityModel?;
      _branch = results[1] as BranchModel?;
      _admissions = results[2] as List<ProgramAdmissionModel>;
      _relatedProgramsByLevel = results[3] as Map<String, List<ProgramModel>>;

      _error = null;
      debugPrint('✅ Program details loaded successfully');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error loading program details: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleLevel(String level) {
    if (_expandedLevels.contains(level)) {
      _expandedLevels.remove(level);
    } else {
      _expandedLevels.add(level);
    }
    notifyListeners();
  }

  bool isLevelExpanded(String level) {
    return _expandedLevels.contains(level);
  }

  void clearProgramData() {
    _program = null;
    _university = null;
    _branch = null;
    _admissions = [];
    _relatedProgramsByLevel = {};
    _expandedLevels.clear();
    _error = null;
    _repository.clearCache();
    notifyListeners();
  }

  @override
  void dispose() {
    clearProgramData();
    super.dispose();
  }
}