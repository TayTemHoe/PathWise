import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_wise/utils/formatters.dart';
import '../../model/ai_match_model.dart';
import '../../utils/app_color.dart';
import '../../viewModel/ai_match_view_model.dart';
import '../form_components.dart';

class EnglishTestDialog extends StatefulWidget {
  final AIMatchViewModel viewModel;
  final EnglishTest? initialTest; // ADDED: To hold data for editing
  final int? editingIndex;        // ADDED: To know which item to update

  const EnglishTestDialog({
    Key? key,
    required this.viewModel,
    this.initialTest,
    this.editingIndex,
  }) : super(key: key);

  @override
  State<EnglishTestDialog> createState() => _EnglishTestDialogState();
}

class _EnglishTestDialogState extends State<EnglishTestDialog> {
  final _formKey = GlobalKey<FormState>();

  final _resultController = TextEditingController();
  final _customTestNameController = TextEditingController();

  String? _selectedTestType;
  int? _selectedYear;
  String? _testTypeError;

  // Standard types to check against when loading data
  final List<String> _standardTypes = [
    'IELTS', 'TOEFL', 'MUET', 'Cambridge', 'IGCSE English'
  ];

  @override
  void initState() {
    super.initState();
    // ADDED: Pre-fill data if editing
    if (widget.initialTest != null) {
      final t = widget.initialTest!;
      _resultController.text = t.result;
      _selectedYear = t.year;

      if (_standardTypes.contains(t.type)) {
        _selectedTestType = t.type;
      } else {
        _selectedTestType = 'Other';
        _customTestNameController.text = t.type;
      }
    }
  }

  @override
  void dispose() {
    _resultController.dispose();
    _customTestNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialTest != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.95,
          maxWidth: MediaQuery.of(context).size.width * 0.95,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DialogHeader(
              title: isEditing ? 'Edit English Test' : 'Add English Test Result', // Dynamic Title
              icon: Icons.language_rounded,
              onClose: () => Navigator.pop(context),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTestTypeSelector(),

                      if (_selectedTestType == 'Other') ...[
                        const SizedBox(height: 20),
                        CustomTextField(
                          label: 'Test Name',
                          controller: _customTestNameController,
                          hint: 'e.g. PTE Academic, Duolingo',
                          prefixIcon: Icons.edit_note_rounded,
                          isRequired: true,
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter the test name';
                            }
                            return null;
                          },
                        ),
                      ],

                      const SizedBox(height: 20),
                      CustomTextField(
                        label: 'Score / Band / Grade',
                        controller: _resultController,
                        hint: _getScoreHint(),
                        prefixIcon: Icons.grade_rounded,
                        isRequired: true,
                        keyboardType: _getKeyboardType(),
                        inputFormatters: _getInputFormatters(),
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter score';
                          }

                          // MUET Validation Logic
                          if (_selectedTestType == 'MUET') {
                            String cleanValue = value.toLowerCase().replaceAll('band', '').replaceAll(' ', '');
                            final score = double.tryParse(cleanValue);

                            if (score == null) {
                              return 'Enter a valid number (e.g. 4 or 4.5)';
                            }
                            if (score < 1 || score > 6) {
                              return 'Score must be between 1 and 6';
                            }
                            return null;
                          }

                          if (_selectedTestType == 'Other') {
                            return null;
                          }

                          return Formatters.validateEnglishScore(value, _selectedTestType);
                        },
                      ),
                      const SizedBox(height: 20),
                      CustomYearPicker(
                        label: 'Assessment Year (Optional)',
                        selectedYear: _selectedYear,
                        onYearSelected: (year) => setState(() => _selectedYear = year),
                        firstYear: 2010,
                        lastYear: DateTime.now().year,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            DialogFooter(
              onCancel: () => Navigator.pop(context),
              onSave: _saveTest, // Renamed method
              saveLabel: isEditing ? 'Save Changes' : 'Add Test',
              saveIcon: isEditing ? Icons.save_rounded : Icons.add_circle_outline_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestTypeSelector() {
    final testTypes = [
      {'name': 'IELTS', 'icon': Icons.flag_rounded, 'desc': 'Band 1.0 - 9.0'},
      {'name': 'TOEFL', 'icon': Icons.school_rounded, 'desc': 'Score 0 - 120'},
      {'name': 'MUET', 'icon': Icons.assignment_rounded, 'desc': 'Band 1 - 6'},
      {'name': 'Cambridge', 'icon': Icons.verified_rounded, 'desc': 'Score 80 - 230'},
      {'name': 'IGCSE English', 'icon': Icons.book_rounded, 'desc': 'Grade A* - G'},
      {'name': 'Other', 'icon': Icons.more_horiz_rounded, 'desc': 'Custom score'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Flexible(
              child: Text(
                'Test Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Text('*', style: TextStyle(color: Colors.red[600], fontSize: 14)),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: testTypes.map((test) {
                final isSelected = _selectedTestType == test['name'];
                return SizedBox(
                  width: (constraints.maxWidth - 10) / 2,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTestType = test['name'] as String;
                        _testTypeError = null;
                        if (_selectedTestType != 'Other') {
                          _customTestNameController.clear();
                        }
                        _resultController.clear();
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.grey[300]!,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            test['icon'] as IconData,
                            color: isSelected ? AppColors.primary : Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  test['name'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  test['desc'] as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected
                                        ? AppColors.primary.withOpacity(0.7)
                                        : Colors.grey[500],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        if (_testTypeError != null) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4.0),
            child: Text(
              _testTypeError!,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
              ),
            ),
          ),
        ],
        if (_selectedTestType != null && _selectedTestType != 'Other') ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Colors.blue[700],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getScoreRangeInfo(_selectedTestType!),
                    style: TextStyle(fontSize: 11, color: Colors.blue[900]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _getScoreHint() {
    if (_selectedTestType == null) return 'Select test type first';
    switch (_selectedTestType!) {
      case 'IELTS':
        return 'e.g., 7.5';
      case 'TOEFL':
        return 'e.g., 95';
      case 'MUET':
        return 'e.g., Band 4 or 4.5';
      case 'Cambridge':
        return 'e.g., 180';
      case 'IGCSE English':
        return 'e.g., A or A*';
      case 'Other':
        return 'Enter score or grade';
      default:
        return 'Enter your score';
    }
  }

  String _getScoreRangeInfo(String testType) {
    switch (testType) {
      case 'IELTS':
        return 'Enter band score between 1.0 and 9.0';
      case 'TOEFL':
        return 'Enter score between 0 and 120';
      case 'MUET':
        return 'Enter band 1-6 (e.g. "Band 4" or "4.5")';
      case 'Cambridge':
        return 'Enter score between 80 and 230';
      case 'IGCSE English':
        return 'Enter grade: A*, A, B, C, D, E, F, or G';
      default:
        return 'Enter your test score';
    }
  }

  TextInputType _getKeyboardType() {
    if (_selectedTestType == null || _selectedTestType == 'Other') {
      return TextInputType.text;
    }

    switch (_selectedTestType!) {
      case 'IELTS':
        return const TextInputType.numberWithOptions(decimal: true);
      case 'MUET':
        return TextInputType.text;
      case 'TOEFL':
      case 'Cambridge':
        return TextInputType.number;
      default:
        return TextInputType.text;
    }
  }

  List<TextInputFormatter> _getInputFormatters() {
    if (_selectedTestType == null || _selectedTestType == 'Other') {
      return [];
    }

    switch (_selectedTestType!) {
      case 'IELTS':
        return Formatters.ieltsFormatter();
      case 'MUET':
        return [];
      case 'TOEFL':
        return Formatters.toeflFormatter();
      case 'Cambridge':
        return Formatters.cambridgeFormatter();
      case 'IGCSE English':
        return Formatters.gradeFormatter();
      default:
        return [];
    }
  }

  // UPDATED: Handle both Save and Add
  void _saveTest() {
    setState(() {
      _testTypeError = null;
    });

    if (_selectedTestType == null) {
      setState(() {
        _testTypeError = 'Please select a test type';
      });
      return;
    }

    if (_formKey.currentState!.validate()) {
      String finalType = _selectedTestType!;
      if (_selectedTestType == 'Other') {
        finalType = _customTestNameController.text.trim();
      }

      final test = EnglishTest(
        type: finalType,
        result: _resultController.text.trim(),
        year: _selectedYear,
      );

      // CHECK: Edit or Add?
      if (widget.initialTest != null && widget.editingIndex != null) {
        // Call update method
        widget.viewModel.updateEnglishTest(widget.editingIndex!, test);
        _showSuccessSnackbar('Test updated successfully!');
      } else {
        // Call add method
        widget.viewModel.addEnglishTest(test);
        _showSuccessSnackbar('Test added successfully!');
      }

      Navigator.pop(context);
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(message, style: const TextStyle(fontSize: 13)),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}