// lib/view/resume/resume_customize_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/viewModel/resume_view_model.dart';
import 'package:path_wise/viewModel/profile_view_model.dart';
import 'package:path_wise/model/resume_model.dart';
import 'package:path_wise/view/resume/resume_preview_view.dart';

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
  static const Color warning = Color(0xFFFDCB6E);
  static Color shadow = Colors.black.withOpacity(0.08);
}

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

  // Reference controllers for dynamic fields
  final List<Map<String, TextEditingController>> _referenceControllers = [];

  final List<Map<String, dynamic>> _colorSchemes = [
    {
      'name': 'Professional Blue',
      'primary': '#3B82F6',
      'secondary': '#60A5FA',
    },
    {
      'name': 'Success Green',
      'primary': '#10B981',
      'secondary': '#34D399',
    },
    {
      'name': 'Creative Purple',
      'primary': '#8B5CF6',
      'secondary': '#A78BFA',
    },
    {
      'name': 'Bold Red',
      'primary': '#EF4444',
      'secondary': '#F87171',
    },
    {
      'name': 'Classic Gray',
      'primary': '#6B7280',
      'secondary': '#9CA3AF',
    },
    {
      'name': 'Energetic Orange',
      'primary': '#F97316',
      'secondary': '#FB923C',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      _initializeReferenceControllers();
    }
  }

  void _initializeReferenceControllers() {
    for (var ref in _references) {
      _referenceControllers.add({
        'name': TextEditingController(text: ref.name),
        'position': TextEditingController(text: ref.position),
        'contact': TextEditingController(text: ref.contact),
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _aboutMeController.dispose();
    for (var controllers in _referenceControllers) {
      controllers['name']?.dispose();
      controllers['position']?.dispose();
      controllers['contact']?.dispose();
    }
    super.dispose();
  }

  /// Handle back navigation confirmation
  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Unsaved Changes'),
        content: const Text(
          'If you exit now, your resume will be lost. Do you want to save first?',
          style: TextStyle(color: _DesignColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Return true to pop (Continue)
            child: const Text('Continue', style: TextStyle(color: _DesignColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(false); // Close dialog
              _saveResume(); // Trigger Save
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _DesignColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: _DesignColors.background,
        appBar: AppBar(
          backgroundColor: _DesignColors.background,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
                Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
            onPressed: () async {
              if (await _onWillPop()) {
                if (mounted) Navigator.pop(context);
              }
            },
          ),
          title: Column(
            children: [
              const Text(
                'Customize Resume',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _DesignColors.textPrimary,
                ),
              ),
              Text(
                _getTemplateName(_selectedTemplate),
                style: const TextStyle(
                  fontSize: 12,
                  color: _DesignColors.textSecondary,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildTabBar(),
              const SizedBox(height: 10),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSectionsTab(),
                    _buildContentTab(),
                    _buildTypographyTab(),
                    _buildColorsTab(),
                  ],
                ),
              ),
              _buildActionButtons(),
            ],
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
        boxShadow: [
          BoxShadow(
            color: _DesignColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _DesignColors.primary.withOpacity(0.1),
          border: Border.all(color: _DesignColors.primary.withOpacity(0.2)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: _DesignColors.primary,
        unselectedLabelColor: _DesignColors.textSecondary,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(icon: Icon(Icons.view_agenda_outlined, size: 20), text: 'Sections'),
          Tab(icon: Icon(Icons.edit_note_outlined, size: 20), text: 'Content'),
          Tab(icon: Icon(Icons.text_fields_outlined, size: 20), text: 'Fonts'),
          Tab(icon: Icon(Icons.palette_outlined, size: 20), text: 'Colors'),
        ],
      ),
    );
  }

  // ===== SECTIONS TAB =====
  Widget _buildSectionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputLabel('Resume Title'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _titleController,
            hint: 'e.g., Software Engineer Resume',
            icon: Icons.title,
          ),
          const SizedBox(height: 24),
          _buildInputLabel('Choose Template'),
          const SizedBox(height: 12),
          _buildTemplateSelector(),
          const SizedBox(height: 24),
          _buildInputLabel('Resume Sections'),
          const SizedBox(height: 4),
          const Text(
            'Toggle sections you want to include',
            style: TextStyle(
              fontSize: 13,
              color: _DesignColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _buildSectionToggles(),
        ],
      ),
    );
  }

  Widget _buildTemplateSelector() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildTemplateCard(
          ResumeTemplateType.tech,
          'Tech Modern',
          Icons.computer,
          const Color(0xFF3B82F6),
        ),
        _buildTemplateCard(
          ResumeTemplateType.business,
          'Business Pro',
          Icons.business_center,
          const Color(0xFF10B981),
        ),
        _buildTemplateCard(
          ResumeTemplateType.creative,
          'Creative',
          Icons.palette,
          const Color(0xFF8B5CF6),
        ),
        _buildTemplateCard(
          ResumeTemplateType.academic,
          'Academic',
          Icons.school,
          const Color(0xFFF59E0B),
        ),
      ],
    );
  }

  Widget _buildTemplateCard(ResumeTemplateType type,
      String name,
      IconData icon,
      Color color,) {
    final isSelected = _selectedTemplate == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedTemplate = type),
      child: Container(
        decoration: BoxDecoration(
          color: _DesignColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _DesignColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? _DesignColors.primary.withOpacity(0.1) : _DesignColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isSelected ? _DesignColors.primary : color).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                  icon,
                  size: 24,
                  color: isSelected ? _DesignColors.primary : color
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? _DesignColors.primary : _DesignColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionToggles() {
    return Container(
      decoration: BoxDecoration(
        color: _DesignColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _DesignColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSectionToggle(
            'Personal Information',
            _sections.personalInfo,
                (v) =>
                setState(() => _sections = _sections.copyWith(personalInfo: v)),
            required: true,
          ),
          _buildSectionToggle(
            'About Me / Summary',
            _sections.aboutMe,
                (v) =>
                setState(() => _sections = _sections.copyWith(aboutMe: v)),
          ),
          _buildSectionToggle(
            'Skills',
            _sections.skills,
                (v) =>
                setState(() => _sections = _sections.copyWith(skills: v)),
            required: true,
          ),
          _buildSectionToggle(
            'Education',
            _sections.education,
                (v) =>
                setState(() => _sections = _sections.copyWith(education: v)),
            required: true,
          ),
          _buildSectionToggle(
            'Experience',
            _sections.experience,
                (v) =>
                setState(() => _sections = _sections.copyWith(experience: v)),
            required: true,
          ),
          _buildSectionToggle(
            'References',
            _sections.references,
                (v) =>
                setState(() => _sections = _sections.copyWith(references: v)),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionToggle(String title,
      bool value,
      Function(bool) onChanged, {
        bool required = false,
        bool isLast = false,
      }) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: required ? null : onChanged,
        title: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _DesignColors.textPrimary,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _DesignColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Required',
                  style: TextStyle(
                    fontSize: 10,
                    color: _DesignColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        activeColor: _DesignColors.primary,
        activeTrackColor: _DesignColors.primary.withOpacity(0.2),
      ),
    );
  }

  // ===== CONTENT TAB =====
  Widget _buildContentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_sections.aboutMe) ...[
            _buildInputLabel('About Me / Professional Summary'),
            const SizedBox(height: 8),
            const Text(
              'Write a brief summary about yourself (2-3 sentences)',
              style: TextStyle(fontSize: 12, color: _DesignColors.textSecondary),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _aboutMeController,
              hint: 'e.g., Passionate software engineer with 3+ years...',
              maxLines: 5,
            ),
            const SizedBox(height: 24),
          ],
          if (_sections.references) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInputLabel('References'),
                TextButton.icon(
                  onPressed: _addReference,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: TextButton.styleFrom(
                    foregroundColor: _DesignColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildReferencesList(),
          ],
        ],
      ),
    );
  }

  Widget _buildReferencesList() {
    if (_referenceControllers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(
          color: _DesignColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'No references added yet',
              style: TextStyle(color: _DesignColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(_referenceControllers.length, (index) {
        return _buildReferenceCard(index);
      }),
    );
  }

  Widget _buildReferenceCard(int index) {
    final controllers = _referenceControllers[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _DesignColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _DesignColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reference ${index + 1}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _DesignColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: _DesignColors.error,
                onPressed: () => _removeReference(index),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: controllers['name']!,
            label: 'Name',
            hint: 'e.g., Dr. John Smith',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: controllers['position']!,
            label: 'Position / Title',
            hint: 'e.g., Senior Lecturer at UTAR',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: controllers['contact']!,
            label: 'Contact (Email/Phone)',
            hint: 'e.g., john@example.com',
          ),
        ],
      ),
    );
  }

  void _addReference() {
    setState(() {
      _referenceControllers.add({
        'name': TextEditingController(),
        'position': TextEditingController(),
        'contact': TextEditingController(),
      });
    });
  }

  void _removeReference(int index) {
    setState(() {
      _referenceControllers[index]['name']?.dispose();
      _referenceControllers[index]['position']?.dispose();
      _referenceControllers[index]['contact']?.dispose();
      _referenceControllers.removeAt(index);
    });
  }

  // ===== TYPOGRAPHY TAB =====
  Widget _buildTypographyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputLabel('Font Sizes'),
          const SizedBox(height: 16),
          _buildFontSizeControl(
            'Header 1 (Name & Job Title)',
            _font.header1FontSize,
            18,
            28,
                (v) =>
                setState(() => _font = _font.copyWith(header1FontSize: v)),
          ),
          const SizedBox(height: 16),
          _buildFontSizeControl(
            'Header 2 (Section Titles)',
            _font.header2FontSize,
            10,
            16,
                (v) =>
                setState(() => _font = _font.copyWith(header2FontSize: v)),
          ),
          const SizedBox(height: 16),
          _buildFontSizeControl(
            'Content (Body Text)',
            _font.contentFontSize,
            9,
            14,
                (v) =>
                setState(() => _font = _font.copyWith(contentFontSize: v)),
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizeControl(String label,
      int value,
      int min,
      int max,
      Function(int) onChanged,) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DesignColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _DesignColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _DesignColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _DesignColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${value}px',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _DesignColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _DesignColors.primary,
              inactiveTrackColor: Colors.grey[200],
              thumbColor: _DesignColors.primary,
              overlayColor: _DesignColors.primary.withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ],
      ),
    );
  }

  // ===== COLORS TAB =====
  Widget _buildColorsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputLabel('Color Scheme'),
          const SizedBox(height: 8),
          const Text(
            'Choose colors for your resume theme',
            style: TextStyle(fontSize: 12, color: _DesignColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ..._colorSchemes.map((scheme) => _buildColorSchemeCard(scheme)),
        ],
      ),
    );
  }

  Widget _buildColorSchemeCard(Map<String, dynamic> scheme) {
    final isSelected = _theme.primaryColorHex == scheme['primary'];
    return GestureDetector(
      onTap: () {
        setState(() {
          _theme = ResumeThemeConfig(
            primaryColorHex: scheme['primary'],
            secondaryColorHex: scheme['secondary'],
          );
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _DesignColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _DesignColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? _DesignColors.primary.withOpacity(0.1) : _DesignColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _parseColor(scheme['primary']),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _parseColor(scheme['secondary']),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                scheme['name'],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? _DesignColors.primary : _DesignColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: _DesignColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  // ===== ACTION BUTTONS =====
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _DesignColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: _DesignColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _previewResume,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _DesignColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Preview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _DesignColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _saveResume,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _DesignColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Resume',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: _DesignColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hint,
    String? label,
    IconData? icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _DesignColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: _DesignColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: icon != null ? Icon(icon, color: _DesignColors.primary) : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _DesignColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Color _parseColor(String hex) {
    final hexColor = hex.replaceAll('#', '');
    final r = int.parse(hexColor.substring(0, 2), radix: 16);
    final g = int.parse(hexColor.substring(2, 4), radix: 16);
    final b = int.parse(hexColor.substring(4, 6), radix: 16);
    return Color.fromRGBO(r, g, b, 1.0);
  }

  String _getTemplateName(ResumeTemplateType template) {
    switch (template) {
      case ResumeTemplateType.tech:
        return 'Tech Modern Template';
      case ResumeTemplateType.business:
        return 'Business Professional Template';
      case ResumeTemplateType.creative:
        return 'Creative Template';
      case ResumeTemplateType.academic:
        return 'Academic Template';
    }
  }

  void _previewResume() {
    // Collect references
    _references = _referenceControllers
        .where((c) =>
    c['name']!.text.isNotEmpty ||
        c['position']!.text.isNotEmpty ||
        c['contact']!.text.isNotEmpty)
        .map((c) =>
        ResumeReference(
          name: c['name']!.text,
          position: c['position']!.text,
          contact: c['contact']!.text,
        ))
        .toList();

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

    if (profileVM.profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile not found. Please complete your profile first.'),
          backgroundColor: _DesignColors.error,
        ),
      );
      return;
    }

    // Collect references
    _references = _referenceControllers
        .where((c) =>
    c['name']!.text.isNotEmpty &&
        c['position']!.text.isNotEmpty &&
        c['contact']!.text.isNotEmpty)
        .map((c) =>
        ResumeReference(
          name: c['name']!.text,
          position: c['position']!.text,
          contact: c['contact']!.text,
        ))
        .toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildLoadingDialog('Saving your resume...'),
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
            backgroundColor: _DesignColors.success,
          ),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resumeVM.error ?? 'Failed to save resume'),
            backgroundColor: _DesignColors.error,
          ),
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _DesignColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}