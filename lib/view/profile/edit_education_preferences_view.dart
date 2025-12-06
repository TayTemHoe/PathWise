// lib/view/profile/edit_education_preferences_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/utils/app_color.dart';
import 'package:path_wise/viewModel/profile_view_model.dart';
import 'package:path_wise/viewModel/ai_match_view_model.dart';
import 'package:path_wise/model/user_profile.dart';
import 'package:path_wise/model/ai_match_model.dart';
import '../../widgets/form_components.dart';
import '../../widgets/multi_select_dropdown.dart';

class EditEducationPreferencesScreen extends StatefulWidget {
  const EditEducationPreferencesScreen({Key? key}) : super(key: key);

  @override
  State<EditEducationPreferencesScreen> createState() => _EditEducationPreferencesScreenState();
}

class _EditEducationPreferencesScreenState extends State<EditEducationPreferencesScreen> {
  // Form state
  final List<String> _selectedStudyLevels = [];
  final List<String> _selectedLocations = [];
  final List<String> _selectedModes = [];
  final TextEditingController _minTuitionController = TextEditingController();
  final TextEditingController _maxTuitionController = TextEditingController();
  final TextEditingController _topNController = TextEditingController();

  String? _tuitionError;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;

  // Available options
  List<String> _availableStudyLevels = [];
  List<String> _availableCountries = [];
  List<String> _availableStudyModes = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _minTuitionController.dispose();
    _maxTuitionController.dispose();
    _topNController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final aiMatchVM = context.read<AIMatchViewModel>();
      final profileVM = context.read<ProfileViewModel>();

      // Load available options quickly (they're cached in AIMatchViewModel)
      _availableStudyLevels = aiMatchVM.availableStudyLevels;
      _availableCountries = aiMatchVM.availableCountries;
      _availableStudyModes = aiMatchVM.availableStudyModes;

      // If options not loaded yet, initialize
      if (_availableStudyLevels.isEmpty) {
        await aiMatchVM.loadProgress(); // This loads the options
        _availableStudyLevels = aiMatchVM.availableStudyLevels;
        _availableCountries = aiMatchVM.availableCountries;
        _availableStudyModes = aiMatchVM.availableStudyModes;
      }

      // PRIORITY 1: Load from AI Match (SharedPreferences) - most up-to-date
      await aiMatchVM.loadProgress(forceRefresh: true);
      final aiPrefs = aiMatchVM.preferences;

      // PRIORITY 2: Load from Profile (Firestore) - as fallback
      final profilePrefs = profileVM.user?.preferences;

      // Clear existing data
      _selectedStudyLevels.clear();
      _selectedLocations.clear();
      _selectedModes.clear();

      // Study Levels
      if (aiPrefs.studyLevel.isNotEmpty) {
        _selectedStudyLevels.addAll(aiPrefs.studyLevel);
        debugPrint('📚 Loaded ${_selectedStudyLevels.length} study levels from AI Match');
      } else if (profilePrefs?.desiredJobTitles != null && profilePrefs!.desiredJobTitles!.isNotEmpty) {
        _selectedStudyLevels.addAll(profilePrefs.desiredJobTitles!);
        debugPrint('📚 Loaded ${_selectedStudyLevels.length} study levels from Profile');
      }

      // Locations
      if (aiPrefs.locations.isNotEmpty) {
        _selectedLocations.addAll(aiPrefs.locations);
        debugPrint('🌍 Loaded ${_selectedLocations.length} locations from AI Match');
      } else if (profilePrefs?.preferredLocations != null && profilePrefs!.preferredLocations!.isNotEmpty) {
        _selectedLocations.addAll(profilePrefs.preferredLocations!);
        debugPrint('🌍 Loaded ${_selectedLocations.length} locations from Profile');
      }

      // Modes
      if (aiPrefs.mode.isNotEmpty) {
        _selectedModes.addAll(aiPrefs.mode);
        debugPrint('💻 Loaded ${_selectedModes.length} modes from AI Match');
      } else if (profilePrefs?.workEnvironment != null && profilePrefs!.workEnvironment!.isNotEmpty) {
        _selectedModes.addAll(profilePrefs.workEnvironment!);
        debugPrint('💻 Loaded ${_selectedModes.length} modes from Profile');
      }

      // Tuition (use AI Match first)
      if (aiPrefs.tuitionMin != null) {
        _minTuitionController.text = aiPrefs.tuitionMin!.toStringAsFixed(0);
      } else if (profilePrefs?.salary?.min != null) {
        _minTuitionController.text = profilePrefs!.salary!.min.toString();
      } else {
        _minTuitionController.clear();
      }

      if (aiPrefs.tuitionMax != null) {
        _maxTuitionController.text = aiPrefs.tuitionMax!.toStringAsFixed(0);
      } else if (profilePrefs?.salary?.max != null) {
        _maxTuitionController.text = profilePrefs!.salary!.max.toString();
      } else {
        _maxTuitionController.clear();
      }

      // Top N Ranking
      if (aiPrefs.maxRanking != null) {
        _topNController.text = aiPrefs.maxRanking.toString();
      } else {
        _topNController.clear();
      }

      debugPrint('✅ Education preferences loaded successfully');
    } catch (e) {
      debugPrint('❌ Error loading preferences: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading preferences: ${e.toString()}'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _savePreferences() async {
    if (!_validateInputs()) return;

    setState(() => _isSaving = true);

    try {
      final profileVM = context.read<ProfileViewModel>();
      final aiMatchVM = context.read<AIMatchViewModel>();

      // Parse tuition values
      int? minTuition;
      int? maxTuition;
      if (_minTuitionController.text.isNotEmpty) {
        minTuition = int.tryParse(_minTuitionController.text);
      }
      if (_maxTuitionController.text.isNotEmpty) {
        maxTuition = int.tryParse(_maxTuitionController.text);
      }

      // Parse Top N
      int? topN;
      if (_topNController.text.isNotEmpty) {
        topN = int.tryParse(_topNController.text);
      }

      // 1. Update ProfileViewModel (Firestore)
      final updatedPrefs = Preferences(
        desiredJobTitles: _selectedStudyLevels.isNotEmpty ? _selectedStudyLevels : null,
        preferredLocations: _selectedLocations.isNotEmpty ? _selectedLocations : null,
        workEnvironment: _selectedModes.isNotEmpty ? _selectedModes : null,
        salary: (minTuition != null || maxTuition != null)
            ? PrefSalary(min: minTuition, max: maxTuition, type: 'Annual')
            : null,
      );

      final success = await profileVM.updatePreferences(updatedPrefs);

      if (!success) {
        throw Exception('Failed to update profile preferences');
      }

      // 2. Update AIMatchViewModel (SharedPreferences)
      final aiPrefs = UserPreferences(
        studyLevel: _selectedStudyLevels,
        locations: _selectedLocations,
        mode: _selectedModes,
        tuitionMin: minTuition?.toDouble(),
        tuitionMax: maxTuition?.toDouble(),
        maxRanking: topN,
      );

      aiMatchVM.updatePreferences(aiPrefs);

      setState(() => _hasChanges = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Education preferences saved successfully'),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error saving preferences: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool _validateInputs() {
    if (_minTuitionController.text.isNotEmpty || _maxTuitionController.text.isNotEmpty) {
      final minTuition = int.tryParse(_minTuitionController.text);
      final maxTuition = int.tryParse(_maxTuitionController.text);

      if (_minTuitionController.text.isNotEmpty && minTuition == null) {
        setState(() => _tuitionError = 'Invalid minimum tuition');
        return false;
      }
      if (_maxTuitionController.text.isNotEmpty && maxTuition == null) {
        setState(() => _tuitionError = 'Invalid maximum tuition');
        return false;
      }
      if (minTuition != null && maxTuition != null && minTuition > maxTuition) {
        setState(() => _tuitionError = 'Min tuition cannot exceed max tuition');
        return false;
      }
      if (minTuition != null && minTuition < 0) {
        setState(() => _tuitionError = 'Tuition cannot be negative');
        return false;
      }
    }
    setState(() => _tuitionError = null);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          final shouldPop = await _showDiscardDialog();
          return shouldPop ?? false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
                Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
            onPressed: () async {
              if (_hasChanges) {
                final shouldPop = await _showDiscardDialog();
                if (shouldPop == true && mounted) Navigator.pop(context);
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            'Education Preferences',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(),
              SizedBox(height: 24),
              _buildAcademicSection(),
              SizedBox(height: 20),
              _buildRankingSection(),
              SizedBox(height: 20),
              _buildLocationSection(),
              SizedBox(height: 20),
              _buildFinancialSection(),
              SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Set your study preferences to get better program recommendations',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicSection() {
    return _buildSectionCard(
      title: 'Academic Preferences',
      icon: Icons.school_rounded,
      color: AppColors.primary,
      children: [
        MultiSelectField(
          label: 'Preferred Study Level(s)',
          icon: Icons.school_rounded,
          items: _availableStudyLevels,
          selectedItems: _selectedStudyLevels,
          hint: 'Select one or more study levels',
          onChanged: (selected) {
            setState(() {
              _selectedStudyLevels.clear();
              _selectedStudyLevels.addAll(selected);
            });
            _markAsChanged();
          },
        ),
        SizedBox(height: 20),
        MultiSelectField(
          label: 'Preferred Study Mode(s)',
          icon: Icons.laptop_rounded,
          items: _availableStudyModes,
          selectedItems: _selectedModes,
          hint: 'Select one or more study modes',
          onChanged: (selected) {
            setState(() {
              _selectedModes.clear();
              _selectedModes.addAll(selected);
            });
            _markAsChanged();
          },
        ),
      ],
    );
  }

  Widget _buildRankingSection() {
    return _buildSectionCard(
      title: 'Ranking Preferences',
      icon: Icons.emoji_events_rounded,
      color: Colors.amber,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FieldLabel(
              label: 'Top N Programs by Subject Ranking',
              icon: Icons.emoji_events_rounded,
            ),
            SizedBox(height: 12),
            TextField(
              controller: _topNController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: 'e.g., 50 (Show top 50 ranked programs)',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.filter_list_rounded, color: Colors.amber[700]),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              onChanged: (_) => _markAsChanged(),
            ),
            SizedBox(height: 8),
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
    );
  }

  Widget _buildLocationSection() {
    return _buildSectionCard(
      title: 'Location Preferences',
      icon: Icons.public_rounded,
      color: Colors.blue,
      children: [
        MultiSelectField(
          label: 'Preferred Countries/Regions',
          icon: Icons.location_on_rounded,
          items: _availableCountries,
          selectedItems: _selectedLocations,
          hint: 'Select one or more countries',
          isSearchable: true,
          onChanged: (selected) {
            setState(() {
              _selectedLocations.clear();
              _selectedLocations.addAll(selected);
            });
            _markAsChanged();
          },
        ),
      ],
    );
  }

  Widget _buildFinancialSection() {
    return _buildSectionCard(
      title: 'Financial Preferences',
      icon: Icons.attach_money_rounded,
      color: Colors.green,
      children: [
        FieldLabel(
          label: 'Tuition Fee Range (MYR)',
          icon: Icons.attach_money_rounded,
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildNumberTextField(
                controller: _minTuitionController,
                label: 'Minimum',
                hint: '0',
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 10, left: 12, right: 12),
              child: Text('to', style: TextStyle(fontSize: 15)),
            ),
            Expanded(
              child: _buildNumberTextField(
                controller: _maxTuitionController,
                label: 'Maximum',
                hint: '200000',
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          'Leave blank if no preference',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        if (_tuitionError != null) ...[
          SizedBox(height: 8),
          Text(
            _tuitionError!,
            style: TextStyle(fontSize: 12, color: Colors.red[700]),
          ),
        ],
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
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                SizedBox(width: 12),
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
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
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
        SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            prefixText: 'RM ',
            prefixStyle: TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          onChanged: (_) {
            _validateInputs();
            _markAsChanged();
          },
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving || !_hasChanges ? null : _savePreferences,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: _hasChanges ? 2 : 0,
        ),
        child: _isSaving
            ? SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Text(
          _hasChanges ? 'Save Preferences' : 'No Changes to Save',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<bool?> _showDiscardDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Discard Changes?'),
        content: Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Discard'),
          ),
        ],
      ),
    );
  }
}