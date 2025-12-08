// lib/viewModel/comparison_view_model.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:path_wise/utils/currency_utils.dart';
import '../model/branch.dart';
import '../model/comparison.dart';
import '../model/program.dart';
import '../model/program_admission.dart';
import '../model/university.dart';
import '../model/university_admission.dart';
import '../repository/comparison_repository.dart';
import '../utils/app_color.dart';

class ComparisonViewModel extends ChangeNotifier {
  final ComparisonRepository _repository = ComparisonRepository.instance;
  final Map<String, ProgramModel> _programCache = {};
  final Map<String, UniversityModel> _universityCache = {};
  final Map<String, BranchModel> _branchCache = {};
  final Map<String, List<ProgramAdmissionModel>> _programAdmissionsCache = {};
  final Map<String, List<UniversityAdmissionModel>> _universityAdmissionsCache = {};

  // State
  List<ComparisonItem> _comparisonItems = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _userId;
  bool _isDisposed = false;

  // Getters
  List<ComparisonItem> get comparisonItems => _comparisonItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasItems => _comparisonItems.isNotEmpty;
  int get itemCount => _comparisonItems.length;

  /// Get count for specific type
  int getItemCountByType(ComparisonType type) {
    return _comparisonItems.where((item) => item.type == type).length;
  }

  /// Check if can add more for specific type
  bool canAddMore(ComparisonType type) {
    return getItemCountByType(type) < 3;
  }

  ComparisonType? get currentType =>
      _comparisonItems.isEmpty ? null : _comparisonItems.first.type;

  void _safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }
  // ==================== INITIALIZATION ====================

  /// Initialize view model with user context
  Future<void> initialize([List<ComparisonItem>? initialItems]) async {
    // ✅ FIXED: Check if disposed
    if (_isDisposed) {
      debugPrint('⚠️ ComparisonViewModel is disposed, skipping initialization');
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('⚠️ No user logged in');
        _comparisonItems.clear();
        _safeNotify();
        return;
      }

      _userId = user.uid;

      // Validate user context
      if (_comparisonItems.isNotEmpty) {
        final oldUserId = _comparisonItems.first.id;
        if (!oldUserId.contains(_userId!)) {
          _comparisonItems.clear();
          _repository.clearCache();
          _safeNotify();
        }
      }

      debugPrint('🔧 Initializing ComparisonViewModel for user: $_userId');

      if (initialItems != null && initialItems.isNotEmpty) {
        debugPrint('📋 Received ${initialItems.length} initial items');

        // Load existing items from SQLite first
        final existingItems = await _repository.getComparisonItems(
          userId: _userId!,
          type: null,
        );

        debugPrint('📦 Loaded ${existingItems.length} items from SQLite');

        // Merge items
        final Map<String, ComparisonItem> itemMap = {};

        for (var item in existingItems) {
          itemMap[item.id] = item;
        }

        for (var item in initialItems) {
          itemMap[item.id] = item;
        }

        _comparisonItems = itemMap.values.toList();
        debugPrint('🔄 Merged to ${_comparisonItems.length} total items');

        printCurrentState();
        _safeNotify();

        // ✅ FIXED: Check disposed before loading data
        if (!_isDisposed) {
          await loadComparisonData();
        }
      } else {
        debugPrint('💾 Loading from SQLite');
        await loadComparisonItems();
      }
    } catch (e) {
      debugPrint('❌ Error initializing comparison: $e');
      _errorMessage = 'Failed to initialize comparison';
      _safeNotify();
    }
  }

  /// Load comparison items from SQLite
  Future<void> loadComparisonItems({ComparisonType? type}) async {
    if (_isDisposed || _userId == null) return;

    _isLoading = true;
    _safeNotify();

    try {
      final allItems = await _repository.getComparisonItems(
        userId: _userId!,
        type: null,
      );

      if (_isDisposed) return; // ✅ Check after async

      if (_comparisonItems.isEmpty) {
        _comparisonItems = allItems;
        debugPrint('🔥 Loaded ${_comparisonItems.length} items from SQLite (fresh load)');
      } else {
        final Map<String, ComparisonItem> itemMap = {};

        for (var item in _comparisonItems) {
          itemMap[item.id] = item;
        }

        for (var item in allItems) {
          itemMap[item.id] = item;
        }

        _comparisonItems = itemMap.values.toList();
        debugPrint('🔄 Merged to ${_comparisonItems.length} items');
      }

      if (_comparisonItems.isNotEmpty) {
        final programCount = _comparisonItems
            .where((i) => i.type == ComparisonType.programs)
            .length;
        final uniCount = _comparisonItems
            .where((i) => i.type == ComparisonType.universities)
            .length;
        debugPrint('   - Programs: $programCount, Universities: $uniCount');
      }

      if (_comparisonItems.isNotEmpty && !_isDisposed) {
        await loadComparisonData();
      }

      printCurrentState();
    } catch (e) {
      debugPrint('❌ Error loading comparison items: $e');
      _errorMessage = 'Failed to load comparison items';
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  void printCurrentState() {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📊 COMPARISON STATE:');
    debugPrint('   Total Items: ${_comparisonItems.length}');

    final programs = _comparisonItems
        .where((item) => item.type == ComparisonType.programs)
        .toList();
    final universities = _comparisonItems
        .where((item) => item.type == ComparisonType.universities)
        .toList();

    debugPrint('   Programs: ${programs.length}');
    for (var item in programs) {
      debugPrint('      - ${item.name}');
    }

    debugPrint('   Universities: ${universities.length}');
    for (var item in universities) {
      debugPrint('      - ${item.name}');
    }
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  /// Load all data for comparison (programs or universities)
  Future<void> loadComparisonData() async {
    if (_isDisposed || _comparisonItems.isEmpty || _userId == null) return;

    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final programItems = _comparisonItems
          .where((item) => item.type == ComparisonType.programs)
          .toList();
      final universityItems = _comparisonItems
          .where((item) => item.type == ComparisonType.universities)
          .toList();

      await Future.wait([
        if (programItems.isNotEmpty && !_isDisposed)
          _loadProgramsData(programItems),
        if (universityItems.isNotEmpty && !_isDisposed)
          _loadUniversitiesData(universityItems),
      ]);

      debugPrint('✅ Loaded comparison data successfully');
    } catch (e) {
      debugPrint('❌ Error loading comparison data: $e');
      _errorMessage = 'Failed to load comparison data';
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<void> _loadProgramsData(List<ComparisonItem> programItems) async {
    if (_isDisposed) return;

    for (var item in programItems) {
      if (_isDisposed) break;

      final program = await _repository.getProgramDetails(item.id);
      if (program != null && !_isDisposed) {
        _programCache[item.id] = program;

        final branch = await _repository.getBranchForProgram(program.branchId);
        if (branch != null) _branchCache[program.branchId] = branch;

        final university = await _repository.getUniversityForProgram(program.universityId);
        if (university != null) {
          _universityCache[program.universityId] = university;

          final itemIndex = _comparisonItems.indexWhere((item) => item.id == program.programId);
          if (itemIndex != -1 && !_isDisposed) {
            _comparisonItems[itemIndex] = _comparisonItems[itemIndex].copyWith(
              logoUrl: university.universityLogo,
            );
          }
        }

        final admissions = await _repository.getProgramAdmissions(item.id);
        _programAdmissionsCache[item.id] = admissions;
      }
    }
  }

  Future<void> _loadUniversitiesData(List<ComparisonItem> universityItems) async {
    if (_isDisposed) return;

    for (var item in universityItems) {
      if (_isDisposed) break;

      final university = await _repository.getUniversityDetails(item.id);
      if (university != null && !_isDisposed) {
        _universityCache[item.id] = university;

        final branches = await _repository.getUniversityBranches(item.id);
        for (var branch in branches) {
          if (_isDisposed) break;
          _branchCache[branch.branchId] = branch;
        }

        final admissions = await _repository.getUniversityAdmissions(item.id);
        _universityAdmissionsCache[item.id] = admissions;
      }
    }
  }

  // ==================== MANAGE ITEMS ====================

  /// Add item to comparison
  Future<bool> addItem(ComparisonItem item) async {
    if (_isDisposed || _userId == null) return false;

    if (!canAddMore(item.type)) {
      debugPrint('⚠️ Maximum 3 ${item.type} items allowed');
      _errorMessage = 'Maximum 3 items can be compared at once';
      _safeNotify();
      return false;
    }

    if (_comparisonItems.any((i) => i.id == item.id)) {
      debugPrint('⚠️ Item already in comparison');
      return false;
    }

    if (_comparisonItems.isNotEmpty && _comparisonItems.first.type != item.type) {
      debugPrint('⚠️ Cannot mix programs and universities');
      _errorMessage = 'Cannot mix programs and universities';
      _safeNotify();
      return false;
    }

    final success = await _repository.addToComparison(userId: _userId!, item: item);

    if (success && !_isDisposed) {
      _comparisonItems.add(item);
      _safeNotify();

      if (item.type == ComparisonType.programs) {
        _repository.getProgramDetails(item.id);
      } else {
        _repository.getUniversityDetails(item.id);
      }
    }

    return success;
  }

  /// Remove item from comparison
  Future<void> removeItem(String itemId) async {
    if (_isDisposed || _userId == null) return;

    final success = await _repository.removeFromComparison(
      userId: _userId!,
      itemId: itemId,
    );

    if (success && !_isDisposed) {
      _comparisonItems.removeWhere((item) => item.id == itemId);
      _safeNotify();
      debugPrint('✅ Removed item $itemId from comparison');
    }
  }

  Future<void> clearCurrentType() async {
    if (_isDisposed || _userId == null || _comparisonItems.isEmpty) return;

    final type = _comparisonItems.first.type;
    final count = await _repository.clearComparisonByType(userId: _userId!, type: type);

    if (count > 0 && !_isDisposed) {
      _comparisonItems.clear();
      _safeNotify();
      debugPrint('✅ Cleared $count items from comparison');
    }
  }

  Future<void> clearAll() async {
    if (_isDisposed || _userId == null) return;

    await _repository.clearComparisonByType(userId: _userId!, type: ComparisonType.programs);
    await _repository.clearComparisonByType(userId: _userId!, type: ComparisonType.universities);

    if (!_isDisposed) {
      _comparisonItems.clear();
      _safeNotify();
      debugPrint('✅ Cleared all comparisons');
    }
  }

  Future<bool> isItemInComparison(String itemId) async {
    if (_userId == null) return false;
    return await _repository.isInComparison(userId: _userId!, itemId: itemId);
  }

  // ==================== PROGRAM COMPARISON DATA ====================

  List<ComparisonAttribute> getProgramAttributes() {
    final currencyFormatter = NumberFormat.currency(
      locale: 'ms_MY',
      symbol: 'RM ',
      decimalDigits: 2,
    );

    // FIX: Filter to only program items
    final programItems = _comparisonItems
        .where((item) => item.type == ComparisonType.programs)
        .toList();

    if (programItems.isEmpty) return [];

    final attributes = <ComparisonAttribute>[];

    attributes.add(
      ComparisonAttribute(
        label: 'Program Name',
        tooltip: 'Official name of the academic program',
        values: programItems.map((item) {
          // Changed from _comparisonItems
          final program = _programCache[item.id];
          if (program == null) return 'Loading...';
          return program.programName;
        }).toList(),
      ),
    );

    attributes.add(
      ComparisonAttribute(
        label: 'University Name',
        tooltip: 'University or institution offering the program',
        values: programItems.map((item) {
          // Changed from _comparisonItems
          final program = _programCache[item.id];
          final university = _universityCache[program?.universityId];
          if (program == null || university == null) return 'Loading...';
          return university.universityName;
        }).toList(),
      ),
    );

    // Subject Ranking
    attributes.add(
      ComparisonAttribute(
        label: 'Subject Rank Range',
        tooltip: 'QS World University subject ranking for this field',
        values: programItems.map((item) {
          // Changed
          final program = _programCache[item.id];
          if (program == null || !program.hasSubjectRanking) return 'Unranked';
          return program.formattedSubjectRanking;
        }).toList(),
      ),
    );

    // Study Level
    attributes.add(
      ComparisonAttribute(
        label: 'Study Level',
        tooltip:
            'Academic qualification awarded (e.g., Diploma, Bachelor, Master)',
        values: programItems.map((item) {
          // Changed
          final program = _programCache[item.id];
          if (program == null) return 'Loading...';
          final level = program.studyLevel ?? 'N/A';
          return level;
        }).toList(),
      ),
    );

    attributes.add(
      ComparisonAttribute(
        label: 'Field of Study',
        tooltip: 'Major subject area or academic discipline',
        values: programItems.map((item) {
          // Changed
          final program = _programCache[item.id];
          if (program == null) return 'Loading...';
          final field = program.subjectArea ?? 'N/A';
          return field;
        }).toList(),
      ),
    );

    // Duration
    attributes.add(
      ComparisonAttribute(
        label: 'Duration',
        tooltip: 'Total duration (years) required to complete the program',
        values: programItems.map((item) {
          // Changed
          final program = _programCache[item.id];
          return program?.formattedDuration ?? 'N/A';
        }).toList(),
      ),
    );

    // Learning Mode
    attributes.add(
      ComparisonAttribute(
        label: 'Learning Mode',
        tooltip: 'Mode of study (e.g., On Campus, Blended, Online)',
        values: programItems.map((item) {
          // Changed
          final program = _programCache[item.id];
          return program?.studyMode ?? 'Not Available';
        }).toList(),
      ),
    );

    // Domestic Tuition Fees
    attributes.add(
      ComparisonAttribute(
        label: 'Domestics Tuition Fee',
        tooltip: 'Approximate tuition fees for Malaysian students',
        values: programItems.map((item) {
          // Changed
          final program = _programCache[item.id];
          final branch = _branchCache[program?.branchId];
          if (program == null || branch == null) return 'Loading...';
          final domFee = program.minDomesticTuitionFee;
          if (domFee != null) {
            double doFees = CurrencyUtils.convertToMYR(domFee) ?? 0;
            return currencyFormatter.format(doFees);
          }
          return 'N/A';
        }).toList(),
      ),
    );

    // International Tuition Fees
    attributes.add(
      ComparisonAttribute(
        label: 'International Tuition Fee',
        tooltip: 'Approximate tuition fees for international students',
        values: programItems.map((item) {
          // Changed
          final program = _programCache[item.id];
          final branch = _branchCache[program?.branchId];
          if (program == null || branch == null) return 'Loading...';
          final intlFee = program.minInternationalTuitionFee;
          if (intlFee != null) {
            double inFees = CurrencyUtils.convertToMYR(intlFee) ?? 0;
            return currencyFormatter.format(inFees);
          }
          return 'N/A';
        }).toList(),
      ),
    );

    // Entry Requirements
    attributes.add(
      ComparisonAttribute(
        label: 'Minimum Entry Requirements',
        tooltip:
            'Academic grades, standardized tests, or language proficiency required for admission',
        values: programItems.map((item) {
          // Changed
          final admissions = _programAdmissionsCache[item.id] ?? [];
          if (admissions.isEmpty) return 'Not Available';

          return admissions
              .take(3)
              .map(
                (adm) => '${adm.progAdmissionLabel}: ${adm.progAdmissionValue}',
              )
              .join('\n');
        }).toList(),
      ),
    );

    return attributes;
  }

  // ==================== UNIVERSITY COMPARISON DATA ====================

  List<ComparisonAttribute> getUniversityAttributes() {
    final currencyFormatter = NumberFormat.currency(
      locale: 'ms_MY',
      symbol: 'RM ',
      decimalDigits: 2,
    );

    // FIX: Filter to only university items
    final universityItems = _comparisonItems
        .where((item) => item.type == ComparisonType.universities)
        .toList();

    if (universityItems.isEmpty) return [];

    final attributes = <ComparisonAttribute>[];

    // University Name
    attributes.add(
      ComparisonAttribute(
        label: 'University Name',
        tooltip: 'Official name of the institution',
        values: universityItems.map((item) => item.name).toList(), // Changed
      ),
    );

    // Ranking
    attributes.add(
      ComparisonAttribute(
        label: 'QS Ranking',
        tooltip: 'QS World University Ranking (global ranking range)',
        values: universityItems.map((item) {
          // Changed
          final uni = _universityCache[item.id];
          if (uni == null || uni.minRanking == null) return 'Unranked';
          if (uni.maxRanking == null || uni.minRanking == uni.maxRanking) {
            return '#${uni.minRanking}';
          }
          return '#${uni.minRanking}–${uni.maxRanking}';
        }).toList(),
      ),
    );

    // Location (aggregate branches)
    attributes.add(
      ComparisonAttribute(
        label: 'Location',
        tooltip: 'Countries and cities where the university has branches',
        values: universityItems.map((item) {
          final branches = _branchCache.values
              .where((b) => b.universityId == item.id)
              .toList();

          if (branches.isEmpty) return 'N/A';

          final countries = branches.map((b) => b.country).toSet();
          final cities = branches.map((b) => b.city).toSet();

          if (countries.length == 1) {
            return '${countries.first}\n• ${cities.length} ${cities.length == 1 ? "City" : "Cities"}';
          }
          return '• ${countries.length} Countries\n• ${cities.length} Cities';
        }).toList(),
      ),
    );

    // Tuition Range
    attributes.add(
      ComparisonAttribute(
        label: 'Domestics Tuition Fee',
        tooltip: 'Approximate tuition fees for Malaysian students',
        values: universityItems.map((item) {
          final uni = _universityCache[item.id];
          if (uni == null) return 'Loading...';

          final dom = uni.domesticTuitionFee;

          if (dom != null) {
            double inFees = CurrencyUtils.convertToMYR(dom) ?? 0;
            return currencyFormatter.format(inFees);
          }
          return 'N/A';
        }).toList(),
      ),
    );

    // International Tuition Fees
    attributes.add(
      ComparisonAttribute(
        label: 'International Tuition Fee',
        tooltip: 'Approximate tuition fees for international students',
        values: universityItems.map((item) {
          final uni = _universityCache[item.id];
          if (uni == null) return 'Loading...';

          final intl = uni.internationalTuitionFee;

          if (intl != null) {
            double inFees = CurrencyUtils.convertToMYR(intl) ?? 0;
            return currencyFormatter.format(inFees);
          }
          return 'N/A';
        }).toList(),
      ),
    );

    // Total Students
    attributes.add(
      ComparisonAttribute(
        label: 'Total Students',
        tooltip: 'Total student population, including international students',
        values: universityItems.map((item) {
          final uni = _universityCache[item.id];
          if (uni == null) return 'Loading...';

          final total = uni.totalStudents;

          if (total == null) return 'N/A';

          final totalStr = _formatNumber(total);
          return '$totalStr Students';
        }).toList(),
      ),
    );

    // Admissions
    attributes.add(
      ComparisonAttribute(
        label: 'Admissions Requirements',
        tooltip:
            'Programs admission requirements and type of admission (e.g., Bachelor, Masters)',
        values: universityItems.map((item) {
          final admissions = _universityAdmissionsCache[item.id] ?? [];
          if (admissions.isEmpty) return 'Not Available';

          // Group by type
          final grouped = <String, List<UniversityAdmissionModel>>{};
          for (var adm in admissions) {
            final type = adm.admissionType ?? 'General';
            grouped.putIfAbsent(type, () => []).add(adm);
          }

          // Format output
          final output = <String>[];
          for (var entry in grouped.entries.take(2)) {
            final reqs = entry.value
                .take(2)
                .map((adm) => '${adm.admissionLabel}: ${adm.admissionValue}')
                .join(', ');
            output.add('${entry.key}: $reqs');
          }

          return output.join('\n');
        }).toList(),
      ),
    );

    return attributes;
  }

  List<ComparisonMetric> getUniversityMetrics(String universityId) {
    final uni = _universityCache[universityId];
    if (uni == null) return [];

    final metrics = <ComparisonMetric>[];

    // International Diversity Score
    if (uni.totalStudents != null && uni.internationalStudents != null) {
      final ratio = (uni.internationalStudents! / uni.totalStudents! * 100);
      String category;
      Color color;

      if (ratio < 5) {
        category = 'Low';
        color = Colors.orange;
      } else if (ratio < 20) {
        category = 'Medium';
        color = Colors.blue;
      } else {
        category = 'High';
        color = Colors.green;
      }

      metrics.add(
        ComparisonMetric(
          label: 'International Diversity',
          value: '${ratio.toStringAsFixed(1)}%',
          category: category,
          color: color,
        ),
      );
    }

    // Faculty-to-Student Ratio
    if (uni.totalStudents != null &&
        uni.totalFacultyStaff != null &&
        uni.totalFacultyStaff! > 0) {
      final ratio = (uni.totalStudents! / uni.totalFacultyStaff!)
          .toStringAsFixed(1);
      metrics.add(
        ComparisonMetric(
          label: 'Student-to-Staff Ratio',
          value: '$ratio:1',
          category: null,
          color: AppColors.primary,
        ),
      );
    }

    // Global Footprint
    final branches = _branchCache.values
        .where((b) => b.universityId == universityId)
        .toList();

    if (branches.isNotEmpty) {
      final countries = branches.map((b) => b.country).toSet().length;
      metrics.add(
        ComparisonMetric(
          label: 'Global Footprint',
          value:
              '${branches.length} ${branches.length == 1 ? "campus" : "campuses"}',
          category: '$countries ${countries == 1 ? "country" : "countries"}',
          color: AppColors.secondary,
        ),
      );
    }

    return metrics;
  }

  // ==================== UTILITY ====================

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toString();
  }

  Future<void> refresh() async {
    if (!_isDisposed) {
      await loadComparisonItems();
    }
  }

  void clearForLogout() {
    if (_isDisposed) return;

    _comparisonItems.clear();
    _repository.clearCache();
    _userId = null;
    _safeNotify();
    debugPrint('🧹 Comparison data cleared for logout');
  }

  @override
  void dispose() {
    debugPrint('🗑️ Disposing ComparisonViewModel');
    _isDisposed = true;
    _comparisonItems.clear();
    _programCache.clear();
    _universityCache.clear();
    _branchCache.clear();
    _programAdmissionsCache.clear();
    _universityAdmissionsCache.clear();
    super.dispose();
  }
}
