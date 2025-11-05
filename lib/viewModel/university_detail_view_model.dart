// lib/viewModel/university_detail_view_model.dart
import 'package:flutter/material.dart';
import 'package:path_wise/services/firebase_service.dart';
import '../model/branch.dart';
import '../model/program.dart';
import '../model/university.dart';
import '../model/university_admission.dart';
import '../repository/university_detail_repository.dart';

class UniversityDetailViewModel extends ChangeNotifier {
  late final UniversityDetailRepository _repository;

  UniversityDetailViewModel() {
    final firebaseService = FirebaseService();
    _repository = UniversityDetailRepository(firebaseService);
  }

  // For testing with dependency injection
  UniversityDetailViewModel.withRepository(UniversityDetailRepository repository) {
    _repository = repository;
  }

  UniversityModel? _university;
  List<BranchModel> _branches = [];
  List<UniversityAdmissionModel> _admissions = [];
  Map<String, List<ProgramModel>> _programsByLevel = {};
  bool _isLoading = false;
  String? _error;
  final Set<String> _expandedLevels = {};

  // Getters
  UniversityModel? get university => _university;
  List<BranchModel> get branches => _branches;
  List<UniversityAdmissionModel> get admissions => _admissions;
  Map<String, List<ProgramModel>> get programsByLevel => _programsByLevel;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUniversityDetails(String universityId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load complete university details
      _university = await _repository.getCompleteUniversityDetails(universityId);

      // Load branches (already cached from getCompleteUniversityDetails)
      _branches = await _repository.getBranchesByUniversity(universityId);

      // Load programs grouped by level
      _programsByLevel = await _repository.getProgramsByStudyLevel(universityId);

      // Load admissions
      _admissions = await _repository.getAdmissionsByUniversity(universityId);

      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading university details: $e');
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

  void clearUniversityData() {
    _university = null;
    _branches = [];
    _admissions = [];
    _programsByLevel = {};
    _expandedLevels.clear();
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    clearUniversityData();
    super.dispose();
  }
}