import 'package:flutter/material.dart';
import 'package:path_wise/utils/formatters.dart';
import '../../model/ai_match_model.dart';
import '../../utils/app_color.dart';
import '../../viewModel/ai_match_view_model.dart';
import '../form_components.dart';

class AcademicRecordDialog extends StatefulWidget {
  final AIMatchViewModel viewModel;
  final AcademicRecord? existingRecord;
  final int? recordIndex;

  const AcademicRecordDialog({
    Key? key,
    required this.viewModel,
    this.existingRecord,
    this.recordIndex,
  }) : super(key: key);

  @override
  State<AcademicRecordDialog> createState() => _AcademicRecordDialogState();
}

class _AcademicRecordDialogState extends State<AcademicRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _institutionController = TextEditingController();
  final _majorController = TextEditingController();
  final _streamController = TextEditingController();
  final _researchAreaController = TextEditingController();
  final _thesisTitleController = TextEditingController();

  int? _selectedYear;
  String? _selectedExamType;
  String? _selectedStream;
  String? _selectedClassOfAward;
  String? _selectedHonors;
  String? _selectedClassification;
  double _cgpaValue = 0.0;

  final List<SubjectGrade> _currentSubjects = [];
  String? _formError;

  bool get isEditMode => widget.existingRecord != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _loadExistingRecord();
    }
  }

  void _loadExistingRecord() {
    final record = widget.existingRecord!;

    _institutionController.text = record.institution ?? '';
    _majorController.text = record.major ?? '';
    _streamController.text = record.programName ?? '';
    _researchAreaController.text = record.researchArea ?? '';
    _thesisTitleController.text = record.thesisTitle ?? '';

    _selectedYear = record.graduationYear;
    _selectedExamType = record.examType;
    _selectedStream = record.stream;
    _selectedClassOfAward = record.classOfAward;
    _selectedHonors = record.honors;
    _selectedClassification = record.classification;
    _cgpaValue = record.cgpa ?? record.totalScore ?? 0.0;

    _currentSubjects.addAll(record.subjects);
  }

  @override
  void dispose() {
    _institutionController.dispose();
    _majorController.dispose();
    _streamController.dispose();
    _researchAreaController.dispose();
    _thesisTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 24.0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.95,
          maxWidth: MediaQuery.of(context).size.width * 0.95,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DialogHeader(
              title: isEditMode
                  ? 'Edit ${widget.viewModel.educationLevel?.label ?? "Academic"} Record'
                  : 'Add ${widget.viewModel.educationLevel?.label ?? "Academic"} Record',
              icon: isEditMode ? Icons.edit_rounded : Icons.school_rounded,
              onClose: () => Navigator.pop(context),
            ),
            if (_formError != null) _buildErrorBanner(),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildFormContent(),
                ),
              ),
            ),
            DialogFooter(
              onCancel: () => Navigator.pop(context),
              onSave: _saveRecord,
              saveLabel: isEditMode ? 'Update Record' : 'Save Record',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border(
          bottom: BorderSide(color: Colors.red[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _formError!,
              style: TextStyle(
                color: Colors.red[900],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: Colors.red[700]),
            onPressed: () => setState(() => _formError = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    setState(() => _formError = message);
  }

  Widget _buildFormContent() {
    switch (widget.viewModel.educationLevel) {
      case EducationLevel.spm:
        return _buildSPMForm();
      case EducationLevel.stpm:
        return _buildSTPMForm();
      case EducationLevel.foundation:
        return _buildFoundationForm();
      case EducationLevel.diploma:
        return _buildDiplomaForm();
      case EducationLevel.bachelor:
        return _buildBachelorForm();
      case EducationLevel.master:
        return _buildMasterForm();
      case EducationLevel.phd:
        return _buildPhDForm();
      default:
        return _buildGenericForm();
    }
  }

  Widget _buildSPMForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Basic Information',
          icon: Icons.info_outline,
        ),
        const SizedBox(height: 16),
        CustomDropdownField<String>(
          label: 'Exam Type',
          value: _selectedExamType,
          items: const ['SPM', 'IGCSE', 'O-Level'],
          onChanged: (value) => setState(() => _selectedExamType = value),
          isRequired: true,
        ),
        const SizedBox(height: 16),
        CustomDropdownField<String>(
          label: 'Stream',
          value: _selectedStream,
          items: const [
            'Pure Science',
            'Arts',
            'Commerce',
            'Technical',
            'Vocational',
            'Religious (Islamic Studies)',
            'Agriculture',
            'Sports Science',
            'Arts & Design',
            'ICT / Computer Science',
            'Other',
          ],
          isRequired: true,
          onChanged: (value) => setState(() => _selectedStream = value),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Institution',
          controller: _institutionController,
          hint: 'Enter school name',
          prefixIcon: Icons.business_rounded,
        ),
        const SizedBox(height: 16),
        CustomYearPicker(
          label: 'Year of Completion',
          selectedYear: _selectedYear,
          onYearSelected: (year) => setState(() => _selectedYear = year),
          validator: Formatters.validateYear,
        ),
        const SizedBox(height: 24),
        const SectionHeader(
          title: 'Subjects & Grades',
          icon: Icons.library_books_rounded,
        ),
        const SizedBox(height: 5),
        _buildSubjectsSection([
          'A+',
          'A',
          'A-',
          'B+',
          'B',
          'C+',
          'C',
          'D',
          'E',
          'F',
        ]),
      ],
    );
  }

  Widget _buildSTPMForm() {
    final double min = 0.0;
    final double max = _selectedExamType == 'STPM'
        ? 4.0
        : _selectedExamType == 'IB'
        ? 45.0
        : 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Basic Information',
          icon: Icons.info_outline,
        ),
        const SizedBox(height: 16),
        CustomDropdownField<String>(
          label: 'Qualification Type',
          value: _selectedExamType,
          items: const ['STPM', 'A-Level', 'IB', 'UEC'],
          onChanged: (value) {
            setState(() {
              _selectedExamType = value;
              _selectedStream = null;
              _cgpaValue = 0;
            });
          },
          isRequired: true,
        ),
        const SizedBox(height: 16),
        CustomDropdownField<String>(
          label: 'Stream / Field',
          value: _selectedStream,
          items: _getStreamOptions(_selectedExamType),
          onChanged: (value) => setState(() => _selectedStream = value),
          isRequired: true,
        ),
        const SizedBox(height: 16),
        if (_selectedExamType == 'STPM' ||
            _selectedExamType == 'IB' ||
            _selectedExamType == 'UEC') ...[
          CustomSlider(
            label: _selectedExamType == 'STPM'
                ? 'CGPA'
                : _selectedExamType == 'IB'
                ? 'Total Score'
                : 'Aggregate Score',
            value: _cgpaValue,
            min: min,
            max: max,
            onChanged: (value) => setState(() => _cgpaValue = value),
            isRequired: true,
            validator: (value) {
              return Formatters.validateCGPA(value ?? 0.0, min, max);
            },
          ),
          const SizedBox(height: 16),
        ],
        CustomTextField(
          label: 'Institution',
          controller: _institutionController,
          hint: 'Enter institution name',
          prefixIcon: Icons.business_rounded,
        ),
        const SizedBox(height: 16),
        CustomYearPicker(
          label: 'Year of Completion',
          selectedYear: _selectedYear,
          onYearSelected: (year) => setState(() => _selectedYear = year),
          validator: Formatters.validateYear,
        ),
        const SizedBox(height: 16),
        const SectionHeader(
          title: 'Subjects & Grades',
          icon: Icons.library_books_rounded,
        ),
        const SizedBox(height: 5),
        _buildSubjectsSection(_getGradeOptions(_selectedExamType)),
      ],
    );
  }

  Widget _buildFoundationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Programme Information',
          icon: Icons.folder_outlined,
        ),
        const SizedBox(height: 16),
        CustomDropdownField<String>(
          label: 'Qualification Type',
          value: _selectedExamType,
          items: const ['Foundation', 'Matriculation'],
          onChanged: (value) {
            setState(() {
              _selectedExamType = value;
              _streamController.text = '';
              _cgpaValue = 0;
            });
          },
          isRequired: true,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Field of Study',
          controller: _streamController,
          hint: 'e.g., Foundation in Science',
          prefixIcon: Icons.folder_outlined,
          isRequired: true,
          validator: Formatters.validateProgramName,
        ),
        const SizedBox(height: 16),
        CustomSlider(
          label: 'CGPA',
          value: _cgpaValue,
          min: 0.0,
          max: 4.0,
          onChanged: (value) => setState(() => _cgpaValue = value),
          isRequired: true,
          validator: (value) {
            return Formatters.validateCGPA(value ?? 0.0, 0.0, 4.0);
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Institution',
          controller: _institutionController,
          hint: 'Enter institution name',
          prefixIcon: Icons.business_rounded,
        ),
        const SizedBox(height: 16),
        CustomYearPicker(
          label: 'Year of Completion',
          selectedYear: _selectedYear,
          onYearSelected: (year) => setState(() => _selectedYear = year),
          validator: Formatters.validateYear,
        ),
      ],
    );
  }

  Widget _buildDiplomaForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Programme Information',
          icon: Icons.folder_outlined,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Programme Name',
          controller: _streamController,
          hint: 'e.g., Diploma in Computer Science',
          prefixIcon: Icons.school_outlined,
          isRequired: true,
          validator: Formatters.validateProgramName,
        ),
        const SizedBox(height: 16),
        CustomSlider(
          label: 'CGPA',
          value: _cgpaValue,
          min: 0.0,
          max: 4.0,
          onChanged: (value) => setState(() => _cgpaValue = value),
          isRequired: true,
          validator: (value) {
            return Formatters.validateCGPA(value ?? 0.0, 0.0, 4.0);
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Institution',
          controller: _institutionController,
          hint: 'Enter institution name',
          prefixIcon: Icons.business_rounded,
        ),
        const SizedBox(height: 16),
        CustomDropdownField<String>(
          label: 'Class of Award',
          value: _selectedClassOfAward,
          items: const [
            'High Distinction',
            'Distinction',
            'Merit',
            'Credit',
            'Pass with Commendation',
            'Pass',
          ],
          onChanged: (value) => setState(() => _selectedClassOfAward = value),
        ),
        const SizedBox(height: 16),
        CustomYearPicker(
          label: 'Year of Completion',
          selectedYear: _selectedYear,
          onYearSelected: (year) => setState(() => _selectedYear = year),
          validator: Formatters.validateYear,
          isRequired: false,
        ),
      ],
    );
  }

  Widget _buildBachelorForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Programme Information',
          icon: Icons.folder_outlined,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Major / Programme',
          controller: _majorController,
          hint: 'e.g., Bachelor of Software Engineering',
          prefixIcon: Icons.school_outlined,
          isRequired: true,
          validator: (value) => Formatters.validateRequired(value, 'Major'),
        ),
        const SizedBox(height: 16),
        CustomSlider(
          label: 'CGPA',
          value: _cgpaValue,
          min: 0.0,
          max: 4.0,
          onChanged: (value) => setState(() => _cgpaValue = value),
          isRequired: true,
          validator: (value) {
            return Formatters.validateCGPA(value ?? 0.0, 0.0, 4.0);
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Institution',
          controller: _institutionController,
          hint: 'Enter university name',
          prefixIcon: Icons.business_rounded,
        ),
        const SizedBox(height: 16),
        CustomDropdownField<String>(
          label: 'Honours Class',
          value: _selectedHonors,
          items: const [
            'First Class',
            'Second Class Upper Division',
            'Second Class Lower Division',
            'Third Class',
            'Pass',
          ],
          onChanged: (value) => setState(() => _selectedHonors = value),
        ),
        const SizedBox(height: 16),
        CustomYearPicker(
          label: 'Year of Completion',
          selectedYear: _selectedYear,
          onYearSelected: (year) => setState(() => _selectedYear = year),
          validator: Formatters.validateYear,
        ),
      ],
    );
  }

  Widget _buildMasterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Programme Information',
          icon: Icons.folder_outlined,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Research Area / Field',
          controller: _researchAreaController,
          hint: 'e.g., Master in Computer Engineering',
          prefixIcon: Icons.psychology_outlined,
          isRequired: true,
          validator: (value) =>
              Formatters.validateRequired(value, 'Research area'),
        ),
        const SizedBox(height: 16),
        CustomSlider(
          label: 'CGPA',
          value: _cgpaValue,
          min: 0.0,
          max: 4.0,
          onChanged: (value) => setState(() => _cgpaValue = value),
          isRequired: true,
          validator: (value) {
            return Formatters.validateCGPA(value ?? 0.0, 0.0, 4.0);
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Institution',
          controller: _institutionController,
          hint: 'Enter university name',
          prefixIcon: Icons.business_rounded,
        ),
        const SizedBox(height: 16),
        CustomDropdownField<String>(
          label: 'Classification',
          value: _selectedClassification,
          items: const ['Distinction', 'Merit', 'Pass'],
          onChanged: (value) => setState(() => _selectedClassification = value),
        ),
        const SizedBox(height: 16),
        CustomYearPicker(
          label: 'Year of Completion',
          selectedYear: _selectedYear,
          onYearSelected: (year) => setState(() => _selectedYear = year),
          validator: Formatters.validateYear,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Thesis Title',
          controller: _thesisTitleController,
          hint: 'Enter thesis title',
          prefixIcon: Icons.article_outlined,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildPhDForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Research Information',
          icon: Icons.science_outlined,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Research Area',
          controller: _researchAreaController,
          hint: 'e.g., Quantum Computing',
          prefixIcon: Icons.science_outlined,
          isRequired: true,
          validator: (value) =>
              Formatters.validateRequired(value, 'Research area'),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Dissertation Title',
          controller: _thesisTitleController,
          hint: 'Enter dissertation title',
          prefixIcon: Icons.article_outlined,
          maxLines: 2,
          isRequired: true,
          validator: (value) =>
              Formatters.validateRequired(value, 'Dissertation title'),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Institution',
          controller: _institutionController,
          hint: 'Enter university name',
          prefixIcon: Icons.business_rounded,
        ),
        const SizedBox(height: 16),
        CustomYearPicker(
          label: 'Year of Completion',
          selectedYear: _selectedYear,
          onYearSelected: (year) => setState(() => _selectedYear = year),
          validator: Formatters.validateYear,
        ),
      ],
    );
  }

  Widget _buildGenericForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Academic Information',
          icon: Icons.info_outline,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Programme / Field',
          controller: _majorController,
          hint: 'Enter your programme',
          prefixIcon: Icons.school_outlined,
          isRequired: true,
          validator: (value) => Formatters.validateRequired(value, 'Programme'),
        ),
        const SizedBox(height: 16),
        CustomSlider(
          label: 'CGPA',
          value: _cgpaValue,
          min: 0.0,
          max: 4.0,
          onChanged: (value) => setState(() => _cgpaValue = value),
          isRequired: true,
          validator: (value) {
            return Formatters.validateCGPA(value ?? 0.0, 0.0, 4.0);
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Institution',
          controller: _institutionController,
          hint: 'Enter institution name',
          prefixIcon: Icons.business_rounded,
        ),
        const SizedBox(height: 16),
        CustomYearPicker(
          label: 'Year of Completion',
          selectedYear: _selectedYear,
          onYearSelected: (year) => setState(() => _selectedYear = year),
          validator: Formatters.validateYear,
        ),
      ],
    );
  }

  Widget _buildSubjectsSection(List<String> gradeOptions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: FieldLabel(label: 'Add Subjects', isRequired: true),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _currentSubjects.add(SubjectGrade(name: '', grade: ''));
                });
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add', style: TextStyle(fontSize: 16)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        if (_currentSubjects.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.library_books_outlined,
                    size: 32,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No subjects added yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Click "Add" to begin',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              ..._currentSubjects.asMap().entries.map((entry) {
                final index = entry.key;
                return _buildSubjectRow(index, gradeOptions);
              }),
            ],
          ),
      ],
    );
  }

  Widget _buildSubjectRow(int index, List<String> gradeOptions) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: _currentSubjects[index].name,
              decoration: InputDecoration(
                hintText: 'Subject name',
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 15,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (value) {
                setState(() {
                  _currentSubjects[index] = SubjectGrade(
                    name: value,
                    grade: _currentSubjects[index].grade,
                  );
                });
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _currentSubjects[index].grade.isEmpty
                  ? null
                  : _currentSubjects[index].grade,
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                isDense: true,
              ),
              hint: Text(
                'Grade',
                style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                overflow: TextOverflow.ellipsis,
              ),
              icon: Icon(
                Icons.arrow_drop_down_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              items: gradeOptions.map((grade) {
                return DropdownMenuItem(
                  value: grade,
                  child: Text(
                    grade,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _currentSubjects[index] = SubjectGrade(
                    name: _currentSubjects[index].name,
                    grade: value ?? '',
                  );
                });
              },
            ),
          ),
          const SizedBox(width: 1),
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: Colors.red[400],
            ),
            onPressed: () {
              setState(() {
                _currentSubjects.removeAt(index);
              });
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  List<String> _getStreamOptions(String? examType) {
    switch (examType) {
      case 'STPM':
        return [
          'Science (Pure)',
          'Science (Applied)',
          'Arts / Humanities',
          'Business / Commerce',
          'Technical / Vocational',
          'Islamic / Religious Studies',
          'Agriculture',
          'Other',
        ];
      case 'A-Level':
        return [
          'Science',
          'Mathematics',
          'Humanities',
          'Social Science',
          'Commerce / Business',
          'Arts',
          'Other',
        ];
      case 'IB':
        return [
          'Group 1: Language & Literature',
          'Group 2: Language Acquisition',
          'Group 3: Individuals & Societies',
          'Group 4: Sciences',
          'Group 5: Mathematics',
          'Group 6: Arts / Electives',
          'Other',
        ];
      case 'UEC':
        return [
          'Science',
          'Commerce',
          'Arts',
          'Technical / Vocational',
          'Other',
        ];
      default:
        return ['Other'];
    }
  }

  List<String> _getGradeOptions(String? examType) {
    switch (examType) {
      case 'STPM':
        return ['A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'F'];
      case 'A-Level':
        return ['A*', 'A', 'B', 'C', 'D', 'E', 'U'];
      case 'IB':
        return ['7', '6', '5', '4', '3', '2', '1'];
      case 'UEC':
        return ['A1', 'A2', 'B3', 'B4', 'C5', 'C6', 'D7', 'E8', 'F9'];
      default:
        return [];
    }
  }

  void _saveRecord() {
    setState(() => _formError = null);

    if (!_formKey.currentState!.validate()) {
      _showError('Please fill in all required fields correctly');
      return;
    }

    if (widget.viewModel.educationLevel == null) {
      _showError('Please select an education level first');
      return;
    }

    final requiresCGPA = [
      EducationLevel.stpm,
      EducationLevel.foundation,
      EducationLevel.diploma,
      EducationLevel.bachelor,
      EducationLevel.master,
    ].contains(widget.viewModel.educationLevel);

    if (requiresCGPA) {
      final cgpaError = Formatters.validateCGPA(_cgpaValue, 0, 4.0);
      if (cgpaError != null) {
        _showError(cgpaError);
        return;
      }
    }

    final requiresYear = [
      EducationLevel.spm,
      EducationLevel.stpm,
      EducationLevel.phd,
    ].contains(widget.viewModel.educationLevel);

    if (requiresYear) {
      final yearError = Formatters.validateYear(_selectedYear);
      if (yearError != null) {
        _showError(yearError);
        return;
      }
    }

    final requiresSubjects = [
      EducationLevel.spm,
      EducationLevel.stpm,
    ].contains(widget.viewModel.educationLevel);

    if (requiresSubjects) {
      final subjectsError = Formatters.validateSubjectsList(_currentSubjects);
      if (subjectsError != null) {
        _showError(subjectsError);
        return;
      }
    }

    if (widget.viewModel.educationLevel == EducationLevel.spm ||
        widget.viewModel.educationLevel == EducationLevel.stpm) {
      if (_selectedExamType == null) {
        _showError('Please select exam type');
        return;
      }
    }

    if (widget.viewModel.educationLevel == EducationLevel.stpm) {
      if (_selectedStream == null) {
        _showError('Please select stream/field');
        return;
      }
    }

    String? levelLabel;
    if (widget.viewModel.educationLevel == EducationLevel.other) {
      levelLabel = widget.viewModel.otherEducationLevelText;
    } else {
      levelLabel = _selectedExamType ?? widget.viewModel.educationLevel!.label;
    }

    String? getTrimmed(String text) {
      final trimmed = text.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    AcademicRecord record;

    switch (widget.viewModel.educationLevel) {
      case EducationLevel.spm:
        record = AcademicRecord(
          level: levelLabel ?? 'SPM',
          subjects: _currentSubjects,
          examType: _selectedExamType,
          stream: _selectedStream,
          institution: getTrimmed(_institutionController.text),
          graduationYear: _selectedYear,
        );
        break;

      case EducationLevel.stpm:
        final usesCGPA = _selectedExamType == 'STPM';
        record = AcademicRecord(
          level: levelLabel ?? 'STPM',
          subjects: _currentSubjects,
          examType: _selectedExamType,
          stream: _selectedStream,
          cgpa: usesCGPA && _cgpaValue > 0 ? _cgpaValue : null,
          totalScore: !usesCGPA && _cgpaValue > 0 ? _cgpaValue : null,
          institution: getTrimmed(_institutionController.text),
          graduationYear: _selectedYear,
        );
        break;

      case EducationLevel.foundation:
        record = AcademicRecord(
          level: levelLabel ?? 'Foundation',
          examType: _selectedExamType,
          programName: getTrimmed(_streamController.text),
          cgpa: _cgpaValue > 0 ? _cgpaValue : null,
          institution: getTrimmed(_institutionController.text),
          graduationYear: _selectedYear,
        );
        break;

      case EducationLevel.diploma:
        record = AcademicRecord(
          level: levelLabel ?? 'Diploma',
          programName: getTrimmed(_streamController.text),
          cgpa: _cgpaValue > 0 ? _cgpaValue : null,
          classOfAward: _selectedClassOfAward,
          institution: getTrimmed(_institutionController.text),
          graduationYear: _selectedYear,
        );
        break;

      case EducationLevel.bachelor:
        record = AcademicRecord(
          level: levelLabel ?? 'Bachelor',
          major: getTrimmed(_majorController.text),
          cgpa: _cgpaValue > 0 ? _cgpaValue : null,
          honors: _selectedHonors,
          institution: getTrimmed(_institutionController.text),
          graduationYear: _selectedYear,
        );
        break;

      case EducationLevel.master:
        record = AcademicRecord(
          level: levelLabel ?? 'Master',
          researchArea: getTrimmed(_researchAreaController.text),
          cgpa: _cgpaValue > 0 ? _cgpaValue : null,
          classification: _selectedClassification,
          thesisTitle: getTrimmed(_thesisTitleController.text),
          institution: getTrimmed(_institutionController.text),
          graduationYear: _selectedYear,
        );
        break;

      case EducationLevel.phd:
        record = AcademicRecord(
          level: levelLabel ?? 'PhD',
          researchArea: getTrimmed(_researchAreaController.text),
          thesisTitle: getTrimmed(_thesisTitleController.text),
          institution: getTrimmed(_institutionController.text),
          graduationYear: _selectedYear,
        );
        break;

      case EducationLevel.other:
      default:
        record = AcademicRecord(
          level: levelLabel ?? 'Unknown',
          programName: getTrimmed(_majorController.text),
          cgpa: _cgpaValue > 0 ? _cgpaValue : null,
          institution: getTrimmed(_institutionController.text),
          graduationYear: _selectedYear,
        );
        break;
    }

    if (isEditMode && widget.recordIndex != null) {
      widget.viewModel.updateAcademicRecord(widget.recordIndex!, record);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text('Academic record updated successfully!',
                  style: const TextStyle(fontSize: 13)),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      widget.viewModel.addAcademicRecord(record);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text('Academic record saved successfully!',
                  style: const TextStyle(fontSize: 13)),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    Navigator.pop(context);
  }
}