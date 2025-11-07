// lib/views/resume_builder/template_selection_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/ViewModel/profile_view_model.dart';
import 'package:path_wise/view/resume/resume_customize_view.dart';
import 'package:path_wise/model/resume_model.dart';
import 'package:path_wise/model/user_profile.dart';

class TemplateSelectionPage extends StatefulWidget {
  const TemplateSelectionPage({Key? key}) : super(key: key);

  @override
  State<TemplateSelectionPage> createState() => _TemplateSelectionPageState();
}

class _TemplateSelectionPageState extends State<TemplateSelectionPage> {
  ResumeTemplateType? _selectedTemplate;
  bool _showPreview = false;

  final Map<ResumeTemplateType, Map<String, dynamic>> _templates = {
    ResumeTemplateType.tech: {
      'name': 'Modern Tech',
      'description': 'Clean and modern design perfect for tech professionals',
      'icon': Icons.computer,
      'color': Color(0xFF3B82F6),
      'gradient': [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
      'features': ['Clean Layout', 'Skills Focus', 'Project Showcase'],
    },
    ResumeTemplateType.business: {
      'name': 'Classic Business',
      'description': 'Professional and traditional for corporate roles',
      'icon': Icons.business_center,
      'color': Color(0xFF10B981),
      'gradient': [Color(0xFF10B981), Color(0xFF059669)],
      'features': ['Professional', 'ATS-Friendly', 'Experience Focus'],
    },
    ResumeTemplateType.creative: {
      'name': 'Creative',
      'description': 'Bold and unique for creative professionals',
      'icon': Icons.palette,
      'color': Color(0xFF8B5CF6),
      'gradient': [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
      'features': ['Bold Design', 'Portfolio Ready', 'Eye-Catching'],
    },
    ResumeTemplateType.academic: {
      'name': 'Academic',
      'description': 'Formal and structured for academic positions',
      'icon': Icons.school,
      'color': Color(0xFFF59E0B),
      'gradient': [Color(0xFFF59E0B), Color(0xFFD97706)],
      'features': ['Traditional', 'Publication Focus', 'Research Ready'],
    },
  };

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
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _showPreview && _selectedTemplate != null
                      ? _buildPreviewSection()
                      : _buildTemplateGrid(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_showPreview)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                setState(() {
                  _showPreview = false;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _showPreview ? 'Template Preview' : 'Choose Template',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _showPreview
                      ? 'Review the template before customizing'
                      : 'Select a template that suits your industry',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateGrid() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text(
            'Popular Templates',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_templates.length} professional templates available',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _templates.length,
            itemBuilder: (context, index) {
              final template = ResumeTemplateType.values[index];
              final templateData = _templates[template]!;
              return _buildTemplateCard(template, templateData);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(
      ResumeTemplateType template,
      Map<String, dynamic> data,
      ) {
    final isSelected = _selectedTemplate == template;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? data['color'] : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? data['color'].withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedTemplate = template;
            });
            Future.delayed(const Duration(milliseconds: 300), () {
              setState(() {
                _showPreview = true;
              });
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Template Preview Image
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: data['gradient'],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Template mini preview
                      Center(
                        child: _buildTemplateMiniPreview(template),
                      ),
                      if (isSelected)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.check,
                              size: 16,
                              color: data['color'],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Template Info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            data['icon'],
                            size: 18,
                            color: data['color'],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              data['name'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          data['description'],
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF6B7280),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: (data['features'] as List<String>)
                            .take(2)
                            .map((feature) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: data['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            feature,
                            style: TextStyle(
                              fontSize: 8,
                              color: data['color'],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ))
                            .toList(),
                      ),
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

  Widget _buildTemplateMiniPreview(ResumeTemplateType template) {
    return Container(
      width: 120,
      height: 160,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildTemplateLayout(template),
      ),
    );
  }

  Widget _buildTemplateLayout(ResumeTemplateType template) {
    switch (template) {
      case ResumeTemplateType.tech:
        return _buildTechLayout();
      case ResumeTemplateType.business:
        return _buildBusinessLayout();
      case ResumeTemplateType.creative:
        return _buildCreativeLayout();
      case ResumeTemplateType.academic:
        return _buildAcademicLayout();
    }
  }

  Widget _buildTechLayout() {
    return Column(
      children: [
        Container(
          height: 35,
          color: const Color(0xFF3B82F6),
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(height: 4, width: 40, color: Colors.white),
              const SizedBox(height: 3),
              Container(height: 2, width: 30, color: Colors.white70),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 2, width: 25, color: const Color(0xFF3B82F6)),
                const SizedBox(height: 4),
                Container(height: 1.5, width: 50, color: Colors.grey[300]),
                Container(height: 1.5, width: 45, color: Colors.grey[300]),
                const SizedBox(height: 6),
                Container(height: 2, width: 25, color: const Color(0xFF3B82F6)),
                const SizedBox(height: 4),
                Container(height: 1.5, width: 50, color: Colors.grey[300]),
                Container(height: 1.5, width: 48, color: Colors.grey[300]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessLayout() {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 3, width: 30, color: Colors.black87),
                  const SizedBox(height: 2),
                  Container(height: 2, width: 25, color: Colors.grey[400]),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: Colors.grey[300]),
          const SizedBox(height: 6),
          Container(height: 2, width: 30, color: const Color(0xFF10B981)),
          const SizedBox(height: 4),
          Container(height: 1.5, width: 50, color: Colors.grey[300]),
          Container(height: 1.5, width: 45, color: Colors.grey[300]),
          const SizedBox(height: 6),
          Container(height: 2, width: 30, color: const Color(0xFF10B981)),
          const SizedBox(height: 4),
          Container(height: 1.5, width: 50, color: Colors.grey[300]),
          Container(height: 1.5, width: 48, color: Colors.grey[300]),
        ],
      ),
    );
  }

  Widget _buildCreativeLayout() {
    return Row(
      children: [
        Container(
          width: 35,
          color: const Color(0xFF8B5CF6),
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 8),
              Container(height: 1, color: Colors.white70),
              const SizedBox(height: 4),
              Container(height: 1, color: Colors.white70),
              const SizedBox(height: 4),
              Container(height: 1, color: Colors.white70),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 3, width: 35, color: Colors.black87),
                const SizedBox(height: 2),
                Container(height: 2, width: 25, color: const Color(0xFF8B5CF6)),
                const SizedBox(height: 6),
                Container(height: 1.5, width: 45, color: Colors.grey[300]),
                Container(height: 1.5, width: 40, color: Colors.grey[300]),
                const SizedBox(height: 6),
                Container(height: 2, width: 25, color: const Color(0xFF8B5CF6)),
                const SizedBox(height: 4),
                Container(height: 1.5, width: 45, color: Colors.grey[300]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAcademicLayout() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(height: 4, width: 40, color: Colors.black87),
          const SizedBox(height: 2),
          Container(height: 2, width: 35, color: Colors.grey[400]),
          const SizedBox(height: 2),
          Container(height: 1.5, width: 30, color: Colors.grey[400]),
          const SizedBox(height: 6),
          Container(height: 1, color: Colors.grey[300]),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 2, width: 30, color: const Color(0xFFF59E0B)),
                const SizedBox(height: 4),
                Container(height: 1.5, width: 45, color: Colors.grey[300]),
                Container(height: 1.5, width: 40, color: Colors.grey[300]),
                const SizedBox(height: 6),
                Container(height: 2, width: 30, color: const Color(0xFFF59E0B)),
                const SizedBox(height: 4),
                Container(height: 1.5, width: 45, color: Colors.grey[300]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    final templateData = _templates[_selectedTemplate]!;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildFullTemplatePreview(),
                const SizedBox(height: 20),
                _buildTemplateDetails(templateData),
              ],
            ),
          ),
        ),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildFullTemplatePreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 500,
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
        child: _buildFullTemplateLayout(_selectedTemplate!),
      ),
    );
  }

  Widget _buildFullTemplateLayout(ResumeTemplateType template) {
    final profileVM = context.watch<ProfileViewModel>();
    final profile = profileVM.profile;
    final skills = profileVM.skills;
    final education = profileVM.education;
    final experience = profileVM.experience;

    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (template) {
      case ResumeTemplateType.tech:
        return _buildFullTechTemplate(profile, skills, experience);
      case ResumeTemplateType.business:
        return _buildFullBusinessTemplate(profile, experience);
      case ResumeTemplateType.creative:
        return _buildFullCreativeTemplate(profile, experience);
      case ResumeTemplateType.academic:
        return _buildFullAcademicTemplate(profile, education);
    }
  }

  Widget _buildFullTechTemplate(UserProfile profile, List<Skill> skills, List<Experience> experience) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name ?? 'Your Name',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Software Engineer',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.email, size: 14, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      profile.email ?? 'email@example.com',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Skills', const Color(0xFF3B82F6)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills.take(6).map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF3B82F6).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        skill.name ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF3B82F6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('Experience', const Color(0xFF3B82F6)),
                const SizedBox(height: 12),
                ...experience.take(2).map((exp) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exp.jobTitle ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          exp.company ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullBusinessTemplate(UserProfile profile, List<Experience> experience) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (profile.name ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name ?? 'Your Name',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Business Professional',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildSectionTitle('Professional Experience', const Color(0xFF10B981)),
            const SizedBox(height: 12),
            ...experience.take(2).map((exp) {
              return _buildBusinessExperienceItem(exp);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFullCreativeTemplate(UserProfile profile, List<Experience> experience) {
    return Row(
      children: [
        Container(
          width: 120,
          color: const Color(0xFF8B5CF6),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (profile.name ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'CONTACT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                profile.email ?? '',
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name ?? 'Your Name',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Creative Professional',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8B5CF6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('Experience', const Color(0xFF8B5CF6)),
                const SizedBox(height: 12),
                ...experience.take(2).map((exp) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exp.jobTitle ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          exp.company ?? '',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullAcademicTemplate(UserProfile profile, List<Education> education) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Text(
            profile.name ?? 'Your Name',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Ph.D. Candidate',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            profile.email ?? 'email@university.edu',
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          _buildSectionTitle('Education', const Color(0xFFF59E0B)),
          const SizedBox(height: 12),
          ...education.take(2).map((edu) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    edu.institution ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${edu.degreeLevel ?? ''} in ${edu.fieldOfStudy ?? ''}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBusinessExperienceItem(Experience exp) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exp.jobTitle ?? '',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            exp.company ?? '',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF10B981),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (exp.description != null) ...[
            const SizedBox(height: 4),
            Text(
              exp.description!,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: color,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTemplateDetails(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: data['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  data['icon'],
                  color: data['color'],
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['description'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Key Features:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          ...(data['features'] as List<String>).map((feature) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 18,
                    color: data['color'],
                  ),
                  const SizedBox(width: 12),
                  Text(
                    feature,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final templateData = _templates[_selectedTemplate]!;

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
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _showPreview = false;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: templateData['color']),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Change Template',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: templateData['color'],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: templateData['gradient'],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: templateData['color'].withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _useThisTemplate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Use Template',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _useThisTemplate() async {
    if (_selectedTemplate == null) return;

    // Show dialog to get resume title
    final titleController = TextEditingController(text: 'My Resume');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Resume Title'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Give your resume a title to help you identify it later.',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Resume Title',
                hintText: 'e.g., Software Engineer Resume',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.title),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      // Create initial resume with selected template
      final initialResume = ResumeDoc(
        id: 'temp',
        title: titleController.text.isEmpty ? 'My Resume' : titleController.text,
        template: _selectedTemplate!,
        theme: const ResumeThemeConfig(),
        font: const ResumeFontConfig(),
        sections: const ResumeSectionConfig(),
        aboutMe: null,
        references: const [],
      );

      // Navigate to customization page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CustomizeResumePage(
            resume: initialResume,
            isEditing: false,
          ),
        ),
      );
    }
  }
}