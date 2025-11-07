// lib/views/resume_builder/preview_resume_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/ViewModel/resume_view_model.dart';
import 'package:path_wise/ViewModel/profile_view_model.dart';
import 'package:path_wise/model/resume_model.dart';
import 'package:path_wise/model/user_profile.dart';

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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resume Preview',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Review your resume before downloading',
                  style: TextStyle(
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

  Widget _buildTemplateLayout(
      UserProfile profile,
      List<Skill> skills,
      List<Education> education,
      List<Experience> experience,
      ) {
    switch (resume.template) {
      case ResumeTemplateType.tech:
        return _buildTechTemplate(profile, skills, experience);
      case ResumeTemplateType.business:
        return _buildBusinessTemplate(profile, experience);
      case ResumeTemplateType.creative:
        return _buildCreativeTemplate(profile, experience);
      case ResumeTemplateType.academic:
        return _buildAcademicTemplate(profile, education);
    }
  }

  // ========== TECH TEMPLATE ==========
  Widget _buildTechTemplate(
      UserProfile profile,
      List<Skill> skills,
      List<Experience> experience,
      ) {
    final primaryColor = _parseColor(resume.theme.primaryColorHex);
    final secondaryColor = _parseColor(resume.theme.secondaryColorHex);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
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
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  resume.title,
                  style: TextStyle(
                    fontSize: resume.font.header2FontSize.toDouble() + 2,
                    color: Colors.white.withOpacity(0.9),
                    fontFamily: resume.font.fontFamily,
                  ),
                ),
                if (resume.sections.personalInfo) ...[
                  const SizedBox(height: 16),
                  _buildContactRow(profile, Colors.white.withOpacity(0.9)),
                ],
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // About Me
                if (resume.sections.aboutMe && resume.aboutMe != null) ...[
                  _buildSectionTitle('About Me', secondaryColor),
                  const SizedBox(height: 12),
                  Text(
                    resume.aboutMe!,
                    style: TextStyle(
                      fontSize: resume.font.contentFontSize.toDouble(),
                      fontFamily: resume.font.fontFamily,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Skills
                if (resume.sections.skills && skills.isNotEmpty) ...[
                  _buildSectionTitle('Skills', secondaryColor),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: skills.map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: secondaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: secondaryColor.withOpacity(0.3),
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
                  const SizedBox(height: 24),
                ],

                // Experience
                if (resume.sections.experience && experience.isNotEmpty) ...[
                  _buildSectionTitle('Experience', secondaryColor),
                  const SizedBox(height: 12),
                  ...experience.map((exp) => _buildExperienceItem(exp, secondaryColor)),
                ],

                // References
                if (resume.sections.references && resume.references.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSectionTitle('References', secondaryColor),
                  const SizedBox(height: 12),
                  ...resume.references.map((ref) => _buildReferenceItem(ref)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== BUSINESS TEMPLATE ==========
  Widget _buildBusinessTemplate(
      UserProfile profile,
      List<Experience> experience,
      ) {
    final primaryColor = _parseColor(resume.theme.primaryColorHex);
    final secondaryColor = _parseColor(resume.theme.secondaryColorHex);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with profile circle
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    (profile.name ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: resume.font.header1FontSize.toDouble(),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
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
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      resume.title,
                      style: TextStyle(
                        fontSize: resume.font.header2FontSize.toDouble() + 2,
                        color: secondaryColor,
                        fontFamily: resume.font.fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Divider(color: primaryColor.withOpacity(0.3), thickness: 2),
          const SizedBox(height: 20),

          // Contact Info
          if (resume.sections.personalInfo) ...[
            _buildContactRow(profile, Colors.black87),
            const SizedBox(height: 24),
          ],

          // About Me
          if (resume.sections.aboutMe && resume.aboutMe != null) ...[
            _buildSectionTitle('Professional Summary', secondaryColor),
            const SizedBox(height: 12),
            Text(
              resume.aboutMe!,
              style: TextStyle(
                fontSize: resume.font.contentFontSize.toDouble(),
                fontFamily: resume.font.fontFamily,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Experience
          if (resume.sections.experience && experience.isNotEmpty) ...[
            _buildSectionTitle('Professional Experience', secondaryColor),
            const SizedBox(height: 12),
            ...experience.map((exp) => _buildExperienceItem(exp, secondaryColor)),
          ],

          // References
          if (resume.sections.references && resume.references.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionTitle('References', secondaryColor),
            const SizedBox(height: 12),
            ...resume.references.map((ref) => _buildReferenceItem(ref)),
          ],
        ],
      ),
    );
  }

  // ========== CREATIVE TEMPLATE ==========
  Widget _buildCreativeTemplate(
      UserProfile profile,
      List<Experience> experience,
      ) {
    final primaryColor = _parseColor(resume.theme.primaryColorHex);
    final secondaryColor = _parseColor(resume.theme.secondaryColorHex);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sidebar
        Container(
          width: 140,
          color: primaryColor,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (profile.name ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: resume.font.header1FontSize.toDouble(),
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'CONTACT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              if (profile.email != null) ...[
                Text(
                  profile.email!,
                  style: TextStyle(
                    fontSize: resume.font.contentFontSize.toDouble() - 1,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ],
              if (profile.phone != null) ...[
                Text(
                  profile.phone!,
                  style: TextStyle(
                    fontSize: resume.font.contentFontSize.toDouble() - 1,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),

        // Main content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name ?? 'Your Name',
                  style: TextStyle(
                    fontSize: resume.font.header1FontSize.toDouble() + 4,
                    fontWeight: FontWeight.bold,
                    fontFamily: resume.font.fontFamily,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  resume.title,
                  style: TextStyle(
                    fontSize: resume.font.header2FontSize.toDouble() + 2,
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                    fontFamily: resume.font.fontFamily,
                  ),
                ),

                const SizedBox(height: 24),

                // About Me
                if (resume.sections.aboutMe && resume.aboutMe != null) ...[
                  _buildSectionTitle('About', secondaryColor),
                  const SizedBox(height: 12),
                  Text(
                    resume.aboutMe!,
                    style: TextStyle(
                      fontSize: resume.font.contentFontSize.toDouble(),
                      fontFamily: resume.font.fontFamily,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Experience
                if (resume.sections.experience && experience.isNotEmpty) ...[
                  _buildSectionTitle('Experience', secondaryColor),
                  const SizedBox(height: 12),
                  ...experience.map((exp) => _buildExperienceItem(exp, secondaryColor)),
                ],

                // References
                if (resume.sections.references && resume.references.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSectionTitle('References', secondaryColor),
                  const SizedBox(height: 12),
                  ...resume.references.map((ref) => _buildReferenceItem(ref)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ========== ACADEMIC TEMPLATE ==========
  Widget _buildAcademicTemplate(
      UserProfile profile,
      List<Education> education,
      ) {
    final primaryColor = _parseColor(resume.theme.primaryColorHex);
    final secondaryColor = _parseColor(resume.theme.secondaryColorHex);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(36),
      child: Column(
        children: [
          // Centered header
          Text(
            profile.name ?? 'Your Name',
            style: TextStyle(
              fontSize: resume.font.header1FontSize.toDouble() + 2,
              fontWeight: FontWeight.bold,
              fontFamily: resume.font.fontFamily,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            resume.title,
            style: TextStyle(
              fontSize: resume.font.header2FontSize.toDouble() + 1,
              color: Colors.grey[700],
              fontFamily: resume.font.fontFamily,
            ),
            textAlign: TextAlign.center,
          ),
          if (resume.sections.personalInfo) ...[
            const SizedBox(height: 12),
            _buildContactRow(profile, Colors.black87, centered: true),
          ],

          const SizedBox(height: 24),
          Divider(color: primaryColor, thickness: 2),
          const SizedBox(height: 24),

          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // About Me
              if (resume.sections.aboutMe && resume.aboutMe != null) ...[
                _buildSectionTitle('Summary', secondaryColor),
                const SizedBox(height: 12),
                Text(
                  resume.aboutMe!,
                  style: TextStyle(
                    fontSize: resume.font.contentFontSize.toDouble(),
                    fontFamily: resume.font.fontFamily,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Education
              if (resume.sections.education && education.isNotEmpty) ...[
                _buildSectionTitle('Education', secondaryColor),
                const SizedBox(height: 12),
                ...education.map((edu) => _buildEducationItem(edu)),
                const SizedBox(height: 24),
              ],

              // References
              if (resume.sections.references && resume.references.isNotEmpty) ...[
                _buildSectionTitle('References', secondaryColor),
                const SizedBox(height: 12),
                ...resume.references.map((ref) => _buildReferenceItem(ref)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ========== HELPER WIDGETS ==========
  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: resume.font.header2FontSize.toDouble(),
        fontWeight: FontWeight.bold,
        color: color,
        fontFamily: resume.font.fontFamily,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildContactRow(UserProfile profile, Color color, {bool centered = false}) {
    final items = <Widget>[];

    if (profile.email != null) {
      items.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.email, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              profile.email!,
              style: TextStyle(
                fontSize: resume.font.contentFontSize.toDouble(),
                color: color,
                fontFamily: resume.font.fontFamily,
              ),
            ),
          ],
        ),
      );
    }

    if (profile.phone != null) {
      items.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phone, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              profile.phone!,
              style: TextStyle(
                fontSize: resume.font.contentFontSize.toDouble(),
                color: color,
                fontFamily: resume.font.fontFamily,
              ),
            ),
          ],
        ),
      );
    }

    if (profile.city != null || profile.country != null) {
      items.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              '${profile.city ?? ''}${profile.city != null && profile.country != null ? ', ' : ''}${profile.country ?? ''}',
              style: TextStyle(
                fontSize: resume.font.contentFontSize.toDouble(),
                color: color,
                fontFamily: resume.font.fontFamily,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      alignment: centered ? WrapAlignment.center : WrapAlignment.start,
      spacing: 16,
      runSpacing: 8,
      children: items,
    );
  }

  Widget _buildExperienceItem(Experience exp, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
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
            '${exp.company ?? ''} ${exp.employmentType != null ? '• ${exp.employmentType}' : ''}',
            style: TextStyle(
              fontSize: resume.font.contentFontSize.toDouble(),
              color: color,
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
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEducationItem(Education edu) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
            ),
          ),
          if (edu.gpa != null) ...[
            const SizedBox(height: 2),
            Text(
              'GPA: ${edu.gpa}',
              style: TextStyle(
                fontSize: resume.font.contentFontSize.toDouble(),
                fontFamily: resume.font.fontFamily,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReferenceItem(ResumeReference ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
          Text(
            ref.position,
            style: TextStyle(
              fontSize: resume.font.contentFontSize.toDouble(),
              fontFamily: resume.font.fontFamily,
            ),
          ),
          Text(
            ref.contact,
            style: TextStyle(
              fontSize: resume.font.contentFontSize.toDouble(),
              color: Colors.grey[600],
              fontFamily: resume.font.fontFamily,
            ),
          ),
        ],
      ),
    );
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
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: viewModel.isDownloading
                          ? null
                          : () async {
                        await viewModel.downloadResume(resume);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: viewModel.isDownloading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.download, color: Colors.white),
                      label: const Text(
                        'Download PDF',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: viewModel.isSharing
                        ? null
                        : () async {
                      await viewModel.shareResume(resume);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF7C3AED)),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: viewModel.isSharing
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF7C3AED),
                      ),
                    )
                        : const Icon(Icons.share, color: Color(0xFF7C3AED)),
                    label: const Text(
                      'Share',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C3AED),
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
}