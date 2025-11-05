// lib/viewModel/program_detail_view_model.dart
import 'package:flutter/material.dart';
import '../model/branch.dart';
import '../model/program.dart';
import '../model/program_admission.dart';
import '../model/university.dart';
import '../repository/program_detail_repository.dart';
import '../services/firebase_service.dart';

class ProgramDetailViewModel extends ChangeNotifier {
  late final ProgramDetailRepository _repository;

  ProgramDetailViewModel() {
    final firebaseService = FirebaseService();
    _repository = ProgramDetailRepository(firebaseService);
  }

  // For testing with dependency injection
  ProgramDetailViewModel.withRepository(ProgramDetailRepository repository) {
    _repository = repository;
  }

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
    notifyListeners();

    try {
      // Load program details
      _program = await _repository.getProgramDetails(programId);

      if (_program == null) {
        throw Exception('Program not found');
      }

      // Load university
      _university = await _repository.getUniversityForProgram(_program!.universityId);

      // Load branch
      _branch = await _repository.getBranchForProgram(
        _program!.branchId,
        _program!.universityId,
      );

      // Load admissions
      _admissions = await _repository.getAdmissionsByProgram(_program!.programId);

      // Load related programs by study level
      if (_program!.studyLevel != null) {
        _relatedProgramsByLevel = await _repository.getRelatedProgramsByLevel(
          _program!.universityId,
          _program!.studyLevel!,
          _program!.programId, // Exclude current program
        );
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading program details: $e');
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
    notifyListeners();
  }

  @override
  void dispose() {
    clearProgramData();
    super.dispose();
  }
}