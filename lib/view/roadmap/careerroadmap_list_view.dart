// lib/view/roadmap/careerroadmap_list_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/viewModel/careerroadmap_view_model.dart';
import 'package:path_wise/view/roadmap/roadmap_detail_view.dart';
import 'package:path_wise/view/roadmap/create_roadmap_view.dart';

import '../../utils/app_color.dart';

// Defining KYYAP Design Colors locally to ensure immediate compatibility
class _DesignColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color background = Color(0xFFF5F7FA);
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color cardBackground = Colors.white;
  static const Color success = Color(0xFF00B894);
  static const Color info = Color(0xFF74B9FF);
  static Color shadow = Colors.black.withOpacity(0.08);
}

class RoadmapListView extends StatefulWidget {
  const RoadmapListView({Key? key}) : super(key: key);

  @override
  State<RoadmapListView> createState() => _RoadmapListViewState();
}

class _RoadmapListViewState extends State<RoadmapListView> {
  List<Map<String, dynamic>> _roadmaps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoadmaps();
  }

  Future<void> _loadRoadmaps() async {
    setState(() => _isLoading = true);

    final viewModel = context.read<CareerRoadmapViewModel>();
    final roadmaps = await viewModel.getAllRoadmaps();

    if (mounted) {
      setState(() {
        _roadmaps = roadmaps;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DesignColors.background,
      appBar: AppBar(
        backgroundColor: _DesignColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Career Roadmaps',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _DesignColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
              Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: _DesignColors.textSecondary),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateRoadmap(),
        backgroundColor: _DesignColors.primary,
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Create Roadmap',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_DesignColors.primary),
            ),
            SizedBox(height: 16),
            Text(
              'Loading your journeys...',
              style: TextStyle(color: _DesignColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_roadmaps.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadRoadmaps,
      color: _DesignColors.primary,
      backgroundColor: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _roadmaps.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return _buildRoadmapCard(_roadmaps[index]);
        },
      ),
    );
  }

  /// Empty state matching KYYAP's "No programs found" style
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 24),
            const Text(
              'No Career Roadmaps Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _DesignColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Create a roadmap to view progression stages, identify skill gaps, and get learning recommendations.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _DesignColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreateRoadmap(),
              icon: const Icon(Icons.add_road, size: 20),
              label: const Text('Create New Roadmap'),
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
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Refined Card Design matching KYYAP widgets
  Widget _buildRoadmapCard(Map<String, dynamic> roadmapData) {
    final roadmapId = roadmapData['id'] as String;
    final jobTitle = roadmapData['jobTitle'] as String;
    final roadmapList = roadmapData['roadmap'] as List<dynamic>;
    final stageCount = roadmapList.length;

    // Extract first and last stage for display
    final firstStage = roadmapList.first as Map<String, dynamic>;
    final lastStage = roadmapList.last as Map<String, dynamic>;
    final firstJobTitle = firstStage['jobTitle'] as String;
    final lastJobTitle = lastStage['jobTitle'] as String;

    return Container(
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _viewRoadmap(roadmapId, jobTitle),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _DesignColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.route,
                        color: _DesignColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            jobTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _DesignColors.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$stageCount career stages',
                            style: const TextStyle(
                              fontSize: 13,
                              color: _DesignColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Action Menu
                    SizedBox(
                      height: 30,
                      width: 30,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        onSelected: (value) {
                          if (value == 'delete') {
                            _deleteRoadmap(roadmapId, jobTitle);
                          }
                        },
                        icon: const Icon(Icons.more_vert, size: 20, color: _DesignColors.textSecondary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Clean Progress Indicator
                _buildProgressIndicator(roadmapList),

                const SizedBox(height: 20),

                // Path Summary (Start -> Goal)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _DesignColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'START',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _DesignColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              firstJobTitle,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _DesignColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: _DesignColors.primary,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GOAL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _DesignColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              lastJobTitle,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _DesignColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Tags / Chips
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.trending_up,
                      'Progression',
                      _DesignColors.info,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      Icons.school_outlined,
                      'Skill Gaps',
                      _DesignColors.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Refined Progress Indicator
  Widget _buildProgressIndicator(List<dynamic> stages) {
    return Row(
      children: List.generate(stages.length, (index) {
        final isLast = index == stages.length - 1;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: _DesignColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: _DesignColors.primary.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  /// Refined Chip Design
  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToCreateRoadmap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateRoadmapView(),
      ),
    );

    if (result == true) {
      _loadRoadmaps();
    }
  }

  Future<void> _viewRoadmap(String roadmapId, String jobTitle) async {
    final viewModel = context.read<CareerRoadmapViewModel>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_DesignColors.primary),
        ),
      ),
    );

    final success = await viewModel.loadRoadmapById(roadmapId);

    if (mounted) {
      Navigator.pop(context);
    }

    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const RoadmapDetailView(),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? 'Failed to load roadmap'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteRoadmap(String roadmapId, String jobTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Roadmap'),
        content: Text(
          'Are you sure you want to delete the roadmap for "$jobTitle"?',
          style: const TextStyle(color: _DesignColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _DesignColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final viewModel = context.read<CareerRoadmapViewModel>();

    // Show loading
    if(mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
        const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_DesignColors.primary),
          ),
        ),
      );
    }

    await viewModel.loadRoadmapById(roadmapId);
    final success = await viewModel.deleteCurrentRoadmap();

    if (mounted) {
      Navigator.pop(context); // Close loading
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Roadmap deleted successfully'),
          backgroundColor: _DesignColors.success,
        ),
      );
      _loadRoadmaps();
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: _DesignColors.primary),
            SizedBox(width: 12),
            Text('Using Roadmaps', style: TextStyle(color: _DesignColors.textPrimary)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpStep('1', 'Generate career suggestions first.'),
              _buildHelpStep('2', 'Create a Roadmap from suggestions.'),
              _buildHelpStep('3', 'Track progress and skill gaps.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
                'Got it', style: TextStyle(color: _DesignColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: _DesignColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: _DesignColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}