// lib/view/resume/resume_preview_view.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/viewModel/resume_view_model.dart';
import 'package:path_wise/viewModel/profile_view_model.dart';
import 'package:path_wise/model/resume_model.dart';
import 'package:path_wise/model/user_profile.dart';
import 'package:intl/intl.dart';

class PreviewResumePage extends StatelessWidget {
  final ResumeDoc resume;

  const PreviewResumePage({Key? key, required this.resume}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: _buildResumePreview(context),
                        ),
                      ),
                      _buildActionButtons(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resume Preview',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  resume.title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildResumePreview(BuildContext context) {
    final profileVM = context.watch<ProfileViewModel>();
    final profile = profileVM.profile;
    final skills = profileVM.skills;
    final education = profileVM.education;
    final experience = profileVM.experience;

    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _buildTemplateLayout(profile, skills, education, experience),
      ),
    );
  }

  Widget _buildTemplateLayout(UserProfile profile,
      List<Skill> skills,
      List<Education> education,
      List<Experience> experience,) {
    switch (resume.template) {
      case ResumeTemplateType.tech:
        return _buildTechTemplate(profile, skills, education, experience);
      case ResumeTemplateType.business:
        return _buildBusinessTemplate(profile, skills, education, experience);
      case ResumeTemplateType.creative:
        return _buildCreativeTemplate(profile, skills, education, experience);
      case ResumeTemplateType.academic:
        return _buildAcademicTemplate(profile, skills, education, experience);
    }
  }

  // ========================================
  // TECH MODERN TEMPLATE - Clean & Modern
  // ========================================
  Widget _buildTechTemplate(UserProfile profile,
      List<Skill> skills,
      List<Education> education,
      List<Experience> experience,) {
    final primaryColor = _parseColor(resume.theme.primaryColorHex);
    final secondaryColor = _parseColor(resume.theme.secondaryColorHex);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient background
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, primaryColor.withOpacity(0.7)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name ?? 'Your Name',
                  style: TextStyle(
                    fontSize: resume.font.header1FontSize.toDouble(),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: resume.font.fontFamily,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  resume.title,
                  style: TextStyle(
                    fontSize: resume.font.header2FontSize.toDouble() + 4,
                    color: Colors.white.withOpacity(0.95),
                    fontFamily: resume.font.fontFamily,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (resume.sections.personalInfo) ...[
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 20,
                    runSpacing: 12,
                    children: [
                      if (profile.email != null)
                        _buildContactItem(
                          Icons.email_outlined,
                          profile.email!,
                          Colors.white.withOpacity(0.95),
                        ),
                      if (profile.phone != null)
                        _buildContactItem(
                          Icons.phone_outlined,
                          profile.phone!,
                          Colors.white.withOpacity(0.95),
                        ),
                      if (profile.city != null || profile.country != null)
                        _buildContactItem(
                          Icons.location_on_outlined,
                          '${profile.city ?? ''}${profile.city != null &&
                              profile.country != null ? ', ' : ''}${profile
                              .country ?? ''}',
                          Colors.white.withOpacity(0.95),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // About Me
                if (resume.sections.aboutMe && resume.aboutMe != null) ...[
                  _buildSectionHeader('PROFESSIONAL SUMMARY', secondaryColor),
                  const SizedBox(height: 12),
                  Text(
                    resume.aboutMe!,
                    style: TextStyle(
                      fontSize: resume.font.contentFontSize.toDouble(),
                      fontFamily: resume.font.fontFamily,
                      height: 1.6,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // Skills
                if (resume.sections.skills && skills.isNotEmpty) ...[
                  _buildSectionHeader('SKILLS', secondaryColor),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: skills.map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: secondaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: secondaryColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              skill.name ?? '',
                              style: TextStyle(
                                fontSize: resume.font.contentFontSize
                                    .toDouble(),
                                color: secondaryColor,
                                fontWeight: FontWeight.w600,
                                fontFamily: resume.font.fontFamily,
                              ),
                            ),
                            if (skill.level != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: secondaryColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Lv ${skill.level}',
                                  style: TextStyle(
                                    fontSize: resume.font.contentFontSize
                                        .toDouble() - 2,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ] else
                              if (skill.levelText != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: secondaryColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    skill.levelText!,
                                    style: TextStyle(
                                      fontSize: resume.font.contentFontSize
                                          .toDouble() - 2,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                ],

                // Experience
                if (resume.sections.experience && experience.isNotEmpty) ...[
                  _buildSectionHeader('WORK EXPERIENCE', secondaryColor),
                  const SizedBox(height: 16),
                  ...experience.map((exp) =>
                      _buildTechExperience(exp, secondaryColor)),
                  const SizedBox(height: 28),
                ],

                // Education
                if (resume.sections.education && education.isNotEmpty) ...[
                  _buildSectionHeader('EDUCATION', secondaryColor),
                  const SizedBox(height: 16),
                  ...education.map((edu) =>
                      _buildTechEducation(edu, secondaryColor)),
                  const SizedBox(height: 28),
                ],

                // References
                if (resume.sections.references &&
                    resume.references.isNotEmpty) ...[
                  _buildSectionHeader('REFERENCES', secondaryColor),
                  const SizedBox(height: 16),
                  ...resume.references.map((ref) => _buildTechReference(ref)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechExperience(Experience exp, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exp.jobTitle ?? '',
                      style: TextStyle(
                        fontSize: resume.font.contentFontSize.toDouble() + 2,
                        fontWeight: FontWeight.bold,
                        fontFamily: resume.font.fontFamily,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          exp.company ?? '',
                          style: TextStyle(
                            fontSize: resume.font.contentFontSize.toDouble(),
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontFamily: resume.font.fontFamily,
                          ),
                        ),
                        if (exp.employmentType != null) ...[
                          Text(
                            ' • ${exp.employmentType}',
                            style: TextStyle(
                              fontSize: resume.font.contentFontSize.toDouble(),
                              color: const Color(0xFF6B7280),
                              fontFamily: resume.font.fontFamily,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (exp.startDate != null || exp.endDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatDateRange(
                            exp.startDate, exp.endDate, exp.isCurrent),
                        style: TextStyle(
                          fontSize: resume.font.contentFontSize.toDouble() - 1,
                          color: const Color(0xFF9CA3AF),
                          fontFamily: resume.font.fontFamily,
                        ),
                      ),
                    ],
                    if (exp.city != null || exp.country != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${exp.city ?? ''}${exp.city != null &&
                            exp.country != null ? ', ' : ''}${exp.country ??
                            ''}',
                        style: TextStyle(
                          fontSize: resume.font.contentFontSize.toDouble() - 1,
                          color: const Color(0xFF9CA3AF),
                          fontFamily: resume.font.fontFamily,
                        ),
                      ),
                    ],
                    if (exp.description != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        exp.description!,
                        style: TextStyle(
                          fontSize: resume.font.contentFontSize.toDouble(),
                          fontFamily: resume.font.fontFamily,
                          height: 1.5,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ],
                    if (exp.achievements?.skillsUsed != null &&
                        exp.achievements!.skillsUsed!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: exp.achievements!.skillsUsed!.map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              skill,
                              style: TextStyle(
                                fontSize: resume.font.contentFontSize
                                    .toDouble() - 1,
                                color: const Color(0xFF4B5563),
                                fontFamily: resume.font.fontFamily,
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
        ],
      ),
    );
  }

  Widget _buildTechEducation(Education edu, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  edu.institution ?? '',
                  style: TextStyle(
                    fontSize: resume.font.contentFontSize.toDouble() + 1,
                    fontWeight: FontWeight.bold,
                    fontFamily: resume.font.fontFamily,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${edu.degreeLevel ?? ''} in ${edu.fieldOfStudy ?? ''}',
                  style: TextStyle(
                    fontSize: resume.font.contentFontSize.toDouble(),
                    fontFamily: resume.font.fontFamily,
                    color: const Color(0xFF374151),
                  ),
                ),
                if (edu.startDate != null || edu.endDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatDateRange(edu.startDate, edu.endDate, edu.isCurrent),
                    style: TextStyle(
                      fontSize: resume.font.contentFontSize.toDouble() - 1,
                      color: const Color(0xFF9CA3AF),
                      fontFamily: resume.font.fontFamily,
                    ),
                  ),
                ],
                if (edu.gpa != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'GPA: ${edu.gpa}',
                    style: TextStyle(
                      fontSize: resume.font.contentFontSize.toDouble(),
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontFamily: resume.font.fontFamily,
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

  Widget _buildTechReference(ResumeReference ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ref.name,
            style: TextStyle(
              fontSize: resume.font.contentFontSize.toDouble(),
              fontWeight: FontWeight.bold,
              fontFamily: resume.font.fontFamily,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            ref.position,
            style: TextStyle(
              fontSize: resume.font.contentFontSize.toDouble() - 1,
              fontFamily: resume.font.fontFamily,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            ref.contact,
            style: TextStyle(
              fontSize: resume.font.contentFontSize.toDouble() - 1,
              color: const Color(0xFF9CA3AF),
              fontFamily: resume.font.fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // BUSINESS PROFESSIONAL TEMPLATE - Classic & Formal
  // ========================================
  Widget _buildBusinessTemplate(UserProfile profile,
      List<Skill> skills,
      List<Education> education,
      List<Experience> experience,) {
    final primaryColor = _parseColor(resume.theme.primaryColorHex);
    final secondaryColor = _parseColor(resume.theme.secondaryColorHex);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(36),
      child: Column(
        children: [
          // Header with profile circle
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _getInitials(profile.name ?? 'U'),
                    style: TextStyle(
                      fontSize: resume.font.header1FontSize.toDouble(),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: resume.font.fontFamily,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name ?? 'Your Name',
                      style: TextStyle(
                        fontSize: resume.font.header1FontSize.toDouble(),
                        fontWeight: FontWeight.bold,
                        fontFamily: resume.font.fontFamily,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      resume.title,
                      style: TextStyle(
                        fontSize: resume.font.header2FontSize.toDouble() + 2,
                        color: secondaryColor,
                        fontFamily: resume.font.fontFamily,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.1)],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Contact Info
          if (resume.sections.personalInfo) ...[
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                if (profile.email != null)
                  _buildBusinessContact(
                    Icons.email,
                    profile.email!,
                    primaryColor,
                  ),
                if (profile.phone != null)
                  _buildBusinessContact(
                    Icons.phone,
                    profile.phone!,
                    primaryColor,
                  ),
                if (profile.city != null || profile.country != null)
                  _buildBusinessContact(
                    Icons.location_on,
                    '${profile.city ?? ''}${profile.city != null &&
                        profile.country != null ? ', ' : ''}${profile.country ??
                        ''}',
                    primaryColor,
                  ),
              ],
            ),
            const SizedBox(height: 28),
          ],

          // Content sections
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // About Me
              if (resume.sections.aboutMe && resume.aboutMe != null) ...[
                _buildBusinessSection('PROFESSIONAL SUMMARY', secondaryColor),
                const SizedBox(height: 12),
                Text(
                  resume.aboutMe!,
                  style: TextStyle(
                    fontSize: resume.font.contentFontSize.toDouble(),
                    fontFamily: resume.font.fontFamily,
                    height: 1.6,
                    color: const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // Experience
              if (resume.sections.experience && experience.isNotEmpty) ...[
                _buildBusinessSection(
                    'PROFESSIONAL EXPERIENCE', secondaryColor),
                const SizedBox(height: 16),
                ...experience.map((exp) =>
                    _buildBusinessExperience(exp, primaryColor)),
                const SizedBox(height: 28),
              ],

              // Education
              if (resume.sections.education && education.isNotEmpty) ...[
                _buildBusinessSection('EDUCATION', secondaryColor),
                const SizedBox(height: 16),
                ...education.map((edu) =>
                    _buildBusinessEducation(edu, primaryColor)),
                const SizedBox(height: 28),
              ],

              // Skills
              if (resume.sections.skills && skills.isNotEmpty) ...[
                _buildBusinessSection('KEY SKILLS', secondaryColor),
                const SizedBox(height: 16),
                _buildBusinessSkills(skills, primaryColor),
                const SizedBox(height: 28),
              ],

              // References
              if (resume.sections.references &&
                  resume.references.isNotEmpty) ...[
                _buildBusinessSection('REFERENCES', secondaryColor),
                const SizedBox(height: 16),
                ...resume.references.map((ref) => _buildBusinessReference(ref)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessContact(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: resume.font.contentFontSize.toDouble(),
            fontFamily: resume.font.fontFamily,
            color: const Color(0xFF374151),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessSection(String title, Color color) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: color, width: 2),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: resume.font.header2FontSize.toDouble(),
          fontWeight: FontWeight.bold,
          color: color,
          fontFamily: resume.font.fontFamily,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildBusinessExperience(Experience exp, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.work, size: 14, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exp.jobTitle ?? '',
                      style: TextStyle(
                        fontSize: resume.font.contentFontSize.toDouble() + 2,
                        fontWeight: FontWeight.bold,
                        fontFamily: resume.font.fontFamily,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exp.company ?? ''}${exp.employmentType != null
                          ? ' • ${exp.employmentType}'
                          : ''}',
                      style: TextStyle(
                        fontSize: resume.font.contentFontSize.toDouble(),
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontFamily: resume.font.fontFamily,
                      ),
                    ),
                    if (exp.startDate != null || exp.endDate != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _formatDateRange(
                            exp.startDate, exp.endDate, exp.isCurrent),
                        style: TextStyle(
                          fontSize: resume.font.contentFontSize.toDouble() - 1,
                          color: const Color(0xFF6B7280),
                          fontFamily: resume.font.fontFamily,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (exp.description != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        exp.description!,
                        style: TextStyle(
                          fontSize: resume.font.contentFontSize.toDouble(),
                          fontFamily: resume.font.fontFamily,
                          height: 1.5,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ],
                    if (exp.achievements?.description != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('•  ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              exp.achievements!.description!,
                              style: TextStyle(
                                fontSize: resume.font.contentFontSize
                                    .toDouble(),
                                fontFamily: resume.font.fontFamily,
                                height: 1.5,
                                color: const Color(0xFF4B5563),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessEducation(Education edu, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.school, size: 14, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  edu.institution ?? '',
                  style: TextStyle(
                    fontSize: resume.font.contentFontSize.toDouble() + 1,
                    fontWeight: FontWeight.bold,
                    fontFamily: resume.font.fontFamily,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${edu.degreeLevel ?? ''} in ${edu.fieldOfStudy ?? ''}',
                  style: TextStyle(
                    fontSize: resume.font.contentFontSize.toDouble(),
                    fontFamily: resume.font.fontFamily,
                    color: const Color(0xFF374151),
                  ),
                ),
                if (edu.startDate != null || edu.endDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatDateRange(edu.startDate, edu.endDate, edu.isCurrent),
                    style: TextStyle(
                      fontSize: resume.font.contentFontSize.toDouble() - 1,
                      color: const Color(0xFF6B7280),
                      fontFamily: resume.font.fontFamily,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (edu.gpa != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'GPA: ${edu.gpa}',
                    style: TextStyle(
                      fontSize: resume.font.contentFontSize.toDouble(),
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontFamily: resume.font.fontFamily,
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

  Widget _buildBusinessSkills(List<Skill> skills, Color color) {
    return Column(
      children: skills.map((skill) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  skill.name ?? '',
                  style: TextStyle(
                    fontSize: resume.font.contentFontSize.toDouble(),
                    fontFamily: resume.font.fontFamily,
                    color: const Color(0xFF374151),
                  ),
                ),
              ),
              if (skill.level != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Level ${skill.level}/5',
                    style: TextStyle(
                      fontSize: resume.font.contentFontSize.toDouble() - 1,
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontFamily: resume.font.fontFamily,
                    ),
                  ),
                )
              else
                if (skill.levelText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      skill.levelText!,
                      style: TextStyle(
                        fontSize: resume.font.contentFontSize.toDouble() - 1,
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontFamily: resume.font.fontFamily,
                      ),
                    ),
                  ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBusinessReference(ResumeReference ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ref.name,
            style: TextStyle(
              fontSize: resume.font.contentFontSize.toDouble() + 1,
              fontWeight: FontWeight.bold,
              fontFamily: resume.font.fontFamily,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ref.position,
            style: TextStyle(
              fontSize: resume.font.contentFontSize.toDouble(),
              fontFamily: resume.font.fontFamily,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ref.contact,
            style: TextStyle(
              fontSize: resume.font.contentFontSize.toDouble() - 1,
              color: const Color(0xFF9CA3AF),
              fontFamily: resume.font.fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // CREATIVE TEMPLATE - Bold & Unique
  // ========================================
  Widget _buildCreativeTemplate(UserProfile profile,
      List<Skill> skills,
      List<Education> education,
      List<Experience> experience,) {
    final primaryColor = _parseColor(resume.theme.primaryColorHex);
    final secondaryColor = _parseColor(resume.theme.secondaryColorHex);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Sidebar
        Container(
          width: 160,
          color: primaryColor,
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Profile Circle
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _getInitials(profile.name ?? 'U'),
                    style: TextStyle(
                      fontSize: resume.font.header1FontSize.toDouble() + 4,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      fontFamily: resume.font.fontFamily,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Contact Info
              if (resume.sections.personalInfo) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const Text(
                        'CONTACT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (profile.email != null)
                        _buildCreativeContact(
                          Icons.email_outlined,
                          profile.email!,
                        ),
                      if (profile.phone != null)
                        _buildCreativeContact(
                          Icons.phone_outlined,
                          profile.phone!,
                        ),
                      if (profile.city != null || profile.country != null)
                        _buildCreativeContact(
                          Icons.location_on_outlined,
                          '${profile.city ?? ''}${profile.city != null &&
                              profile.country != null ? '\n' : ''}${profile
                              .country ?? ''}',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Skills in Sidebar
              if (resume.sections.skills && skills.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const Text(
                        'SKILLS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...skills.take(8).map((skill) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                skill.name ?? '',
                                style: TextStyle(
                                  fontSize: resume.font.contentFontSize
                                      .toDouble() - 1,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: resume.font.fontFamily,
                                ),
                              ),
                              if (skill.level != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: List.generate(5, (index) {
                                    return Container(
                                      width: 20,
                                      height: 4,
                                      margin: const EdgeInsets.only(right: 4),
                                      decoration: BoxDecoration(
                                        color: index < (skill.level ?? 0)
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    );
                                  }),
                                ),
                              ] else
                                if (skill.levelText != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    skill.levelText!,
                                    style: TextStyle(
                                      fontSize: resume.font.contentFontSize
                                          .toDouble() - 2,
                                      color: Colors.white.withOpacity(0.8),
                                      fontFamily: resume.font.fontFamily,
                                    ),
                                  ),
                                ],
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Main Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name & Title
                Text(
                  profile.name ?? 'Your Name',
                  style: TextStyle(
                    fontSize: resume.font.header1FontSize.toDouble() + 6,
                    fontWeight: FontWeight.bold,
                    fontFamily: resume.font.fontFamily,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  resume.title,
                  style: TextStyle(
                    fontSize: resume.font.header2FontSize.toDouble() + 4,
                    color: secondaryColor,
                    fontWeight: FontWeight.w600,
                    fontFamily: resume.font.fontFamily,
                  ),
                ),
                const SizedBox(height: 24),

                // About Me
                if (resume.sections.aboutMe && resume.aboutMe != null) ...[
                  _buildCreativeSection('ABOUT', secondaryColor),
                  const SizedBox(height: 12),
                  Text(
                    resume.aboutMe!,
                    style: TextStyle(
                      fontSize: resume.font.contentFontSize.toDouble(),
                      fontFamily: resume.font.fontFamily,
                      height: 1.6,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // Experience
                if (resume.sections.experience && experience.isNotEmpty) ...[
                  _buildCreativeSection('EXPERIENCE', secondaryColor),
                  const SizedBox(height: 16),
                  ...experience.map((exp) =>
                      _buildCreativeExperience(exp, secondaryColor)),
                  const SizedBox(height: 28),
                ],

                // Education
                if (resume.sections.education && education.isNotEmpty) ...[
                  _buildCreativeSection('EDUCATION', secondaryColor),
                  const SizedBox(height: 16),
                  ...education.map((edu) =>
                      _buildCreativeEducation(edu, secondaryColor)),
                  const SizedBox(height: 28),
                ],

                // References
                if (resume.sections.references &&
                    resume.references.isNotEmpty) ...[
                  _buildCreativeSection('REFERENCES', secondaryColor),
                  const SizedBox(height: 16),
                  ...resume.references.map((ref) =>
                      _buildCreativeReference(ref)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreativeContact(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: resume.font.contentFontSize.toDouble() - 1,
                color: Colors.white.withOpacity(0.95),
                fontFamily: resume.font.fontFamily,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreativeSection(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: resume.font.header2FontSize.toDouble() + 2,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: resume.font.fontFamily,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildCreativeExperience(Experience exp, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exp.jobTitle ?? '',
            style: TextStyle(
              fontSize: resume.font.contentFontSize.toDouble() + 2,
              fontWeight: FontWeight.bold,
              fontFamily: resume.font.fontFamily,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            exp.company ?? '',
            style: TextStyle(
              fontSize: resume.font.contentFontSize.toDouble() + 1,
              color: color,
              fontWeight: FontWeight.w600,
              fontFamily: resume.font.fontFamily,
            ),
          ),
          if (exp.startDate != null || exp.endDate != null) ...[
            const SizedBox(height: 2),
            Text(
              '${_formatDateRange(
                  exp.startDate, exp.endDate, exp.isCurrent)}${exp
                  .employmentType != null ? ' • ${exp.employmentType}' : ''}',
              style: TextStyle(
                fontSize: resume.font.contentFontSize.toDouble() - 1,
                color: const Color(0xFF6B7280),
                fontFamily: resume.font.fontFamily,
              ),
            ),
          ],
          if (exp.description != null) ...[
            const SizedBox(height: 8),
            Text(
              exp.description!,
              style: TextStyle(
                fontSize: resume.font.contentFontSize.toDouble(),
                fontFamily: resume.font.fontFamily,
                height: 1.5,
                color: const Color(0xFF374151),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCreativeEducation(Education edu, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            edu.institution ?? '',
            style: TextStyle(
              fontSize: resume.font.contentFontSize.toDouble() + 1,
              fontWeight: FontWeight.bold,
              fontFamily: resume.font.fontFamily,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${edu.degreeLevel ?? ''} in ${edu.fieldOfStudy ?? ''}',
            style: TextStyle(
              fontSize: resume.font.contentFontSize.toDouble(),
              fontFamily: resume.font.fontFamily,
              color: const Color(0xFF374151),
            ),
          ),
          if (edu.startDate != null || edu.endDate != null) ...[
            const SizedBox(height: 2),
            Text(
              _formatDateRange(edu.startDate, edu.endDate, edu.isCurrent),
              style: TextStyle(
                fontSize: resume.font.contentFontSize.toDouble() - 1,
                color: const Color(0xFF6B7280),
                fontFamily: resume.font.fontFamily,
              ),
            ),
          ],
          if (edu.gpa != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'GPA: ${edu.gpa}',
                style: TextStyle(
                  fontSize: resume.font.contentFontSize.toDouble() - 1,
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontFamily: resume.font.fontFamily,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCreativeReference(ResumeReference ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ref.name,
            style: TextStyle(
              fontSize: resume.font.contentFontSize.toDouble(),
              fontWeight: FontWeight.bold,
              fontFamily: resume.font.fontFamily,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            ref.position,
            style: TextStyle(
              fontSize: resume.font.contentFontSize.toDouble() - 1,
              fontFamily: resume.font.fontFamily,
              color: const Color(0xFF6B7280),
            ),
          ),
          Text(
            ref.contact,
            style: TextStyle(
              fontSize: resume.font.contentFontSize.toDouble() - 1,
              color: const Color(0xFF9CA3AF),
              fontFamily: resume.font.fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // ACADEMIC TEMPLATE - Traditional & Scholarly
  // ========================================
  Widget _buildAcademicTemplate(UserProfile profile,
      List<Skill> skills,
      List<Education> education,
      List<Experience> experience,) {
    final primaryColor = _parseColor(resume.theme.primaryColorHex);
    final secondaryColor = _parseColor(resume.theme.secondaryColorHex);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          // Centered Header
          Column(
            children: [
              Text(
                profile.name ?? 'Your Name',
                style: TextStyle(
                  fontSize: resume.font.header1FontSize.toDouble() + 4,
                  fontWeight: FontWeight.bold,
                  fontFamily: resume.font.fontFamily,
                  color: const Color(0xFF111827),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                resume.title,
                style: TextStyle(
                  fontSize: resume.font.header2FontSize.toDouble() + 2,
                  color: const Color(0xFF6B7280),
                  fontFamily: resume.font.fontFamily,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (resume.sections.personalInfo) ...[
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (profile.email != null)
                      Text(
                        profile.email!,
                        style: TextStyle(
                          fontSize: resume.font.contentFontSize.toDouble(),
                          fontFamily: resume.font.fontFamily,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    if (profile.phone != null)
                      Text(
                        profile.phone!,
                        style: TextStyle(
                          fontSize: resume.font.contentFontSize.toDouble(),
                          fontFamily: resume.font.fontFamily,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    if (profile.city != null || profile.country != null)
                      Text(
                        '${profile.city ?? ''}${profile.city != null &&
                            profile.country != null ? ', ' : ''}${profile
                            .country ?? ''}',
                        style: TextStyle(
                          fontSize: resume.font.contentFontSize.toDouble(),
                          fontFamily: resume.font.fontFamily,
                          color: const Color(0xFF374151),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),

          const SizedBox(height: 28),
          Container(
            height: 2,
            color: primaryColor,
          ),
          const SizedBox(height: 28),

          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // About Me
              if (resume.sections.aboutMe && resume.aboutMe != null) ...[
                _buildAcademicSection('SUMMARY', secondaryColor),
                const SizedBox(height: 12),
                Text(
                  resume.aboutMe!,
                  style: TextStyle(
                    fontSize: resume.font.contentFontSize.toDouble(),
                    fontFamily: resume.font.fontFamily,
                    height: 1.7,
                    color: const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // Education (Primary for Academic)
              if (resume.sections.education && education.isNotEmpty) ...[
                _buildAcademicSection('EDUCATION', secondaryColor),
                const SizedBox(height: 16),
                ...education.map((edu) =>
                    _buildAcademicEducation(edu, primaryColor)),
                const SizedBox(height: 28),
              ],

              // Experience
              if (resume.sections.experience && experience.isNotEmpty) ...[
                _buildAcademicSection(
                    'PROFESSIONAL EXPERIENCE', secondaryColor),
                const SizedBox(height: 16),
                ...experience.map((exp) =>
                    _buildAcademicExperience(exp, primaryColor)),
                const SizedBox(height: 28),
              ],

              // Skills
              if (resume.sections.skills && skills.isNotEmpty) ...[
                _buildAcademicSection('SKILLS & COMPETENCIES', secondaryColor),
                const SizedBox(height: 16),
                _buildAcademicSkills(skills),
                const SizedBox(height: 28),
              ],

              // References
              if (resume.sections.references &&
                  resume.references.isNotEmpty) ...[
                _buildAcademicSection('REFERENCES', secondaryColor),
                const SizedBox(height: 16),
                ...resume.references.map((ref) =>
                    _buildAcademicReference(ref, primaryColor)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicSection(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: resume.font.header2FontSize.toDouble() + 1,
        fontWeight: FontWeight.bold,
        color: color,
        fontFamily: resume.font.fontFamily,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildAcademicEducation(Education edu, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${edu.degreeLevel ?? ''} in ${edu.fieldOfStudy ?? ''}',
                      style: TextStyle(
                        fontSize: resume.font.contentFontSize.toDouble() + 2,
                        fontWeight: FontWeight.bold,
                        fontFamily: resume.font.fontFamily,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      edu.institution ?? '',
                      style: TextStyle(
                        fontSize: resume.font.contentFontSize.toDouble() + 1,
                        fontFamily: resume.font.fontFamily,
                        color: const Color(0xFF374151),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    if (edu.startDate != null || edu.endDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatDateRange(
                            edu.startDate, edu.endDate, edu.isCurrent),
                        style: TextStyle(
                          fontSize: resume.font.contentFontSize.toDouble() - 1,
                          color: const Color(0xFF6B7280),
                          fontFamily: resume.font.fontFamily,
                        ),
                      ),
                    ],
                    if (edu.gpa != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'GPA: ${edu.gpa}',
                        style: TextStyle(
                          fontSize: resume.font.contentFontSize.toDouble(),
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontFamily: resume.font.fontFamily,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicExperience(Experience exp, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exp.jobTitle ?? '',
                  style: TextStyle(
                    fontSize: resume.font.contentFontSize.toDouble() + 1,
                    fontWeight: FontWeight.bold,
                    fontFamily: resume.font.fontFamily,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  exp.company ?? '',
                  style: TextStyle(
                    fontSize: resume.font.contentFontSize.toDouble(),
                    fontFamily: resume.font.fontFamily,
                    color: const Color(0xFF374151),
                  ),
                ),
                if (exp.startDate != null || exp.endDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatDateRange(exp.startDate, exp.endDate, exp.isCurrent),
                    style: TextStyle(
                      fontSize: resume.font.contentFontSize.toDouble() - 1,
                      color: const Color(0xFF6B7280),
                      fontFamily: resume.font.fontFamily,
                    ),
                  ),
                ],
                if (exp.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    exp.description!,
                    style: TextStyle(
                      fontSize: resume.font.contentFontSize.toDouble(),
                      fontFamily: resume.font.fontFamily,
                      height: 1.6,
                      color: const Color(0xFF4B5563),
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

  Widget _buildAcademicSkills(List<Skill> skills) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills.map((skill) {
        return Text(
          '${skill.name ?? ''}${skill.level != null
              ? ' (Level ${skill.level})'
              : skill.levelText != null ? ' (${skill.levelText})' : ''} • ',
          style: TextStyle(
            fontSize: resume.font.contentFontSize.toDouble(),
            fontFamily: resume.font.fontFamily,
            color: const Color(0xFF374151),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAcademicReference(ResumeReference ref, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref.name,
                  style: TextStyle(
                    fontSize: resume.font.contentFontSize.toDouble() + 1,
                    fontWeight: FontWeight.bold,
                    fontFamily: resume.font.fontFamily,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ref.position,
                  style: TextStyle(
                    fontSize: resume.font.contentFontSize.toDouble(),
                    fontFamily: resume.font.fontFamily,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ref.contact,
                  style: TextStyle(
                    fontSize: resume.font.contentFontSize.toDouble() - 1,
                    color: const Color(0xFF9CA3AF),
                    fontFamily: resume.font.fontFamily,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // SHARED HELPER WIDGETS & METHODS
  // ========================================

  Widget _buildSectionHeader(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: resume.font.header2FontSize.toDouble(),
        fontWeight: FontWeight.bold,
        color: color,
        fontFamily: resume.font.fontFamily,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: resume.font.contentFontSize.toDouble(),
              color: color,
              fontFamily: resume.font.fontFamily,
            ),
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  String _formatDateRange(Timestamp? start, Timestamp? end, bool? isCurrent) {
    final dateFormat = DateFormat('MMM yyyy');

    if (start == null && end == null) return '';

    final startStr = start != null
        ? dateFormat.format(start.toDate())
        : 'Unknown';
    final endStr = isCurrent == true ? 'Present' : (end != null ? dateFormat
        .format(end.toDate()) : 'Present');

    return '$startStr - $endStr';
  }

  Color _parseColor(String hex) {
    final hexColor = hex.replaceAll('#', '');
    final r = int.parse(hexColor.substring(0, 2), radix: 16);
    final g = int.parse(hexColor.substring(2, 4), radix: 16);
    final b = int.parse(hexColor.substring(4, 6), radix: 16);
    return Color.fromRGBO(r, g, b, 1.0);
  }

  // ========================================
  // ACTION BUTTONS
  // ========================================

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Consumer<ResumeViewModel>(
        builder: (context, viewModel, child) {
          return SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: viewModel.isSharing
                        ? null
                        : () async {
                      // Show loading dialog
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) =>
                            _buildLoadingDialog('Preparing to share...'),
                      );

                      await viewModel.shareResume(resume);

                      if (context.mounted) {
                        Navigator.pop(context); // Close loading dialog

                        if (viewModel.successMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(
                                      Icons.check_circle, color: Colors.white),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Resume ready to share!',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              margin: const EdgeInsets.all(16),
                            ),
                          );
                        } else if (viewModel.error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(
                                      Icons.error_outline, color: Colors.white),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      viewModel.error!,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              margin: const EdgeInsets.all(16),
                            ),
                          );
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFF7C3AED), width: 2),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                        Icons.share_outlined, color: Color(0xFF7C3AED),
                        size: 20),
                    label: const Text(
                      'Share',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: viewModel.isDownloading
                          ? null
                          : () async {
                        // Show loading dialog
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) =>
                              _buildLoadingDialog('Downloading your resume...'),
                        );

                        final path = await viewModel.downloadResume(resume);

                        if (context.mounted) {
                          Navigator.pop(context); // Close loading dialog

                          if (path != null &&
                              viewModel.successMessage != null) {
                            // Show success with file location
                            showDialog(
                              context: context,
                              builder: (context) => _buildSuccessDialog(context, path),
                            );
                          } else if (viewModel.error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.error_outline,
                                        color: Colors.white),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        viewModel.error!,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(
                          Icons.download_rounded, color: Colors.white,
                          size: 20),
                      label: const Text(
                        'Download PDF',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

// Helper method for loading dialog in preview page
  Widget _buildLoadingDialog(String message) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Please wait...',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for success dialog with file location
  // Helper method for success dialog with file location
  Widget _buildSuccessDialog(BuildContext context, String filePath) {  // ADD context parameter
    final fileName = filePath.split('/').last;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Download Successful!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Your resume has been saved to:',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.folder_outlined,
                    size: 20,
                    color: Color(0xFF7C3AED),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fileName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF374151),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Downloads folder',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}