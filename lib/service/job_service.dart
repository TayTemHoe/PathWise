import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:path_wise/model/job_models.dart';


class JobService {
  final String apiKey = 'e41d8eaff2msh041a382f6bb1904p194aecjsn715ac6c5b487';
  final String apiHost = 'jsearch.p.rapidapi.com';
  final String searchEndpoint = 'https://jsearch.p.rapidapi.com/search';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch jobs from JSearch API with proper filtering and multi-country support
  Future<List<JobModel>> fetchJobs({
    String? query,
    String? location,
    String? country, // NEW: Country code parameter (us, uk, my, sg, etc.)
    JobFilters? filters,
    int page = 1,
  }) async {
    try {
      // Build query parameters
      final queryParams = _buildQueryParams(
        query: query,
        location: location,
        country: country,
        filters: filters,
        page: page,
      );

      final uri = Uri.parse(searchEndpoint).replace(queryParameters: queryParams);

      debugPrint('🔍 Fetching jobs from: $uri');

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
          debugPrint('⚠️ No jobs found');
          return [];
        }

        final jobList = _parseJobsResponse(data);
        debugPrint('✅ Fetched ${jobList.length} jobs');
        return jobList;
      } else {
        debugPrint('❌ API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load jobs: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('❌ Error fetching jobs: $error');
      throw Exception('Error fetching jobs: $error');
    }
  }

  /// Build query parameters for JSearch API
  Map<String, String> _buildQueryParams({
    String? query,
    String? location,
    String? country,
    JobFilters? filters,
    int page = 1,
  }) {
    final params = <String, String>{};

    // Main search query - combine job title with location if provided
    String searchQuery = '';

    if (query != null && query.isNotEmpty) {
      searchQuery = query;
    } else if (filters?.query != null && filters!.query!.isNotEmpty) {
      searchQuery = filters.query!;
    } else {
      searchQuery = 'Software Developer'; // Default query
    }

    // Add location to query if provided (e.g., "Software Developer in Kuala Lumpur")
    if (location != null && location.isNotEmpty && location.toLowerCase() != 'malaysia') {
      searchQuery += ' in $location';
    }

    params['query'] = searchQuery;

    // Country code (IMPORTANT: This filters jobs by country)
    // Supported codes: us, uk, ca, au, sg, my, in, de, fr, etc.
    if (country != null && country.isNotEmpty) {
      params['country'] = country.toLowerCase();
    } else if (filters?.location != null) {
      // Try to extract country code from filters
      final countryCode = _extractCountryCode(filters!.location!);
      if (countryCode != null) {
        params['country'] = countryCode;
      }
    } else {
      // Default to Malaysia
      params['country'] = 'my';
    }

    // Remote jobs filter
    if (filters?.remote != null) {
      if (filters!.remote == 'Remote') {
        params['remote_jobs_only'] = 'true';
      }
    }

    // Employment types (FULLTIME, CONTRACTOR, PARTTIME, INTERN)
    if (filters?.employmentTypes != null && filters!.employmentTypes!.isNotEmpty) {
      params['employment_types'] = filters.employmentTypes!.join(',');
    }

    // Date posted filter (all, today, 3days, week, month)
    if (filters?.dateRange != null && filters!.dateRange!.isNotEmpty) {
      params['date_posted'] = filters.dateRange!;
    }

    // Pagination
    params['page'] = page.toString();
    params['num_pages'] = '1';

    return params;
  }

  /// Extract country code from location string
  /// Examples: "Kuala Lumpur, Malaysia" -> "my", "New York, USA" -> "us"
  String? _extractCountryCode(String location) {
    final locationLower = location.toLowerCase();

    // Map of country names/keywords to their codes
    final countryMap = {
      'malaysia': 'my',
      'singapore': 'sg',
      'united states': 'us',
      'usa': 'us',
      'america': 'us',
      'united kingdom': 'uk',
      'uk': 'uk',
      'england': 'uk',
      'canada': 'ca',
      'australia': 'au',
      'india': 'in',
      'indonesia': 'id',
      'philippines': 'ph',
      'thailand': 'th',
      'vietnam': 'vn',
      'germany': 'de',
      'france': 'fr',
      'spain': 'es',
      'italy': 'it',
      'netherlands': 'nl',
      'japan': 'jp',
      'south korea': 'kr',
      'china': 'cn',
      'hong kong': 'hk',
      'taiwan': 'tw',
      'new zealand': 'nz',
      'brazil': 'br',
      'mexico': 'mx',
      'argentina': 'ar',
    };

    // Check if location contains any country keyword
    for (var entry in countryMap.entries) {
      if (locationLower.contains(entry.key)) {
        return entry.value;
      }
    }

    return null; // Return null if no country code found
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
      }).whereType<JobModel>().toList(); // Filter out nulls
    } catch (e) {
      debugPrint('❌ Error parsing jobs response: $e');
      return [];
    }
  }

  /// Search jobs by career suggestion (from AI recommendations)
  Future<List<JobModel>> searchJobsByCareerSuggestion({
    required String jobTitle,
    String? location,
    String? country,
    int page = 1,
  }) async {
    return fetchJobs(
      query: jobTitle,
      location: location,
      country: country ?? 'my',
      page: page,
    );
  }

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
      // Generate custom ID
      final bookmarkId = await _generateNextBookmarkId(uid);

      final bookmarkRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('job_bookmarks')
          .doc(bookmarkId);

      // Save job with metadata
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

  /// Check if a job is already saved/bookmarked
  /// Uses job_id from JSearch API as unique identifier
  Future<String?> isJobSaved(String uid, String jobId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('job_bookmarks')
          .where('job_id', isEqualTo: jobId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id; // Return bookmark ID
      }
      return null;
    } catch (error) {
      debugPrint('❌ Error checking if job is saved: $error');
      return null;
    }
  }

  /// Get total count of saved jobs
  Future<int> getSavedJobsCount(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('job_bookmarks')
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (error) {
      debugPrint('❌ Error getting saved jobs count: $error');
      return 0;
    }
  }

  /// Apply client-side filtering (for filters not supported by API)
  List<JobModel> applyLocalFilters(
      List<JobModel> jobs,
      JobFilters filters,
      ) {
    var filteredJobs = jobs;

    // Filter by salary range
    if (filters.minSalary != null || filters.maxSalary != null) {
      filteredJobs = filteredJobs.where((job) {
        if (job.jobMinSalary == null || job.jobMaxSalary == null) {
          return false;
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
        // For 'Hybrid', we keep both (API doesn't distinguish hybrid well)
        return true;
      }).toList();
    }

    // Filter by company type/industry
    if (filters.industries != null && filters.industries!.isNotEmpty) {
      filteredJobs = filteredJobs.where((job) {
        final companyType = job.employerCompanyType?.toLowerCase() ?? '';
        return filters.industries!.any(
              (industry) => companyType.contains(industry.toLowerCase()),
        );
      }).toList();
    }

    return filteredJobs;
  }

  /// Search jobs with comprehensive filtering
  Future<List<JobModel>> searchJobsWithFilters({
    required String query,
    String? location,
    String? country,
    required JobFilters filters,
    int page = 1,
  }) async {
    // Fetch from API with supported filters
    final jobs = await fetchJobs(
      query: query,
      location: location,
      country: country,
      filters: filters,
      page: page,
    );

    // Apply additional client-side filtering
    return applyLocalFilters(jobs, filters);
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
}