// lib/view/resume/resume_customize_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/viewModel/resume_view_model.dart';
import 'package:path_wise/viewModel/profile_view_model.dart';
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
                      _buildTabBar(),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customize Resume',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getTemplateName(_selectedTemplate),
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
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        isScrollable: false,
        tabs: const [
          Tab(icon: Icon(Icons.view_agenda, size: 18), text: 'Sections'),
          Tab(icon: Icon(Icons.edit_note, size: 18), text: 'Content'),
          Tab(icon: Icon(Icons.text_fields, size: 18), text: 'Fonts'),
          Tab(icon: Icon(Icons.palette, size: 18), text: 'Colors'),
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
          const Text(
            'Resume Title',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'e.g., Software Engineer Resume',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Choose Template',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          _buildTemplateSelector(),
          const SizedBox(height: 24),
          const Text(
            'Resume Sections',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Required sections are always included',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: isSelected ? color : Colors.grey),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey[700],
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            : const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
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
              ),
            ),
            if (required) ...[
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
                    fontSize: 9,
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

  // ===== CONTENT TAB =====
  Widget _buildContentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_sections.aboutMe) ...[
            const Text(
              'About Me / Professional Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Write a brief summary about yourself (2-3 sentences)',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _aboutMeController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'e.g., Passionate software engineer with 3+ years...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (_sections.references) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'References',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addReference,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF7C3AED),
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No references added yet',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                color: Colors.red,
                onPressed: () => _removeReference(index),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controllers['name'],
            decoration: InputDecoration(
              labelText: 'Name',
              hintText: 'e.g., Dr. John Smith',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controllers['position'],
            decoration: InputDecoration(
              labelText: 'Position / Title',
              hintText: 'e.g., Senior Lecturer at UTAR',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controllers['contact'],
            decoration: InputDecoration(
              labelText: 'Contact (Email/Phone)',
              hintText: 'e.g., john@example.com',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
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
          const Text(
            'Font Sizes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          _buildFontSizeControl(
            'Header 1 (Name & Job Title)',
            _font.header1FontSize,
            18,
            28,
                (v) =>
                setState(() => _font = _font.copyWith(header1FontSize: v)),
          ),
          const SizedBox(height: 20),
          _buildFontSizeControl(
            'Header 2 (Section Titles)',
            _font.header2FontSize,
            10,
            16,
                (v) =>
                setState(() => _font = _font.copyWith(header2FontSize: v)),
          ),
          const SizedBox(height: 20),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${value}px',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ),
            ],
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
          const Text(
            'Color Scheme',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose colors for your resume theme',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C3AED) : Colors.transparent,
            width: 2,
          ),
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _parseColor(scheme['secondary']),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                scheme['name'],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF7C3AED),
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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _previewResume,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF7C3AED)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Preview',
                  style: TextStyle(
                    fontSize: 14,
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
                ),
                child: ElevatedButton(
                  onPressed: _saveResume,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Resume',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== HELPER METHODS =====
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
      title: _titleController.text.isEmpty ? 'My Resume' : _titleController
          .text,
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
          content: Text(
              'Profile not found. Please complete your profile first.'),
          backgroundColor: Colors.red,
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

    // Show improved loading dialog
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
        aboutMe: _aboutMeController.text.isEmpty ? null : _aboutMeController
            .text,
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
        aboutMe: _aboutMeController.text.isEmpty ? null : _aboutMeController
            .text,
        references: _references,
      );
    }

    if (mounted) {
      Navigator.pop(context); // Close loading dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Resume saved successfully!',
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
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    resumeVM.error ?? 'Failed to save resume',
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
  }

// Add this helper method to build improved loading dialog
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
}