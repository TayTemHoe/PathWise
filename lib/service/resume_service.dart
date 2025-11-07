// lib/services/resume_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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

      // Load custom font if needed
      final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
      final ttf = pw.Font.ttf(fontData);

      // Parse colors
      final primaryColor = _parseColor(resume.theme.primaryColorHex);
      final secondaryColor = _parseColor(resume.theme.secondaryColorHex);

      // Build PDF based on template
      switch (resume.template) {
        case ResumeTemplateType.tech:
          _buildTechTemplate(pdf, resume, profile, ttf, primaryColor, secondaryColor);
          break;
        case ResumeTemplateType.business:
          _buildBusinessTemplate(pdf, resume, profile, ttf, primaryColor, secondaryColor);
          break;
        case ResumeTemplateType.creative:
          _buildCreativeTemplate(pdf, resume, profile, ttf, primaryColor, secondaryColor);
          break;
        case ResumeTemplateType.academic:
          _buildAcademicTemplate(pdf, resume, profile, ttf, primaryColor, secondaryColor);
          break;
      }

      // Save to temporary file
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/resume_${resume.id}_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

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
      final file = await generateResumePDF(resume: resume, profile: profile);

      // Move to downloads directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${resume.title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final savedFile = File('${directory.path}/$fileName');
      await file.copy(savedFile.path);

      return savedFile.path;
    } catch (e) {
      print('[ResumeService] downloadResumePDF error: $e');
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
      pw.Font font,
      PdfColor primaryColor,
      PdfColor secondaryColor,
      ) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                color: primaryColor,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      profile.name ?? 'Your Name',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: resume.font.header1FontSize.toDouble(),
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      resume.title,
                      style: pw.TextStyle(
                        font: font,
                        fontSize: resume.font.header2FontSize.toDouble(),
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Personal Info Section
              if (resume.sections.personalInfo) ...[
                _buildPersonalInfoSection(resume, profile, font, secondaryColor),
                pw.SizedBox(height: 15),
              ],

              // About Me Section
              if (resume.sections.aboutMe && resume.aboutMe != null) ...[
                _buildSection('About Me', resume.aboutMe!, resume, font, secondaryColor),
                pw.SizedBox(height: 15),
              ],

              // Skills Section
              if (resume.sections.skills && profile.skills != null) ...[
                _buildSkillsSection(profile.skills!, resume, font, secondaryColor),
                pw.SizedBox(height: 15),
              ],

              // Education Section
              if (resume.sections.education && profile.education != null) ...[
                _buildEducationSection(profile.education!, resume, font, secondaryColor),
                pw.SizedBox(height: 15),
              ],

              // Experience Section
              if (resume.sections.experience && profile.experience != null) ...[
                _buildExperienceSection(profile.experience!, resume, font, secondaryColor),
                pw.SizedBox(height: 15),
              ],

              // References Section
              if (resume.sections.references && resume.references.isNotEmpty) ...[
                _buildReferencesSection(resume.references, resume, font, secondaryColor),
              ],
            ],
          );
        },
      ),
    );
  }

  void _buildBusinessTemplate(
      pw.Document pdf,
      ResumeDoc resume,
      UserProfile profile,
      pw.Font font,
      PdfColor primaryColor,
      PdfColor secondaryColor,
      ) {
    // Similar structure to tech template but with different styling
    _buildTechTemplate(pdf, resume, profile, font, primaryColor, secondaryColor);
  }

  void _buildCreativeTemplate(
      pw.Document pdf,
      ResumeDoc resume,
      UserProfile profile,
      pw.Font font,
      PdfColor primaryColor,
      PdfColor secondaryColor,
      ) {
    // Similar structure with creative styling
    _buildTechTemplate(pdf, resume, profile, font, primaryColor, secondaryColor);
  }

  void _buildAcademicTemplate(
      pw.Document pdf,
      ResumeDoc resume,
      UserProfile profile,
      pw.Font font,
      PdfColor primaryColor,
      PdfColor secondaryColor,
      ) {
    // Similar structure with academic styling
    _buildTechTemplate(pdf, resume, profile, font, primaryColor, secondaryColor);
  }

  // =============================
  // Section Builders
  // =============================

  pw.Widget _buildPersonalInfoSection(
      ResumeDoc resume,
      UserProfile profile,
      pw.Font font,
      PdfColor color,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Contact Information',
          style: pw.TextStyle(
            font: font,
            fontSize: resume.font.header2FontSize.toDouble(),
            color: color,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        if (profile.email != null)
          pw.Text('Email: ${profile.email}', style: pw.TextStyle(font: font, fontSize: resume.font.contentFontSize.toDouble())),
        if (profile.phone != null)
          pw.Text('Phone: ${profile.phone}', style: pw.TextStyle(font: font, fontSize: resume.font.contentFontSize.toDouble())),
        if (profile.city != null || profile.country != null)
          pw.Text(
            'Location: ${profile.city ?? ''}${profile.city != null && profile.country != null ? ', ' : ''}${profile.country ?? ''}',
            style: pw.TextStyle(font: font, fontSize: resume.font.contentFontSize.toDouble()),
          ),
      ],
    );
  }

  pw.Widget _buildSection(
      String title,
      String content,
      ResumeDoc resume,
      pw.Font font,
      PdfColor color,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            font: font,
            fontSize: resume.font.header2FontSize.toDouble(),
            color: color,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          content,
          style: pw.TextStyle(font: font, fontSize: resume.font.contentFontSize.toDouble()),
        ),
      ],
    );
  }

  pw.Widget _buildSkillsSection(
      List<Skill> skills,
      ResumeDoc resume,
      pw.Font font,
      PdfColor color,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Skills',
          style: pw.TextStyle(
            font: font,
            fontSize: resume.font.header2FontSize.toDouble(),
            color: color,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        ...skills.map((skill) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: pw.Text(
            '• ${skill.name} ${skill.levelText != null ? '(${skill.levelText})' : ''}',
            style: pw.TextStyle(font: font, fontSize: resume.font.contentFontSize.toDouble()),
          ),
        )),
      ],
    );
  }

  pw.Widget _buildEducationSection(
      List<Education> education,
      ResumeDoc resume,
      pw.Font font,
      PdfColor color,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Education',
          style: pw.TextStyle(
            font: font,
            fontSize: resume.font.header2FontSize.toDouble(),
            color: color,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        ...education.map((edu) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                edu.institution ?? '',
                style: pw.TextStyle(
                  font: font,
                  fontSize: resume.font.contentFontSize.toDouble(),
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '${edu.degreeLevel ?? ''} in ${edu.fieldOfStudy ?? ''}',
                style: pw.TextStyle(font: font, fontSize: resume.font.contentFontSize.toDouble()),
              ),
              if (edu.gpa != null)
                pw.Text(
                  'GPA: ${edu.gpa}',
                  style: pw.TextStyle(font: font, fontSize: resume.font.contentFontSize.toDouble()),
                ),
            ],
          ),
        )),
      ],
    );
  }

  pw.Widget _buildExperienceSection(
      List<Experience> experience,
      ResumeDoc resume,
      pw.Font font,
      PdfColor color,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Experience',
          style: pw.TextStyle(
            font: font,
            fontSize: resume.font.header2FontSize.toDouble(),
            color: color,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        ...experience.map((exp) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                exp.jobTitle ?? '',
                style: pw.TextStyle(
                  font: font,
                  fontSize: resume.font.contentFontSize.toDouble(),
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '${exp.company ?? ''} • ${exp.employmentType ?? ''}',
                style: pw.TextStyle(font: font, fontSize: resume.font.contentFontSize.toDouble()),
              ),
              if (exp.description != null)
                pw.Text(
                  exp.description!,
                  style: pw.TextStyle(font: font, fontSize: resume.font.contentFontSize.toDouble()),
                ),
            ],
          ),
        )),
      ],
    );
  }

  pw.Widget _buildReferencesSection(
      List<ResumeReference> references,
      ResumeDoc resume,
      pw.Font font,
      PdfColor color,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'References',
          style: pw.TextStyle(
            font: font,
            fontSize: resume.font.header2FontSize.toDouble(),
            color: color,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        ...references.map((ref) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 5),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                ref.name,
                style: pw.TextStyle(
                  font: font,
                  fontSize: resume.font.contentFontSize.toDouble(),
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                ref.position,
                style: pw.TextStyle(font: font, fontSize: resume.font.contentFontSize.toDouble()),
              ),
              pw.Text(
                ref.contact,
                style: pw.TextStyle(font: font, fontSize: resume.font.contentFontSize.toDouble()),
              ),
            ],
          ),
        )),
      ],
    );
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