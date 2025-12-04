import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:path_wise/model/job_models.dart';

class JobService {
  final String apiKey = 'f2d1f59c5cmsh20bf9b01cf6ae7cp1ab00ajsn7ba5f1714182';
  final String apiHost = 'jsearch.p.rapidapi.com';
  final String searchEndpoint = 'https://jsearch.p.rapidapi.com/search';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch ALL jobs from JSearch API with pagination
  Future<List<JobModel>> fetchJobs({
    String? query,
    String? country,
    String? datePosted,
    int maxResults = 50,
  }) async {
    try {
      List<JobModel> allJobs = [];
      int currentPage = 1; // Start at page 1 (was 10 in your original code)
      bool hasMorePages = true;
      int pagesFetched = 0;
      int maxPages = 3; // LIMIT 2: Never fetch more than 3 pages, regardless of results

      // Loop only if:
      // 1. We have more pages to fetch
      // 2. We haven't reached our max result count
      // 3. We haven't exceeded our max page limit
      while (hasMorePages && allJobs.length < maxResults && pagesFetched < maxPages) {
        debugPrint('🔍 Fetching page $currentPage...');

        final pageJobs = await _fetchJobsPage(
          query: query,
          country: country,
          datePosted: datePosted,
          page: currentPage,
        );

        if (pageJobs.isEmpty) {
          hasMorePages = false;
          debugPrint('⚠️ No more jobs available at page $currentPage');
        } else {
          allJobs.addAll(pageJobs);
          pagesFetched++;

          debugPrint('✅ Fetched ${pageJobs.length} jobs (Total: ${allJobs.length})');

          // JSearch API returns 10 jobs per page.
          // If we get less than 10, it implies it's the last page.
          if (pageJobs.length < 10) {
            hasMorePages = false;
          } else {
            currentPage++;
          }
        }

        // Small delay to prevent hitting API rate limits too quickly (optional but recommended)
        if (hasMorePages) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      debugPrint('✅ Search complete. Total jobs: ${allJobs.length}');
      return allJobs;
    } catch (error) {
      debugPrint('❌ Error fetching jobs: $error');
      throw Exception('Error fetching jobs: $error');
    }
  }

  /// Fetch a single page of jobs from JSearch API
  Future<List<JobModel>> _fetchJobsPage({
    String? query,
    String? country,
    String? datePosted,
    int page = 2,
  }) async {
    try {
      // Build query parameters
      final queryParams = _buildQueryParams(
        query: query,
        country: country,
        datePosted: datePosted,
        page: page,
      );

      final uri = Uri.parse(searchEndpoint).replace(queryParameters: queryParams);

      debugPrint('🔍 API Request: $uri');

      final response = await http.get(
        uri,
        headers: {
          'x-rapidapi-key': apiKey,
          'x-rapidapi-host': apiHost,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check if data contains jobs
        if (data['data'] == null || data['data'].isEmpty) {
          return [];
        }

        final jobList = _parseJobsResponse(data);
        return jobList;
      } else {
        debugPrint('❌ API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load jobs: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('❌ Error fetching page: $error');
      throw Exception('Error fetching page: $error');
    }
  }

  /// Build query parameters for JSearch API
  Map<String, String> _buildQueryParams({
    String? query,
    String? country,
    String? datePosted,
    int page = 1,
  }) {
    final params = <String, String>{};

    // Main search query (required)
    if (query != null && query.isNotEmpty) {
      params['query'] = query;
    } else {
      params['query'] = 'jobs'; // Default query
    }

    // Country code (my, us, uk, sg, etc.)
    if (country != null && country.isNotEmpty) {
      params['country'] = country.toLowerCase();
    } else {
      params['country'] = 'my'; // Default to Malaysia
    }

    // Date posted filter (all, today, 3days, week, month)
    if (datePosted != null && datePosted.isNotEmpty) {
      params['date_posted'] = datePosted;
    } else {
      params['date_posted'] = 'all';
    }

    // Pagination
    params['page'] = page.toString();
    params['num_pages'] = '1'; // Always fetch 1 page at a time

    return params;
  }

  /// Parse jobs response from JSearch API
  List<JobModel> _parseJobsResponse(Map<String, dynamic> data) {
    try {
      final jobDataList = List<Map<String, dynamic>>.from(data['data'] ?? []);

      return jobDataList.map((jobData) {
        try {
          return JobModel.fromJson(jobData);
        } catch (e) {
          debugPrint('⚠️ Error parsing job: $e');
          return null;
        }
      }).whereType<JobModel>().toList();
    } catch (e) {
      debugPrint('❌ Error parsing jobs response: $e');
      return [];
    }
  }

  /// Apply client-side filters to job list
  List<JobModel> applyLocalFilters(
      List<JobModel> jobs,
      JobFilters filters,
      ) {
    var filteredJobs = jobs;

    // Filter by salary range
    if (filters.minSalary != null || filters.maxSalary != null) {
      filteredJobs = filteredJobs.where((job) {
        // If job has no salary info, include it (show "not specified")
        if (job.jobMinSalary == null || job.jobMaxSalary == null) {
          return true; // Include jobs with unspecified salary
        }

        final minSalary = double.tryParse(job.jobMinSalary!) ?? 0;
        final maxSalary = double.tryParse(job.jobMaxSalary!) ?? 0;

        if (filters.minSalary != null && maxSalary < filters.minSalary!) {
          return false;
        }
        if (filters.maxSalary != null && minSalary > filters.maxSalary!) {
          return false;
        }

        return true;
      }).toList();
    }

    // Filter by work mode (Remote/Hybrid/On-site)
    if (filters.remote != null) {
      filteredJobs = filteredJobs.where((job) {
        if (filters.remote == 'Remote') {
          return job.isRemote == true;
        } else if (filters.remote == 'On-site') {
          return job.isRemote == false;
        }
        // For 'Hybrid', include both (API doesn't distinguish hybrid well)
        return true;
      }).toList();
    }

    // Filter by location (city/state match)
    if (filters.location != null && filters.location!.isNotEmpty) {
      final locationQuery = filters.location!.toLowerCase();
      filteredJobs = filteredJobs.where((job) {
        final jobLocation = '${job.jobLocation.city}, ${job.jobLocation.state}'.toLowerCase();
        return jobLocation.contains(locationQuery);
      }).toList();
    }

    // Filter by employment types (FULLTIME, PARTTIME, INTERN, CONTRACTOR)
    if (filters.employmentTypes != null && filters.employmentTypes!.isNotEmpty) {
      filteredJobs = filteredJobs.where((job) {
        // Check if any of the job's employment types match the filter
        return job.jobEmploymentTypes.any((type) =>
            filters.employmentTypes!.any((filterType) =>
                type.toUpperCase().contains(filterType.toUpperCase())));
      }).toList();
    }

    return filteredJobs;
  }

  /// Search jobs with comprehensive filtering
  Future<List<JobModel>> searchJobsWithFilters({
    required String query,
    required String country,
    required JobFilters filters,
  }) async {
    // Step 1: Fetch from API with query, country, and date posted
    final jobs = await fetchJobs(
      query: query,
      country: country,
      datePosted: filters.dateRange,
    );

    // Step 2: Apply local filters (salary, location, work mode, employment type)
    return applyLocalFilters(jobs, filters);
  }

  /// Get list of supported countries with their codes
  static Map<String, String> getSupportedCountries() {
    return {
      'my': 'Malaysia',
      'sg': 'Singapore',
      'us': 'United States',
      'uk': 'United Kingdom',
      'ca': 'Canada',
      'au': 'Australia',
      'in': 'India',
      'id': 'Indonesia',
      'ph': 'Philippines',
      'th': 'Thailand',
      'vn': 'Vietnam',
      'de': 'Germany',
      'fr': 'France',
      'es': 'Spain',
      'it': 'Italy',
      'nl': 'Netherlands',
      'jp': 'Japan',
      'kr': 'South Korea',
      'cn': 'China',
      'hk': 'Hong Kong',
      'tw': 'Taiwan',
      'nz': 'New Zealand',
      'br': 'Brazil',
      'mx': 'Mexico',
      'ar': 'Argentina',
    };
  }

  /// Get country code from country name
  static String? getCountryCode(String countryName) {
    final countries = getSupportedCountries();
    final entry = countries.entries.firstWhere(
          (entry) => entry.value.toLowerCase() == countryName.toLowerCase(),
      orElse: () => MapEntry('', ''),
    );
    return entry.key.isNotEmpty ? entry.key : null;
  }

  // ==================== FIRESTORE METHODS ====================

  /// Generate next job bookmark ID (JB0001, JB0002, etc.)
  Future<String> _generateNextBookmarkId(String uid) async {
    final bookmarksRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('job_bookmarks');

    final snapshot = await bookmarksRef.get();

    int maxNumber = 0;

    for (var doc in snapshot.docs) {
      final docId = doc.id;
      if (docId.startsWith('JB') && docId.length >= 3) {
        final numberPart = docId.substring(2);
        final number = int.tryParse(numberPart);
        if (number != null && number > maxNumber) {
          maxNumber = number;
        }
      }
    }

    final nextNumber = maxNumber + 1;
    return 'JB${nextNumber.toString().padLeft(4, '0')}';
  }

  /// Save a job to Firestore (Bookmark)
  Future<String> saveJobToFirestore(String uid, JobModel job) async {
    try {
      final bookmarkId = await _generateNextBookmarkId(uid);

      final bookmarkRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('job_bookmarks')
          .doc(bookmarkId);

      await bookmarkRef.set({
        ...job.toMap(),
        'bookmarkId': bookmarkId,
        'savedAt': Timestamp.now(),
      });

      debugPrint('✅ Job bookmarked with ID: $bookmarkId');
      return bookmarkId;
    } catch (error) {
      debugPrint('❌ Error saving job: $error');
      throw Exception('Error saving job to Firestore: $error');
    }
  }

  /// Remove a saved job from Firestore
  Future<void> removeSavedJob(String uid, String bookmarkId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('job_bookmarks')
          .doc(bookmarkId)
          .delete();

      debugPrint('🗑️ Removed bookmark: $bookmarkId');
    } catch (error) {
      debugPrint('❌ Error removing job: $error');
      throw Exception('Error removing job: $error');
    }
  }

  /// Fetch all saved/bookmarked jobs
  Future<List<JobModel>> fetchSavedJobs(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('job_bookmarks')
          .orderBy('savedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          return JobModel.fromFirestore(data, doc.id);
        } catch (e) {
          debugPrint('⚠️ Error parsing saved job: $e');
          return null;
        }
      }).whereType<JobModel>().toList();
    } catch (error) {
      debugPrint('❌ Error fetching saved jobs: $error');
      throw Exception('Error fetching saved jobs: $error');
    }
  }

  /// Stream saved jobs (real-time updates)
  Stream<List<JobModel>> streamSavedJobs(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('job_bookmarks')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          return JobModel.fromFirestore(data, doc.id);
        } catch (e) {
          debugPrint('⚠️ Error parsing saved job: $e');
          return null;
        }
      }).whereType<JobModel>().toList();
    });
  }
}