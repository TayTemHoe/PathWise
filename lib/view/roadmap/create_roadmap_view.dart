// lib/view/roadmap/create_roadmap_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/viewModel/careerroadmap_view_model.dart';
import 'package:path_wise/viewModel/career_view_model.dart';
import 'package:path_wise/viewModel/profile_view_model.dart';
import 'package:path_wise/view/roadmap/roadmap_detail_view.dart';

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
    setState(() {
      _existingRoadmaps = roadmaps;
    });
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: _buildBody(),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                'Create Career Roadmap',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 48),
            child: Text(
              'Choose a career path from your suggestions',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<CareerViewModel>(
      builder: (context, careerVM, _) {
        if (careerVM.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!careerVM.hasLatestSuggestion) {
          return _buildNoSuggestionsState();
        }

        return Column(
          children: [
            _buildProfileUpdateWarning(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Select a Career Path',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...careerVM.latestSuggestion!.matches.map((match) {
                    return _buildCareerSuggestionCard(match.jobTitle);
                  }).toList(),
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
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF59E0B)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFF59E0B),
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
                        color: Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last updated $monthsAgo months ago. Update your profile for more accurate recommendations.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF92400E),
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
                  backgroundColor: const Color(0xFFF59E0B),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Update',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.lightbulb_outline,
                size: 80,
                color: Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Career Suggestions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You need to generate career suggestions first\nbefore creating a roadmap',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go to Career Suggestions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? const Color(0xFF8B5CF6)
              : exists
              ? Colors.orange
              : Colors.transparent,
          width: 2,
        ),
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF8B5CF6)
                      : exists
                      ? Colors.orange
                      : const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isSelected
                      ? Icons.check_circle
                      : exists
                      ? Icons.error_outline
                      : Icons.work_outline,
                  color: isSelected || exists ? Colors.white : const Color(0xFF8B5CF6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jobTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    if (exists) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Roadmap already exists',
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
              if (isSelected)
                const Icon(
                  Icons.arrow_forward,
                  color: Color(0xFF8B5CF6),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _generateRoadmap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
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

    // Show M6: Analyzing Skills
    _showLoadingDialog('Analyzing your skills and generating roadmap...');

    final success = await roadmapVM.generateCareerRoadmap(
      jobTitle: _selectedJobTitle!,
      profileViewModel: profileVM,
    );

    Navigator.pop(context); // Close loading dialog

    setState(() => _isLoading = false);

    if (success && mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(roadmapVM.successMessage ?? 'Roadmap generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to roadmap detail view
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const RoadmapDetailView(),
        ),
      );
    } else if (mounted) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(roadmapVM.errorMessage ?? 'Failed to generate roadmap'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showExistingRoadmapDialog(String jobTitle) async {
    final roadmapId = _findExistingRoadmapId(jobTitle);

    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Roadmap Already Exists'),
        content: Text(
          'A career roadmap for "$jobTitle" already exists. Would you like to view it or delete and create a new one?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete & Create New'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'view'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
            ),
            child: const Text('View Existing'),
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

    Navigator.pop(context); // Close loading

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

    // Load and delete the existing roadmap
    await viewModel.loadRoadmapById(roadmapId);
    final success = await viewModel.deleteCurrentRoadmap();

    if (success) {
      // Reload existing roadmaps
      await _loadExistingRoadmaps();

      // Select this job title
      setState(() {
        _selectedJobTitle = jobTitle;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Previous roadmap deleted. You can now create a new one.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}