// lib/services/resume_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_wise/model/ai_match_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../model/resume_model.dart';
import '../model/user_profile.dart';

class ResumeService {
  ResumeService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get _uid => _auth.currentUser?.uid ?? 'U0001';

  // =============================
  // Core refs
  // =============================
  CollectionReference<Map<String, dynamic>> _resumesCol(String uid) =>
      _db.collection('users').doc(uid).collection('resumes');

  DocumentReference<Map<String, dynamic>> _resumeDoc(String uid, String resumeId) =>
      _resumesCol(uid).doc(resumeId);

  // =============================
  // Helpers
  // =============================
  Timestamp _dateOnly([DateTime? d]) {
    final now = d ?? DateTime.now();
    final dateOnly = DateTime(now.year, now.month, now.day);
    return Timestamp.fromDate(dateOnly);
  }

  /// Generate next resume ID e.g. RS0001
  Future<String> _nextResumeId(String uid) async {
    final snap = await _resumesCol(uid).get();
    int maxNum = 0;
    for (final d in snap.docs) {
      final id = d.id;
      if (id.startsWith('RS')) {
        final tail = id.substring(2);
        final n = int.tryParse(tail) ?? 0;
        if (n > maxNum) maxNum = n;
      }
    }
    final next = maxNum + 1;
    return 'RS${next.toString().padLeft(4, '0')}';
  }

  // =============================
  // CRUD Operations
  // =============================

  /// List all resumes for a user
  Future<List<ResumeDoc>> listResumes({String? uid, int limit = 100}) async {
    try {
      final userId = uid ?? _uid;
      final snap = await _resumesCol(userId)
          .orderBy('updatedAt', descending: true)
          .limit(limit)
          .get();

      return snap.docs
          .map((d) => ResumeDoc.fromSnapshot(d as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      print('[ResumeService] listResumes error: $e');
      rethrow;
    }
  }

  /// Get a single resume by ID
  Future<ResumeDoc?> getResume({String? uid, required String resumeId}) async {
    try {
      final userId = uid ?? _uid;
      final doc = await _resumeDoc(userId, resumeId).get();
      if (!doc.exists) return null;
      return ResumeDoc.fromSnapshot(doc as DocumentSnapshot<Map<String, dynamic>>);
    } catch (e) {
      print('[ResumeService] getResume error: $e');
      rethrow;
    }
  }

  /// Create a new resume
  Future<ResumeDoc> createResume({
    String? uid,
    required ResumeDoc resume,
  }) async {
    try {
      final userId = uid ?? _uid;
      final id = await _nextResumeId(userId);
      final now = _dateOnly();

      final newResume = resume.copyWith(
        createdAt: now.toDate(),
        updatedAt: now.toDate(),
      );

      final data = newResume.toMap();
      data['createdAt'] = now;
      data['updatedAt'] = now;

      await _resumeDoc(userId, id).set(data);

      final doc = await _resumeDoc(userId, id).get();
      return ResumeDoc.fromSnapshot(doc as DocumentSnapshot<Map<String, dynamic>>);
    } catch (e) {
      print('[ResumeService] createResume error: $e');
      rethrow;
    }
  }

  /// Update an existing resume
  Future<void> updateResume({
    String? uid,
    required ResumeDoc resume,
  }) async {
    try {
      final userId = uid ?? _uid;
      final data = resume.toMap();
      data['updatedAt'] = _dateOnly();

      await _resumeDoc(userId, resume.id).update(data);
    } catch (e) {
      print('[ResumeService] updateResume error: $e');
      rethrow;
    }
  }

  /// Delete a resume
  Future<void> deleteResume({String? uid, required String resumeId}) async {
    try {
      final userId = uid ?? _uid;
      await _resumeDoc(userId, resumeId).delete();
    } catch (e) {
      print('[ResumeService] deleteResume error: $e');
      rethrow;
    }
  }

  // =============================
  // PDF Generation
  // =============================

  /// Generate PDF from resume and user profile
  Future<File> generateResumePDF({
    required ResumeDoc resume,
    required UserProfile profile,
  }) async {
    try {
      final pdf = pw.Document();

      // Load custom font with fallback
      pw.Font? customFont;
      try {
        final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
        customFont = pw.Font.ttf(fontData);
        print('[ResumeService] Custom font loaded successfully');
      } catch (e) {
        print('[ResumeService] Warning: Could not load custom font, using default: $e');
        // customFont will remain null, and we'll use default fonts
      }

      // Parse colors
      final primaryColor = _parseColor(resume.theme.primaryColorHex);
      final secondaryColor = _parseColor(resume.theme.secondaryColorHex);

      // Build PDF based on template
      switch (resume.template) {
        case ResumeTemplateType.tech:
          _buildTechTemplate(pdf, resume, profile, customFont, primaryColor, secondaryColor);
          break;
        case ResumeTemplateType.business:
          _buildBusinessTemplate(pdf, resume, profile, customFont, primaryColor, secondaryColor);
          break;
        case ResumeTemplateType.creative:
          _buildCreativeTemplate(pdf, resume, profile, customFont, primaryColor, secondaryColor);
          break;
        case ResumeTemplateType.academic:
          _buildAcademicTemplate(pdf, resume, profile, customFont, primaryColor, secondaryColor);
          break;
      }

      // Save to temporary file
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/resume_${resume.id}_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      print('[ResumeService] PDF generated successfully at: ${file.path}');
      return file;
    } catch (e) {
      print('[ResumeService] generateResumePDF error: $e');
      rethrow;
    }
  }

  /// Download PDF to device
  Future<String> downloadResumePDF({
    required ResumeDoc resume,
    required UserProfile profile,
  }) async {
    try {
      print('[ResumeService] Starting download process...');

      // Generate the PDF first
      final pdfFile = await generateResumePDF(resume: resume, profile: profile);
      print('[ResumeService] PDF generated at: ${pdfFile.path}');

      // Get the public directory based on platform
      Directory? publicDirectory;

      if (Platform.isAndroid) {
        // For Android, use Downloads directory
        publicDirectory = Directory('/storage/emulated/0/Download');

        // If that doesn't exist, try alternative
        if (!await publicDirectory.exists()) {
          publicDirectory = Directory('/storage/emulated/0/Downloads');
        }

        // If still doesn't exist, use external storage
        if (!await publicDirectory.exists()) {
          publicDirectory = await getExternalStorageDirectory();
          if (publicDirectory != null) {
            // Navigate to Downloads folder
            final pathParts = publicDirectory.path.split('/');
            final downloadsPath = '/${pathParts[1]}/${pathParts[2]}/Download';
            publicDirectory = Directory(downloadsPath);
          }
        }
      } else if (Platform.isIOS) {
        // For iOS, use Documents directory (iOS doesn't have a Downloads folder)
        publicDirectory = await getApplicationDocumentsDirectory();
      } else {
        // Fallback
        publicDirectory = await getApplicationDocumentsDirectory();
      }

      // Ensure directory exists
      if (publicDirectory != null && !await publicDirectory.exists()) {
        await publicDirectory.create(recursive: true);
      }

      if (publicDirectory == null) {
        throw Exception('Could not access storage directory');
      }

      // Create filename with sanitized resume title
      final sanitizedTitle = resume.title
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${sanitizedTitle}_$timestamp.pdf';

      // Full path for the downloaded file
      final downloadPath = '${publicDirectory.path}/$fileName';
      final downloadFile = File(downloadPath);

      // Copy the PDF to the public directory
      await pdfFile.copy(downloadPath);

      // Delete the temporary file
      await pdfFile.delete();

      print('[ResumeService] PDF downloaded successfully to: $downloadPath');
      return downloadPath;
    } catch (e) {
      print('[ResumeService] downloadResumePDF error: $e');
      rethrow;
    }
  }

  /// Alternative: Save to app's Documents directory (easier to access)
  Future<String> downloadResumeToDocuments({
    required ResumeDoc resume,
    required UserProfile profile,
  }) async {
    try {
      print('[ResumeService] Starting download to documents...');

      // Generate the PDF
      final pdfFile = await generateResumePDF(resume: resume, profile: profile);

      // Get Documents directory
      final directory = await getApplicationDocumentsDirectory();

      // Create a 'Resumes' subfolder
      final resumesFolder = Directory('${directory.path}/Resumes');
      if (!await resumesFolder.exists()) {
        await resumesFolder.create(recursive: true);
      }

      // Create filename
      final sanitizedTitle = resume.title
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${sanitizedTitle}_$timestamp.pdf';

      // Save path
      final savePath = '${resumesFolder.path}/$fileName';
      final savedFile = File(savePath);

      // Copy file
      await pdfFile.copy(savePath);
      await pdfFile.delete();

      print('[ResumeService] PDF saved to: $savePath');
      return savePath;
    } catch (e) {
      print('[ResumeService] downloadResumeToDocuments error: $e');
      rethrow;
    }
  }

  /// Best option: Use MediaStore for Android 10+ (Scoped Storage)
  Future<String> downloadResumeWithMediaStore({
    required ResumeDoc resume,
    required UserProfile profile,
  }) async {
    try {
      print('[ResumeService] Starting MediaStore download...');

      // Generate the PDF
      final pdfFile = await generateResumePDF(resume: resume, profile: profile);

      if (Platform.isAndroid) {
        // For Android 10+ (API 29+), use platform channel or external storage
        final directory = await getExternalStorageDirectory();

        if (directory != null) {
          // Navigate to public Downloads
          // Path is like: /storage/emulated/0/Android/data/com.example.app/files
          // We want: /storage/emulated/0/Download
          final pathComponents = directory.path.split('/');
          final publicDownloadPath = '/storage/emulated/0/Download';
          final publicDownload = Directory(publicDownloadPath);

          if (await publicDownload.exists()) {
            final sanitizedTitle = resume.title
                .replaceAll(RegExp(r'[^\w\s-]'), '')
                .replaceAll(RegExp(r'\s+'), '_');
            final timestamp = DateTime
                .now()
                .millisecondsSinceEpoch;
            final fileName = '${sanitizedTitle}_$timestamp.pdf';

            final downloadPath = '$publicDownloadPath/$fileName';
            await pdfFile.copy(downloadPath);
            await pdfFile.delete();

            print('[ResumeService] PDF downloaded to: $downloadPath');
            return downloadPath;
          }
        }
      }

      // Fallback to documents directory
      return await downloadResumeToDocuments(resume: resume, profile: profile);
    } catch (e) {
      print('[ResumeService] downloadResumeWithMediaStore error: $e');
      rethrow;
    }
  }

  /// Share resume PDF
  Future<void> shareResumePDF({
    required ResumeDoc resume,
    required UserProfile profile,
  }) async {
    try {
      final file = await generateResumePDF(resume: resume, profile: profile);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: resume.title,
        text: 'Sharing my resume: ${resume.title}',
      );
    } catch (e) {
      print('[ResumeService] shareResumePDF error: $e');
      rethrow;
    }
  }

  // =============================
  // PDF Template Builders
  // =============================

  void _buildTechTemplate(
      pw.Document pdf,
      ResumeDoc resume,
      UserProfile profile,
      pw.Font? font,
      PdfColor primaryColor,
      PdfColor secondaryColor,
      ) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Section with colored background
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(32),
                decoration: pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    colors: [primaryColor, primaryColor.shade(0.3)],
                    begin: pw.Alignment.topLeft,
                    end: pw.Alignment.bottomRight,
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Name
                    pw.Text(
                      profile.name ?? 'Your Name',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: resume.font.header1FontSize.toDouble(),
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    // Job Title
                    pw.Text(
                      resume.title,
                      style: pw.TextStyle(
                        font: font,
                        fontSize: resume.font.header2FontSize.toDouble() + 2,
                        color: PdfColors.white,
                      ),
                    ),
                    // Contact Information
                    if (resume.sections.personalInfo) ...[
                      pw.SizedBox(height: 20),
                      pw.Wrap(
                        spacing: 20,
                        runSpacing: 8,
                        children: [
                          if (profile.email != null)
                            _buildContactItem(
                              '✉',
                              profile.email!,
                              font,
                              resume.font.contentFontSize.toDouble() - 1,
                            ),
                          if (profile.phone != null)
                            _buildContactItem(
                              '📞',
                              profile.phone!,
                              font,
                              resume.font.contentFontSize.toDouble() - 1,
                            ),
                          if (profile.city != null || profile.country != null)
                            _buildContactItem(
                              '📍',
                              '${profile.city ?? ''}${profile.city != null && profile.country != null ? ', ' : ''}${profile.country ?? ''}',
                              font,
                              resume.font.contentFontSize.toDouble() - 1,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Content Section
              pw.Padding(
                padding: const pw.EdgeInsets.all(32),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // About Me / Professional Summary
                    if (resume.sections.aboutMe && resume.aboutMe != null) ...[
                      _buildSectionHeader('PROFESSIONAL SUMMARY', secondaryColor, font, resume.font.header2FontSize.toDouble()),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        resume.aboutMe!,
                        style: pw.TextStyle(
                          font: font,
                          fontSize: resume.font.contentFontSize.toDouble(),
                          height: 1.6,
                          color: PdfColor.fromHex('#374151'),
                        ),
                      ),
                      pw.SizedBox(height: 24),
                    ],

                    // Skills Section
                    if (resume.sections.skills && profile.skills != null && profile.skills!.isNotEmpty) ...[
                      _buildSectionHeader('SKILLS', secondaryColor, font, resume.font.header2FontSize.toDouble()),
                      pw.SizedBox(height: 12),
                      pw.Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: profile.skills!.map((skill) {
                          return pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: pw.BoxDecoration(
                              color: secondaryColor.shade(0.9),
                              borderRadius: pw.BorderRadius.circular(6),
                              border: pw.Border.all(
                                color: secondaryColor.shade(0.7),
                                width: 1,
                              ),
                            ),
                            child: pw.Row(
                              mainAxisSize: pw.MainAxisSize.min,
                              children: [
                                pw.Text(
                                  skill.name ?? '',
                                  style: pw.TextStyle(
                                    font: font,
                                    fontSize: resume.font.contentFontSize.toDouble(),
                                    color: secondaryColor,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                if (skill.level != null) ...[
                                  pw.SizedBox(width: 6),
                                  pw.Container(
                                    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: pw.BoxDecoration(
                                      color: secondaryColor,
                                      borderRadius: pw.BorderRadius.circular(3),
                                    ),
                                    child: pw.Text(
                                      'Lv ${skill.level}',
                                      style: pw.TextStyle(
                                        font: font,
                                        fontSize: resume.font.contentFontSize.toDouble() - 2,
                                        color: PdfColors.white,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ] else if (skill.levelText != null) ...[
                                  pw.SizedBox(width: 6),
                                  pw.Container(
                                    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: pw.BoxDecoration(
                                      color: secondaryColor,
                                      borderRadius: pw.BorderRadius.circular(3),
                                    ),
                                    child: pw.Text(
                                      skill.levelText!,
                                      style: pw.TextStyle(
                                        font: font,
                                        fontSize: resume.font.contentFontSize.toDouble() - 2,
                                        color: PdfColors.white,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      pw.SizedBox(height: 24),
                    ],

                    // Work Experience Section
                    if (resume.sections.experience && profile.experience != null && profile.experience!.isNotEmpty) ...[
                      _buildSectionHeader('WORK EXPERIENCE', secondaryColor, font, resume.font.header2FontSize.toDouble()),
                      pw.SizedBox(height: 12),
                      ...profile.experience!.map((exp) => _buildStyledExperience(exp, secondaryColor, font, resume)),
                    ],

                    // Education Section
                    if (resume.sections.education && profile.education != null && profile.education!.isNotEmpty) ...[
                      _buildSectionHeader('EDUCATION', secondaryColor, font, resume.font.header2FontSize.toDouble()),
                      pw.SizedBox(height: 12),
                      ...profile.education!.map((edu) => _buildStyledEducation(edu, secondaryColor, font, resume)),
                    ],

                    // References Section
                    if (resume.sections.references && resume.references.isNotEmpty) ...[
                      _buildSectionHeader('REFERENCES', secondaryColor, font, resume.font.header2FontSize.toDouble()),
                      pw.SizedBox(height: 12),
                      ...resume.references.map((ref) => _buildStyledReference(ref, font, resume)),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper: Build contact item for header
  pw.Widget _buildContactItem(String icon, String text, pw.Font? font, double fontSize) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          icon,
          style: pw.TextStyle(fontSize: fontSize + 2),
        ),
        pw.SizedBox(width: 6),
        pw.Text(
          text,
          style: pw.TextStyle(
            font: font,
            fontSize: fontSize,
            color: PdfColors.white,
          ),
        ),
      ],
    );
  }

  // Helper: Build section header
  pw.Widget _buildSectionHeader(String title, PdfColor color, pw.Font? font, double fontSize) {
    return pw.Row(
      children: [
        pw.Container(
          width: 4,
          height: 20,
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Text(
          title,
          style: pw.TextStyle(
            font: font,
            fontSize: fontSize,
            fontWeight: pw.FontWeight.bold,
            color: color,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  void _buildBusinessTemplate(
      pw.Document pdf,
      ResumeDoc resume,
      UserProfile profile,
      pw.Font? font,
      PdfColor primaryColor,
      PdfColor secondaryColor,
      ) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Section
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(32),
                color: PdfColors.white,
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Profile Circle
                    pw.Container(
                      width: 80,
                      height: 80,
                      decoration: pw.BoxDecoration(
                        color: primaryColor,
                        shape: pw.BoxShape.circle,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          _getInitials(profile.name ?? 'U'),
                          style: pw.TextStyle(
                            font: font,
                            fontSize: resume.font.header1FontSize.toDouble(),
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 24),
                    // Name and Title
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            profile.name ?? 'Your Name',
                            style: pw.TextStyle(
                              font: font,
                              fontSize: resume.font.header1FontSize.toDouble(),
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            resume.title,
                            style: pw.TextStyle(
                              font: font,
                              fontSize: resume.font.header2FontSize.toDouble() + 2,
                              color: secondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              pw.Container(
                height: 2,
                color: primaryColor,
              ),

              // Content
              pw.Padding(
                padding: const pw.EdgeInsets.all(32),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Contact Info
                    if (resume.sections.personalInfo) ...[
                      pw.Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          if (profile.email != null)
                            _buildContactRow('Email: ${profile.email}', font, resume.font.contentFontSize.toDouble()),
                          if (profile.phone != null)
                            _buildContactRow('Phone: ${profile.phone}', font, resume.font.contentFontSize.toDouble()),
                          if (profile.city != null || profile.country != null)
                            _buildContactRow(
                              'Location: ${profile.city ?? ''}${profile.city != null && profile.country != null ? ', ' : ''}${profile.country ?? ''}',
                              font,
                              resume.font.contentFontSize.toDouble(),
                            ),
                        ],
                      ),
                      pw.SizedBox(height: 24),
                    ],

                    // About Me
                    if (resume.sections.aboutMe && resume.aboutMe != null) ...[
                      _buildSectionHeaderPDF('PROFESSIONAL SUMMARY', secondaryColor, font, resume.font.header2FontSize.toDouble()),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        resume.aboutMe!,
                        style: pw.TextStyle(
                          font: font,
                          fontSize: resume.font.contentFontSize.toDouble(),
                          height: 1.6,
                        ),
                      ),
                      pw.SizedBox(height: 20),
                    ],

                    // Experience
                    if (resume.sections.experience && profile.experience != null && profile.experience!.isNotEmpty) ...[
                      _buildSectionHeaderPDF('EXPERIENCE', secondaryColor, font, resume.font.header2FontSize.toDouble()),
                      pw.SizedBox(height: 12),
                      ...profile.experience!.map((exp) => _buildStyledExperience(exp, secondaryColor, font, resume)),
                    ],

                    // Education
                    if (resume.sections.education && profile.education != null && profile.education!.isNotEmpty) ...[
                      _buildSectionHeaderPDF('EDUCATION', secondaryColor, font, resume.font.header2FontSize.toDouble()),
                      pw.SizedBox(height: 12),
                      ...profile.education!.map((edu) => _buildStyledEducation(edu, secondaryColor, font, resume)),
                    ],

                    // Skills
                    if (resume.sections.skills && profile.skills != null && profile.skills!.isNotEmpty) ...[
                      _buildSectionHeaderPDF('SKILLS', secondaryColor, font, resume.font.header2FontSize.toDouble()),
                      pw.SizedBox(height: 12),
                      pw.Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: profile.skills!.map((skill) {
                          return pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: secondaryColor),
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Text(
                              skill.name ?? '',
                              style: pw.TextStyle(
                                font: font,
                                fontSize: resume.font.contentFontSize.toDouble(),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    // References
                    if (resume.sections.references && resume.references.isNotEmpty) ...[
                      pw.SizedBox(height: 20),
                      _buildSectionHeaderPDF('REFERENCES', secondaryColor, font, resume.font.header2FontSize.toDouble()),
                      pw.SizedBox(height: 12),
                      ...resume.references.map((ref) => _buildStyledReference(ref, font, resume)),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _buildCreativeTemplate(
      pw.Document pdf,
      ResumeDoc resume,
      UserProfile profile,
      pw.Font? font,
      PdfColor primaryColor,
      PdfColor secondaryColor,
      ) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left Sidebar
              pw.Container(
                width: 150,
                color: primaryColor,
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.SizedBox(height: 20),
                      // Profile Circle
                      pw.Container(
                        width: 80,
                        height: 80,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          shape: pw.BoxShape.circle,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            _getInitials(profile.name ?? 'U'),
                            style: pw.TextStyle(
                              font: font,
                              fontSize: resume.font.header1FontSize.toDouble(),
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 24),

                      // Contact
                      if (resume.sections.personalInfo) ...[
                        pw.Text(
                          'CONTACT',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                            letterSpacing: 1,
                          ),
                        ),
                        pw.SizedBox(height: 12),
                        if (profile.email != null) ...[
                          pw.Text(
                            profile.email!,
                            style: pw.TextStyle(
                              font: font,
                              fontSize: resume.font.contentFontSize.toDouble() - 1,
                              color: PdfColors.white,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.SizedBox(height: 8),
                        ],
                        if (profile.phone != null) ...[
                          pw.Text(
                            profile.phone!,
                            style: pw.TextStyle(
                              font: font,
                              fontSize: resume.font.contentFontSize.toDouble() - 1,
                              color: PdfColors.white,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.SizedBox(height: 8),
                        ],
                      ],

                      // Skills
                      if (resume.sections.skills && profile.skills != null && profile.skills!.isNotEmpty) ...[
                        pw.SizedBox(height: 16),
                        pw.Text(
                          'SKILLS',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                            letterSpacing: 1,
                          ),
                        ),
                        pw.SizedBox(height: 12),
                        ...profile.skills!.take(8).map((skill) {
                          return pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 8),
                            child: pw.Text(
                              skill.name ?? '',
                              style: pw.TextStyle(
                                font: font,
                                fontSize: resume.font.contentFontSize.toDouble() - 1,
                                color: PdfColors.white,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),

              // Main Content
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(32),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Name & Title
                      pw.Text(
                        profile.name ?? 'Your Name',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: resume.font.header1FontSize.toDouble() + 4,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        resume.title,
                        style: pw.TextStyle(
                          font: font,
                          fontSize: resume.font.header2FontSize.toDouble() + 2,
                          color: secondaryColor,
                        ),
                      ),
                      pw.SizedBox(height: 24),

                      // About Me
                      if (resume.sections.aboutMe && resume.aboutMe != null) ...[
                        _buildSectionHeaderPDF('ABOUT', secondaryColor, font, resume.font.header2FontSize.toDouble()),
                        pw.SizedBox(height: 12),
                        pw.Text(
                          resume.aboutMe!,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: resume.font.contentFontSize.toDouble(),
                            height: 1.6,
                          ),
                        ),
                        pw.SizedBox(height: 20),
                      ],

                      // Experience
                      if (resume.sections.experience && profile.experience != null && profile.experience!.isNotEmpty) ...[
                        _buildSectionHeaderPDF('EXPERIENCE', secondaryColor, font, resume.font.header2FontSize.toDouble()),
                        pw.SizedBox(height: 12),
                        ...profile.experience!.map((exp) => _buildStyledExperience(exp, secondaryColor, font, resume)),
                      ],

                      // Education
                      if (resume.sections.education && profile.education != null && profile.education!.isNotEmpty) ...[
                        _buildSectionHeaderPDF('EDUCATION', secondaryColor, font, resume.font.header2FontSize.toDouble()),
                        pw.SizedBox(height: 12),
                        ...profile.education!.map((edu) => _buildStyledEducation(edu, secondaryColor, font, resume)),
                      ],

                      // References
                      if (resume.sections.references && resume.references.isNotEmpty) ...[
                        _buildSectionHeaderPDF('REFERENCES', secondaryColor, font, resume.font.header2FontSize.toDouble()),
                        pw.SizedBox(height: 12),
                        ...resume.references.map((ref) => _buildStyledReference(ref, font, resume)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _buildAcademicTemplate(
      pw.Document pdf,
      ResumeDoc resume,
      UserProfile profile,
      pw.Font? font,
      PdfColor primaryColor,
      PdfColor secondaryColor,
      ) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Centered Header
              pw.Column(
                children: [
                  pw.Text(
                    profile.name ?? 'Your Name',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: resume.font.header1FontSize.toDouble() + 4,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    resume.title,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: resume.font.header2FontSize.toDouble() + 2,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  if (resume.sections.personalInfo) ...[
                    pw.SizedBox(height: 12),
                    pw.Wrap(
                      alignment: pw.WrapAlignment.center,
                      spacing: 12,
                      children: [
                        if (profile.email != null)
                          pw.Text(
                            profile.email!,
                            style: pw.TextStyle(
                              font: font,
                              fontSize: resume.font.contentFontSize.toDouble(),
                            ),
                          ),
                        if (profile.phone != null)
                          pw.Text(
                            profile.phone!,
                            style: pw.TextStyle(
                              font: font,
                              fontSize: resume.font.contentFontSize.toDouble(),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),

              pw.SizedBox(height: 24),
              pw.Container(height: 2, color: primaryColor),
              pw.SizedBox(height: 24),

              // Content
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // About Me
                  if (resume.sections.aboutMe && resume.aboutMe != null) ...[
                    _buildSectionHeaderPDF('SUMMARY', secondaryColor, font, resume.font.header2FontSize.toDouble()),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      resume.aboutMe!,
                      style: pw.TextStyle(
                        font: font,
                        fontSize: resume.font.contentFontSize.toDouble(),
                        height: 1.7,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                  ],

                  // Education
                  if (resume.sections.education && profile.education != null && profile.education!.isNotEmpty) ...[
                    _buildSectionHeaderPDF('EDUCATION', secondaryColor, font, resume.font.header2FontSize.toDouble()),
                    pw.SizedBox(height: 12),
                    ...profile.education!.map((edu) => _buildStyledEducation(edu, primaryColor, font, resume)),
                  ],

                  // Experience
                  if (resume.sections.experience && profile.experience != null && profile.experience!.isNotEmpty) ...[
                    _buildSectionHeaderPDF('EXPERIENCE', secondaryColor, font, resume.font.header2FontSize.toDouble()),
                    pw.SizedBox(height: 12),
                    ...profile.experience!.map((exp) => _buildStyledExperience(exp, primaryColor, font, resume)),
                  ],

                  // Skills
                  if (resume.sections.skills && profile.skills != null && profile.skills!.isNotEmpty) ...[
                    _buildSectionHeaderPDF('SKILLS', secondaryColor, font, resume.font.header2FontSize.toDouble()),
                    pw.SizedBox(height: 12),
                    pw.Wrap(
                      spacing: 8,
                      children: profile.skills!.map((skill) {
                        return pw.Text(
                          '${skill.name ?? ''} • ',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: resume.font.contentFontSize.toDouble(),
                          ),
                        );
                      }).toList(),
                    ),
                    pw.SizedBox(height: 20),
                  ],

                  // References
                  if (resume.sections.references && resume.references.isNotEmpty) ...[
                    _buildSectionHeaderPDF('REFERENCES', secondaryColor, font, resume.font.header2FontSize.toDouble()),
                    pw.SizedBox(height: 12),
                    ...resume.references.map((ref) => _buildStyledReference(ref, font, resume)),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  pw.Widget _buildContactRow(String text, pw.Font? font, double fontSize) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        font: font,
        fontSize: fontSize,
      ),
    );
  }

  pw.Widget _buildSectionHeaderPDF(String title, PdfColor color, pw.Font? font, double fontSize) {
    return pw.Row(
      children: [
        pw.Container(
          width: 4,
          height: 18,
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Text(
          title,
          style: pw.TextStyle(
            font: font,
            fontSize: fontSize,
            fontWeight: pw.FontWeight.bold,
            color: color,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  // =============================
  // Section Builders
  // =============================

  pw.Widget _buildStyledExperience(
      Experience exp,
      PdfColor color,
      pw.Font? font,
      ResumeDoc resume,
      ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Bullet point
          pw.Container(
            width: 8,
            height: 8,
            margin: const pw.EdgeInsets.only(top: 6),
            decoration: pw.BoxDecoration(
              color: color,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.SizedBox(width: 12),
          // Content
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Job Title
                pw.Text(
                  exp.jobTitle ?? '',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: resume.font.contentFontSize.toDouble() + 2,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#111827'),
                  ),
                ),
                pw.SizedBox(height: 4),
                // Company & Employment Type
                pw.Row(
                  children: [
                    pw.Text(
                      exp.company ?? '',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: resume.font.contentFontSize.toDouble(),
                        color: color,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (exp.employmentType != null) ...[
                      pw.Text(
                        ' • ${exp.employmentType}',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: resume.font.contentFontSize.toDouble(),
                          color: PdfColor.fromHex('#6B7280'),
                        ),
                      ),
                    ],
                  ],
                ),
                // Date & Location
                if (exp.startDate != null || exp.endDate != null || exp.city != null) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '${_formatDateRange(exp.startDate, exp.endDate, exp.isCurrent)}${(exp.city != null || exp.country != null) ? ' • ${exp.city ?? ''}${exp.city != null && exp.country != null ? ', ' : ''}${exp.country ?? ''}' : ''}',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: resume.font.contentFontSize.toDouble() - 1,
                      color: PdfColor.fromHex('#9CA3AF'),
                    ),
                  ),
                ],
                // Description
                if (exp.description != null) ...[
                  pw.SizedBox(height: 8),
                  pw.Text(
                    exp.description!,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: resume.font.contentFontSize.toDouble(),
                      height: 1.5,
                      color: PdfColor.fromHex('#374151'),
                    ),
                  ),
                ],
                // Skills Used
                if (exp.achievements?.skillsUsed != null && exp.achievements!.skillsUsed!.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  pw.Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: exp.achievements!.skillsUsed!.map((skill) {
                      return pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#F3F4F6'),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          skill,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: resume.font.contentFontSize.toDouble() - 1,
                            color: PdfColor.fromHex('#4B5563'),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Build styled education entry
  pw.Widget _buildStyledEducation(
      AcademicRecord edu,
      PdfColor color,
      pw.Font? font,
      ResumeDoc resume,
      ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Bullet point
          pw.Container(
            width: 8,
            height: 8,
            margin: const pw.EdgeInsets.only(top: 6),
            decoration: pw.BoxDecoration(
              color: color,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.SizedBox(width: 12),
          // Content
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Institution
                pw.Text(
                  edu.institution ?? '',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: resume.font.contentFontSize.toDouble() + 1,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#111827'),
                  ),
                ),
                pw.SizedBox(height: 4),
                // Degree
                pw.Text(
                  '${edu.level ?? ''} in ${edu.major ?? ''}',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: resume.font.contentFontSize.toDouble(),
                    color: PdfColor.fromHex('#374151'),
                  ),
                ),
                // Date
                if (edu.startDate != null || edu.endDate != null) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    _formatDateRange(edu.startDate, edu.endDate, edu.isCurrent),
                    style: pw.TextStyle(
                      font: font,
                      fontSize: resume.font.contentFontSize.toDouble() - 1,
                      color: PdfColor.fromHex('#9CA3AF'),
                    ),
                  ),
                ],
                // CGPA
                if (edu.cgpa != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: color.shade(0.9),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'CGPA: ${edu.cgpa}',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: resume.font.contentFontSize.toDouble() - 1,
                        color: color,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

// Helper: Build styled reference entry
  pw.Widget _buildStyledReference(
      ResumeReference ref,
      pw.Font? font,
      ResumeDoc resume,
      ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F9FAFB'),
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(
          color: PdfColor.fromHex('#E5E7EB'),
          width: 1,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            ref.name,
            style: pw.TextStyle(
              font: font,
              fontSize: resume.font.contentFontSize.toDouble(),
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#111827'),
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            ref.position,
            style: pw.TextStyle(
              font: font,
              fontSize: resume.font.contentFontSize.toDouble() - 1,
              color: PdfColor.fromHex('#6B7280'),
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            ref.contact,
            style: pw.TextStyle(
              font: font,
              fontSize: resume.font.contentFontSize.toDouble() - 1,
              color: PdfColor.fromHex('#9CA3AF'),
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Format date range
  String _formatDateRange(dynamic start, dynamic end, bool? isCurrent) {
    String formatDate(dynamic date) {
      if (date == null) return '';
      if (date is Timestamp) {
        final dt = date.toDate();
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${months[dt.month - 1]} ${dt.year}';
      }
      return date.toString();
    }

    final startStr = formatDate(start);
    final endStr = isCurrent == true ? 'Present' : formatDate(end);

    if (startStr.isEmpty && endStr.isEmpty) return '';
    if (startStr.isEmpty) return endStr;
    if (endStr.isEmpty) return startStr;

    return '$startStr - $endStr';
  }

  // =============================
  // Helper Functions
  // =============================

  PdfColor _parseColor(String hex) {
    final hexColor = hex.replaceAll('#', '');
    final r = int.parse(hexColor.substring(0, 2), radix: 16);
    final g = int.parse(hexColor.substring(2, 4), radix: 16);
    final b = int.parse(hexColor.substring(4, 6), radix: 16);
    return PdfColor(r / 255, g / 255, b / 255);
  }
}