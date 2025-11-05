// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../model/branch.dart';
import '../model/university_filter.dart';
import '../model/program.dart';
import '../model/university.dart';
import '../model/university_admission.dart';

class FirebaseService {
  static final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  // ==================== AGGRESSIVE CACHING ====================

  // Cache universities data
  static final Map<String, UniversityModel> _universityCache = {};
  static final Map<String, List<BranchModel>> _branchCache = {};
  static final Map<String, List<ProgramModel>> _programCache = {};
  static final Map<String, List<UniversityAdmissionModel>> _admissionCache = {};

  // Cache metadata
  static DateTime? _lastUniversityCacheTime;
  static DateTime? _lastBranchCacheTime;
  static const Duration _cacheValidity = Duration(hours: 24);

  // Pagination cache to prevent re-fetching same pages
  static final Map<String, List<UniversityModel>> _paginationCache = {};
  static final Map<String, DocumentSnapshot?> _paginationLastDoc = {};

  // Request tracking to prevent duplicates
  static final Set<String> _activeRequests = {};
  static int _requestCount = 0;

  FirebaseService() : _firestore = FirebaseFirestore.instance;
  FirebaseService.withFirestore(FirebaseFirestore firestore) : _firestore = firestore;

  static const String usersCollectionName = 'users';
  String get universitiesCollection => 'universities';
  String get branchesCollection => 'branches';
  String get programsCollection => 'programs';
  String get admissionsCollection => 'university_admissions';

  static CollectionReference get usersCollection =>
      db.collection(usersCollectionName);

  // ==================== REQUEST TRACKING ====================

  static void _logRequest(String operation) {
    _requestCount++;
    if (kDebugMode) {
      print('🔥 Firebase Request #$_requestCount: $operation');
    }
  }

  static int getRequestCount() => _requestCount;
  static void resetRequestCount() => _requestCount = 0;

  // ==================== CACHE MANAGEMENT ====================

  static bool _isCacheValid(DateTime? lastCacheTime) {
    if (lastCacheTime == null) return false;
    return DateTime.now().difference(lastCacheTime) < _cacheValidity;
  }

  static void clearAllCaches() {
    _universityCache.clear();
    _branchCache.clear();
    _programCache.clear();
    _admissionCache.clear();
    _paginationCache.clear();
    _paginationLastDoc.clear();
    _lastUniversityCacheTime = null;
    _lastBranchCacheTime = null;
    if (kDebugMode) {
      print('🧹 All caches cleared');
    }
  }

  // ==================== OPTIMIZED UNIVERSITY OPERATIONS ====================
  /// Get university from cache or fetch if needed
  Future<UniversityModel?> getUniversity(String universityId) async {
    // Check cache first
    if (_universityCache.containsKey(universityId)) {
      if (kDebugMode) {
        print('📦 Cache HIT: University $universityId');
      }
      return _universityCache[universityId];
    }

    // Prevent duplicate requests
    final requestKey = 'uni_$universityId';
    if (_activeRequests.contains(requestKey)) {
      if (kDebugMode) {
        print('⏸️ Request already in progress: $universityId');
      }
      // Wait for active request to complete
      await Future.delayed(const Duration(milliseconds: 100));
      return _universityCache[universityId];
    }

    _activeRequests.add(requestKey);

    try {
      _logRequest('getUniversity($universityId)');

      // Try cache-first strategy
      final doc = await _firestore
          .collection(universitiesCollection)
          .doc(universityId)
          .get(const GetOptions(source: Source.cache));

      UniversityModel? university;

      if (doc.exists && doc.data() != null) {
        university = UniversityModel.fromJson(doc.data()!);
      } else {
        // Fallback to server
        _logRequest('getUniversity($universityId) - server fallback');
        final serverDoc = await _firestore
            .collection(universitiesCollection)
            .doc(universityId)
            .get(const GetOptions(source: Source.server));

        if (serverDoc.exists && serverDoc.data() != null) {
          university = UniversityModel.fromJson(serverDoc.data()!);
        }
      }

      if (university != null) {
        _universityCache[universityId] = university;
      }

      return university;
    } finally {
      _activeRequests.remove(requestKey);
    }
  }

  /// Get branches with aggressive caching
  Future<List<BranchModel>> getBranchesByUniversity(String universityId) async {
    // Check cache first
    if (_branchCache.containsKey(universityId)) {
      if (kDebugMode) {
        print('📦 Cache HIT: Branches for $universityId');
      }
      return _branchCache[universityId]!;
    }

    // Prevent duplicate requests
    final requestKey = 'branch_$universityId';
    if (_activeRequests.contains(requestKey)) {
      if (kDebugMode) {
        print('⏸️ Request already in progress: branches for $universityId');
      }
      await Future.delayed(const Duration(milliseconds: 100));
      return _branchCache[universityId] ?? [];
    }

    _activeRequests.add(requestKey);

    try {
      _logRequest('getBranchesByUniversity($universityId)');

      // Try cache-first
      QuerySnapshot snapshot;
      try {
        snapshot = await _firestore
            .collection(branchesCollection)
            .where('university_id', isEqualTo: universityId)
            .get(const GetOptions(source: Source.cache));

        if (snapshot.docs.isEmpty) {
          throw Exception('No cache data');
        }
      } catch (e) {
        // Fallback to server
        _logRequest('getBranchesByUniversity($universityId) - server fallback');
        snapshot = await _firestore
            .collection(branchesCollection)
            .where('university_id', isEqualTo: universityId)
            .get(const GetOptions(source: Source.server));
      }

      final branches = snapshot.docs
          .map((doc) => BranchModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      _branchCache[universityId] = branches;
      _lastBranchCacheTime = DateTime.now();

      return branches;
    } finally {
      _activeRequests.remove(requestKey);
    }
  }

  /// Get programs with caching
  // Get programs by branch
  Future<List<ProgramModel>> getProgramsByBranch(String branchId) async {
    if (_programCache.containsKey(branchId)) {
      debugPrint('📦 Cache HIT: Programs for $branchId');
      return _programCache[branchId]!;
    }

    final requestKey = 'program_$branchId';
    if (_activeRequests.contains(requestKey)) {
      await Future.delayed(const Duration(milliseconds: 100));
      return _programCache[branchId] ?? [];
    }

    _activeRequests.add(requestKey);

    try {
      debugPrint('🔥 Fetching programs for $branchId...');

      QuerySnapshot snapshot;
      try {
        snapshot = await _firestore
            .collection(programsCollection)
            .where('branch_id', isEqualTo: branchId)
            .get(const GetOptions(source: Source.cache));

        if (snapshot.docs.isEmpty) throw Exception('No cache data');
      } catch (e) {
        snapshot = await _firestore
            .collection(programsCollection)
            .where('branch_id', isEqualTo: branchId)
            .get(const GetOptions(source: Source.server));
      }

      final programs = snapshot.docs
          .map((doc) => ProgramModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      _programCache[branchId] = programs;
      return programs;
    } finally {
      _activeRequests.remove(requestKey);
    }
  }

  /// Get admissions with caching
  Future<List<UniversityAdmissionModel>> getAdmissionsByUniversity(
      String universityId) async {
    // Check cache first
    if (_admissionCache.containsKey(universityId)) {
      if (kDebugMode) {
        print('📦 Cache HIT: Admissions for $universityId');
      }
      return _admissionCache[universityId]!;
    }

    // Prevent duplicate requests
    final requestKey = 'admission_$universityId';
    if (_activeRequests.contains(requestKey)) {
      await Future.delayed(const Duration(milliseconds: 100));
      return _admissionCache[universityId] ?? [];
    }

    _activeRequests.add(requestKey);

    try {
      _logRequest('getAdmissionsByUniversity($universityId)');

      // Try cache-first
      QuerySnapshot snapshot;
      try {
        snapshot = await _firestore
            .collection(admissionsCollection)
            .where('university_id', isEqualTo: universityId)
            .get(const GetOptions(source: Source.cache));

        if (snapshot.docs.isEmpty) {
          throw Exception('No cache data');
        }
      } catch (e) {
        _logRequest('getAdmissionsByUniversity($universityId) - server fallback');
        snapshot = await _firestore
            .collection(admissionsCollection)
            .where('university_id', isEqualTo: universityId)
            .get(const GetOptions(source: Source.server));
      }

      final admissions = snapshot.docs
          .map((doc) => UniversityAdmissionModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      _admissionCache[universityId] = admissions;

      return admissions;
    } finally {
      _activeRequests.remove(requestKey);
    }
  }

  /// Optimized batch fetch for multiple universities
  Future<List<UniversityModel>> getBatchUniversities(List<String> universityIds) async {
    if (universityIds.isEmpty) return [];

    final results = <UniversityModel>[];
    final idsToFetch = <String>[];

    // Check cache first
    for (final id in universityIds) {
      if (_universityCache.containsKey(id)) {
        results.add(_universityCache[id]!);
      } else {
        idsToFetch.add(id);
      }
    }

    if (idsToFetch.isEmpty) {
      if (kDebugMode) {
        print('📦 Cache HIT: All ${universityIds.length} universities');
      }
      return results;
    }

    if (kDebugMode) {
      print('🔍 Need to fetch ${idsToFetch.length} universities from Firestore');
    }

    // Fetch in batches of 10 (Firestore 'in' limit)
    for (int i = 0; i < idsToFetch.length; i += 10) {
      final batch = idsToFetch.skip(i).take(10).toList();

      _logRequest('getBatchUniversities(${batch.length} universities)');

      try {
        final snapshot = await _firestore
            .collection(universitiesCollection)
            .where(FieldPath.documentId, whereIn: batch)
            .get(const GetOptions(source: Source.cache));

        if (snapshot.docs.isNotEmpty) {
          for (var doc in snapshot.docs) {
            final uni = UniversityModel.fromJson(doc.data() as Map<String, dynamic>);
            results.add(uni);
            _universityCache[uni.universityId] = uni;
          }
        } else {
          throw Exception('No cache');
        }
      } catch (e) {
        // Fallback to server
        _logRequest('getBatchUniversities - server fallback (${batch.length})');
        final snapshot = await _firestore
            .collection(universitiesCollection)
            .where(FieldPath.documentId, whereIn: batch)
            .get(const GetOptions(source: Source.server));

        for (var doc in snapshot.docs) {
          final uni = UniversityModel.fromJson(doc.data() as Map<String, dynamic>);
          results.add(uni);
          _universityCache[uni.universityId] = uni;
        }
      }
    }

    return results;
  }

  /// Optimized pagination query
  Future<QuerySnapshot> getAllUniversities({
    int limit = 10,
    DocumentSnapshot? lastDoc,
    FilterModel? filter,
  }) async {
    // Create cache key based on filter
    final cacheKey = _createCacheKey(filter, lastDoc?.id);

    // Check pagination cache
    if (_paginationCache.containsKey(cacheKey) && lastDoc == null) {
      if (kDebugMode) {
        print('📦 Cache HIT: Paginated universities');
      }
      // Return cached snapshot (need to convert back)
      // For now, proceed with query
    }

    Query query = _firestore.collection(universitiesCollection);

    // Apply filters (same as before)
    if (filter != null) {
      if (filter.minStudents != null) {
        query = query.where('total_students', isGreaterThanOrEqualTo: filter.minStudents);
      }
      if (filter.maxStudents != null) {
        query = query.where('total_students', isLessThanOrEqualTo: filter.maxStudents);
      }
    }

    query = query.orderBy('university_id').limit(limit);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    _logRequest('getAllUniversities(limit: $limit, hasFilter: ${filter != null})');

    // Try cache first
    try {
      final snapshot = await query.get(const GetOptions(source: Source.cache));
      if (snapshot.docs.isNotEmpty) {
        if (kDebugMode) {
          print('📦 Cache HIT: Query returned ${snapshot.docs.length} universities');
        }
        return snapshot;
      }
    } catch (e) {
      // Continue to server
    }

    // Fallback to server
    _logRequest('getAllUniversities - server fallback');
    final snapshot = await query.get(const GetOptions(source: Source.server));

    return snapshot;
  }

  String _createCacheKey(FilterModel? filter, String? lastDocId) {
    if (filter == null) return 'default_${lastDocId ?? 'start'}';
    return '${filter.hashCode}_${lastDocId ?? 'start'}';
  }

  // ==================== STANDARD CRUD (Keep for compatibility) ====================

  Future<void> createUniversity(UniversityModel university) async {
    _logRequest('createUniversity');
    await _firestore
        .collection(universitiesCollection)
        .doc(university.universityId)
        .set(university.toJson());
    _universityCache[university.universityId] = university;
  }

  Future<void> updateUniversity(UniversityModel university) async {
    _logRequest('updateUniversity');
    await _firestore
        .collection(universitiesCollection)
        .doc(university.universityId)
        .update(university.toJson());
    _universityCache[university.universityId] = university;
  }

  Future<void> deleteUniversity(String universityId) async {
    _logRequest('deleteUniversity');
    await _firestore
        .collection(universitiesCollection)
        .doc(universityId)
        .delete();
    _universityCache.remove(universityId);
  }

  Future<void> createBranch(BranchModel branch) async {
    _logRequest('createBranch');
    await _firestore
        .collection(branchesCollection)
        .doc(branch.branchId)
        .set(branch.toJson());
    _branchCache.remove(branch.universityId);
  }

  Future<void> updateBranch(BranchModel branch) async {
    _logRequest('updateBranch');
    await _firestore
        .collection(branchesCollection)
        .doc(branch.branchId)
        .update(branch.toJson());
    _branchCache.remove(branch.universityId);
  }

  Future<void> deleteBranch(String branchId) async {
    _logRequest('deleteBranch');
    await _firestore
        .collection(branchesCollection)
        .doc(branchId)
        .delete();
  }

  Future<void> createProgram(ProgramModel program) async {
    _logRequest('createProgram');
    await _firestore
        .collection(programsCollection)
        .doc(program.programId)
        .set(program.toJson());
    _programCache.remove(program.branchId);
  }

  Future<void> updateProgram(ProgramModel program) async {
    _logRequest('updateProgram');
    await _firestore
        .collection(programsCollection)
        .doc(program.programId)
        .update(program.toJson());
    _programCache.remove(program.branchId);
  }

  Future<void> deleteProgram(String programId) async {
    _logRequest('deleteProgram');
    await _firestore
        .collection(programsCollection)
        .doc(programId)
        .delete();
  }

  Future<void> createAdmission(UniversityAdmissionModel admission) async {
    _logRequest('createAdmission');
    await _firestore
        .collection(admissionsCollection)
        .doc(admission.uniAdmissionId)
        .set(admission.toJson());
    _admissionCache.remove(admission.universityId);
  }

  Future<UniversityAdmissionModel?> getAdmission(String admissionId) async {
    _logRequest('getAdmission');
    final doc = await _firestore
        .collection(admissionsCollection)
        .doc(admissionId)
        .get();

    if (doc.exists && doc.data() != null) {
      return UniversityAdmissionModel.fromJson(doc.data()!);
    }
    return null;
  }

  Future<void> updateAdmission(UniversityAdmissionModel admission) async {
    _logRequest('updateAdmission');
    await _firestore
        .collection(admissionsCollection)
        .doc(admission.uniAdmissionId)
        .update(admission.toJson());
    _admissionCache.remove(admission.universityId);
  }

  Future<void> deleteAdmission(String admissionId) async {
    _logRequest('deleteAdmission');
    await _firestore
        .collection(admissionsCollection)
        .doc(admissionId)
        .delete();
  }

  // ==================== USER OPERATIONS (Keep existing) ====================

  static Future<String> addDocument(String collectionName, Map<String, dynamic> data) async {
    _logRequest('addDocument($collectionName)');
    final docRef = await db.collection(collectionName).add(data);
    return docRef.id;
  }

  static Future<void> setDocument(String collectionName, String docId,
      Map<String, dynamic> data, {bool merge = false}) async {
    _logRequest('setDocument($collectionName)');
    await db.collection(collectionName).doc(docId).set(
        data, SetOptions(merge: merge));
  }

  static Future<DocumentSnapshot> getDocument(String collectionName, String docId) async {
    _logRequest('getDocument($collectionName)');
    return await db.collection(collectionName).doc(docId).get();
  }

  static Future<QuerySnapshot> getCollection(String collectionName) async {
    _logRequest('getCollection($collectionName)');
    return await db.collection(collectionName).get();
  }

  static Future<void> updateDocument(String collectionName, String docId,
      Map<String, dynamic> data) async {
    _logRequest('updateDocument($collectionName)');
    await db.collection(collectionName).doc(docId).update(data);
  }

  static Future<void> deleteDocument(String collectionName, String docId) async {
    _logRequest('deleteDocument($collectionName)');
    await db.collection(collectionName).doc(docId).delete();
  }

  static Future<bool> documentExists(String collectionName, String docId) async {
    _logRequest('documentExists($collectionName)');
    final doc = await db.collection(collectionName).doc(docId).get();
    return doc.exists;
  }

  // User-specific operations
  static Future<String> addUser(Map<String, dynamic> userData) async =>
      await addDocument(usersCollectionName, userData);

  static Future<DocumentSnapshot> getUser(String userId) async =>
      await getDocument(usersCollectionName, userId);

  static Future<void> updateUser(String userId, Map<String, dynamic> userData) async =>
      await updateDocument(usersCollectionName, userId, userData);

  static Future<void> deleteUser(String userId) async =>
      await deleteDocument(usersCollectionName, userId);

  static Stream<DocumentSnapshot> getUserStream(String userId) =>
      db.collection(usersCollectionName).doc(userId).snapshots();

  static Stream<QuerySnapshot> getCollectionStreamWithQuery(
      String collectionName,
      Query Function(CollectionReference) queryBuilder) {
    final query = queryBuilder(db.collection(collectionName));
    return query.snapshots();
  }

  static Future<QuerySnapshot> getCollectionWithQuery(String collectionName,
      Query Function(CollectionReference) queryBuilder) async {
    try {
      final query = queryBuilder(db.collection(collectionName));
      return await query.get();
    } catch (e) {
      throw Exception('Failed to query collection $collectionName: $e');
    }
  }

  // Batch operations
  static WriteBatch createBatch() {
    return db.batch();
  }

  static Future<void> commitBatch(WriteBatch batch) async {
    try {
      await batch.commit();
    } catch (e) {
      throw Exception('Batch commit failed: $e');
    }
  }

  static Future<QuerySnapshot> getAllUsers() async {
    return await getCollection(usersCollectionName);
  }

  static Future<QuerySnapshot> getUserByEmail(String email) async {
    return await getCollectionWithQuery(
      usersCollectionName,
          (collection) => collection.where('email', isEqualTo: email).limit(1),
    );
  }
}