// lib/view/roadmap/roadmap_list_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/ViewModel/careerroadmap_view_model.dart';
import 'package:path_wise/view/roadmap/roadmap_detail_view.dart';
import 'package:path_wise/view/roadmap/create_roadmap_view.dart';

/// Main screen showing all career roadmaps
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
                'Your Career Roadmaps',
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
              'Explore your career progression paths',
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_roadmaps.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadRoadmaps,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _roadmaps.length,
        itemBuilder: (context, index) {
          return _buildRoadmapCard(_roadmaps[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
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
                Icons.map_outlined,
                size: 80,
                color: Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Career Roadmaps Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first career roadmap to see your\nprogression path and skill gaps',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreateRoadmap(),
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Roadmap'),
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

  Widget _buildRoadmapCard(Map<String, dynamic> roadmapData) {
    final roadmapId = roadmapData['id'] as String;
    final jobTitle = roadmapData['jobTitle'] as String;
    final roadmapList = roadmapData['roadmap'] as List<dynamic>;
    final stageCount = roadmapList.length;

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
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildProgressIndicator(roadmapList),
              const SizedBox(height: 12),
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
                    'See Skills',
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

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await viewModel.loadRoadmapById(roadmapId);

    Navigator.pop(context); // Close loading

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
        title: const Text('Delete Roadmap'),
        content: Text(
          'Are you sure you want to delete the roadmap for "$jobTitle"? This action cannot be undone.',
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
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final viewModel = context.read<CareerRoadmapViewModel>();

    // Load the roadmap first
    await viewModel.loadRoadmapById(roadmapId);

    // Delete it
    final success = await viewModel.deleteCurrentRoadmap();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Roadmap deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadRoadmaps();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? 'Failed to delete roadmap'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}