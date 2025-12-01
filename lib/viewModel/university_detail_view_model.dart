// lib/viewModel/university_detail_view_model_v2.dart
import 'package:flutter/material.dart';
import '../model/branch.dart';
import '../model/program.dart';
import '../model/university.dart';
import '../model/university_admission.dart';
import '../repository/university_detail_repository.dart';

class UniversityDetailViewModel extends ChangeNotifier {
  final UniversityDetailRepository _repository = UniversityDetailRepository();

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
      debugPrint('📥 Loading university details for $universityId...');

      // Load all data concurrently
      final results = await Future.wait([
        _repository.getCompleteUniversityDetails(universityId),
        _repository.getBranchesByUniversity(universityId),
        _repository.getProgramsByStudyLevel(universityId),
        _repository.getAdmissionsByUniversity(universityId),
      ]);

      _university = results[0] as UniversityModel?;
      _branches = results[1] as List<BranchModel>;
      _programsByLevel = results[2] as Map<String, List<ProgramModel>>;
      _admissions = results[3] as List<UniversityAdmissionModel>;

      if (_university == null) {
        throw Exception('University not found');
      }

      _error = null;
      debugPrint('✅ University details loaded successfully');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error loading university details: $e');
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
    _repository.clearCache();
    notifyListeners();
  }

  @override
  void dispose() {
    clearUniversityData();
    super.dispose();
  }
}