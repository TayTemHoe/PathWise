// lib/view/resume/resume_preview_view.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/viewModel/resume_view_model.dart';
import 'package:path_wise/viewModel/profile_view_model.dart';
import 'package:path_wise/model/resume_model.dart';
import 'package:path_wise/model/user_profile.dart';
import 'package:intl/intl.dart';

import '../../utils/app_color.dart';

// Defining KYYAP Design Colors locally
class _DesignColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color background = Color(0xFFF5F7FA);
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color cardBackground = Colors.white;
  static const Color success = Color(0xFF00B894);
  static const Color error = Color(0xFFD63031);
  static Color shadow = Colors.black.withOpacity(0.08);
}

class PreviewResumePage extends StatelessWidget {
  final ResumeDoc resume;

  const PreviewResumePage({Key? key, required this.resume}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DesignColors.background,
      appBar: AppBar(
        backgroundColor: _DesignColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
              Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'Resume Preview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _DesignColors.textPrimary,
              ),
            ),
            Text(
              resume.title,
              style: const TextStyle(
                fontSize: 12,
                color: _DesignColors.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: _DesignColors.primary),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Edit',
          ),
        ],
      ),
      body: SafeArea(
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
    );
  }

  Widget _buildResumePreview(BuildContext context) {
    final profileVM = context.watch<ProfileViewModel>();
    final profile = profileVM.profile;
    final skills = profileVM.skills;
    final education = profileVM.education;
    final experience = profileVM.experience;

    if (profile == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_DesignColors.primary),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _DesignColors.shadow,
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
  // TECH MODERN TEMPLATE
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
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
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
                              profile.country != null ? ', ' : ''}${profile.country ?? ''}',
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
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: secondaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: secondaryColor.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          skill.name ?? '',
                          style: TextStyle(
                            fontSize: resume.font.contentFontSize.toDouble(),
                            color: secondaryColor,
                            fontWeight: FontWeight.w600,
                            fontFamily: resume.font.fontFamily,
                          ),
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
        border: Border.all(color: Colors.grey[200]!),
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
  // BUSINESS PROFESSIONAL TEMPLATE
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
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
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
          Divider(color: primaryColor, thickness: 2),
          const SizedBox(height: 24),

          // Contact Info
          if (resume.sections.personalInfo) ...[
            Wrap(
              spacing: 24,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                if (profile.email != null)
                  _buildBusinessContact(Icons.email, profile.email!, primaryColor),
                if (profile.phone != null)
                  _buildBusinessContact(Icons.phone, profile.phone!, primaryColor),
                if (profile.city != null || profile.country != null)
                  _buildBusinessContact(
                    Icons.location_on,
                    '${profile.city ?? ''}, ${profile.country ?? ''}',
                    primaryColor,
                  ),
              ],
            ),
            const SizedBox(height: 28),
          ],

          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

              if (resume.sections.experience && experience.isNotEmpty) ...[
                _buildBusinessSection('EXPERIENCE', secondaryColor),
                const SizedBox(height: 16),
                ...experience.map((exp) => _buildBusinessExperience(exp, primaryColor)),
                const SizedBox(height: 28),
              ],

              if (resume.sections.education && education.isNotEmpty) ...[
                _buildBusinessSection('EDUCATION', secondaryColor),
                const SizedBox(height: 16),
                ...education.map((edu) => _buildBusinessEducation(edu, primaryColor)),
                const SizedBox(height: 28),
              ],

              if (resume.sections.skills && skills.isNotEmpty) ...[
                _buildBusinessSection('SKILLS', secondaryColor),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: skills.map((skill) => Text(
                    '• ${skill.name}',
                    style: TextStyle(
                      fontSize: resume.font.contentFontSize.toDouble(),
                      fontFamily: resume.font.fontFamily,
                      color: const Color(0xFF374151),
                    ),
                  )).toList(),
                ),
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
        border: Border(bottom: BorderSide(color: color, width: 1.5)),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                exp.jobTitle ?? '',
                style: TextStyle(
                  fontSize: resume.font.contentFontSize.toDouble() + 2,
                  fontWeight: FontWeight.bold,
                  fontFamily: resume.font.fontFamily,
                ),
              ),
              if (exp.startDate != null)
                Text(
                  _formatDateRange(exp.startDate, exp.endDate, exp.isCurrent),
                  style: TextStyle(
                    fontSize: resume.font.contentFontSize.toDouble() - 1,
                    color: const Color(0xFF6B7280),
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          Text(
            exp.company ?? '',
            style: TextStyle(
              fontSize: resume.font.contentFontSize.toDouble(),
              color: color,
              fontWeight: FontWeight.w600,
              fontFamily: resume.font.fontFamily,
            ),
          ),
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

  Widget _buildBusinessEducation(Education edu, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                edu.institution ?? '',
                style: TextStyle(
                  fontSize: resume.font.contentFontSize.toDouble() + 1,
                  fontWeight: FontWeight.bold,
                  fontFamily: resume.font.fontFamily,
                ),
              ),
              if (edu.startDate != null)
                Text(
                  _formatDateRange(edu.startDate, edu.endDate, edu.isCurrent),
                  style: TextStyle(
                    fontSize: resume.font.contentFontSize.toDouble() - 1,
                    color: const Color(0xFF6B7280),
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          Text(
            '${edu.degreeLevel ?? ''} in ${edu.fieldOfStudy ?? ''}',
            style: TextStyle(
              fontSize: resume.font.contentFontSize.toDouble(),
              fontFamily: resume.font.fontFamily,
              color: const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // CREATIVE TEMPLATE
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
        // Sidebar
        Container(
          width: 160,
          color: primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Text(
                  _getInitials(profile.name ?? 'U'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              if (resume.sections.personalInfo) ...[
                const Text(
                  'CONTACT',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                if (profile.email != null) _buildCreativeContact(Icons.email, profile.email!),
                const SizedBox(height: 8),
                if (profile.phone != null) _buildCreativeContact(Icons.phone, profile.phone!),
                const SizedBox(height: 32),
              ],

              if (resume.sections.skills && skills.isNotEmpty) ...[
                const Text(
                  'SKILLS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                ...skills.take(8).map((skill) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    skill.name ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                )),
              ],
            ],
          ),
        ),

        // Main Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name ?? 'Your Name',
                  style: TextStyle(
                    fontSize: resume.font.header1FontSize.toDouble() + 6,
                    fontWeight: FontWeight.bold,
                    fontFamily: resume.font.fontFamily,
                    color: const Color(0xFF111827),
                  ),
                ),
                Text(
                  resume.title,
                  style: TextStyle(
                    fontSize: resume.font.header2FontSize.toDouble() + 2,
                    color: secondaryColor,
                    fontWeight: FontWeight.w600,
                    fontFamily: resume.font.fontFamily,
                  ),
                ),
                const SizedBox(height: 32),

                if (resume.sections.aboutMe && resume.aboutMe != null) ...[
                  _buildCreativeSection('PROFILE', secondaryColor),
                  const SizedBox(height: 8),
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

                if (resume.sections.experience && experience.isNotEmpty) ...[
                  _buildCreativeSection('EXPERIENCE', secondaryColor),
                  const SizedBox(height: 16),
                  ...experience.map((exp) => _buildCreativeExperience(exp, secondaryColor)),
                  const SizedBox(height: 28),
                ],

                if (resume.sections.education && education.isNotEmpty) ...[
                  _buildCreativeSection('EDUCATION', secondaryColor),
                  const SizedBox(height: 16),
                  ...education.map((edu) => _buildCreativeEducation(edu, secondaryColor)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreativeContact(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(height: 4),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildCreativeSection(String title, Color color) {
    return Row(
      children: [
        Container(width: 4, height: 20, color: color),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: resume.font.header2FontSize.toDouble() + 2,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 1.5,
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
            ),
          ),
          Text(
            exp.company ?? '',
            style: TextStyle(
              fontSize: resume.font.contentFontSize.toDouble(),
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (exp.description != null) ...[
            const SizedBox(height: 8),
            Text(
              exp.description!,
              style: TextStyle(
                fontSize: resume.font.contentFontSize.toDouble(),
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
            ),
          ),
          Text(
            '${edu.degreeLevel ?? ''} in ${edu.fieldOfStudy ?? ''}',
            style: TextStyle(
              fontSize: resume.font.contentFontSize.toDouble(),
              color: const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // ACADEMIC TEMPLATE
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            profile.name ?? 'Your Name',
            style: TextStyle(
              fontSize: resume.font.header1FontSize.toDouble() + 4,
              fontWeight: FontWeight.bold,
              fontFamily: resume.font.fontFamily,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            resume.title,
            style: TextStyle(
              fontSize: resume.font.header2FontSize.toDouble() + 2,
              color: const Color(0xFF6B7280),
              fontFamily: resume.font.fontFamily,
            ),
          ),
          if (resume.sections.personalInfo) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              children: [
                if (profile.email != null) Text(profile.email!),
                if (profile.phone != null) Text(profile.phone!),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Container(height: 2, width: 60, color: primaryColor),
          const SizedBox(height: 32),

          // Content (Left aligned)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (resume.sections.education && education.isNotEmpty) ...[
                _buildAcademicSection('EDUCATION', secondaryColor),
                const SizedBox(height: 16),
                ...education.map((edu) => _buildAcademicEducation(edu)),
                const SizedBox(height: 28),
              ],

              if (resume.sections.experience && experience.isNotEmpty) ...[
                _buildAcademicSection('EXPERIENCE', secondaryColor),
                const SizedBox(height: 16),
                ...experience.map((exp) => _buildAcademicExperience(exp)),
                const SizedBox(height: 28),
              ],

              if (resume.sections.skills && skills.isNotEmpty) ...[
                _buildAcademicSection('SKILLS', secondaryColor),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: skills.map((skill) => Chip(
                    label: Text(skill.name ?? ''),
                    backgroundColor: Colors.grey[100],
                  )).toList(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicSection(String title, Color color) {
    return Center(
      child: Text(
        title,
        style: TextStyle(
          fontSize: resume.font.header2FontSize.toDouble() + 1,
          fontWeight: FontWeight.bold,
          color: color,
          fontFamily: resume.font.fontFamily,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildAcademicEducation(Education edu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            edu.institution ?? '',
            style: TextStyle(
              fontSize: resume.font.contentFontSize.toDouble() + 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${edu.degreeLevel ?? ''} in ${edu.fieldOfStudy ?? ''}',
            style: TextStyle(
              fontSize: resume.font.contentFontSize.toDouble(),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicExperience(Experience exp) {
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
            ),
          ),
          Text(
            exp.company ?? '',
            style: TextStyle(
              fontSize: resume.font.contentFontSize.toDouble(),
              fontStyle: FontStyle.italic,
            ),
          ),
          if (exp.description != null)
            Text(
              exp.description!,
              style: TextStyle(
                fontSize: resume.font.contentFontSize.toDouble(),
                color: const Color(0xFF4B5563),
              ),
            ),
        ],
      ),
    );
  }

  // ========================================
  // SHARED HELPERS
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
        Text(
          text,
          style: TextStyle(
            fontSize: resume.font.contentFontSize.toDouble(),
            color: color,
            fontFamily: resume.font.fontFamily,
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
    final startStr = start != null ? dateFormat.format(start.toDate()) : 'Unknown';
    final endStr = isCurrent == true ? 'Present' : (end != null ? dateFormat.format(end.toDate()) : 'Present');
    return '$startStr - $endStr';
  }

  Color _parseColor(String hex) {
    final hexColor = hex.replaceAll('#', '');
    final r = int.parse(hexColor.substring(0, 2), radix: 16);
    final g = int.parse(hexColor.substring(2, 4), radix: 16);
    final b = int.parse(hexColor.substring(4, 6), radix: 16);
    return Color.fromRGBO(r, g, b, 1.0);
  }

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
                    onPressed: viewModel.isSharing ? null : () => _handleShare(context, viewModel),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _DesignColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.share_outlined, size: 20, color: _DesignColors.primary),
                    label: const Text('Share', style: TextStyle(color: _DesignColors.primary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: viewModel.isDownloading ? null : () => _handleDownload(context, viewModel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _DesignColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 20, color: Colors.white),
                    label: const Text('Download PDF', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleShare(BuildContext context, ResumeViewModel viewModel) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _buildLoadingDialog('Preparing to share...'),
    );

    await viewModel.shareResume(resume);

    if (context.mounted) {
      Navigator.pop(context);
      if (viewModel.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.successMessage!),
            backgroundColor: _DesignColors.success,
          ),
        );
      }
    }
  }

  Future<void> _handleDownload(BuildContext context, ResumeViewModel viewModel) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _buildLoadingDialog('Downloading your resume...'),
    );

    final path = await viewModel.downloadResume(resume);

    if (context.mounted) {
      Navigator.pop(context);
      if (path != null && viewModel.successMessage != null) {
        showDialog(
          context: context,
          builder: (ctx) => _buildSuccessDialog(context, path),
        );
      }
    }
  }

  Widget _buildLoadingDialog(String message) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_DesignColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessDialog(BuildContext context, String filePath) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: _DesignColors.success, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Download Successful!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Saved to: ${filePath.split('/').last}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _DesignColors.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _DesignColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Done', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}