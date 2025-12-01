// lib/services/local_data_source.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../model/university.dart';
import '../model/branch.dart';
import '../model/program.dart';
import '../model/university_admission.dart';
import '../model/program_admission.dart';
import '../model/university_filter.dart';
import '../model/program_filter.dart';
import '../utils/currency_utils.dart';
import 'database_helper.dart';

class LocalDataSource {
  static final LocalDataSource instance = LocalDataSource._init();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Map<String, BranchModel> _branchCache = {};
  Timer? _branchCacheTimer;

  LocalDataSource._init();

  // ==================== PROGRAMS ====================

  /// FIXED: Get programs with filters and pagination
  Future<List<ProgramModel>> getPrograms({
    int limit = 10,
    int offset = 0,
    ProgramFilterModel? filter,
  }) async {
    try {
      final whereClause = <String>[];
      final whereArgs = <dynamic>[];

      whereClause.add('is_deleted = 0');

      // // ✅ NEW: Filter by subject ranking if specified
      // if (filter?.topN != null) {
      //   whereClause.add('min_subject_ranking IS NOT NULL');
      //   whereClause.add('min_subject_ranking > 0');
      // }

      // CRITICAL: Apply Malaysian filter if specified
      if (filter?.malaysianBranchIds != null &&
          filter!.malaysianBranchIds!.isNotEmpty) {
        final placeholders = filter.malaysianBranchIds!
            .map((_) => '?')
            .join(',');
        whereClause.add('branch_id IN ($placeholders)');
        whereArgs.addAll(filter.malaysianBranchIds!);
        debugPrint(
          '🇲🇾 Filtering ${filter.malaysianBranchIds!.length} Malaysian branches',
        );
      }

      if (filter?.countries != null && filter!.countries.isNotEmpty) {
        final countryBranchIds = await _getBranchIdsByCountries(
          filter.countries,
        );

        if (countryBranchIds.isNotEmpty) {
          // ✅ FIXED: If Malaysian filter exists, combine intelligently
          if (filter.malaysianBranchIds != null &&
              filter.malaysianBranchIds!.isNotEmpty) {
            // User wants specific countries AND Malaysian branches
            // Check if Malaysia is in the country list
            final wantsMalaysia = filter.countries.any(
                  (c) => c.toLowerCase() == 'malaysia',
            );

            if (wantsMalaysia) {
              // Combine Malaysian branches with other country branches
              final combinedBranches = countryBranchIds.toSet();

              // Remove previous Malaysian filter and use combined set
              whereClause.removeLast();
              whereArgs.removeRange(
                whereArgs.length - filter.malaysianBranchIds!.length,
                whereArgs.length,
              );

              final placeholders = combinedBranches.map((_) => '?').join(',');
              whereClause.add('branch_id IN ($placeholders)');
              whereArgs.addAll(combinedBranches);

              debugPrint(
                '🌍 Combined filter: ${combinedBranches.length} branches (including Malaysia)',
              );
            } else {
              // Replace Malaysian filter with selected countries only
              whereClause.removeLast();
              whereArgs.removeRange(
                whereArgs.length - filter.malaysianBranchIds!.length,
                whereArgs.length,
              );

              final placeholders = countryBranchIds.map((_) => '?').join(',');
              whereClause.add('branch_id IN ($placeholders)');
              whereArgs.addAll(countryBranchIds);

              debugPrint(
                '🌍 Country filter: ${countryBranchIds.length} branches from ${filter.countries.join(", ")}',
              );
            }
          } else {
            // Only country filter (no Malaysian filter)
            final placeholders = countryBranchIds.map((_) => '?').join(',');
            whereClause.add('branch_id IN ($placeholders)');
            whereArgs.addAll(countryBranchIds);
            debugPrint(
              '🌍 Country-only filter: ${countryBranchIds.length} branches',
            );
          }
        } else {
          debugPrint('⚠️ No branches found for selected countries');
          return []; // Early return
        }
      }

      // Search query
      if (filter?.searchQuery != null && filter!.searchQuery!.isNotEmpty) {
        whereClause.add('program_name LIKE ?');
        whereArgs.add('%${filter.searchQuery}%');
      }

      // University IDs filter
      if (filter?.universityIds.isNotEmpty ?? false) {
        final placeholders = filter!.universityIds.map((_) => '?').join(',');
        whereClause.add('university_id IN ($placeholders)');
        whereArgs.addAll(filter.universityIds);
      }

      // Subject area filter
      if (filter?.subjectArea.isNotEmpty ?? false) {
        if (filter!.subjectArea.length == 1) {
          whereClause.add('subject_area = ?');
          whereArgs.add(filter.subjectArea.first);
        } else {
          final placeholders = filter.subjectArea.map((_) => '?').join(',');
          whereClause.add('subject_area IN ($placeholders)');
          whereArgs.addAll(filter.subjectArea);
        }
      }

      // Study modes filter
      if (filter?.studyModes.isNotEmpty ?? false) {
        final placeholders = filter!.studyModes.map((_) => '?').join(',');
        whereClause.add('study_mode IN ($placeholders)');
        whereArgs.addAll(filter.studyModes);
      }

      // Study levels filter
      if (filter?.studyLevels.isNotEmpty ?? false) {
        final placeholders = filter!.studyLevels.map((_) => '?').join(',');
        whereClause.add('study_level IN ($placeholders)');
        whereArgs.addAll(filter.studyLevels);
      }

      // Intake months filter
      if (filter?.intakeMonths.isNotEmpty ?? false) {
        // For JSON array matching, we need to check if any selected month exists in intake_period
        final intakeConditions = filter!.intakeMonths
            .map((month) {
          return 'intake_period LIKE ?';
        })
            .join(' OR ');

        if (intakeConditions.isNotEmpty) {
          whereClause.add('($intakeConditions)');
          for (var month in filter.intakeMonths) {
            whereArgs.add('%"$month"%');
          }
        }
      }

      // Duration filter (convert years to months)
      if (filter?.minDurationYears != null ||
          filter?.maxDurationYears != null) {
        whereClause.add('duration_months IS NOT NULL');

        if (filter!.minDurationYears != null) {
          final minMonths = (filter.minDurationYears! * 12).round();
          whereClause.add('CAST(duration_months AS INTEGER) >= ?');
          whereArgs.add(minMonths);
        }

        if (filter.maxDurationYears != null) {
          final maxMonths = (filter.maxDurationYears! * 12).round();
          whereClause.add('CAST(duration_months AS INTEGER) <= ?');
          whereArgs.add(maxMonths);
        }
      }

      // Tuition fee filter (requires branch lookup for Malaysian vs International)
      if (filter?.minTuitionFeeMYR != null ||
          filter?.maxTuitionFeeMYR != null) {
        // We need to filter by converted fees
        // This is complex - we'll handle it post-query for accuracy
        debugPrint('⚠️ Tuition filter will be applied post-query');
      }

      // Build ORDER BY clause
      String orderBy = _getProgramOrderBy(filter);

      // ✅ NEW: Determine SQL limit based on Top N logic
      int sqlLimit = limit;
      int sqlOffset = offset;

      final bool needsTuitionFiltering = (filter?.minTuitionFeeMYR != null || filter?.maxTuitionFeeMYR != null);
      final bool hasTopN = filter?.topN != null;

      // ✅ STRATEGY: Handle Top N + Tuition Filter combination
      if (hasTopN && needsTuitionFiltering) {
        // Fetch more data to ensure we have enough matches after tuition filtering
        sqlLimit = (filter!.topN! * 5).clamp(100, 1000);
        sqlOffset = 0; // Start from beginning to ensure Top N is respected
      } else if (hasTopN) {
        // Apply Top N limit directly
        final remainingInTopN = filter!.topN! - offset;
        if (remainingInTopN <= 0) {
          debugPrint('🛑 Already fetched all Top ${filter.topN} programs');
          return [];
        }
        sqlLimit = (limit < remainingInTopN) ? limit : remainingInTopN;
      } else if (needsTuitionFiltering) {
        // Only tuition filter - fetch more for post-processing
        sqlLimit = limit * 5;
      }

      // Build final query
      final sql = '''
      SELECT * FROM programs
      WHERE ${whereClause.join(' AND ')}
      ORDER BY $orderBy
      LIMIT ? OFFSET ?
    ''';

      whereArgs.add(sqlLimit);
      whereArgs.add(sqlOffset);

      debugPrint('📊 SQL: $sql');
      debugPrint('📊 Args: $whereArgs');

      final results = await _dbHelper.rawQuery(sql, whereArgs);
      var programs = results.map((row) => _mapProgramFromLocal(row)).toList();

      // Post-query tuition filtering
      if (needsTuitionFiltering) {
        programs = await _filterProgramsByTuition(
          programs,
          filter?.minTuitionFeeMYR,
          filter?.maxTuitionFeeMYR,
        );
      }

      // ✅ NEW: Apply Top N after filtering (if both filters active)
      if (hasTopN && needsTuitionFiltering) {
        if (programs.length > filter!.topN!) {
          programs = programs.sublist(0, filter.topN!);
        }

        // Handle pagination
        if (offset >= programs.length) {
          return [];
        }

        final endIndex = (offset + limit < programs.length) ? offset + limit : programs.length;
        programs = programs.sublist(offset, endIndex);
      } else if (programs.length > limit) {
        // Ensure we return only the requested limit
        programs = programs.sublist(0, limit);
      }

      return programs;
    } catch (e) {
      debugPrint('❌ Error getting programs: $e');
      return [];
    }
  }

  Future<int> countProgramsInTuitionRange(
    double? minFee,
    double? maxFee,
  ) async {
    if (minFee == null && maxFee == null) {
      return await _dbHelper.getRecordCount(
        'programs',
        where: 'is_deleted = 0',
      );
    }

    // For tuition filters, we need to do post-query counting
    // This is expensive, so we'll estimate based on sample
    final sampleSize = 1000;
    final sql = '''
    SELECT * FROM programs
    WHERE is_deleted = 0
    LIMIT ?
  ''';

    final sample = await _dbHelper.rawQuery(sql, [sampleSize]);
    final samplePrograms = sample
        .map((row) => _mapProgramFromLocal(row))
        .toList();
    final filtered = await _filterProgramsByTuition(
      samplePrograms,
      minFee,
      maxFee,
    );

    final totalPrograms = await _dbHelper.getRecordCount(
      'programs',
      where: 'is_deleted = 0',
    );
    final matchRate = filtered.length / sampleSize;

    return (totalPrograms * matchRate).round();
  }

  Future<List<ProgramModel>> filterProgramsByTuitionPublic(
    List<ProgramModel> programs,
    double? minFee,
    double? maxFee,
  ) async {
    return await _filterProgramsByTuition(programs, minFee, maxFee);
  }

  Future<List<UniversityModel>> filterUniversitiesByTuition(
      List<UniversityModel> universities,
      double? minFee,
      double? maxFee,
      ) async {
    if (universities.isEmpty || (minFee == null && maxFee == null)) return universities;

    // 1. Batch Fetch Branches for ALL universities in one go (Optimization)
    final uniIds = universities.map((u) => u.universityId).toList();
    final branchMap = await getBranchesForUniversities(uniIds); // Batch operation

    final filtered = <UniversityModel>[];

    for (var uni in universities) {
      final branches = branchMap[uni.universityId] ?? [];
      if (branches.isEmpty) continue;

      // Determine fee type based on location context
      final isMalaysianContext = branches.any((b) => b.country.toLowerCase() == 'malaysia');

      // Smart Queries: Fetch only necessary tuition fee field
      final feeStr = isMalaysianContext ? uni.domesticTuitionFee : uni.internationalTuitionFee;
      if (feeStr == null) continue;

      final feeInMYR = CurrencyUtils.convertToMYR(feeStr);
      if (feeInMYR == null || feeInMYR <= 0) continue;

      // Apply range filter
      if ((minFee == null || feeInMYR >= minFee) && (maxFee == null || feeInMYR <= maxFee)) {
        filtered.add(uni);
      }
    }
    return filtered;
  }

  Future<Map<String, List<BranchModel>>> getBranchesForUniversities(List<String> universityIds) async {
    if (universityIds.isEmpty) return {};

    final placeholders = universityIds.map((_) => '?').join(',');
    final sql = 'SELECT * FROM branches WHERE university_id IN ($placeholders) AND is_deleted = 0';

    final results = await _dbHelper.rawQuery(sql, universityIds);
    final map = <String, List<BranchModel>>{};

    for (var row in results) {
      final branch = _mapBranchFromLocal(row);
      if (!map.containsKey(branch.universityId)) map[branch.universityId] = [];
      map[branch.universityId]!.add(branch);
    }
    return map;
  }

  Future<List<String>> _getBranchIdsByCountries(List<String> countries) async {
    try {
      if (countries.isEmpty) return [];

      final placeholders = countries.map((_) => '?').join(',');
      final sql =
          '''
      SELECT branch_id FROM branches
      WHERE LOWER(country) IN (${countries.map((_) => 'LOWER(?)').join(',')})
      AND is_deleted = 0
    ''';

      final results = await _dbHelper.rawQuery(sql, countries);
      return results.map((row) => row['branch_id'] as String).toList();
    } catch (e) {
      debugPrint('❌ Error getting branch IDs by countries: $e');
      return [];
    }
  }

  Future<Set<String>> getBranchIdsByCountries(List<String> countries) async {
    try {
      if (countries.isEmpty) return {};

      final sql =
          '''
      SELECT branch_id FROM branches
      WHERE LOWER(country) IN (${countries.map((_) => 'LOWER(?)').join(',')})
      AND is_deleted = 0
    ''';

      final results = await _dbHelper.rawQuery(sql, countries);
      return results.map((row) => row['branch_id'] as String).toSet();
    } catch (e) {
      debugPrint('❌ Error getting branch IDs by countries: $e');
      return {};
    }
  }

  /// Filter programs by tuition fee (post-query)
  Future<List<ProgramModel>> _filterProgramsByTuition(
    List<ProgramModel> programs,
    double? minFee,
    double? maxFee,
  ) async {
    if (programs.isEmpty) return [];
    if (minFee == null && maxFee == null)
      return programs; // ✅ NEW: Early return

    // ✅ Load branches in batch (more efficient)
    final branchIds = programs.map((p) => p.branchId).toSet();

    for (final branchId in branchIds) {
      if (!_branchCache.containsKey(branchId)) {
        final branch = await getBranchById(branchId);
        if (branch != null) {
          _branchCache[branchId] = branch;
        }
      }
    }

    final filtered = <ProgramModel>[];

    for (var program in programs) {
      final branch = _branchCache[program.branchId];
      if (branch == null) continue;

      final isMalaysian = branch.country.toLowerCase() == 'malaysia';

      String? feeStr;
      if (isMalaysian && program.minDomesticTuitionFee != null) {
        feeStr = program.minDomesticTuitionFee;
      } else if (!isMalaysian && program.minInternationalTuitionFee != null) {
        feeStr = program.minInternationalTuitionFee;
      }

      if (feeStr == null) continue;

      final feeInMYR = CurrencyUtils.convertToMYR(feeStr);
      if (feeInMYR == null || feeInMYR <= 0) continue;

      // Apply range filter
      bool inRange = true;
      if (minFee != null && feeInMYR < minFee) inRange = false;
      if (maxFee != null && feeInMYR > maxFee) inRange = false;

      if (inRange) {
        filtered.add(program);
      }
    }

    return filtered;
  }

  String _getProgramOrderBy(ProgramFilterModel? filter) {
    if (filter?.rankingSortOrder == 'desc') {
      return 'min_subject_ranking DESC NULLS LAST';
    } else if (filter?.rankingSortOrder == 'asc' || filter?.topN != null) {
      return 'min_subject_ranking ASC NULLS LAST';
    }
    return 'program_name ASC';
  }

  /// Get universities with filters and pagination
  Future<List<UniversityModel>> getUniversities({
    int limit = 10,
    int offset = 0,
    UniversityFilterModel? filter,
  }) async {
    try {
      final whereClause = <String>[];
      final whereArgs = <dynamic>[];
      var orderBy = '';
      bool hasLocationFilter = false;

      // =======================================================================
      // 1. BUILD SQL FILTERS (Pre-Query)
      // =======================================================================

      whereClause.add('is_deleted = 0');

      // Search
      if (filter?.searchQuery != null && filter!.searchQuery!.isNotEmpty) {
        whereClause.add('LOWER(university_name) LIKE LOWER(?)');
        whereArgs.add('%${filter.searchQuery}%');
      }

      // 1. Check for Country
      if (filter?.country != null && filter!.country!.isNotEmpty) {
        whereClause.add(
          'EXISTS (SELECT 1 FROM branches b WHERE b.university_id = universities.university_id AND LOWER(b.country) = LOWER(?) AND b.is_deleted = 0)',
        );
        whereArgs.add(filter!.country);
        hasLocationFilter = true;
      }

      // 2. Check for City (Changed 'else if' to 'if')
      if (filter?.city != null && filter!.city!.isNotEmpty) {
        whereClause.add(
          'EXISTS (SELECT 1 FROM branches b WHERE b.university_id = universities.university_id AND LOWER(b.city) = LOWER(?) AND b.is_deleted = 0)',
        );
        whereArgs.add(filter!.city);
        hasLocationFilter = true;
      }

      // 3. Handle Default (Only if no specific location filter was applied)
      if (!hasLocationFilter && filter?.shouldDefaultToMalaysia == true) {
        whereClause.add(
          'EXISTS (SELECT 1 FROM branches b WHERE b.university_id = universities.university_id AND LOWER(b.country) = LOWER(?) AND b.is_deleted = 0)',
        );
        whereArgs.add('malaysia');
      }

      // Students Count
      if (filter?.minStudents != null) {
        whereClause.add('total_students >= ?');
        whereArgs.add(filter!.minStudents!);
      }
      if (filter?.maxStudents != null) {
        whereClause.add('total_students <= ?');
        whereArgs.add(filter!.maxStudents!);
      }

      // Institution Type
      if (filter?.institutionType != null && filter!.institutionType!.isNotEmpty) {
        whereClause.add('institution_type = ?');
        whereArgs.add(filter.institutionType);
      }

      // =======================================================================
      // 2. SORTING (Ranking Logic)
      // =======================================================================

      final isRankingFilterActive = filter?.topN != null || filter?.rankingSortOrder != null;

      if (isRankingFilterActive) {
        // Sort by min_ranking. Unranked (NULL) items go to the bottom.
        final sortOrder = (filter?.rankingSortOrder?.toLowerCase() == 'desc') ? 'DESC' : 'ASC';
        orderBy = 'min_ranking IS NULL ASC, min_ranking $sortOrder';
      } else {
        orderBy = 'min_ranking ASC NULLS LAST';
      }

      // =======================================================================
      // 3. HANDLE LIMITS & PAGINATION
      // =======================================================================

      final bool needsTuitionFiltering = (filter?.minTuitionFeeMYR != null || filter?.maxTuitionFeeMYR != null);

      // --- STRATEGY A: Post-Query Filtering Active (Tuition) ---
      // We must fetch more data, filter in memory, then slice manually.
      if (needsTuitionFiltering) {
        // 1. Determine how many raw rows to scan.
        // If TopN is 10, we might need to scan 100 rows to find 10 matches.
        // We fetch a generous chunk to ensure we find enough matches.
        int scanLimit = 500; // Default large scan
        if (filter?.topN != null) {
          // Scan up to 10x the TopN requirement, capped at 1000 to be safe
          scanLimit = (filter!.topN! * 10).clamp(100, 1000);
        } else {
          // If no TopN, but paging, scan up to the requested page end + buffer
          scanLimit = (offset + limit) * 5;
          if (scanLimit < 100) scanLimit = 100;
        }

        // 2. Execute SQL with expanded limit and NO offset (fetch from top)
        // We ignore SQL offset because skipping raw rows might skip valid matches
        // that belong on page 1.
        final sql = '''
          SELECT * FROM universities
          WHERE ${whereClause.join(' AND ')}
          ORDER BY $orderBy
          LIMIT ? 
        '''; // No SQL OFFSET

        final expandedArgs = List.from(whereArgs)..add(scanLimit);

        final rawResults = await _dbHelper.rawQuery(sql, expandedArgs);
        var candidates = rawResults.map((row) => _mapUniversityFromLocal(row)).toList();

        // 3. Apply Tuition Filter (Async)
        candidates = await filterUniversitiesByTuition(
          candidates,
          filter?.minTuitionFeeMYR,
          filter?.maxTuitionFeeMYR,
        );

        // 4. Apply Top N Limit to the FILTERED list
        if (filter?.topN != null) {
          if (candidates.length > filter!.topN!) {
            candidates = candidates.sublist(0, filter.topN!);
          }
        }

        // 5. Manual Pagination (Slice the list)
        if (offset >= candidates.length) {
          return []; // Page is out of bounds
        }

        final endIndex = (offset + limit < candidates.length)
            ? offset + limit
            : candidates.length;

        return candidates.sublist(offset, endIndex);
      }

      // --- STRATEGY B: Standard SQL Pagination (No Tuition Filter) ---
      else {
        // Apply Top N logic for efficient fetching
        int sqlLimit = limit;

        if (filter?.topN != null) {
          final remainingInTopN = filter!.topN! - offset;
          if (remainingInTopN <= 0) return []; // Already fetched all Top N

          // Fetch the smaller of (Page Size) or (Remaining Top N)
          sqlLimit = (limit < remainingInTopN) ? limit : remainingInTopN;
        }

        final sql = '''
          SELECT * FROM universities
          WHERE ${whereClause.join(' AND ')}
          ORDER BY $orderBy
          LIMIT ? OFFSET ?
        ''';

        whereArgs.add(sqlLimit);
        whereArgs.add(offset);

        final results = await _dbHelper.rawQuery(sql, whereArgs);
        return results.map((row) => _mapUniversityFromLocal(row)).toList();
      }

    } catch (e, st) {
      debugPrint('❌ Error getting universities: $e\n$st');
      return [];
    }
  }

  Future<List<BranchModel>> getBranchesByIds(List<String> branchIds) async {
    if (branchIds.isEmpty) return [];
    final placeholders = branchIds.map((_) => '?').join(',');
    final sql = 'SELECT * FROM branches WHERE branch_id IN ($placeholders) AND is_deleted = 0';
    final results = await _dbHelper.rawQuery(sql, branchIds);
    return results.map((row) => _mapBranchFromLocal(row)).toList();
  }

  // FIXED: Case-insensitive search
  Future<List<UniversityModel>> searchUniversities(
    String query, {
    int limit = 20,
  }) async {
    try {
      final sql = '''
      SELECT * FROM universities
      WHERE is_deleted = 0 
      AND LOWER(university_name) LIKE LOWER(?)
      ORDER BY university_name COLLATE NOCASE ASC
      LIMIT ?
    ''';

      final results = await _dbHelper.rawQuery(sql, ['%$query%', limit]);
      return results.map((row) => _mapUniversityFromLocal(row)).toList();
    } catch (e) {
      debugPrint('❌ Error searching universities: $e');
      return [];
    }
  }

  Future<UniversityModel?> getUniversityById(String universityId) async {
    try {
      final sql = '''
        SELECT * FROM universities
        WHERE university_id = ? AND is_deleted = 0
      ''';

      final results = await _dbHelper.rawQuery(sql, [universityId]);
      if (results.isEmpty) return null;
      return _mapUniversityFromLocal(results.first);
    } catch (e) {
      debugPrint('❌ Error getting university: $e');
      return null;
    }
  }

  // ==================== BRANCHES ====================

  Future<List<BranchModel>> getBranchesByUniversity(String universityId) async {
    try {
      final sql = '''
        SELECT * FROM branches
        WHERE university_id = ? AND is_deleted = 0
        ORDER BY branch_name ASC
      ''';

      final results = await _dbHelper.rawQuery(sql, [universityId]);
      return results.map((row) => _mapBranchFromLocal(row)).toList();
    } catch (e) {
      debugPrint('❌ Error getting branches: $e');
      return [];
    }
  }

  Future<BranchModel?> getBranchById(String branchId) async {
    try {
      final sql = '''
        SELECT * FROM branches
        WHERE branch_id = ? AND is_deleted = 0
      ''';

      final results = await _dbHelper.rawQuery(sql, [branchId]);
      if (results.isEmpty) return null;
      return _mapBranchFromLocal(results.first);
    } catch (e) {
      debugPrint('❌ Error getting branch: $e');
      return null;
    }
  }

  Future<Set<String>> getMalaysianBranchIds() async {
    try {
      final sql = '''
        SELECT branch_id FROM branches
        WHERE country = 'Malaysia' AND is_deleted = 0
      ''';

      final results = await _dbHelper.rawQuery(sql, null);
      return results.map((row) => row['branch_id'] as String).toSet();
    } catch (e) {
      debugPrint('❌ Error getting Malaysian branch IDs: $e');
      return {};
    }
  }

  // ==================== OTHER PROGRAM METHODS ====================

  Future<List<ProgramModel>> getProgramsByUniversity(
    String universityId, {
    int limit = 50,
  }) async {
    try {
      final sql = '''
        SELECT * FROM programs
        WHERE university_id = ? AND is_deleted = 0
        ORDER BY program_name ASC
        LIMIT ?
      ''';

      final results = await _dbHelper.rawQuery(sql, [universityId, limit]);
      return results.map((row) => _mapProgramFromLocal(row)).toList();
    } catch (e) {
      debugPrint('❌ Error getting programs by university: $e');
      return [];
    }
  }

  Future<List<ProgramModel>> getProgramsByBranch(
    String branchId, {
    int limit = 100,
  }) async {
    try {
      final sql = '''
        SELECT * FROM programs
        WHERE branch_id = ? AND is_deleted = 0
        ORDER BY program_name ASC
        LIMIT ?
      ''';

      final results = await _dbHelper.rawQuery(sql, [branchId, limit]);
      return results.map((row) => _mapProgramFromLocal(row)).toList();
    } catch (e) {
      debugPrint('❌ Error getting programs by branch: $e');
      return [];
    }
  }

  Future<Map<String, List<ProgramModel>>> getProgramsByStudyLevel(
    String universityId,
  ) async {
    try {
      final sql = '''
        SELECT * FROM programs
        WHERE university_id = ? AND is_deleted = 0
        ORDER BY study_level, program_name ASC
        LIMIT 100
      ''';

      final results = await _dbHelper.rawQuery(sql, [universityId]);
      final programs = results.map((row) => _mapProgramFromLocal(row)).toList();

      final Map<String, List<ProgramModel>> grouped = {};
      for (var program in programs) {
        final level = program.studyLevel ?? 'Other';
        grouped.putIfAbsent(level, () => []).add(program);
      }

      return grouped;
    } catch (e) {
      debugPrint('❌ Error getting programs by level: $e');
      return {};
    }
  }

  Future<Map<String, List<ProgramModel>>> getRelatedProgramsByLevel(
    String universityId,
    String studyLevel,
    String excludeProgramId,
  ) async {
    try {
      final sql = '''
        SELECT * FROM programs
        WHERE university_id = ? 
        AND study_level = ? 
        AND program_id != ?
        AND is_deleted = 0
        ORDER BY program_name ASC
        LIMIT 50
      ''';

      final results = await _dbHelper.rawQuery(sql, [
        universityId,
        studyLevel,
        excludeProgramId,
      ]);

      final programs = results.map((row) => _mapProgramFromLocal(row)).toList();
      return {studyLevel: programs};
    } catch (e) {
      debugPrint('❌ Error getting related programs: $e');
      return {};
    }
  }

  Future<List<ProgramModel>> searchPrograms(
    String query, {
    int limit = 20,
  }) async {
    try {
      final sql = '''
        SELECT * FROM programs
        WHERE is_deleted = 0 
        AND program_name LIKE ?
        ORDER BY program_name ASC
        LIMIT ?
      ''';

      final results = await _dbHelper.rawQuery(sql, ['%$query%', limit]);
      return results.map((row) => _mapProgramFromLocal(row)).toList();
    } catch (e) {
      debugPrint('❌ Error searching programs: $e');
      return [];
    }
  }

  Future<ProgramModel?> getProgramById(String programId) async {
    try {
      final sql = '''
        SELECT * FROM programs
        WHERE program_id = ? AND is_deleted = 0
      ''';

      final results = await _dbHelper.rawQuery(sql, [programId]);
      if (results.isEmpty) return null;
      return _mapProgramFromLocal(results.first);
    } catch (e) {
      debugPrint('❌ Error getting program: $e');
      return null;
    }
  }

  Future<int> getProgramCountByUniversity(String universityId) async {
    return await _dbHelper.getRecordCount(
      'programs',
      where: 'university_id = ? AND is_deleted = 0',
      whereArgs: [universityId],
    );
  }

  // ==================== ADMISSIONS ====================

  Future<List<UniversityAdmissionModel>> getUniversityAdmissions(
    String universityId,
  ) async {
    try {
      final sql = '''
        SELECT * FROM university_admissions
        WHERE university_id = ? AND is_deleted = 0
      ''';

      final results = await _dbHelper.rawQuery(sql, [universityId]);
      return results
          .map((row) => _mapUniversityAdmissionFromLocal(row))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting university admissions: $e');
      return [];
    }
  }

  Future<List<ProgramAdmissionModel>> getProgramAdmissions(
    String programId,
  ) async {
    try {
      debugPrint('🔎 Fetching Program Admissions for programId: $programId');

      final sql = '''
      SELECT * FROM program_admissions
      WHERE program_id = ? AND is_deleted = 0
    ''';

      debugPrint('📝 SQL: $sql');

      final results = await _dbHelper.rawQuery(sql, [programId]);

      debugPrint('📦 Query Result Count: ${results.length}');
      for (var row in results) {
        debugPrint('➡ Row: $row');
      }

      final mapped = results
          .map((row) => _mapProgramAdmissionFromLocal(row))
          .toList();

      debugPrint('✅ Successfully mapped ${mapped.length} admissions\n');
      return mapped;
    } catch (e, stack) {
      debugPrint('❌ Error getting program admissions: $e');
      debugPrint('📌 Stacktrace: $stack');
      return [];
    }
  }

  // ==================== FILTER METADATA ====================

  Future<List<String>> getAvailableCountries() async {
    try {
      final sql = '''
        SELECT DISTINCT country FROM branches
        WHERE is_deleted = 0
        ORDER BY country ASC
      ''';

      final results = await _dbHelper.rawQuery(sql, null);
      return results
          .map((row) => row['country'] as String)
          .where((c) => c.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting countries: $e');
      return [];
    }
  }

  Future<List<String>> getCitiesForCountry(String country) async {
    try {
      final sql = '''
        SELECT DISTINCT city FROM branches
        WHERE country = ? AND is_deleted = 0
        ORDER BY city ASC
      ''';

      final results = await _dbHelper.rawQuery(sql, [country]);
      return results
          .map((row) => row['city'] as String)
          .where((c) => c.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting cities: $e');
      return [];
    }
  }

  Future<List<String>> getAvailableSubjectAreas() async {
    try {
      final sql = '''
        SELECT DISTINCT subject_area FROM programs
        WHERE is_deleted = 0 AND subject_area IS NOT NULL
        ORDER BY subject_area ASC
      ''';

      final results = await _dbHelper.rawQuery(sql, null);
      return results
          .map((row) => row['subject_area'] as String)
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting subject areas: $e');
      return [];
    }
  }

  Future<List<String>> getAvailableStudyModes() async {
    try {
      final sql = '''
        SELECT DISTINCT study_mode FROM programs
        WHERE is_deleted = 0 AND study_mode IS NOT NULL
        ORDER BY study_mode ASC
      ''';

      final results = await _dbHelper.rawQuery(sql, null);
      return results
          .map((row) => row['study_mode'] as String)
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting study modes: $e');
      return [];
    }
  }

  Future<List<String>> getAvailableStudyLevels() async {
    try {
      final sql = '''
        SELECT DISTINCT study_level FROM programs
        WHERE is_deleted = 0 AND study_level IS NOT NULL
        ORDER BY study_level ASC
      ''';

      final results = await _dbHelper.rawQuery(sql, null);
      return results
          .map((row) => row['study_level'] as String)
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting study levels: $e');
      return [];
    }
  }

  Future<(int, int)> getStudentRange() async {
    try {
      final sql = '''
        SELECT 
          MIN(total_students) as min,
          MAX(total_students) as max
        FROM universities
        WHERE is_deleted = 0 AND total_students IS NOT NULL AND total_students > 0
      ''';

      final results = await _dbHelper.rawQuery(sql, null);
      if (results.isEmpty) return (0, 100000);

      final row = results.first;
      final min = (row['min'] as int?) ?? 0;
      final max = (row['max'] as int?) ?? 100000;

      return ((min / 1000).floor() * 1000, ((max / 1000).ceil() * 1000));
    } catch (e) {
      debugPrint('❌ Error getting student range: $e');
      return (0, 100000);
    }
  }

  Future<(int, int)> getRankingRange() async {
    try {
      final sql = '''
        SELECT 
          MIN(min_ranking) as min,
          MAX(COALESCE(max_ranking, min_ranking)) as max
        FROM universities
        WHERE is_deleted = 0 AND min_ranking IS NOT NULL AND min_ranking > 0
      ''';

      final results = await _dbHelper.rawQuery(sql, null);
      if (results.isEmpty) return (1, 2000);

      final row = results.first;
      return (row['min'] as int? ?? 1, row['max'] as int? ?? 2000);
    } catch (e) {
      debugPrint('❌ Error getting ranking range: $e');
      return (1, 2000);
    }
  }

  Future<(int, int)> getSubjectRankingRange() async {
    try {
      final sql = '''
        SELECT 
          MIN(min_subject_ranking) as min,
          MAX(COALESCE(max_subject_ranking, min_subject_ranking)) as max
        FROM programs
        WHERE is_deleted = 0 AND min_subject_ranking IS NOT NULL AND min_subject_ranking > 0
      ''';

      final results = await _dbHelper.rawQuery(sql, null);
      if (results.isEmpty) return (1, 500);

      final row = results.first;
      return (row['min'] as int? ?? 1, row['max'] as int? ?? 500);
    } catch (e) {
      debugPrint('❌ Error getting subject ranking range: $e');
      return (1, 500);
    }
  }

  Future<(double, double)> getDurationRange() async {
    try {
      final sql = '''
        SELECT 
          MIN(CAST(duration_months AS REAL) / 12.0) as min,
          MAX(CAST(duration_months AS REAL) / 12.0) as max
        FROM programs
        WHERE is_deleted = 0 AND duration_months IS NOT NULL
      ''';

      final results = await _dbHelper.rawQuery(sql, null);
      if (results.isEmpty) return (1.0, 6.0);

      final row = results.first;
      return (row['min'] as double? ?? 1.0, row['max'] as double? ?? 6.0);
    } catch (e) {
      debugPrint('❌ Error getting duration range: $e');
      return (1.0, 6.0);
    }
  }
  // ==================== MAPPER METHODS ====================

  UniversityModel _mapUniversityFromLocal(Map<String, dynamic> row) {
    return UniversityModel(
      universityId: (row['university_id'] ?? '') as String,
      universityName: (row['university_name'] ?? '') as String,
      universityLogo: (row['university_logo'] ?? '') as String,
      universityUrl: (row['university_url'] ?? '') as String,
      uniDescription: (row['uni_description'] ?? '') as String,
      domesticTuitionFee: row['domestic_tuition_fee'] as String?,
      internationalTuitionFee: row['international_tuition_fee'] as String?,
      totalStudents: row['total_students'] as int?,
      internationalStudents: row['international_students'] as int?,
      totalFacultyStaff: row['total_faculty_staff'] as int?,
      minRanking: row['min_ranking'] as int?,
      maxRanking: row['max_ranking'] as int?,
      programCount: row['program_count'] as int? ?? 0,
    );
  }

  BranchModel _mapBranchFromLocal(Map<String, dynamic> row) {
    return BranchModel(
      branchId: row['branch_id'] as String,
      universityId: row['university_id'] as String,
      branchName: row['branch_name'] as String,
      country: row['country'] as String,
      city: row['city'] as String,
    );
  }

  ProgramModel _mapProgramFromLocal(Map<String, dynamic> row) {
    List<String> intakePeriod = [];
    if (row['intake_period'] != null) {
      try {
        intakePeriod = List<String>.from(
          jsonDecode(row['intake_period'] as String),
        );
      } catch (e) {
        debugPrint('Error parsing intake_period: $e');
      }
    }

    return ProgramModel(
      programId: (row['program_id'] ?? '') as String,
      branchId: (row['branch_id'] ?? '') as String,
      programName: (row['program_name'] ?? '') as String,
      programUrl: (row['program_url'] ?? '') as String,
      progDescription: (row['prog_description'] ?? '') as String,
      durationMonths: row['duration_months'] as String?,
      subjectArea: row['subject_area'] as String?,
      studyLevel: row['study_level'] as String?,
      studyMode: row['study_mode'] as String?,
      intakePeriod: intakePeriod,
      minDomesticTuitionFee: row['min_domestic_tuition_fee'] as String?,
      minInternationalTuitionFee:
          row['min_international_tuition_fee'] as String?,
      entryRequirement: row['entry_requirement'] as String?,
      minSubjectRanking: row['min_subject_ranking'] as int?,
      maxSubjectRanking: row['max_subject_ranking'] as int?,
      universityId: (row['university_id'] ?? '') as String,
    );
  }

  UniversityAdmissionModel _mapUniversityAdmissionFromLocal(
    Map<String, dynamic> row,
  ) {
    return UniversityAdmissionModel(
      uniAdmissionId: row['uni_admission_id'] as String,
      universityId: row['university_id'] as String,
      admissionType: row['admission_type'] as String?,
      admissionLabel: row['admission_label'] as String?,
      admissionValue: row['admission_value'] as String?,
    );
  }

  ProgramAdmissionModel _mapProgramAdmissionFromLocal(
    Map<String, dynamic> row,
  ) {
    return ProgramAdmissionModel(
      progAdmissionId: row['prog_admission_id'] as String,
      programId: row['program_id'] as String,
      progAdmissionLabel: row['prog_admission_label'] as String?,
      progAdmissionValue: row['prog_admission_value'] as String?,
    );
  }

  // ==================== ADDITIONAL FILTER QUERIES ====================

  Future<List<String>> getAvailableIntakeMonths() async {
    try {
      final sql = '''
        SELECT DISTINCT json_each.value as month
        FROM programs, json_each(programs.intake_period)
        WHERE programs.is_deleted = 0 AND programs.intake_period IS NOT NULL
        ORDER BY month ASC
      ''';

      final results = await _dbHelper.rawQuery(sql, null);

      final months = results
          .map((row) => row['month'] as String)
          .where((m) => m.isNotEmpty)
          .toList();

      final monthOrder = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      months.sort((a, b) {
        int indexA = monthOrder.indexOf(a);
        int indexB = monthOrder.indexOf(b);
        if (indexA == -1) indexA = 999;
        if (indexB == -1) indexB = 999;
        return indexA.compareTo(indexB);
      });

      return months;
    } catch (e) {
      debugPrint('❌ Error getting intake months: $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> getAvailableUniversities() async {
    try {
      final sql = '''
        SELECT DISTINCT university_id, university_name
        FROM universities
        WHERE is_deleted = 0
        ORDER BY university_name ASC
      ''';

      final results = await _dbHelper.rawQuery(sql, null);

      return results
          .map(
            (row) => {
              'id': row['university_id'] as String,
              'name': row['university_name'] as String,
            },
          )
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting universities: $e');
      return [];
    }
  }

  Future<(double, double)> getTuitionFeeRange() async {
    try {
      final sql = '''
        SELECT 
          domestic_tuition_fee,
          international_tuition_fee
        FROM universities
        WHERE is_deleted = 0 
        AND (domestic_tuition_fee IS NOT NULL OR international_tuition_fee IS NOT NULL)
        LIMIT 200
      ''';

      final results = await _dbHelper.rawQuery(sql, null);

      double minFee = double.infinity;
      double maxFee = 0.0;

      for (var row in results) {
        if (row['domestic_tuition_fee'] != null) {
          final fee = CurrencyUtils.convertToMYR(
            row['domestic_tuition_fee'] as String,
          );
          if (fee != null && fee > 0) {
            if (fee < minFee) minFee = fee;
            if (fee > maxFee) maxFee = fee;
          }
        }

        if (row['international_tuition_fee'] != null) {
          final fee = CurrencyUtils.convertToMYR(
            row['international_tuition_fee'] as String,
          );
          if (fee != null && fee > 0) {
            if (fee < minFee) minFee = fee;
            if (fee > maxFee) maxFee = fee;
          }
        }
      }

      if (minFee == double.infinity) minFee = 0;

      minFee = (minFee / 1000).floor() * 1000;
      maxFee = ((maxFee / 1000).ceil() * 1000);

      return (minFee, maxFee);
    } catch (e) {
      debugPrint('❌ Error getting tuition range: $e');
      return (0.0, 500000.0);
    }
  }

  Future<(double, double)> getProgramTuitionFeeRange() async {
    try {
      final sql = '''
        SELECT 
          min_domestic_tuition_fee,
          min_international_tuition_fee
        FROM programs
        WHERE is_deleted = 0 
        AND (min_domestic_tuition_fee IS NOT NULL OR min_international_tuition_fee IS NOT NULL)
        LIMIT 200
      ''';

      final results = await _dbHelper.rawQuery(sql, null);

      double minFee = double.infinity;
      double maxFee = 0.0;

      for (var row in results) {
        if (row['min_domestic_tuition_fee'] != null) {
          final fee = CurrencyUtils.convertToMYR(
            row['min_domestic_tuition_fee'] as String,
          );
          if (fee != null && fee > 0) {
            if (fee < minFee) minFee = fee;
            if (fee > maxFee) maxFee = fee;
          }
        }

        if (row['min_international_tuition_fee'] != null) {
          final fee = CurrencyUtils.convertToMYR(
            row['min_international_tuition_fee'] as String,
          );
          if (fee != null && fee > 0) {
            if (fee < minFee) minFee = fee;
            if (fee > maxFee) maxFee = fee;
          }
        }
      }

      if (minFee == double.infinity) minFee = 0;

      minFee = (minFee / 1000).floor() * 1000;
      maxFee = ((maxFee / 1000).ceil() * 1000);

      return (minFee, maxFee);
    } catch (e) {
      debugPrint('❌ Error getting program tuition range: $e');
      return (0.0, 500000.0);
    }
  }

  void _resetBranchCacheTimer() {
    _branchCacheTimer?.cancel();
    _branchCacheTimer = Timer(Duration(minutes: 5), () {
      _branchCache.clear();
      debugPrint('🧹 Branch cache cleared (5 min timeout)');
    });
  }
}
