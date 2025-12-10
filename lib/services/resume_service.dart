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
import '../model/user_profile.dart'; // Ensure this exports UserModel

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

  Future<File> generateResumePDF({
    required ResumeDoc resume,
    required UserModel profile,
    List<EnglishTest>? englishTests,
  }) async {
    try {
      final pdf = pw.Document();

      pw.Font? customFont;
      try {
        final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
        customFont = pw.Font.ttf(fontData);
      } catch (e) {
        print('[ResumeService] Warning: Could not load custom font, using default: $e');
      }

      final primaryColor = _parseColor(resume.theme.primaryColorHex);
      final secondaryColor = _parseColor(resume.theme.secondaryColorHex);
      final eTests = englishTests ?? [];

      switch (resume.template) {
        case ResumeTemplateType.tech:
          _buildTechTemplate(pdf, resume, profile, eTests, customFont, primaryColor, secondaryColor);
          break;
        case ResumeTemplateType.business:
          _buildBusinessTemplate(pdf, resume, profile, eTests, customFont, primaryColor, secondaryColor);
          break;
        case ResumeTemplateType.creative:
          _buildCreativeTemplate(pdf, resume, profile, eTests, customFont, primaryColor, secondaryColor);
          break;
        case ResumeTemplateType.academic:
          _buildAcademicTemplate(pdf, resume, profile, eTests, customFont, primaryColor, secondaryColor);
          break;
      }

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/resume_${resume.id}_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      return file;
    } catch (e) {
      print('[ResumeService] generateResumePDF error: $e');
      rethrow;
    }
  }

  Future<String> downloadResumePDF({
    required ResumeDoc resume,
    required UserModel profile,
    List<EnglishTest>? englishTests,
  }) async {
    try {
      final pdfFile = await generateResumePDF(resume: resume, profile: profile, englishTests: englishTests);

      Directory? publicDirectory;
      if (Platform.isAndroid) {
        publicDirectory = Directory('/storage/emulated/0/Download');
        if (!await publicDirectory.exists()) publicDirectory = Directory('/storage/emulated/0/Downloads');
        if (!await publicDirectory.exists()) {
          final ext = await getExternalStorageDirectory();
          if(ext != null) {
            final parts = ext.path.split('/');
            publicDirectory = Directory('/${parts[1]}/${parts[2]}/Download');
          }
        }
      } else {
        publicDirectory = await getApplicationDocumentsDirectory();
      }

      if (publicDirectory != null && !await publicDirectory.exists()) {
        await publicDirectory.create(recursive: true);
      }

      if (publicDirectory == null) throw Exception('Could not access storage directory');

      final sanitizedTitle = resume.title.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(RegExp(r'\s+'), '_');
      final downloadPath = '${publicDirectory.path}/${sanitizedTitle}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      await pdfFile.copy(downloadPath);
      await pdfFile.delete();

      return downloadPath;
    } catch (e) {
      rethrow;
    }
  }

  /// Share resume PDF
  Future<void> shareResumePDF({
    required ResumeDoc resume,
    required UserModel profile,
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
      UserModel profile,
      List<EnglishTest> englishTests,
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
              // Header
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
                    pw.Text(
                      profile.name,
                      style: pw.TextStyle(font: font, fontSize: resume.font.header1FontSize.toDouble(), fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      resume.title,
                      style: pw.TextStyle(font: font, fontSize: resume.font.header2FontSize.toDouble() + 2, color: PdfColors.white),
                    ),
                    if (resume.sections.personalInfo) ...[
                      pw.SizedBox(height: 20),
                      pw.Wrap(
                        spacing: 20,
                        runSpacing: 8,
                        children: [
                          if (profile.email != null) _buildContactItem('✉', profile.email!, font, resume.font.contentFontSize.toDouble()),
                          if (profile.phone != null) _buildContactItem('📞', profile.phone!, font, resume.font.contentFontSize.toDouble()),
                          if (profile.city != null || profile.country != null)
                            _buildContactItem('📍', '${profile.city ?? ''}, ${profile.country ?? ''}', font, resume.font.contentFontSize.toDouble()),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Content
              pw.Padding(
                padding: const pw.EdgeInsets.all(32),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (resume.sections.aboutMe && resume.aboutMe != null) ...[
                      _buildSectionHeader('PROFESSIONAL SUMMARY', secondaryColor, font, resume.font.header2FontSize.toDouble()),
                      pw.SizedBox(height: 12),
                      pw.Text(resume.aboutMe!, style: pw.TextStyle(font: font, fontSize: resume.font.contentFontSize.toDouble())),
                      pw.SizedBox(height: 24),
                    ],

                    if (resume.sections.skills && profile.skills != null && profile.skills!.isNotEmpty) ...[
                      _buildSectionHeader('SKILLS', secondaryColor, font, resume.font.header2FontSize.toDouble()),
                      pw.SizedBox(height: 12),
                      pw.Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: profile.skills!.map((skill) => _buildSkillChip(skill, secondaryColor, font, resume)).toList(),
                      ),
                      pw.SizedBox(height: 24),
                    ],

                    if (englishTests.isNotEmpty) ...[
                      _buildSectionHeader('LANGUAGES & PROFICIENCY', secondaryColor, font, resume.font.header2FontSize.toDouble()),
                      pw.SizedBox(height: 12),
                      ...englishTests.map((test) => _buildStyledEnglishTest(test, secondaryColor, font, resume)),
                      pw.SizedBox(height: 24),
                    ],

                    if (resume.sections.experience && profile.experience != null && profile.experience!.isNotEmpty) ...[
                      _buildSectionHeader('WORK EXPERIENCE', secondaryColor, font, resume.font.header2FontSize.toDouble()),
                      pw.SizedBox(height: 12),
                      ...profile.experience!.map((exp) => _buildStyledExperience(exp, secondaryColor, font, resume)),
                    ],

                    if (resume.sections.education && profile.education != null && profile.education!.isNotEmpty) ...[
                      _buildSectionHeader('EDUCATION', secondaryColor, font, resume.font.header2FontSize.toDouble()),
                      pw.SizedBox(height: 12),
                      ...profile.education!.map((edu) => _buildStyledEducation(edu, secondaryColor, font, resume)),
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

  void _buildBusinessTemplate(
      pw.Document pdf,
      ResumeDoc resume,
      UserModel profile,
      List<EnglishTest> englishTests,
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
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(32),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: 60, height: 60,
                      decoration: pw.BoxDecoration(color: primaryColor, shape: pw.BoxShape.circle),
                      child: pw.Center(child: pw.Text(_getInitials(profile.name), style: pw.TextStyle(color: PdfColors.white, fontSize: 24, fontWeight: pw.FontWeight.bold, font: font))),
                    ),
                    pw.SizedBox(width: 20),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(profile.name, style: pw.TextStyle(font: font, fontSize: 24, fontWeight: pw.FontWeight.bold)),
                          pw.Text(resume.title, style: pw.TextStyle(font: font, fontSize: 14, color: secondaryColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.Container(height: 2, color: primaryColor),

              pw.Padding(
                padding: const pw.EdgeInsets.all(32),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (resume.sections.personalInfo) ...[
                      pw.Wrap(
                        spacing: 16, runSpacing: 8,
                        children: [
                          if (profile.email != null) _buildContactRow('Email: ${profile.email}', font, 10),
                          if (profile.phone != null) _buildContactRow('Phone: ${profile.phone}', font, 10),
                          if (profile.city != null || profile.country != null)
                            _buildContactRow('Loc: ${profile.city ?? ''}, ${profile.country ?? ''}', font, 10),
                        ],
                      ),
                      pw.SizedBox(height: 24),
                    ],

                    if (resume.sections.aboutMe && resume.aboutMe != null) ...[
                      _buildSectionHeaderPDF('PROFILE', secondaryColor, font, 14),
                      pw.SizedBox(height: 8),
                      pw.Text(resume.aboutMe!, style: pw.TextStyle(font: font)),
                      pw.SizedBox(height: 16),
                    ],

                    if (resume.sections.skills && profile.skills != null && profile.skills!.isNotEmpty) ...[
                      _buildSectionHeaderPDF('SKILLS', secondaryColor, font, 14),
                      pw.SizedBox(height: 8),
                      pw.Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: profile.skills!.map((skill) {
                          return pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: secondaryColor),
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Text(skill.name ?? '', style: pw.TextStyle(font: font, fontSize: 10)),
                          );
                        }).toList(),
                      ),
                      pw.SizedBox(height: 16),
                    ],

                    if (englishTests.isNotEmpty) ...[
                      _buildSectionHeaderPDF('LANGUAGES & PROFICIENCY', secondaryColor, font, 14),
                      pw.SizedBox(height: 8),
                      ...englishTests.map((test) => _buildStyledEnglishTest(test, secondaryColor, font, resume)),
                      pw.SizedBox(height: 16),
                    ],

                    if (resume.sections.education && profile.education != null && profile.education!.isNotEmpty) ...[
                      _buildSectionHeaderPDF('EDUCATION', secondaryColor, font, 14),
                      pw.SizedBox(height: 8),
                      ...profile.education!.map((edu) => _buildStyledEducation(edu, secondaryColor, font, resume)),
                      pw.SizedBox(height: 16),
                    ],

                    if (resume.sections.experience && profile.experience != null && profile.experience!.isNotEmpty) ...[
                      _buildSectionHeaderPDF('EXPERIENCE', secondaryColor, font, 14),
                      pw.SizedBox(height: 8),
                      ...profile.experience!.map((exp) => _buildStyledExperience(exp, secondaryColor, font, resume)),
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
      UserModel profile,
      List<EnglishTest> englishTests,
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
              // Sidebar
              pw.Container(
                width: 180,
                color: primaryColor,
                padding: const pw.EdgeInsets.all(20),
                child: pw.Column(
                  children: [
                    pw.SizedBox(height: 40),
                    pw.Text(profile.name, style: pw.TextStyle(font: font, color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                    pw.SizedBox(height: 20),

                    if (resume.sections.personalInfo) ...[
                      pw.Text('CONTACT', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 10),
                      if (profile.email != null)
                        pw.Text(profile.email!, style: pw.TextStyle(color: PdfColors.white, fontSize: 10), textAlign: pw.TextAlign.center),
                      if (profile.phone != null) ...[
                        pw.SizedBox(height: 6),
                        pw.Text(profile.phone!, style: pw.TextStyle(color: PdfColors.white, fontSize: 10), textAlign: pw.TextAlign.center),
                      ],
                      if (profile.city != null || profile.country != null) ...[
                        pw.SizedBox(height: 6),
                        pw.Text('${profile.city ?? ''}, ${profile.country ?? ''}', style: pw.TextStyle(color: PdfColors.white, fontSize: 10), textAlign: pw.TextAlign.center),
                      ],
                      pw.SizedBox(height: 20),
                    ],

                    if (resume.sections.skills && profile.skills != null && profile.skills!.isNotEmpty) ...[
                      pw.Text('SKILLS', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 10),
                      ...profile.skills!.take(10).map((s) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Text(s.name ?? '', style: pw.TextStyle(color: PdfColors.white, fontSize: 10), textAlign: pw.TextAlign.center)
                      )),
                    ],

                    pw.SizedBox(height: 20),

                    if (englishTests.isNotEmpty) ...[
                      pw.Text('LANGUAGES', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 10),
                      ...englishTests.map((t) => pw.Text('${t.type}: ${t.result}', style: pw.TextStyle(color: PdfColors.white, fontSize: 10), textAlign: pw.TextAlign.center)),
                    ],
                  ],
                ),
              ),

              // Main Content
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(32),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(resume.title, style: pw.TextStyle(font: font, fontSize: 28, color: secondaryColor)),
                      pw.SizedBox(height: 20),

                      if (resume.sections.aboutMe && resume.aboutMe != null) ...[
                        _buildSectionHeaderPDF('ABOUT ME', secondaryColor, font, 14),
                        pw.SizedBox(height: 8),
                        pw.Text(resume.aboutMe!, style: pw.TextStyle(font: font)),
                        pw.SizedBox(height: 20),
                      ],

                      if (resume.sections.experience && profile.experience != null && profile.experience!.isNotEmpty) ...[
                        _buildSectionHeaderPDF('WORK HISTORY', secondaryColor, font, 14),
                        pw.SizedBox(height: 10),
                        ...profile.experience!.map((e) => _buildStyledExperience(e, secondaryColor, font, resume)),
                      ],

                      if (resume.sections.education && profile.education != null && profile.education!.isNotEmpty) ...[
                        _buildSectionHeaderPDF('EDUCATION', secondaryColor, font, 14),
                        pw.SizedBox(height: 10),
                        ...profile.education!.map((e) => _buildStyledEducation(e, secondaryColor, font, resume)),
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
      UserModel profile,
      List<EnglishTest> englishTests,
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
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(profile.name, style: pw.TextStyle(font: font, fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.Text(resume.title, style: pw.TextStyle(font: font, fontSize: 14)),
                    pw.SizedBox(height: 8),
                    pw.Text('${profile.email ?? ''} | ${profile.phone ?? ''}', style: pw.TextStyle(font: font, fontSize: 10)),
                    if (profile.city != null || profile.country != null)
                      pw.Text('${profile.city ?? ''}, ${profile.country ?? ''}', style: pw.TextStyle(font: font, fontSize: 10)),
                  ],
                ),
              ),
              pw.Divider(color: primaryColor),
              pw.SizedBox(height: 20),

              // Education First for Academic
              if (resume.sections.education && profile.education != null && profile.education!.isNotEmpty) ...[
                _buildSectionHeaderPDF('EDUCATION', secondaryColor, font, 12),
                pw.SizedBox(height: 10),
                ...profile.education!.map((e) => _buildStyledEducation(e, primaryColor, font, resume)),
                pw.SizedBox(height: 16),
              ],

              if (resume.sections.skills && profile.skills != null && profile.skills!.isNotEmpty) ...[
                _buildSectionHeaderPDF('SKILLS & EXPERTISE', secondaryColor, font, 12),
                pw.SizedBox(height: 8),
                pw.Wrap(
                  spacing: 12,
                  children: profile.skills!.map((skill) {
                    return pw.Text(
                        '• ${skill.name ?? ''}',
                        style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey800)
                    );
                  }).toList(),
                ),
                pw.SizedBox(height: 16),
              ],

              if (englishTests.isNotEmpty) ...[
                _buildSectionHeaderPDF('LANGUAGES & PROFICIENCY', secondaryColor, font, 12),
                pw.SizedBox(height: 10),
                ...englishTests.map((test) => _buildStyledEnglishTest(test, primaryColor, font, resume)),
                pw.SizedBox(height: 16),
              ],

              if (resume.sections.experience && profile.experience != null && profile.experience!.isNotEmpty) ...[
                _buildSectionHeaderPDF('PROFESSIONAL EXPERIENCE', secondaryColor, font, 12),
                pw.SizedBox(height: 10),
                ...profile.experience!.map((e) => _buildStyledExperience(e, primaryColor, font, resume)),
              ],
            ],
          );
        },
      ),
    );
  }

  // =============================
  // Widget Builders (Helpers)
  // =============================

  // ✅ HELPER: Aggregate subjects and grades into a string
  String _getSubjectSummary(List<SubjectGrade> subjects) {
    if (subjects.isEmpty) return '';

    // Aggregate by grade count: e.g. { "A+": 2, "A": 3 }
    final distribution = <String, int>{};
    for (final s in subjects) {
      final g = s.grade.trim();
      if (g.isNotEmpty) {
        distribution[g] = (distribution[g] ?? 0) + 1;
      }
    }

    // Sort keys roughly alphabetically or however beneficial
    final entries = distribution.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return entries.map((e) => '${e.value}${e.key}').join(', ');
  }

  pw.Widget _buildStyledEducation(
      AcademicRecord edu,
      PdfColor color,
      pw.Font? font,
      ResumeDoc resume,
      ) {
    final programTitle = edu.programName ?? edu.major ?? edu.level;
    final subTitle = edu.institution ?? '';
    final score = edu.cgpa != null ? 'CGPA: ${edu.cgpa}' : (edu.totalScore != null ? 'Score: ${edu.totalScore}' : null);
    final honors = edu.honors ?? edu.classOfAward ?? edu.classification;
    final dateRange = _formatDateRange(edu.startDate, edu.endDate, edu.isCurrent);

    // ✅ Generate Subject Summary
    final subjectSummary = _getSubjectSummary(edu.subjects);

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 6, height: 6,
            margin: const pw.EdgeInsets.only(top: 5),
            decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        programTitle,
                        style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold, fontSize: resume.font.contentFontSize.toDouble() + 1),
                      ),
                    ),
                    pw.Text(
                      dateRange,
                      style: pw.TextStyle(font: font, fontSize: resume.font.contentFontSize.toDouble() - 1, color: PdfColors.grey700),
                    ),
                  ],
                ),
                if (subTitle.isNotEmpty)
                  pw.Text(
                    subTitle,
                    style: pw.TextStyle(font: font, fontSize: resume.font.contentFontSize.toDouble(), color: PdfColors.grey800),
                  ),

                // Details Row
                pw.Wrap(
                    spacing: 12,
                    children: [
                      if (edu.level.isNotEmpty)
                        pw.Text(edu.level, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      if (score != null)
                        pw.Text(score, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: color)),
                      if (honors != null)
                        pw.Text(honors, style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)),
                      if (edu.examType != null)
                        pw.Text(edu.examType!, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ]
                ),

                // ✅ Subject Summary Display
                if (subjectSummary.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Results: $subjectSummary',
                    style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey800),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStyledEnglishTest(
      EnglishTest test,
      PdfColor color,
      pw.Font? font,
      ResumeDoc resume,
      ) {
    String details = '';
    if (test.bands != null && test.bands!.isNotEmpty) {
      details = test.bands!.entries.map((e) => '${e.key}: ${e.value}').join(' • ');
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: color.shade(0.1),
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: color.shade(0.5)),
            ),
            child: pw.Text(
              test.type,
              style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold, fontSize: 10, color: color),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Text(
            'Result: ${test.result}',
            style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold, fontSize: 11),
          ),
          if (test.year != null) ...[
            pw.SizedBox(width: 8),
            pw.Text('(${test.year})', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
          ],
          if (details.isNotEmpty) ...[
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Text(
                details,
                style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700),
                overflow: pw.TextOverflow.visible,
              ),
            ),
          ]
        ],
      ),
    );
  }

  pw.Widget _buildStyledExperience(Experience exp, PdfColor color, pw.Font? font, ResumeDoc resume) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(width: 6, height: 6, margin: const pw.EdgeInsets.only(top: 6), decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle)),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(exp.jobTitle ?? 'Job Title', style: pw.TextStyle(font: font, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Row(
                  children: [
                    pw.Text(exp.company ?? 'Company', style: pw.TextStyle(font: font, fontSize: 11, color: color)),
                    if (exp.employmentType != null) pw.Text(' • ${exp.employmentType}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                  ],
                ),
                pw.Text(_formatDateRange(exp.startDate, exp.endDate, exp.isCurrent), style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                if (exp.description != null) pw.Text(exp.description!, style: pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSkillChip(Skill skill, PdfColor color, pw.Font? font, ResumeDoc resume) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: color.shade(0.5)),
      ),
      child: pw.Text('${skill.name} ${skill.level != null ? '(Lv${skill.level})' : ''}', style: pw.TextStyle(font: font, fontSize: 10, color: color)),
    );
  }

  pw.Widget _buildContactItem(String icon, String text, pw.Font? font, double fontSize) {
    return pw.Row(children: [pw.Text(icon), pw.SizedBox(width: 4), pw.Text(text, style: pw.TextStyle(font: font, fontSize: fontSize, color: PdfColors.white))]);
  }

  pw.Widget _buildContactRow(String text, pw.Font? font, double fontSize) {
    return pw.Text(text, style: pw.TextStyle(font: font, fontSize: fontSize));
  }

  pw.Widget _buildSectionHeader(String title, PdfColor color, pw.Font? font, double fontSize) {
    return pw.Row(children: [pw.Container(width: 4, height: 16, color: color), pw.SizedBox(width: 8), pw.Text(title, style: pw.TextStyle(font: font, fontSize: fontSize, fontWeight: pw.FontWeight.bold, color: color))]);
  }

  pw.Widget _buildSectionHeaderPDF(String title, PdfColor color, pw.Font? font, double fontSize) {
    return _buildSectionHeader(title, color, font, fontSize);
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  String _formatDateRange(dynamic start, dynamic end, bool? isCurrent) {
    if (start == null) return '';
    String fmt(dynamic d) {
      if (d is Timestamp) {
        final dt = d.toDate();
        return '${dt.month}/${dt.year}';
      }
      return '';
    }
    final s = fmt(start);
    final e = (isCurrent == true) ? 'Present' : fmt(end);
    return '$s - $e';
  }

  PdfColor _parseColor(String hex) {
    final hexColor = hex.replaceAll('#', '');
    if (hexColor.length == 6) {
      return PdfColor.fromInt(int.parse('FF$hexColor', radix: 16));
    }
    return PdfColors.blue;
  }
}