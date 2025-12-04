// lib/viewmodels/resume_view_model.dart
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_wise/model/resume_model.dart';
import 'package:path_wise/model/user_profile.dart';
import 'package:path_wise/services/resume_service.dart';
import 'package:path_wise/services/profile_service.dart';

class ResumeViewModel extends ChangeNotifier {
  ResumeViewModel({
    ResumeService? resumeService,
    ProfileService? profileService,
    FirebaseAuth? auth,
  })  : _resumeService = resumeService ?? ResumeService(),
        _profileService = profileService ?? ProfileService(),
        _auth = auth ?? FirebaseAuth.instance;

  final ResumeService _resumeService;
  final ProfileService _profileService;
  final FirebaseAuth _auth;

  // =============================
  // State
  // =============================
  List<ResumeDoc> _resumes = [];
  ResumeDoc? _currentResume;
  UserProfile? _userProfile;

  bool _isLoading = false;
  bool _isCreating = false;
  bool _isUpdating = false;
  bool _isDeleting = false;
  bool _isGeneratingPDF = false;
  bool _isDownloading = false;
  bool _isSharing = false;

  String? _error;
  String? _successMessage;

  // =============================
  // Getters
  // =============================
  List<ResumeDoc> get resumes => _resumes;
  ResumeDoc? get currentResume => _currentResume;
  UserProfile? get userProfile => _userProfile;

  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  bool get isUpdating => _isUpdating;
  bool get isDeleting => _isDeleting;
  bool get isGeneratingPDF => _isGeneratingPDF;
  bool get isDownloading => _isDownloading;
  bool get isSharing => _isSharing;

  bool get hasAnyOperation =>
      _isLoading ||
          _isCreating ||
          _isUpdating ||
          _isDeleting ||
          _isGeneratingPDF ||
          _isDownloading ||
          _isSharing;

  String? get error => _error;
  String? get successMessage => _successMessage;

  String? get uid => FirebaseAuth.instance.currentUser?.uid;
  // =============================
  // State Setters
  // =============================
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setCreating(bool value) {
    _isCreating = value;
    notifyListeners();
  }

  void _setUpdating(bool value) {
    _isUpdating = value;
    notifyListeners();
  }

  void _setDeleting(bool value) {
    _isDeleting = value;
    notifyListeners();
  }

  void _setGeneratingPDF(bool value) {
    _isGeneratingPDF = value;
    notifyListeners();
  }

  void _setDownloading(bool value) {
    _isDownloading = value;
    notifyListeners();
  }

  void _setSharing(bool value) {
    _isSharing = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    _successMessage = null;
    notifyListeners();
  }

  void _setSuccess(String message) {
    _successMessage = message;
    _error = null;
    notifyListeners();
  }

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  // =============================
  // Load Data
  // =============================

  /// Load all resumes and user profile
  Future<void> loadAll() async {
    _setLoading(true);
    _setError(null);

    try {
      // Load resumes and profile in parallel
      final results = await Future.wait([
        _resumeService.listResumes(),
        _profileService.getUserWithSubcollections(uid!),
      ]);

      _resumes = results[0] as List<ResumeDoc>;
      _userProfile = results[1] as UserProfile?;

      notifyListeners();
    } catch (e) {
      _setError('Failed to load data: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh the list
  Future<void> refresh() => loadAll();

  /// Load a specific resume
  Future<void> loadResume(String resumeId) async {
    _setLoading(true);
    _setError(null);

    try {
      _currentResume = await _resumeService.getResume(resumeId: resumeId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load resume: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Set current resume for editing
  void setCurrentResume(ResumeDoc? resume) {
    _currentResume = resume;
    notifyListeners();
  }

  // =============================
  // CRUD Operations
  // =============================

  /// Create a new resume
  Future<bool> createResume({
    required String title,
    required ResumeTemplateType template,
    required ResumeThemeConfig theme,
    required ResumeFontConfig font,
    required ResumeSectionConfig sections,
    String? aboutMe,
    List<ResumeReference> references = const [],
  }) async {
    _setCreating(true);
    _setError(null);

    try {
      // Validate user profile
      if (_userProfile == null) {
        await _profileService.getUserWithSubcollections(uid!);
        if (_userProfile == null) {
          _setError('Please complete your profile before creating a resume');
          return false;
        }
      }

      // Check for missing essential data
      final missingFields = _validateProfileData(sections);
      if (missingFields.isNotEmpty) {
        _setError('Missing required fields: ${missingFields.join(', ')}');
        return false;
      }

      // Create resume document
      final newResume = ResumeDoc(
        id: '', // Will be generated by services
        title: title,
        template: template,
        theme: theme,
        font: font,
        sections: sections,
        aboutMe: aboutMe,
        references: references,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await _resumeService.createResume(resume: newResume);

      // Add to local list
      _resumes = [created, ..._resumes];
      _currentResume = created;

      _setSuccess('Resume created successfully!');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create resume: ${e.toString()}');
      return false;
    } finally {
      _setCreating(false);
    }
  }

  /// Update an existing resume
  Future<bool> updateResume(ResumeDoc resume) async {
    _setUpdating(true);
    _setError(null);

    try {
      await _resumeService.updateResume(resume: resume);

      // Update in local list
      _resumes = _resumes.map((r) => r.id == resume.id ? resume : r).toList();
      if (_currentResume?.id == resume.id) {
        _currentResume = resume;
      }

      _setSuccess('Resume updated successfully!');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update resume: ${e.toString()}');
      return false;
    } finally {
      _setUpdating(false);
    }
  }

  /// Delete a resume
  Future<bool> deleteResume(String resumeId) async {
    _setDeleting(true);
    _setError(null);

    try {
      await _resumeService.deleteResume(resumeId: resumeId);

      // Remove from local list
      _resumes = _resumes.where((r) => r.id != resumeId).toList();
      if (_currentResume?.id == resumeId) {
        _currentResume = null;
      }

      _setSuccess('Resume deleted successfully!');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete resume: ${e.toString()}');
      return false;
    } finally {
      _setDeleting(false);
    }
  }

  // =============================
  // PDF Operations
  // =============================

  /// Download resume as PDF
  Future<String?> downloadResume(ResumeDoc resume) async {
    _setDownloading(true);
    _setError(null);

    try {
      // Check and request permission
      if (Platform.isAndroid) {
        final status = await Permission.storage.status;
        if (!status.isGranted) {
          final result = await Permission.storage.request();
          if (!result.isGranted) {
            // For Android 13+ (API 33+), we don't need storage permission
            // But for older versions, we do
            if (Platform.isAndroid) {
              // Try requesting manageExternalStorage for Android 11+
              final manageStatus = await Permission.manageExternalStorage.status;
              if (!manageStatus.isGranted) {
                await Permission.manageExternalStorage.request();
              }
            }
          }
        }
      }

      if (_userProfile == null) {
        _userProfile = await _profileService.getUserWithSubcollections(uid!);
      }

      if (_userProfile == null) {
        _setError('Profile data not found');
        return null;
      }

      final path = await _resumeService.downloadResumePDF(
        resume: resume,
        profile: _userProfile!,
      );

      _setSuccess('Resume saved successfully!\nLocation: $path');
      return path;
    } catch (e) {
      _setError('Failed to download resume: ${e.toString()}');
      return null;
    } finally {
      _setDownloading(false);
    }
  }



  /// Share resume as PDF
  Future<bool> shareResume(ResumeDoc resume) async {
    _setSharing(true);
    _setError(null);

    try {
      if (_userProfile == null) {
        _userProfile = await _profileService.getUserWithSubcollections(uid!);
      }

      if (_userProfile == null) {
        _setError('Profile data not found');
        return false;
      }

      await _resumeService.shareResumePDF(
        resume: resume,
        profile: _userProfile!,
      );

      _setSuccess('Resume shared successfully!');
      return true;
    } catch (e) {
      _setError('Failed to share resume: ${e.toString()}');
      return false;
    } finally {
      _setSharing(false);
    }
  }

  /// Generate PDF preview (for in-app viewing)
  Future<bool> generatePDFPreview(ResumeDoc resume) async {
    _setGeneratingPDF(true);
    _setError(null);

    try {
      if (_userProfile == null) {
        _userProfile = await _profileService.getUserWithSubcollections(uid!);
      }

      if (_userProfile == null) {
        _setError('Profile data not found');
        return false;
      }

      await _resumeService.generateResumePDF(
        resume: resume,
        profile: _userProfile!,
      );

      return true;
    } catch (e) {
      _setError('Failed to generate PDF: ${e.toString()}');
      return false;
    } finally {
      _setGeneratingPDF(false);
    }
  }

  // =============================
  // Validation
  // =============================

  /// Validate profile data based on selected sections
  List<String> _validateProfileData(ResumeSectionConfig sections) {
    final missing = <String>[];

    if (_userProfile == null) {
      missing.add('Profile');
      return missing;
    }

    // Check personal info
    if (sections.personalInfo) {
      if (_userProfile!.name == null || _userProfile!.name!.isEmpty) {
        missing.add('Name');
      }
      if (_userProfile!.email == null || _userProfile!.email!.isEmpty) {
        missing.add('Email');
      }
    }

    // Check skills
    if (sections.skills) {
      if (_userProfile!.skills == null || _userProfile!.skills!.isEmpty) {
        missing.add('At least one skill');
      }
    }

    // Check education
    if (sections.education) {
      if (_userProfile!.education == null || _userProfile!.education!.isEmpty) {
        missing.add('At least one education entry');
      }
    }

    return missing;
  }

  /// Check if profile is complete enough to create a resume
  bool get isProfileComplete {
    if (_userProfile == null) return false;

    return (_userProfile!.name?.isNotEmpty ?? false) &&
        (_userProfile!.email?.isNotEmpty ?? false) &&
        ((_userProfile!.skills?.isNotEmpty ?? false) ||
            (_userProfile!.education?.isNotEmpty ?? false));
  }

  /// Get profile completion message
  String get profileCompletionMessage {
    if (_userProfile == null) {
      return 'Please create a profile first';
    }

    final missing = <String>[];
    if (_userProfile!.name?.isEmpty ?? true) missing.add('Name');
    if (_userProfile!.email?.isEmpty ?? true) missing.add('Email');
    if (_userProfile!.skills?.isEmpty ?? true) missing.add('Skills');
    if (_userProfile!.education?.isEmpty ?? true) missing.add('Education');

    if (missing.isEmpty) {
      return 'Profile is complete!';
    }

    return 'Missing: ${missing.join(', ')}';
  }

  // =============================
  // Helper Methods
  // =============================

  /// Get resume count
  int get resumeCount => _resumes.length;

  /// Check if user has any resumes
  bool get hasResumes => _resumes.isNotEmpty;

  /// Get latest resume
  ResumeDoc? get latestResume => _resumes.isEmpty ? null : _resumes.first;

  /// Sort resumes by date
  void sortResumesByDate({bool descending = true}) {
    _resumes.sort((a, b) {
      final aDate = a.updatedAt ?? a.createdAt ?? DateTime(2000);
      final bDate = b.updatedAt ?? b.createdAt ?? DateTime(2000);
      return descending
          ? bDate.compareTo(aDate)
          : aDate.compareTo(bDate);
    });
    notifyListeners();
  }

  /// Sort resumes by title
  void sortResumesByTitle({bool ascending = true}) {
    _resumes.sort((a, b) => ascending
        ? a.title.compareTo(b.title)
        : b.title.compareTo(a.title));
    notifyListeners();
  }

  /// Filter resumes by template
  List<ResumeDoc> getResumesByTemplate(ResumeTemplateType template) {
    return _resumes.where((r) => r.template == template).toList();
  }

  /// Search resumes by title
  List<ResumeDoc> searchResumes(String query) {
    if (query.isEmpty) return _resumes;

    final lowerQuery = query.toLowerCase();
    return _resumes
        .where((r) => r.title.toLowerCase().contains(lowerQuery))
        .toList();
  }
}