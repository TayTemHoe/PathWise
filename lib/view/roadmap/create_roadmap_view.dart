// lib/view/roadmap/create_roadmap_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/viewModel/careerroadmap_view_model.dart';
import 'package:path_wise/viewModel/career_view_model.dart';
import 'package:path_wise/viewModel/profile_view_model.dart';
import 'package:path_wise/view/roadmap/roadmap_detail_view.dart';

// Defining KYYAP Design Colors locally
class _DesignColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color background = Color(0xFFF5F7FA);
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color warning = Color(0xFFFDCB6E); // KYYAP Warning
  static const Color error = Color(0xFFD63031);
  static const Color cardBackground = Colors.white;
}

/// Screen for creating a new career roadmap
/// Allows user to select from career suggestions
class CreateRoadmapView extends StatefulWidget {
  const CreateRoadmapView({Key? key}) : super(key: key);

  @override
  State<CreateRoadmapView> createState() => _CreateRoadmapViewState();
}

class _CreateRoadmapViewState extends State<CreateRoadmapView> {
  String? _selectedJobTitle;
  bool _isLoading = false;
  List<Map<String, dynamic>> _existingRoadmaps = [];

  @override
  void initState() {
    super.initState();
    _loadExistingRoadmaps();
  }

  Future<void> _loadExistingRoadmaps() async {
    final viewModel = context.read<CareerRoadmapViewModel>();
    final roadmaps = await viewModel.getAllRoadmaps();
    if (mounted) {
      setState(() {
        _existingRoadmaps = roadmaps;
      });
    }
  }

  bool _isRoadmapExists(String jobTitle) {
    return _existingRoadmaps.any((r) => r['jobTitle'] == jobTitle);
  }

  String? _findExistingRoadmapId(String jobTitle) {
    final roadmap = _existingRoadmaps.firstWhere(
          (r) => r['jobTitle'] == jobTitle,
      orElse: () => {},
    );
    return roadmap['id'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DesignColors.background,
      appBar: AppBar(
        backgroundColor: _DesignColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _DesignColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Roadmap',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _DesignColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Sub-header / Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Choose a career path from your AI suggestions to generate a personalized roadmap.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: _DesignColors.textSecondary.withOpacity(0.8),
                ),
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<CareerViewModel>(
      builder: (context, careerVM, _) {
        if (careerVM.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_DesignColors.primary),
            ),
          );
        }

        if (!careerVM.hasLatestSuggestion) {
          return _buildNoSuggestionsState();
        }

        return Column(
          children: [
            _buildProfileUpdateWarning(),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16, left: 4),
                    child: Text(
                      'Suggested Career Paths',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _DesignColors.textPrimary,
                      ),
                    ),
                  ),
                  ...careerVM.latestSuggestion!.matches.map((match) {
                    return _buildCareerSuggestionCard(match.jobTitle);
                  }).toList(),
                  // Add extra padding at bottom so FAB/Button doesn't cover content
                  const SizedBox(height: 80),
                ],
              ),
            ),
            if (_selectedJobTitle != null) _buildGenerateButton(),
          ],
        );
      },
    );
  }

  Widget _buildProfileUpdateWarning() {
    return Consumer<ProfileViewModel>(
      builder: (context, profileVM, _) {
        final profile = profileVM.profile;
        if (profile == null) return const SizedBox.shrink();

        final lastUpdated = profile.lastUpdated?.toDate();
        if (lastUpdated == null) return const SizedBox.shrink();

        final monthsAgo = DateTime.now().difference(lastUpdated).inDays ~/ 30;

        if (monthsAgo <= 4) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _DesignColors.warning.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _DesignColors.warning),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFE67E22), // Darker orange for icon visibility
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile Update Recommended',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD35400),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last updated $monthsAgo months ago. Update for better accuracy.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFD35400),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to profile update
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(60, 36),
                ),
                child: const Text(
                  'Update',
                  style: TextStyle(
                    color: Color(0xFFE67E22),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoSuggestionsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            const Text(
              'No Career Suggestions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _DesignColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Generate career suggestions in the Career tab first to create a roadmap.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _DesignColors.textSecondary.withOpacity(0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 20),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _DesignColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareerSuggestionCard(String jobTitle) {
    final isSelected = _selectedJobTitle == jobTitle;
    final exists = _isRoadmapExists(jobTitle);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _DesignColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isSelected
            ? Border.all(color: _DesignColors.primary, width: 2)
            : Border.all(color: Colors.transparent, width: 2),
      ),
      child: InkWell(
        onTap: () {
          if (exists) {
            _showExistingRoadmapDialog(jobTitle);
          } else {
            setState(() {
              _selectedJobTitle = isSelected ? null : jobTitle;
            });
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _DesignColors.primary
                      : exists
                      ? Colors.orange.withOpacity(0.1)
                      : _DesignColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSelected
                      ? Icons.check
                      : exists
                      ? Icons.priority_high
                      : Icons.work_outline,
                  color: isSelected
                      ? Colors.white
                      : exists
                      ? Colors.orange
                      : _DesignColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),

              // Text Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jobTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? _DesignColors.primary : _DesignColors.textPrimary,
                      ),
                    ),
                    if (exists) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Roadmap already created',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _generateRoadmap,
            style: ElevatedButton.styleFrom(
              backgroundColor: _DesignColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 0), // Height controlled by SizedBox
            ),
            child: _isLoading
                ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Text(
              'Generate Career Roadmap',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _generateRoadmap() async {
    if (_selectedJobTitle == null) return;

    setState(() => _isLoading = true);

    final roadmapVM = context.read<CareerRoadmapViewModel>();
    final profileVM = context.read<ProfileViewModel>();

    // Show clean loading dialog
    _showLoadingDialog('Analyzing skills & generating roadmap...');

    final success = await roadmapVM.generateCareerRoadmap(
      jobTitle: _selectedJobTitle!,
      profileViewModel: profileVM,
    );

    if (mounted) Navigator.pop(context); // Close loading dialog

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(roadmapVM.successMessage ?? 'Roadmap generated successfully!'),
          backgroundColor: const Color(0xFF00B894), // Success Green
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const RoadmapDetailView(),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(roadmapVM.errorMessage ?? 'Failed to generate roadmap'),
          backgroundColor: _DesignColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_DesignColors.primary),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: _DesignColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showExistingRoadmapDialog(String jobTitle) async {
    final roadmapId = _findExistingRoadmapId(jobTitle);

    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Roadmap Exists'),
        content: Text(
          'A roadmap for "$jobTitle" already exists. What would you like to do?',
          style: const TextStyle(color: _DesignColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _DesignColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            child: const Text('Delete & New', style: TextStyle(color: _DesignColors.error)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'view'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _DesignColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('View Existing', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (action == 'view' && roadmapId != null && mounted) {
      _viewExistingRoadmap(roadmapId);
    } else if (action == 'delete' && roadmapId != null && mounted) {
      await _deleteAndSelectRoadmap(roadmapId, jobTitle);
    }
  }

  Future<void> _viewExistingRoadmap(String roadmapId) async {
    final viewModel = context.read<CareerRoadmapViewModel>();
    _showLoadingDialog('Loading roadmap...');
    final success = await viewModel.loadRoadmapById(roadmapId);
    if (mounted) Navigator.pop(context);

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const RoadmapDetailView(),
        ),
      );
    }
  }

  Future<void> _deleteAndSelectRoadmap(String roadmapId, String jobTitle) async {
    final viewModel = context.read<CareerRoadmapViewModel>();

    // Load and delete
    await viewModel.loadRoadmapById(roadmapId);
    final success = await viewModel.deleteCurrentRoadmap();

    if (success) {
      await _loadExistingRoadmaps();
      if(mounted) {
        setState(() {
          _selectedJobTitle = jobTitle;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Previous roadmap deleted. You can now create a new one.'),
            backgroundColor: Color(0xFF00B894),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}