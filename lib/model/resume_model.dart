// lib/models/resume_models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// ===========================
/// ENUM: Template
/// ===========================
enum ResumeTemplateType { tech, business, creative, academic }

ResumeTemplateType _tplFromStr(String? s) {
  switch ((s ?? '').toLowerCase()) {
    case 'tech':
      return ResumeTemplateType.tech;
    case 'business':
      return ResumeTemplateType.business;
    case 'creative':
      return ResumeTemplateType.creative;
    case 'academic':
      return ResumeTemplateType.academic;
    default:
      return ResumeTemplateType.tech;
  }
}

String _tplToStr(ResumeTemplateType t) => t.name; // "tech"|"business"|...

/// ===========================
/// THEME: primary + secondary
/// ===========================
class ResumeThemeConfig {
  final String primaryColorHex;   // "#RRGGBB"
  final String secondaryColorHex; // "#RRGGBB"

  const ResumeThemeConfig({
    this.primaryColorHex = '#4F46E5',
    this.secondaryColorHex = '#22C55E',
  });

  factory ResumeThemeConfig.fromMap(Map<String, dynamic>? m) {
    m ??= {};
    return ResumeThemeConfig(
      primaryColorHex: (m['primaryColor'] ?? '#4F46E5').toString(),
      secondaryColorHex: (m['secondaryColor'] ?? '#22C55E').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'primaryColor': primaryColorHex,
    'secondaryColor': secondaryColorHex,
  };

  ResumeThemeConfig copyWith({
    String? primaryColorHex,
    String? secondaryColorHex,
  }) {
    return ResumeThemeConfig(
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      secondaryColorHex: secondaryColorHex ?? this.secondaryColorHex,
    );
  }
}

/// ===========================
/// FONT config (granular sizes)
/// ===========================
class ResumeFontConfig {
  final String fontFamily; // "Roboto" etc
  final int header1FontSize; // Title/Name
  final int header2FontSize; // Section headings
  final int contentFontSize; // Body

  const ResumeFontConfig({
    this.fontFamily = 'Roboto',
    this.header1FontSize = 22,
    this.header2FontSize = 12,
    this.contentFontSize = 11,
  });

  factory ResumeFontConfig.fromMap(Map<String, dynamic>? m) {
    m ??= {};
    int _i(dynamic v, int d) =>
        (v is num) ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? d;

    return ResumeFontConfig(
      fontFamily: (m['fontFamily'] ?? 'Roboto').toString(),
      header1FontSize: _i(m['header1FontSize'], 22),
      header2FontSize: _i(m['header2FontSize'], 12),
      contentFontSize: _i(m['contentFontSize'], 11),
    );
  }

  Map<String, dynamic> toMap() => {
    'fontFamily': fontFamily,
    'header1FontSize': header1FontSize,
    'header2FontSize': header2FontSize,
    'contentFontSize': contentFontSize,
  };

  ResumeFontConfig copyWith({
    String? fontFamily,
    int? header1FontSize,
    int? header2FontSize,
    int? contentFontSize,
  }) {
    return ResumeFontConfig(
      fontFamily: fontFamily ?? this.fontFamily,
      header1FontSize: header1FontSize ?? this.header1FontSize,
      header2FontSize: header2FontSize ?? this.header2FontSize,
      contentFontSize: contentFontSize ?? this.contentFontSize,
    );
  }
}

/// ===========================
/// REFERENCES (array<map>)
/// ===========================
class ResumeReference {
  final String name;
  final String position; // e.g., "Lecturer in UTAR"
  final String contact; // email/phone

  const ResumeReference({
    required this.name,
    required this.position,
    required this.contact,
  });

  factory ResumeReference.fromMap(Map<String, dynamic> m) {
    return ResumeReference(
      name: (m['name'] ?? '').toString(),
      position: (m['position'] ?? '').toString(),
      contact: (m['contact'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'position': position,
    'contact': contact,
  };
}

/// ===========================
/// SECTION toggles
/// ===========================
class ResumeSectionConfig {
  final bool aboutMe;
  final bool personalInfo;
  final bool skills;
  final bool education;
  final bool experience;
  final bool references;

  const ResumeSectionConfig({
    this.aboutMe = true,
    this.personalInfo = true,
    this.skills = true,
    this.education = true,
    this.experience = true,
    this.references = true,
  });

  factory ResumeSectionConfig.fromMap(Map<String, dynamic>? m) {
    m ??= {};
    bool b(dynamic v, [bool d = false]) => v is bool ? v : d;

    return ResumeSectionConfig(
      aboutMe: b(m['aboutMe'], true),
      personalInfo: b(m['personalInfo'], true),
      skills: b(m['skills'], true),
      education: b(m['education'], true),
      experience: b(m['experience'], true),
      references: b(m['references'], true),
    );
  }

  Map<String, dynamic> toMap() => {
    'aboutMe': aboutMe,
    'personalInfo': personalInfo,
    'skills': skills,
    'education': education,
    'experience': experience,
    'references': references,
  };

  ResumeSectionConfig copyWith({
    bool? aboutMe,
    bool? personalInfo,
    bool? skills,
    bool? education,
    bool? experience,
    bool? references,
  }) {
    return ResumeSectionConfig(
      aboutMe: aboutMe ?? this.aboutMe,
      personalInfo: personalInfo ?? this.personalInfo,
      skills: skills ?? this.skills,
      education: education ?? this.education,
      experience: experience ?? this.experience,
      references: references ?? this.references,
    );
  }
}

/// ===========================
/// ROOT: Resume document
/// ===========================
class ResumeDoc {
  final String id; // Firestore doc id e.g. RS0001
  final String title; // e.g. "Software Engineer Intern"
  final ResumeTemplateType template; // Tech/Business/Creative/Academic

  final ResumeThemeConfig theme; // colors
  final ResumeFontConfig font; // fonts + sizes

  final String? aboutMe; // free text
  final List<ResumeReference> references; // list

  final ResumeSectionConfig sections; // toggles

  final DateTime? createdAt; // date-only
  final DateTime? updatedAt; // date-only

  const ResumeDoc({
    required this.id,
    required this.title,
    required this.template,
    required this.theme,
    required this.font,
    required this.sections,
    this.aboutMe,
    this.references = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// Robust mapper from Firestore map
  factory ResumeDoc.fromMap(Map<String, dynamic> m, String id) {
    DateTime? _dt(v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    // Parse references (List<Map>)
    final refs = <ResumeReference>[];
    final rawRefs = m['references'];
    if (rawRefs is List) {
      for (final e in rawRefs) {
        if (e is Map) {
          refs.add(ResumeReference.fromMap(Map<String, dynamic>.from(e)));
        }
      }
    }

    return ResumeDoc(
      id: id,
      title: (m['title'] ?? 'My Resume').toString(),
      template: _tplFromStr(m['template']?.toString()),
      theme: ResumeThemeConfig.fromMap(m['theme'] as Map<String, dynamic>?),
      font: ResumeFontConfig.fromMap(m['font'] as Map<String, dynamic>?),
      aboutMe: m['aboutMe']?.toString(),
      references: refs,
      sections:
      ResumeSectionConfig.fromMap(m['sections'] as Map<String, dynamic>?),
      createdAt: _dt(m['createdAt']),
      updatedAt: _dt(m['updatedAt']),
    );
  }

  /// Friendly ctor from DocumentSnapshot
  factory ResumeDoc.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? <String, dynamic>{};
    return ResumeDoc.fromMap(data, snap.id);
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() => {
    'title': title,
    'template': _tplToStr(template),
    'theme': theme.toMap(),
    'font': font.toMap(),
    if (aboutMe != null) 'aboutMe': aboutMe,
    'references': references.map((e) => e.toMap()).toList(),
    'sections': sections.toMap(),
    if (createdAt != null) 'createdAt': Timestamp.fromDate(_dateOnly(createdAt!)),
    if (updatedAt != null) 'updatedAt': Timestamp.fromDate(_dateOnly(updatedAt!)),
  };

  /// Copy with builder
  ResumeDoc copyWith({
    String? title,
    ResumeTemplateType? template,
    ResumeThemeConfig? theme,
    ResumeFontConfig? font,
    String? aboutMe,
    List<ResumeReference>? references,
    ResumeSectionConfig? sections,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ResumeDoc(
      id: id,
      title: title ?? this.title,
      template: template ?? this.template,
      theme: theme ?? this.theme,
      font: font ?? this.font,
      aboutMe: aboutMe ?? this.aboutMe,
      references: references ?? this.references,
      sections: sections ?? this.sections,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Helpers: date-only normalizer
  static DateTime nowDateOnly() => _dateOnly(DateTime.now());

  static DateTime _dateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day);
}
