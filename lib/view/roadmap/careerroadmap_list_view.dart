// lib/view/roadmap/careerroadmap_list_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/ViewModel/careerroadmap_view_model.dart';
import 'package:path_wise/view/roadmap/roadmap_detail_view.dart';
import 'package:path_wise/view/roadmap/create_roadmap_view.dart';

/// Main screen showing all career roadmaps as independent page
/// This is a standalone page that can be used as a bottom navigation item
/// UC015: Initial entry point for viewing roadmaps
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

    setState(() {
      _roadmaps = roadmaps;
      _isLoading = false;
    });
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateRoadmap(),
        backgroundColor: const Color(0xFF8B5CF6),
        icon: const Icon(Icons.add),
        label: const Text('Create Roadmap'),
      ),
    );
  }

  /// Header without back button - standalone page design
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Career Roadmaps',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _roadmaps.isEmpty
                ? 'Start planning your career journey'
                : 'Your career progression paths',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
        ),
      );
    }

    if (_roadmaps.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadRoadmaps,
      color: const Color(0xFF8B5CF6),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _roadmaps.length,
        itemBuilder: (context, index) {
          return _buildRoadmapCard(_roadmaps[index]);
        },
      ),
    );
  }

  /// Empty state when no roadmaps exist
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration container
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.map_outlined,
                size: 100,
                color: Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(height: 32),

            // Title
            const Text(
              'No Career Roadmaps Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              'Create your first career roadmap to:\n• View career progression stages\n• Identify skill gaps\n• Get learning recommendations',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.6,
              ),
            ),
            const SizedBox(height: 40),

            // Create roadmap button
            ElevatedButton.icon(
              onPressed: () => _navigateToCreateRoadmap(),
              icon: const Icon(Icons.add_road, size: 24),
              label: const Text(
                'Create Roadmap',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: const Color(0xFF8B5CF6).withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 16),

            // Hint text
            Text(
              'Tip: Generate career suggestions first to get started',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Roadmap card showing job title and basic info
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _viewRoadmap(roadmapId, jobTitle),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.route,
                      color: Color(0xFF8B5CF6),
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$stageCount career stages',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteRoadmap(roadmapId, jobTitle);
                      }
                    },
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
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
                            Text('Delete Roadmap'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Career progression indicator
              _buildProgressIndicator(roadmapList),

              const SizedBox(height: 12),

              // Career path summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start:',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            firstJobTitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1E293B),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Color(0xFF8B5CF6),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Goal:',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lastJobTitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1E293B),
                              fontWeight: FontWeight.w600,
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

              const SizedBox(height: 12),

              // Action chips
              Row(
                children: [
                  _buildInfoChip(
                    Icons.trending_up,
                    'View Progression',
                    const Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.school,
                    'Skill Gaps',
                    const Color(0xFF10B981),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Progress indicator showing career stages
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
                    color: const Color(0xFF8B5CF6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF8B5CF6),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  /// Info chip widget
  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Navigate to create roadmap view
  Future<void> _navigateToCreateRoadmap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateRoadmapView(),
      ),
    );

    // Reload roadmaps if a new one was created
    if (result == true) {
      _loadRoadmaps();
    }
  }

  /// View specific roadmap details
  Future<void> _viewRoadmap(String roadmapId, String jobTitle) async {
    final viewModel = context.read<CareerRoadmapViewModel>();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
        ),
      ),
    );

    final success = await viewModel.loadRoadmapById(roadmapId);

    // Close loading dialog
    if (mounted) {
      Navigator.pop(context);
    }

    if (success && mounted) {
      // Navigate to detail view
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const RoadmapDetailView(),
        ),
      );
    } else if (mounted) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? 'Failed to load roadmap'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  /// Delete roadmap with confirmation
  Future<void> _deleteRoadmap(String roadmapId, String jobTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Delete Roadmap'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete the roadmap for "$jobTitle"?\n\nThis will also delete:\n• Associated skill gaps\n• Learning resources\n\nThis action cannot be undone.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
        ),
      ),
    );

    // Load the roadmap first
    await viewModel.loadRoadmapById(roadmapId);

    // Delete it
    final success = await viewModel.deleteCurrentRoadmap();

    // Close loading
    if (mounted) {
      Navigator.pop(context);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Roadmap deleted successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      _loadRoadmaps();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(viewModel.errorMessage ?? 'Failed to delete roadmap'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }
}