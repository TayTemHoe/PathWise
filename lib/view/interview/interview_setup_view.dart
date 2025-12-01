// lib/view/interview/interview_setup_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/viewModel/interview_view_model.dart';
import 'package:path_wise/viewModel/career_view_model.dart';
import 'package:path_wise/viewModel/profile_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      await careerVM.latestSuggestion?.matches??[];
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
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final user = 'U0001';
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in'),
          backgroundColor: Colors.red,
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
        child: const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'Generating Interview Questions...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'This may take 3-5 seconds',
                style: TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final interviewVM = context.read<InterviewViewModel>();
      final profileVM = context.read<ProfileViewModel>();


      // Start new interview session - generates questions via AI
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
        // Show success message (M2)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your interview simulation has begun. Take your time.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to interview session page
        Navigator.of(context).pushReplacementNamed('/interview-session');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(interviewVM.errorMessage ?? 'Failed to start interview'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Interview Setup'),
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<CareerViewModel>(
        builder: (context, careerVM, child) {
          if (careerVM.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildJobTitleSection(careerVM),
                _buildDifficultySection(),
                _buildSessionSettingsSection(),
                _buildQuestionCategoriesSection(),
                _buildSummarySection(),
                _buildStartButton(),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildJobTitleSection(CareerViewModel careerVM) {
    final suggestions = careerVM.latestSuggestion?.matches ?? [];
    final hasSuggestions = suggestions.isNotEmpty;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.work_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Select Job Title',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Suggested jobs section
            if (!_useCustomJob && hasSuggestions) ...[
              const Text(
                'Choose from your career suggestions:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ...suggestions.map((match) {
                return RadioListTile<String>(
                  title: Text(match.jobTitle),
                  subtitle: Text(
                    'Fit Score: ${match.fitScore}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: match.jobTitle,
                  groupValue: _selectedJobTitle,
                  onChanged: (value) {
                    setState(() {
                      _selectedJobTitle = value;
                      _useCustomJob = false;
                    });
                  },
                  activeColor: const Color(0xFF8B5CF6),
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
              const Divider(height: 32),
            ],

            // No suggestions warning
            if (!_useCustomJob && !hasSuggestions) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'No career suggestions available. Please use custom job title.',
                        style: TextStyle(fontSize: 13),
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
                Checkbox(
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
                  activeColor: const Color(0xFF8B5CF6),
                ),
                const Text(
                  'Enter custom job title',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),

            // Custom job input
            if (_useCustomJob) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customJobController,
                decoration: InputDecoration(
                  hintText: 'e.g., Software Engineer, Data Analyst',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  prefixIcon: const Icon(Icons.edit),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultySection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school_outlined, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Difficulty Level',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildDifficultyChip('Beginner', Colors.green),
                const SizedBox(width: 12),
                _buildDifficultyChip('Intermediate', Colors.orange),
                const SizedBox(width: 12),
                _buildDifficultyChip('Advanced', Colors.red),
              ],
            ),
            const SizedBox(height: 12),
            _buildDifficultyDescription(),
          ],
        ),
      ),
    );
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
            color: isSelected ? color : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Text(
            level,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyDescription() {
    final descriptions = {
      'Beginner': 'Basic concepts and fundamental questions',
      'Intermediate': 'Moderate complexity with practical scenarios',
      'Advanced': 'Complex scenarios requiring expert knowledge',
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              descriptions[_difficultyLevel]!,
              style: TextStyle(fontSize: 12, color: Colors.blue[900]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionSettingsSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings_outlined, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Session Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Duration
            Row(
              children: [
                const Icon(Icons.timer, color: Color(0xFF8B5CF6), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Duration: ${_sessionDuration.toInt()} minutes',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Slider(
                        value: _sessionDuration,
                        min: 15,
                        max: 60,
                        divisions: 9,
                        label: '${_sessionDuration.toInt()} min',
                        activeColor: const Color(0xFF8B5CF6),
                        onChanged: (value) => setState(() => _sessionDuration = value),
                      ),
                      Text(
                        'Range: 15-60 minutes',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Questions
            Row(
              children: [
                const Icon(Icons.question_answer, color: Color(0xFF8B5CF6), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Number of Questions: ${_numQuestions.toInt()}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Slider(
                        value: _numQuestions,
                        min: 5,
                        max: 10,
                        divisions: 5,
                        label: '${_numQuestions.toInt()}',
                        activeColor: const Color(0xFF8B5CF6),
                        onChanged: (value) => setState(() => _numQuestions = value),
                      ),
                      Text(
                        'Range: 5-10 questions',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCategoriesSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category_outlined, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Question Types',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select multiple categories (AI will distribute randomly)',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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
                        // Keep at least one category selected
                        if (_selectedCategories.length > 1) {
                          _selectedCategories.remove(category);
                        }
                      }
                    });
                  },
                  selectedColor: const Color(0xFF8B5CF6),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: 12,
                  ),
                  checkmarkColor: Colors.white,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    final jobTitle = _useCustomJob
        ? (_customJobController.text.trim().isEmpty ? 'Not entered' : _customJobController.text.trim())
        : (_selectedJobTitle ?? 'Not selected');

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      color: const Color(0xFFF3F4F6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.summarize, color: Color(0xFF8B5CF6)),
                const SizedBox(width: 8),
                const Text(
                  'Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildSummaryRow('Job Title', jobTitle),
            _buildSummaryRow('Difficulty', _difficultyLevel),
            _buildSummaryRow('Duration', '${_sessionDuration.toInt()} minutes'),
            _buildSummaryRow('Questions', '${_numQuestions.toInt()}'),
            _buildSummaryRow(
              'Categories',
              _selectedCategories.join(', '),
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            const Text(': ', style: TextStyle(fontWeight: FontWeight.w600)),
            Expanded(
              child: Text(
                value,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 12),
          Divider(color: Colors.grey[300], height: 1),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildStartButton() {
    final isValid = _isFormValid();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: isValid ? _startInterview : null,
          icon: const Icon(Icons.play_arrow, size: 24),
          label: const Text(
            'Start Interview Session',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            disabledBackgroundColor: Colors.grey[300],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: isValid ? 4 : 0,
          ),
        ),
      ),
    );
  }
}