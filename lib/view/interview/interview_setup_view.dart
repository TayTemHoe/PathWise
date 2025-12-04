// lib/view/interview/interview_setup_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/viewModel/interview_view_model.dart';
import 'package:path_wise/viewModel/career_view_model.dart';
import 'package:path_wise/viewModel/profile_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../utils/app_color.dart';

// Defining KYYAP Design Colors locally
class _DesignColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color background = Color(0xFFF5F7FA);
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color cardBackground = Colors.white;
  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFFDCB6E);
  static const Color error = Color(0xFFD63031);
  static Color shadow = Colors.black.withOpacity(0.08);
}

class InterviewSetupPage extends StatefulWidget {
  const InterviewSetupPage({Key? key}) : super(key: key);

  @override
  State<InterviewSetupPage> createState() => _InterviewSetupPageState();
}

class _InterviewSetupPageState extends State<InterviewSetupPage> {
  // Form controllers
  final TextEditingController _customJobController = TextEditingController();

  // Selected values
  String? _selectedJobTitle;
  bool _useCustomJob = false;
  String _difficultyLevel = 'Intermediate';
  double _sessionDuration = 30.0;
  double _numQuestions = 7.0;

  // Question categories with default selections
  final Set<String> _selectedCategories = {'Technical Skills', 'Behavioral'};

  final List<String> _availableCategories = [
    'Technical Skills',
    'Behavioral',
    'Situational',
    'Company Fit',
    'Leadership',
    'Problem Solving',
    'Communication',
    'Adaptability',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCareerSuggestions();
    });
  }

  Future<void> _loadCareerSuggestions() async {
    final careerVM = context.read<CareerViewModel>();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && !careerVM.hasLatestSuggestion) {
      // In a real app you might trigger a fetch here
      // await careerVM.fetchSuggestions();
    }
  }

  bool _isFormValid() {
    final hasJobTitle = _useCustomJob
        ? _customJobController.text.trim().isNotEmpty
        : _selectedJobTitle != null;
    final hasCategories = _selectedCategories.isNotEmpty;
    return hasJobTitle && hasCategories;
  }

  Future<void> _startInterview() async {
    if (!_isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a job title and at least one question category'),
          backgroundColor: _DesignColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in'),
          backgroundColor: _DesignColors.error,
        ),
      );
      return;
    }

    final jobTitle = _useCustomJob
        ? _customJobController.text.trim()
        : _selectedJobTitle!;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
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
              children: const [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_DesignColors.primary),
                ),
                SizedBox(height: 20),
                Text(
                  'Generating Interview Questions...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _DesignColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'AI is tailoring questions to your profile...',
                  style: TextStyle(fontSize: 13, color: _DesignColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final interviewVM = context.read<InterviewViewModel>();
      final profileVM = context.read<ProfileViewModel>();

      // Start new interview session
      final success = await interviewVM.startNewInterviewSession(
        userId: profileVM.uid,
        jobTitle: jobTitle,
        difficultyLevel: _difficultyLevel,
        sessionDuration: _sessionDuration.toInt(),
        numQuestions: _numQuestions.toInt(),
        questionCategories: _selectedCategories.toList(),
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Interview session ready'),
            backgroundColor: _DesignColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.of(context).pushReplacementNamed('/interview-session');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(interviewVM.errorMessage ?? 'Failed to start interview'),
            backgroundColor: _DesignColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: _DesignColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _customJobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DesignColors.background,
      appBar: AppBar(
        title: const Text(
          'Interview Setup',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _DesignColors.textPrimary,
          ),
        ),
        backgroundColor: _DesignColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
              Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<CareerViewModel>(
        builder: (context, careerVM, child) {
          if (careerVM.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_DesignColors.primary),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildJobTitleSection(careerVM),
                const SizedBox(height: 20),
                _buildDifficultySection(),
                const SizedBox(height: 20),
                _buildSessionSettingsSection(),
                const SizedBox(height: 20),
                _buildQuestionCategoriesSection(),
                const SizedBox(height: 20),
                _buildSummarySection(),
                const SizedBox(height: 24),
                _buildStartButton(),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      width: double.infinity,
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
      child: child,
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _DesignColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _DesignColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _DesignColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildJobTitleSection(CareerViewModel careerVM) {
    final suggestions = careerVM.latestSuggestion?.matches ?? [];
    final hasSuggestions = suggestions.isNotEmpty;

    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(Icons.work_outline, 'Select Job Title'),
          const SizedBox(height: 16),

          // Suggested jobs section
          if (!_useCustomJob && hasSuggestions) ...[
            const Text(
              'Recommended for you:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _DesignColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            ...suggestions.map((match) {
              return RadioListTile<String>(
                title: Text(
                  match.jobTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _DesignColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Fit Score: ${match.fitScore}%',
                  style: const TextStyle(fontSize: 12, color: _DesignColors.textSecondary),
                ),
                value: match.jobTitle,
                groupValue: _selectedJobTitle,
                onChanged: (value) {
                  setState(() {
                    _selectedJobTitle = value;
                    _useCustomJob = false;
                  });
                },
                activeColor: _DesignColors.primary,
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }).toList(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(),
            ),
          ],

          // No suggestions warning
          if (!_useCustomJob && !hasSuggestions) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _DesignColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _DesignColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'No suggestions available. Please enter a custom job title.',
                      style: TextStyle(fontSize: 12, color: _DesignColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Custom job toggle
          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _useCustomJob,
                  onChanged: (value) {
                    setState(() {
                      _useCustomJob = value ?? false;
                      if (_useCustomJob) {
                        _selectedJobTitle = null;
                      } else {
                        _customJobController.clear();
                      }
                    });
                  },
                  activeColor: _DesignColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Enter custom job title',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _DesignColors.textPrimary,
                ),
              ),
            ],
          ),

          // Custom job input
          if (_useCustomJob) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customJobController,
              style: const TextStyle(color: _DesignColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g., Software Engineer',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: _DesignColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _DesignColors.primary),
                ),
                prefixIcon: const Icon(Icons.edit_outlined, color: _DesignColors.primary, size: 20),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDifficultySection() {
    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(Icons.school_outlined, 'Difficulty Level'),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildDifficultyChip('Beginner', _DesignColors.success),
              const SizedBox(width: 12),
              _buildDifficultyChip('Intermediate', _DesignColors.warning),
              const SizedBox(width: 12),
              _buildDifficultyChip('Advanced', _DesignColors.error),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _DesignColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 18, color: _DesignColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getDifficultyDescription(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: _DesignColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDifficultyDescription() {
    switch (_difficultyLevel) {
      case 'Beginner':
        return 'Basic concepts and fundamental questions suitable for entry-level positions.';
      case 'Intermediate':
        return 'Moderate complexity with practical scenarios and role-specific challenges.';
      case 'Advanced':
        return 'Complex scenarios requiring expert knowledge, system design, and leadership skills.';
      default:
        return '';
    }
  }

  Widget _buildDifficultyChip(String level, Color color) {
    final isSelected = _difficultyLevel == level;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _difficultyLevel = level),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : _DesignColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey[200]!,
              width: 1.5,
            ),
          ),
          child: Text(
            level,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : _DesignColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionSettingsSection() {
    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(Icons.tune_outlined, 'Session Settings'),
          const SizedBox(height: 20),

          // Duration Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Duration', style: TextStyle(fontWeight: FontWeight.w600)),
              Text('${_sessionDuration.toInt()} mins', style: const TextStyle(color: _DesignColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _DesignColors.primary,
              inactiveTrackColor: _DesignColors.primary.withOpacity(0.1),
              thumbColor: _DesignColors.primary,
              overlayColor: _DesignColors.primary.withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: _sessionDuration,
              min: 15,
              max: 60,
              divisions: 3,
              label: '${_sessionDuration.toInt()} min',
              onChanged: (value) => setState(() => _sessionDuration = value),
            ),
          ),

          const SizedBox(height: 12),

          // Questions Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Questions', style: TextStyle(fontWeight: FontWeight.w600)),
              Text('${_numQuestions.toInt()} questions', style: const TextStyle(color: _DesignColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _DesignColors.primary,
              inactiveTrackColor: _DesignColors.primary.withOpacity(0.1),
              thumbColor: _DesignColors.primary,
              overlayColor: _DesignColors.primary.withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: _numQuestions,
              min: 5,
              max: 10,
              divisions: 5,
              label: '${_numQuestions.toInt()}',
              onChanged: (value) => setState(() => _numQuestions = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCategoriesSection() {
    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(Icons.category_outlined, 'Question Types'),
          const SizedBox(height: 8),
          const Text(
            'Select categories to focus on (AI will mix them)',
            style: TextStyle(fontSize: 12, color: _DesignColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableCategories.map((category) {
              final isSelected = _selectedCategories.contains(category);
              return FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCategories.add(category);
                    } else {
                      if (_selectedCategories.length > 1) {
                        _selectedCategories.remove(category);
                      }
                    }
                  });
                },
                selectedColor: _DesignColors.primary.withOpacity(0.1),
                backgroundColor: _DesignColors.background,
                checkmarkColor: _DesignColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? _DesignColors.primary : _DesignColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? _DesignColors.primary : Colors.transparent,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final jobTitle = _useCustomJob
        ? (_customJobController.text.trim().isEmpty ? 'Not entered' : _customJobController.text.trim())
        : (_selectedJobTitle ?? 'Not selected');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _DesignColors.primary.withOpacity(0.1), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Session Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _DesignColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Job Title', jobTitle),
          _buildSummaryRow('Difficulty', _difficultyLevel),
          _buildSummaryRow('Format', '${_numQuestions.toInt()} Questions / ${_sessionDuration.toInt()} Mins'),
          _buildSummaryRow(
            'Focus',
            _selectedCategories.join(', '),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _DesignColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: _DesignColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    final isValid = _isFormValid();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: isValid ? _startInterview : null,
          icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
          label: const Text(
            'Start Interview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _DesignColors.primary,
            disabledBackgroundColor: Colors.grey[300],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: isValid ? 4 : 0,
          ),
        ),
      ),
    );
  }
}