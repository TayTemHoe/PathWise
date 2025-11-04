import 'package:flutter/material.dart';
import 'package:path_wise/model/careerroadmap_model.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/ViewModel/careerroadmap_view_model.dart';
import 'package:path_wise/ViewModel/career_view_model.dart';
import 'package:path_wise/view/roadmap/create_roadmap_view.dart';

// lib/view/roadmap/roadmap_detail_view.dart

/// Detailed view of a career roadmap with skill gaps and learning resources
/// UC015: Complete implementation
class RoadmapDetailView extends StatefulWidget {
  const RoadmapDetailView({Key? key}) : super(key: key);

  @override
  State<RoadmapDetailView> createState() => _RoadmapDetailViewState();
}

class _RoadmapDetailViewState extends State<RoadmapDetailView> {
  final ScrollController _scrollController = ScrollController();
  bool _showSkillGapButton = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Hide/show skill gap button based on scroll position
    if (_scrollController.hasClients) {
      final showButton = _scrollController.offset < 300;
      if (showButton != _showSkillGapButton) {
        setState(() => _showSkillGapButton = showButton);
      }
    }
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
    return Consumer<CareerRoadmapViewModel>(
      builder: (context, viewModel, _) {
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Career Roadmap',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          viewModel.currentJobTitle ?? 'Career Path',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark_border, color: Colors.white),
                    onPressed: () => viewModel.bookmarkRoadmap(),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    return Consumer<CareerRoadmapViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!viewModel.hasRoadmap) {
          return const Center(
            child: Text('No roadmap data available'),
          );
        }

        return ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            _buildRoadmapStages(viewModel),
            const SizedBox(height: 24),
            _buildSkillGapSection(viewModel),
            if (viewModel.hasLearningResources) ...[
              const SizedBox(height: 24),
              _buildLearningResourcesSection(viewModel),
            ],
          ],
        );
      },
    );
  }

  Widget _buildRoadmapStages(CareerRoadmapViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Career Journey',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          viewModel.stageCount,
              (index) => _buildStageCard(viewModel, index),
        ),
      ],
    );
  }

  Widget _buildStageCard(CareerRoadmapViewModel viewModel, int index) {
    final stage = viewModel.roadmapStages[index];
    final isExpanded = viewModel.isStageExpanded(index);
    final isFirst = index == 0;
    final isLast = index == viewModel.stageCount - 1;

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isFirst
                  ? const Color(0xFF10B981)
                  : isExpanded
                  ? const Color(0xFF8B5CF6)
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => viewModel.toggleStageExpansion(index),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isFirst
                                  ? const Color(0xFFD1FAE5)
                                  : const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isFirst ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: isFirst ? const Color(0xFF10B981) : const Color(0xFF8B5CF6),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        stage.jobTitle,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                    if (isFirst)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Current Position',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  stage.estimatedTimeframe,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: const Color(0xFF8B5CF6),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildInfoChip(
                            Icons.code,
                            '${stage.requiredSkills.length} skills',
                            const Color(0xFF3B82F6),
                          ),
                          _buildInfoChip(
                            Icons.attach_money,
                            stage.salaryRange,
                            const Color(0xFF10B981),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded) _buildExpandedStageContent(stage),
            ],
          ),
        ),
        if (!isLast) _buildStageConnector(),
      ],
    );
  }

  Widget _buildStageConnector() {
    return Container(
      margin: const EdgeInsets.only(left: 32, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 2,
            height: 24,
            color: const Color(0xFF8B5CF6),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_downward,
            size: 16,
            color: Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedStageContent(RoadmapStage stage) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Responsibilities',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            stage.responsibilities,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Required Skills',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: stage.requiredSkills.map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDD6FE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  skill,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7C3AED),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Progression Milestones',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          ...stage.progressionMilestones.map((milestone) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      milestone,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSkillGapSection(CareerRoadmapViewModel viewModel) {
    final readiness = viewModel.careerReadinessPercentage;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Skill Gap Analysis',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: CircularProgressIndicator(
                        value: readiness / 100,
                        strokeWidth: 12,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getReadinessColor(readiness),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${readiness.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const Text(
                          'Ready',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                viewModel.roadmapStages.isNotEmpty
                    ? 'Ready for ${viewModel.roadmapStages.first.jobTitle}'
                    : 'Career Readiness',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            if (viewModel.criticalSkillGaps > 0) ...[
              _buildSkillGapCategory(
                'Critical Skills',
                viewModel.criticalSkillGaps,
                Colors.red,
                viewModel.getSkillGapsByPriority('Critical'),
              ),
              const SizedBox(height: 12),
            ],
            if (viewModel.highSkillGaps > 0) ...[
              _buildSkillGapCategory(
                'Important Skills',
                viewModel.highSkillGaps,
                Colors.orange,
                viewModel.getSkillGapsByPriority('High'),
              ),
              const SizedBox(height: 12),
            ],
            if (viewModel.mediumSkillGaps > 0) ...[
              _buildSkillGapCategory(
                'Nice-to-have',
                viewModel.mediumSkillGaps,
                Colors.green,
                viewModel.getSkillGapsByPriority('Medium'),
              ),
            ],
            if (viewModel.totalSkillGaps == 0) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.celebration,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Excellent! You already have all the required skills!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (viewModel.totalSkillGaps > 0 && !viewModel.hasLearningResources) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: viewModel.isLoadingResources
                      ? null
                      : () => _generateLearningResources(viewModel),
                  icon: viewModel.isLoadingResources
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Icon(Icons.school),
                  label: const Text('Find Learning Resources'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkillGapCategory(
      String title,
      int count,
      Color color,
      List<SkillGapEntry> gaps,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            Text(
              '$count missing',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: gaps.map((gap) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                gap.skillName,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLearningResourcesSection(CareerRoadmapViewModel viewModel) {
    final resources = viewModel.currentLearningResources!.resources;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Learning Resources',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'For System Design',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...resources.map((resource) {
              return _buildResourceCard(resource);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceCard(LearningResourceEntry resource) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.courseName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        resource.provider,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: resource.cost == 0
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    resource.cost == 0 ? 'Free' : 'RM ${resource.cost}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: Color(0xFFFBBF24)),
                const SizedBox(width: 4),
                const Text(
                  '4.8',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.access_time, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                const Text(
                  '6 weeks',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
            if (resource.certification != 'No Certificate') ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDD6FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified,
                      size: 16,
                      color: Color(0xFF8B5CF6),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        resource.certification,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7C3AED),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Launch URL
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Start Learning'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
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

  Color _getReadinessColor(double readiness) {
    if (readiness >= 80) return const Color(0xFF10B981);
    if (readiness >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Future<void> _generateLearningResources(CareerRoadmapViewModel viewModel) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Finding the best learning resources...',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    final success = await viewModel.generateLearningResources();

    Navigator.pop(context);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? viewModel.successMessage ?? 'Learning resources generated!'
                : viewModel.errorMessage ?? 'Failed to generate resources',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}

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