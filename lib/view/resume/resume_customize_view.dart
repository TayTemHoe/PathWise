// lib/views/resume_builder/customize_resume_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/ViewModel/resume_view_model.dart';
import 'package:path_wise/ViewModel/profile_view_model.dart';
import 'package:path_wise/model/resume_model.dart';
import 'package:path_wise/view/resume/resume_preview_view.dart';

class CustomizeResumePage extends StatefulWidget {
  final ResumeDoc? resume;
  final bool isEditing;

  const CustomizeResumePage({
    Key? key,
    this.resume,
    this.isEditing = false,
  }) : super(key: key);

  @override
  State<CustomizeResumePage> createState() => _CustomizeResumePageState();
}

class _CustomizeResumePageState extends State<CustomizeResumePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _titleController;
  late TextEditingController _aboutMeController;

  ResumeTemplateType _selectedTemplate = ResumeTemplateType.tech;
  ResumeFontConfig _font = const ResumeFontConfig();
  ResumeThemeConfig _theme = const ResumeThemeConfig();
  ResumeSectionConfig _sections = const ResumeSectionConfig();
  List<ResumeReference> _references = [];

  final List<Map<String, dynamic>> _fontFamilies = [
    {
      'name': 'Inter',
      'preview': 'The quick brown fox jumps over the lazy dog',
    },
    {
      'name': 'Roboto',
      'preview': 'The quick brown fox jumps over the lazy dog',
    },
    {
      'name': 'Open Sans',
      'preview': 'The quick brown fox jumps over the lazy dog',
    },
    {
      'name': 'Lato',
      'preview': 'The quick brown fox jumps over the lazy dog',
    },
    {
      'name': 'Poppins',
      'preview': 'The quick brown fox jumps over the lazy dog',
    },
    {
      'name': 'Montserrat',
      'preview': 'The quick brown fox jumps over the lazy dog',
    },
  ];

  final List<Map<String, dynamic>> _colorSchemes = [
    {
      'name': 'Professional Blue',
      'description': 'Primary & accent colors',
      'primary': '#3B82F6',
      'secondary': '#60A5FA',
    },
    {
      'name': 'Success Green',
      'description': 'Primary & accent colors',
      'primary': '#10B981',
      'secondary': '#34D399',
    },
    {
      'name': 'Creative Purple',
      'description': 'Primary & accent colors',
      'primary': '#8B5CF6',
      'secondary': '#A78BFA',
    },
    {
      'name': 'Bold Red',
      'description': 'Primary & accent colors',
      'primary': '#EF4444',
      'secondary': '#F87171',
    },
    {
      'name': 'Classic Gray',
      'description': 'Primary & accent colors',
      'primary': '#6B7280',
      'secondary': '#9CA3AF',
    },
    {
      'name': 'Energetic Orange',
      'description': 'Primary & accent colors',
      'primary': '#F97316',
      'secondary': '#FB923C',
    },
  ];

  final List<Map<String, dynamic>> _resumeSections = [
    {
      'key': 'aboutMe',
      'title': 'Professional Summary',
      'required': false,
    },
    {
      'key': 'experience',
      'title': 'Work Experience',
      'required': true,
    },
    {
      'key': 'education',
      'title': 'Education',
      'required': true,
    },
    {
      'key': 'skills',
      'title': 'Skills',
      'required': true,
    },
    {
      'key': 'projects',
      'title': 'Projects',
      'required': false,
    },
    {
      'key': 'certifications',
      'title': 'Certifications',
      'required': false,
    },
    {
      'key': 'hobbies',
      'title': 'Hobbies & Interests',
      'required': false,
    },
    {
      'key': 'references',
      'title': 'References',
      'required': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _titleController = TextEditingController(
      text: widget.resume?.title ?? 'My Resume',
    );
    _aboutMeController = TextEditingController(
      text: widget.resume?.aboutMe ?? '',
    );

    if (widget.resume != null) {
      _selectedTemplate = widget.resume!.template;
      _font = widget.resume!.font;
      _theme = widget.resume!.theme;
      _sections = widget.resume!.sections;
      _references = List.from(widget.resume!.references);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _aboutMeController.dispose();
    super.dispose();
  }

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
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildTemplateInfo(),
                      const SizedBox(height: 16),
                      _buildTabBar(),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildTypographyTab(),
                            _buildColorsTab(),
                            _buildSectionsTab(),
                          ],
                        ),
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

  Widget _buildHeader() {
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
                  'Customize Resume',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Personalize your resume design and content',
                  style: TextStyle(
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

  Widget _buildTemplateInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Template name row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Template: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      _getTemplateName(_selectedTemplate),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Action buttons row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildHeaderButton(
                  'Preview',
                  Icons.visibility_outlined,
                  _previewResume,
                ),
                const SizedBox(width: 8),
                _buildHeaderButton(
                  'Save',
                  Icons.save_outlined,
                  _saveResume,
                ),
                const SizedBox(width: 8),
                _buildHeaderButton(
                  'Download',
                  Icons.download_outlined,
                  _downloadPDF,
                  isPrimary: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(
      String label,
      IconData icon,
      VoidCallback onPressed, {
        bool isPrimary = false,
      }) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFF7C3AED) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: isPrimary ? null : Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isPrimary ? Colors.white : const Color(0xFF1F2937),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isPrimary ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFF7C3AED),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF6B7280),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.text_fields, size: 20),
            text: 'Typography',
          ),
          Tab(
            icon: Icon(Icons.palette, size: 20),
            text: 'Colors',
          ),
          Tab(
            icon: Icon(Icons.view_agenda, size: 20),
            text: 'Sections',
          ),
        ],
      ),
    );
  }

  Widget _buildTypographyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Font Family',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          ..._fontFamilies.map((font) => _buildFontCard(font)),
          const SizedBox(height: 24),
          const Text(
            'Font Size',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildFontSizeSlider('Base Font Size', _font.contentFontSize, 10, 18),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Current: 14px',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      '${_font.contentFontSize}px',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFontCard(Map<String, dynamic> font) {
    final isSelected = _font.fontFamily == font['name'];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF7C3AED) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _font = _font.copyWith(fontFamily: font['name']);
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      font['name'],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    if (isSelected) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF7C3AED),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  font['preview'],
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontFamily: font['name'],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFontSizeSlider(String label, int value, int min, int max) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFF7C3AED),
            inactiveTrackColor: Colors.grey[300],
            thumbColor: const Color(0xFF7C3AED),
            overlayColor: const Color(0xFF7C3AED).withOpacity(0.2),
          ),
          child: Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: (v) {
              setState(() {
                _font = _font.copyWith(contentFontSize: v.round());
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColorsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Color Scheme',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          ..._colorSchemes.map((scheme) => _buildColorSchemeCard(scheme)),
        ],
      ),
    );
  }

  Widget _buildColorSchemeCard(Map<String, dynamic> scheme) {
    final isSelected = _theme.primaryColorHex == scheme['primary'];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF7C3AED) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _theme = ResumeThemeConfig(
                primaryColorHex: scheme['primary'],
                secondaryColorHex: scheme['secondary'],
              );
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(int.parse(scheme['primary'].replaceAll('#', '0xFF'))),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scheme['name'],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        scheme['description'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF7C3AED),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resume Sections',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: _resumeSections.map((section) {
                final index = _resumeSections.indexOf(section);
                return _buildSectionToggle(
                  section,
                  index == _resumeSections.length - 1,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Section Order',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) {
                // Handle reordering
              },
              children: _resumeSections.take(4).map((section) {
                return _buildDraggableSection(section);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionToggle(Map<String, dynamic> section, bool isLast) {
    final isEnabled = _getSectionValue(section['key']);
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: SwitchListTile(
        value: isEnabled,
        onChanged: section['required']
            ? null
            : (value) {
          setState(() {
            _setSectionValue(section['key'], value);
          });
        },
        title: Row(
          children: [
            Text(
              section['title'],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
            ),
            if (section['required']) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Required',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        activeColor: const Color(0xFF7C3AED),
      ),
    );
  }

  Widget _buildDraggableSection(Map<String, dynamic> section) {
    return Container(
      key: ValueKey(section['key']),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.drag_handle, size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            section['title'],
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  bool _getSectionValue(String key) {
    switch (key) {
      case 'aboutMe':
        return _sections.aboutMe;
      case 'personalInfo':
        return _sections.personalInfo;
      case 'skills':
        return _sections.skills;
      case 'education':
        return _sections.education;
      case 'experience':
        return _sections.experience;
      case 'references':
        return _sections.references;
      default:
        return false;
    }
  }

  void _setSectionValue(String key, bool value) {
    switch (key) {
      case 'aboutMe':
        _sections = _sections.copyWith(aboutMe: value);
        break;
      case 'skills':
        _sections = _sections.copyWith(skills: value);
        break;
      case 'references':
        _sections = _sections.copyWith(references: value);
        break;
    }
  }

  void _previewResume() {
    // Create temporary resume with current settings
    final previewResume = ResumeDoc(
      id: widget.resume?.id ?? 'temp',
      title: _titleController.text.isEmpty ? 'My Resume' : _titleController.text,
      template: _selectedTemplate,
      theme: _theme,
      font: _font,
      sections: _sections,
      aboutMe: _aboutMeController.text.isEmpty ? null : _aboutMeController.text,
      references: _references,
    );

    // Navigate to preview page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreviewResumePage(resume: previewResume),
      ),
    );
  }

  void _saveResume() async {
    final resumeVM = context.read<ResumeViewModel>();
    final profileVM = context.read<ProfileViewModel>();

    // Validate profile data
    if (profileVM.profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile not found. Please complete your profile first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Saving your resume...'),
            ],
          ),
        ),
      ),
    );

    bool success = false;

    if (widget.isEditing && widget.resume != null) {
      final updated = widget.resume!.copyWith(
        title: _titleController.text,
        template: _selectedTemplate,
        theme: _theme,
        font: _font,
        sections: _sections,
        aboutMe: _aboutMeController.text.isEmpty ? null : _aboutMeController.text,
        references: _references,
        updatedAt: DateTime.now(),
      );
      success = await resumeVM.updateResume(updated);
    } else {
      success = await resumeVM.createResume(
        title: _titleController.text,
        template: _selectedTemplate,
        theme: _theme,
        font: _font,
        sections: _sections,
        aboutMe: _aboutMeController.text.isEmpty ? null : _aboutMeController.text,
        references: _references,
      );
    }

    if (mounted) {
      Navigator.pop(context); // Close loading dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resume saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate back to list
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resumeVM.error ?? 'Failed to save resume'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _downloadPDF() async {
    final resumeVM = context.read<ResumeViewModel>();
    final profileVM = context.read<ProfileViewModel>();

    if (profileVM.profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile not found. Please complete your profile first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create temporary resume for download
    final tempResume = ResumeDoc(
      id: widget.resume?.id ?? 'temp',
      title: _titleController.text,
      template: _selectedTemplate,
      theme: _theme,
      font: _font,
      sections: _sections,
      aboutMe: _aboutMeController.text.isEmpty ? null : _aboutMeController.text,
      references: _references,
    );

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final path = await resumeVM.downloadResume(tempResume);

    if (mounted) {
      Navigator.pop(context); // Close loading

      if (path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resume downloaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  String _getTemplateName(ResumeTemplateType template) {
    switch (template) {
      case ResumeTemplateType.tech:
        return 'Modern Tech';
      case ResumeTemplateType.business:
        return 'Classic Business';
      case ResumeTemplateType.creative:
        return 'Creative';
      case ResumeTemplateType.academic:
        return 'Academic';
    }
  }
}