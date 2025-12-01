import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../model/ai_match_model.dart';
import '../../utils/app_color.dart';
import '../../viewModel/ai_match_view_model.dart';
import '../form_components.dart';
import '../multi_select_dropdown.dart';

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({Key? key}) : super(key: key);

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  // Form state
  final List<String> _selectedStudyLevels = [];
  final List<String> _selectedLocations = [];
  final List<String> _selectedModes = [];

  final TextEditingController _minTuitionController = TextEditingController();
  final TextEditingController _maxTuitionController = TextEditingController();
  final TextEditingController _topNController = TextEditingController();

  bool _scholarshipRequired = false;
  bool _workStudyImportant = false;
  bool _hasSpecialNeeds = false;
  final TextEditingController _specialNeedsController = TextEditingController();

  int? _minRanking;
  String? _tuitionError;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInitialized) {
        _loadExistingPreferences();
        _isInitialized = true;
      }
    });
  }

  void _loadExistingPreferences() {
    final viewModel = context.read<AIMatchViewModel>();
    final prefs = viewModel.preferences;

    setState(() {
      // Clear existing selections
      _selectedStudyLevels.clear();
      _selectedLocations.clear();
      _selectedModes.clear();

      // Load study level
      if (prefs.studyLevel.isNotEmpty) {
        _selectedStudyLevels.addAll(prefs.studyLevel);
      }

      // Load locations
      if (prefs.locations.isNotEmpty) {
        _selectedLocations.addAll(prefs.locations);
      }

      // Load mode
      if (prefs.mode.isNotEmpty) {
        _selectedModes.addAll(prefs.mode);
      }

      // Load tuition
      if (prefs.tuitionMin != null) {
        _minTuitionController.text = prefs.tuitionMin!.toStringAsFixed(0);
      } else {
        _minTuitionController.clear();
      }

      if (prefs.tuitionMax != null) {
        _maxTuitionController.text = prefs.tuitionMax!.toStringAsFixed(0);
      } else {
        _maxTuitionController.clear();
      }

      // Load other preferences
      if (prefs.maxRanking != null) {
        _topNController.text = prefs.maxRanking!.toString();
      } else {
        _topNController.clear();
      }
    });
  }

  @override
  void dispose() {
    _minTuitionController.dispose();
    _maxTuitionController.dispose();
    _specialNeedsController.dispose();
    _topNController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AIMatchViewModel>(
      builder: (context, viewModel, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPageHeader(),
              const SizedBox(height: 24),

              // Academic Preferences Section
              _buildSectionCard(
                title: 'Academic Preferences',
                icon: Icons.school_rounded,
                color: AppColors.primary,
                children: [
                  MultiSelectField(
                    label: 'Preferred Study Level(s)',
                    icon: Icons.school_rounded,
                    items: viewModel.availableStudyLevels,
                    selectedItems: _selectedStudyLevels,
                    hint: 'Select one or more study levels',
                    onChanged: (selected) {
                      setState(() {
                        _selectedStudyLevels.clear();
                        _selectedStudyLevels.addAll(selected);
                      });
                      _savePreferences(viewModel);
                    },
                  ),
                  const SizedBox(height: 20),
                  MultiSelectField(
                    label: 'Preferred Study Mode(s)',
                    icon: Icons.laptop_rounded,
                    items: viewModel.availableStudyModes,
                    selectedItems: _selectedModes,
                    hint: 'Select one or more study modes',
                    onChanged: (selected) {
                      setState(() {
                        _selectedModes.clear();
                        _selectedModes.addAll(selected);
                      });
                      _savePreferences(viewModel);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Ranking Preferences Section
              _buildSectionCard(
                title: 'Ranking Preferences',
                icon: Icons.emoji_events_rounded,
                color: Colors.amber,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FieldLabel(
                        label: 'Top N Programs by Subject Ranking',
                        icon: Icons.emoji_events_rounded,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _topNController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: 'e.g., 50 (Show top 50 ranked programs)',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: Icon(Icons.filter_list_rounded, color: Colors.amber[700]),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                        onChanged: (_) => _savePreferences(viewModel),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Leave blank to show all programs regardless of ranking',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Location Preferences Section
              _buildSectionCard(
                title: 'Location Preferences',
                icon: Icons.public_rounded,
                color: Colors.blue,
                children: [
                  MultiSelectField(
                    label: 'Preferred Countries/Regions',
                    icon: Icons.location_on_rounded,
                    items: viewModel.availableCountries,
                    selectedItems: _selectedLocations,
                    hint: 'Select one or more countries',
                    isSearchable: true,
                    onChanged: (selected) {
                      setState(() {
                        _selectedLocations.clear();
                        _selectedLocations.addAll(selected);
                      });
                      _savePreferences(viewModel);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Financial Preferences Section
              _buildSectionCard(
                title: 'Financial Preferences',
                icon: Icons.attach_money_rounded,
                color: Colors.green,
                children: [
                  _buildTuitionRangeFields(viewModel),
                  // const SizedBox(height: 20),
                  // _buildToggleOption(
                  //   icon: Icons.card_giftcard_rounded,
                  //   title: 'Scholarship Required',
                  //   subtitle: 'Only show programs with scholarship opportunities',
                  //   value: _scholarshipRequired,
                  //   color: Colors.amber,
                  //   onChanged: (value) {
                  //     setState(() {
                  //       _scholarshipRequired = value;
                  //     });
                  //     _savePreferences(viewModel);
                  //   },
                  // ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.tune_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Study Preferences',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Help us understand your ideal study environment',
                style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTuitionRangeFields(AIMatchViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel(
          label: 'Tuition Fee Range (MYR)',
          icon: Icons.attach_money_rounded,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildNumberTextField(
                controller: _minTuitionController,
                label: 'Minimum',
                hint: '0',
                isDecimal: true,
                onChanged: (_) {
                  _validateInputs();
                  _savePreferences(viewModel);
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 10, left: 12, right: 12),
              child: Text(
                'to',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
              ),
            ),
            Expanded(
              child: _buildNumberTextField(
                controller: _maxTuitionController,
                label: 'Maximum',
                hint: '200000',
                isDecimal: true,
                onChanged: (_) {
                  _validateInputs();
                  _savePreferences(viewModel);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Leave blank if no preference',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        if (_tuitionError != null) ...[
          const SizedBox(height: 8),
          Text(
            _tuitionError!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.red[700],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNumberTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isDecimal = false,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
          inputFormatters: [
            if (isDecimal)
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            else
              FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            prefixText: 'RM ',
            prefixStyle: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  bool _validateInputs() {
    bool isValid = true;

    // Validate tuition
    if (_minTuitionController.text.isNotEmpty || _maxTuitionController.text.isNotEmpty) {
      final minTuition = double.tryParse(_minTuitionController.text);
      final maxTuition = double.tryParse(_maxTuitionController.text);

      if (_minTuitionController.text.isNotEmpty && minTuition == null) {
        setState(() => _tuitionError = 'Invalid minimum tuition');
        isValid = false;
      } else if (_maxTuitionController.text.isNotEmpty && maxTuition == null) {
        setState(() => _tuitionError = 'Invalid maximum tuition');
        isValid = false;
      } else if (minTuition != null && maxTuition != null && minTuition > maxTuition) {
        setState(() => _tuitionError = 'Min tuition cannot exceed max tuition');
        isValid = false;
      } else if (minTuition != null && minTuition < 0) {
        setState(() => _tuitionError = 'Tuition cannot be negative');
        isValid = false;
      } else {
        setState(() => _tuitionError = null);
      }
    } else {
      setState(() => _tuitionError = null);
    }

    return isValid;
  }

  Widget _buildToggleOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required Function(bool) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: value ? color.withOpacity(0.08) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? color.withOpacity(0.3) : Colors.grey[300]!,
          width: value ? 2 : 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: value ? color.withOpacity(0.15) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: value ? color : Colors.grey[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: value ? color : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(value: value, onChanged: onChanged, activeColor: color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _savePreferences(AIMatchViewModel viewModel) {
    if (!_validateInputs()) {
      return;
    }

    double? minTuition;
    double? maxTuition;
    int? topNRanking;

    if (_topNController.text.isNotEmpty) {
      topNRanking = int.tryParse(_topNController.text);
    }

    if (_minTuitionController.text.isNotEmpty) {
      minTuition = double.tryParse(_minTuitionController.text);
    }

    if (_maxTuitionController.text.isNotEmpty) {
      maxTuition = double.tryParse(_maxTuitionController.text);
    }

    final preferences = UserPreferences(
      studyLevel: _selectedStudyLevels,
      tuitionMin: minTuition,
      tuitionMax: maxTuition,
      scholarshipRequired: _scholarshipRequired,
      locations: _selectedLocations,
      mode: _selectedModes,
      maxRanking: topNRanking,
      workStudyImportant: _workStudyImportant,
      hasSpecialNeeds: _hasSpecialNeeds,
      specialNeedsDetails: _hasSpecialNeeds ? _specialNeedsController.text : null,
    );

    viewModel.updatePreferences(preferences);
  }
}