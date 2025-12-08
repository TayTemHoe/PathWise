import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_wise/utils/formatters.dart';
import '../../model/ai_match_model.dart';
import '../../utils/app_color.dart';
import '../form_components.dart';

class AcademicRecordDialog extends StatefulWidget {
  final AcademicRecord? existingRecord;
  final bool showLevelDropdown;
  final EducationLevel? preselectedLevel;
  final Function(AcademicRecord) onSave;
  final bool isEditMode;

  const AcademicRecordDialog({
    Key? key,
    this.existingRecord,
    this.showLevelDropdown = false,
    this.preselectedLevel,
    required this.onSave,
  }) : isEditMode = existingRecord != null,
       super(key: key);

  @override
  State<AcademicRecordDialog> createState() => _AcademicRecordDialogState();
}

class _AcademicRecordDialogState extends State<AcademicRecordDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _institutionController = TextEditingController();
  final _majorController = TextEditingController();
  final _streamController = TextEditingController();
  final _researchAreaController = TextEditingController();
  final _thesisTitleController = TextEditingController();
  final _otherLevelController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  // State variables
  late EducationLevel _currentLevel;
  int? _selectedYear;
  String? _selectedExamType;
  String? _selectedStream;
  String? _selectedClassOfAward;
  String? _selectedHonors;
  String? _selectedClassification;
  double _cgpaValue = 0.0;
  final List<SubjectGrade> _currentSubjects = [];

  Timestamp? _selectedStartDate;
  Timestamp? _selectedEndDate;

  String? _formError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  void _initializeState() {
    if (widget.isEditMode) {
      final record = widget.existingRecord!;
      // Try to match string level to enum
      try {
        _currentLevel = EducationLevel.values.firstWhere(
          (e) => e.label.toLowerCase() == record.level.toLowerCase(),
          orElse: () => EducationLevel.other,
        );
      } catch (_) {
        _currentLevel = EducationLevel.other;
      }

      // ✅ NEW: Initialize "other" level text if applicable
      if (_currentLevel == EducationLevel.other) {
        _otherLevelController.text = record.level;
      }

      _institutionController.text = record.institution ?? '';
      _majorController.text = record.major ?? '';
      _streamController.text = record.programName ?? '';
      _researchAreaController.text = record.researchArea ?? '';
      _thesisTitleController.text = record.thesisTitle ?? '';

      _selectedStartDate = record.startDate;
      _selectedEndDate = record.endDate;

      if (record.startDate != null) {
        _startDateController.text = DateFormat(
          'MMM yyyy',
        ).format(record.startDate!.toDate());
      }
      if (record.endDate != null) {
        _endDateController.text = DateFormat(
          'MMM yyyy',
        ).format(record.endDate!.toDate());
      }

      _selectedExamType = record.examType;
      _selectedStream = record.stream;
      _selectedClassOfAward = record.classOfAward;
      _selectedHonors = record.honors;
      _selectedClassification = record.classification;
      _cgpaValue = record.cgpa ?? record.totalScore ?? 0.0;

      _currentSubjects.addAll(record.subjects);
    } else {
      // Default level logic
      _currentLevel = widget.preselectedLevel ?? EducationLevel.spm;
      if (_currentLevel == EducationLevel.spm) {
        _selectedExamType = 'SPM';
      }
    }
  }

  @override
  void dispose() {
    _institutionController.dispose();
    _majorController.dispose();
    _streamController.dispose();
    _researchAreaController.dispose();
    _thesisTitleController.dispose();
    _otherLevelController.dispose(); // ✅ NEW
    _startDateController.dispose();
    _endDateController.dispose();
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
          maxWidth: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DialogHeader(
              title: widget.isEditMode ? 'Edit Record' : 'Add Record',
              icon: widget.isEditMode
                  ? Icons.edit_rounded
                  : Icons.school_rounded,
              onClose: () => Navigator.pop(context),
            ),
            if (_formError != null) _buildErrorBanner(),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Only show dropdown if requested (Edit Education View)
                      if (widget.showLevelDropdown) ...[
                        _buildLevelDropdown(),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 20),
                      ] else ...[
                        // If dropdown is hidden, show the fixed level title
                        Text(
                          _currentLevel.label,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      _buildFormContent(),
                    ],
                  ),
                ),
              ),
            ),
            DialogFooter(
              onCancel: () => Navigator.pop(context),
              onSave: _handleSave,
              saveLabel: widget.isEditMode ? 'Update' : 'Save',
              isLoading: _isSaving,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Education Level',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<EducationLevel>(
              value: _currentLevel,
              isExpanded: true,
              items: EducationLevel.values.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Text(
                    level.label,
                    style: const TextStyle(fontSize: 15),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _currentLevel = value;
                    // Reset type dependent fields
                    _selectedExamType = value == EducationLevel.spm
                        ? 'SPM'
                        : null;
                    _cgpaValue = 0.0;
                    _currentSubjects.clear();

                    // ✅ NEW: Clear "other" level text when switching away from "Other"
                    if (value != EducationLevel.other) {
                      _otherLevelController.clear();
                    }
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.red[50],
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_formError!, style: TextStyle(color: Colors.red[900])),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: Colors.red[700]),
            onPressed: () => setState(() => _formError = null),
          ),
        ],
      ),
    );
  }

  // --- Dynamic Form Builder ---
  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ NEW: Show "Specify Education Level" field if "Other" is selected
        if (_currentLevel == EducationLevel.other) ...[
          const SectionHeader(
            title: 'Specify Your Education Level',
            icon: Icons.edit_outlined,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Education Level Name',
            controller: _otherLevelController,
            // You'll add this controller
            hint: 'e.g., Certificate, Professional Course, Diploma',
            prefixIcon: Icons.school_outlined,
            isRequired: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please specify your education level';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
        ],

        // Then continue with the existing form content
        ..._buildLevelSpecificForm(),
      ],
    );
  }

  // Helper method to organize the form
  List<Widget> _buildLevelSpecificForm() {
    switch (_currentLevel) {
      case EducationLevel.spm:
        return [_buildSPMForm()];
      case EducationLevel.stpm:
        return [_buildSTPMForm()];
      case EducationLevel.foundation:
        return [_buildFoundationForm()];
      case EducationLevel.diploma:
        return [_buildDiplomaForm()];
      case EducationLevel.bachelor:
        return [_buildBachelorForm()];
      case EducationLevel.master:
        return [_buildMasterForm()];
      case EducationLevel.phd:
        return [_buildPhDForm()];
      default:
        return [_buildGenericForm()];
    }
  }

  // --- Specific Forms ---

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
        _buildSideBySideDatePickers(),
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
          onChanged: (value) => setState(() {
            _selectedExamType = value;
            _cgpaValue = 0;
            _selectedStream = null;
          }),
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
        if (['STPM', 'IB', 'UEC'].contains(_selectedExamType)) ...[
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
            validator: (value) =>
                Formatters.validateCGPA(value ?? 0.0, min, max),
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
        _buildSideBySideDatePickers(),
        const SizedBox(height: 24),
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
          validator: (value) => Formatters.validateCGPA(value ?? 0.0, 0.0, 4.0),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Institution',
          controller: _institutionController,
          hint: 'Enter institution name',
          prefixIcon: Icons.business_rounded,
        ),
        const SizedBox(height: 16),
        _buildSideBySideDatePickers(),
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
          validator: (value) => Formatters.validateCGPA(value ?? 0.0, 0.0, 4.0),
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
        _buildSideBySideDatePickers(),
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
          validator: (value) => Formatters.validateCGPA(value ?? 0.0, 0.0, 4.0),
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
        _buildSideBySideDatePickers(),
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
          validator: (value) => Formatters.validateCGPA(value ?? 0.0, 0.0, 4.0),
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
        _buildSideBySideDatePickers(),
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
        _buildSideBySideDatePickers(),
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
          validator: (value) => Formatters.validateCGPA(value ?? 0.0, 0.0, 4.0),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Institution',
          controller: _institutionController,
          hint: 'Enter institution name',
          prefixIcon: Icons.business_rounded,
        ),
        const SizedBox(height: 16),
        _buildSideBySideDatePickers(),
      ],
    );
  }

  Widget _buildSideBySideDatePickers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Start Date
            Expanded(
              child: _buildDatePickerField(
                label: 'Start Date',
                controller: _startDateController,
                selectedDate: _selectedStartDate,
                onDateSelected: (date) {
                  setState(() {
                    _selectedStartDate = date;
                    if (date != null) {
                      _startDateController.text = DateFormat(
                        'MMM yyyy',
                      ).format(date.toDate());
                    } else {
                      _startDateController.clear();
                    }
                  });
                },
              ),
            ),

            const SizedBox(width: 8),

            // End Date
            Expanded(
              child: _buildDatePickerField(
                label: 'End Date',
                controller: _endDateController,
                selectedDate: _selectedEndDate,
                onDateSelected: (date) {
                  setState(() {
                    _selectedEndDate = date;
                    if (date != null) {
                      _endDateController.text = DateFormat(
                        'MMM yyyy',
                      ).format(date.toDate());
                    } else {
                      _endDateController.clear();
                    }
                  });
                },
              ),
            ),
          ],
        ),

        // Validation message
        if (_hasDateValidationError())
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.orange[700]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Both dates must be filled together or left empty',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ✅ NEW: Individual date picker field (compact version)
  Widget _buildDatePickerField({
    required String label,
    required TextEditingController controller,
    required Timestamp? selectedDate,
    required Function(Timestamp?) onDateSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label: label, isRequired: false),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Select',
            hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[50],
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, size: 16, color: Colors.grey[600]),
                    onPressed: () {
                      controller.clear();
                      onDateSelected(null);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
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
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange[700]!, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
            ),
          ),
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w500,
          ),
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: selectedDate?.toDate() ?? DateTime.now(),
              firstDate: DateTime(1950),
              lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: AppColors.primary,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: AppColors.textPrimary,
                    ),
                  ),
                  child: child!,
                );
              },
            );

            if (picked != null) {
              onDateSelected(Timestamp.fromDate(picked));
            }
          },
        ),
      ],
    );
  }

  // ✅ NEW: Validation helper
  bool _hasDateValidationError() {
    final hasStart = _selectedStartDate != null;
    final hasEnd = _selectedEndDate != null;

    // Error if only one is filled
    return (hasStart && !hasEnd) || (!hasStart && hasEnd);
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
                return _buildSubjectRow(entry.key, gradeOptions);
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

  void _handleSave() {
    setState(() {
      _formError = null;
      _isSaving = true;
    });

    // 1. Validate main form fields (Level, Institution, etc.)
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _formError = 'Please fill in all required fields';
        _isSaving = false;
      });
      return;
    }

    // 2. Validate that at least one subject exists
    final bool requiresSubjectValidation = [
      EducationLevel.spm,
      EducationLevel.stpm,
    ].contains(_currentLevel);

    if (requiresSubjectValidation) {
      // 2. Validate that at least one subject exists
      if (_currentSubjects.isEmpty) {
        setState(() {
          _formError = 'Please add at least one subject';
          _isSaving = false;
        });
        return;
      }

      // 3. Validate subject completeness
      bool hasIncompleteSubjects = _currentSubjects.any(
              (s) => s.name.trim().isEmpty || s.grade.trim().isEmpty
      );

      if (hasIncompleteSubjects) {
        setState(() {
          _formError = 'Please enter a name and grade for all subjects';
          _isSaving = false;
        });
        return;
      }
    }

    // 4. Validate date consistency
    if (_hasDateValidationError()) {
      setState(() {
        _formError =
        'Both start and end dates must be filled together, or leave both empty';
        _isSaving = false;
      });
      return;
    }

    // 5. Validate end date is after start date
    if (_selectedStartDate != null && _selectedEndDate != null) {
      if (_selectedEndDate!.toDate().isBefore(_selectedStartDate!.toDate())) {
        setState(() {
          _formError = 'End date must be after start date';
          _isSaving = false;
        });
        return;
      }
    }

    // Proceed to save
    final record = _buildAcademicRecord();
    widget.onSave(record);
  }

  AcademicRecord _buildAcademicRecord() {
    String? getTrimmed(String text) {
      final trimmed = text.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    String level;
    if (_currentLevel == EducationLevel.other) {
      level = getTrimmed(_otherLevelController.text) ?? 'Other';
    } else {
      level = _currentLevel.label;
    }

    String? institution = getTrimmed(_institutionController.text);
    // ✅ Use the state variables instead of parsing
    Timestamp? startDate = _selectedStartDate;
    Timestamp? endDate = _selectedEndDate;
    bool isCurrent = false;

    switch (_currentLevel) {
      case EducationLevel.spm:
        return AcademicRecord(
          id: widget.existingRecord?.id ?? '',
          level: level,
          subjects: _currentSubjects,
          examType: _selectedExamType,
          stream: _selectedStream,
          institution: institution,
          startDate: startDate,
          endDate: endDate,
          isCurrent: isCurrent,
        );

      case EducationLevel.stpm:
        final usesCGPA = _selectedExamType == 'STPM';
        return AcademicRecord(
          id: widget.existingRecord?.id ?? '',
          level: level,
          subjects: _currentSubjects,
          examType: _selectedExamType,
          stream: _selectedStream,
          institution: institution,
          startDate: startDate,
          endDate: endDate,
          cgpa: usesCGPA && _cgpaValue > 0 ? _cgpaValue : null,
          totalScore: !usesCGPA && _cgpaValue > 0 ? _cgpaValue : null,
          isCurrent: isCurrent,
        );

      case EducationLevel.foundation:
        return AcademicRecord(
          id: widget.existingRecord?.id ?? '',
          level: level,
          examType: _selectedExamType,
          programName: getTrimmed(_streamController.text),
          cgpa: _cgpaValue > 0 ? _cgpaValue : null,
          institution: institution,
          startDate: startDate,
          endDate: endDate,
          isCurrent: isCurrent,
        );

      case EducationLevel.diploma:
        return AcademicRecord(
          id: widget.existingRecord?.id ?? '',
          level: level,
          programName: getTrimmed(_streamController.text),
          cgpa: _cgpaValue > 0 ? _cgpaValue : null,
          classOfAward: _selectedClassOfAward,
          institution: institution,
          startDate: startDate,
          endDate: endDate,
          isCurrent: isCurrent,
        );

      case EducationLevel.bachelor:
        return AcademicRecord(
          id: widget.existingRecord?.id ?? '',
          level: level,
          major: getTrimmed(_majorController.text),
          cgpa: _cgpaValue > 0 ? _cgpaValue : null,
          honors: _selectedHonors,
          institution: institution,
          startDate: startDate,
          endDate: endDate,
          isCurrent: isCurrent,
        );

      case EducationLevel.master:
        return AcademicRecord(
          id: widget.existingRecord?.id ?? '',
          level: level,
          researchArea: getTrimmed(_researchAreaController.text),
          cgpa: _cgpaValue > 0 ? _cgpaValue : null,
          classification: _selectedClassification,
          thesisTitle: getTrimmed(_thesisTitleController.text),
          institution: institution,
          startDate: startDate,
          endDate: endDate,
          isCurrent: isCurrent,
        );

      case EducationLevel.phd:
        return AcademicRecord(
          id: widget.existingRecord?.id ?? '',
          level: level,
          researchArea: getTrimmed(_researchAreaController.text),
          thesisTitle: getTrimmed(_thesisTitleController.text),
          institution: institution,
          startDate: startDate,
          endDate: endDate,
          isCurrent: isCurrent,
        );

      default:
        return AcademicRecord(
          id: widget.existingRecord?.id ?? '',
          level: level,
          programName: getTrimmed(_majorController.text),
          cgpa: _cgpaValue > 0 ? _cgpaValue : null,
          institution: institution,
          startDate: startDate,
          endDate: endDate,
          isCurrent: isCurrent,
        );
    }
  }

  // --- Helper Methods ---

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
          'Arts (A-Level)',
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
          'Arts (UEC)',
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
}
