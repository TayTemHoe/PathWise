// lib/view/roadmap/roadmap_detail_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_wise/model/careerroadmap_model.dart';
import 'package:path_wise/viewModel/careerroadmap_view_model.dart';

// Defining KYYAP Design Colors locally
class _DesignColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color background = Color(0xFFF5F7FA);
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color cardBackground = Colors.white;
  static const Color success = Color(0xFF00B894);
  static const Color info = Color(0xFF74B9FF);
  static const Color warning = Color(0xFFFDCB6E);
  static const Color error = Color(0xFFD63031);
  static Color shadow = Colors.black.withOpacity(0.08);
}

/// Detailed view of a career roadmap with skill gaps and learning resources
class RoadmapDetailView extends StatefulWidget {
  const RoadmapDetailView({Key? key}) : super(key: key);

  @override
  State<RoadmapDetailView> createState() => _RoadmapDetailViewState();
}

class _RoadmapDetailViewState extends State<RoadmapDetailView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
        title: Consumer<CareerRoadmapViewModel>(
          builder: (context, viewModel, _) {
            return Text(
              viewModel.currentJobTitle ?? 'Career Roadmap',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _DesignColors.textPrimary,
              ),
            );
          },
        ),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<CareerRoadmapViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_DesignColors.primary),
            ),
          );
        }

        if (!viewModel.hasRoadmap) {
          return const Center(
            child: Text(
              'No roadmap data available',
              style: TextStyle(color: _DesignColors.textSecondary),
            ),
          );
        }

        return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRoadmapStages(viewModel),
              const SizedBox(height: 24),
              _buildSkillGapSection(viewModel),
              if (viewModel.hasLearningResources) ...[
                const SizedBox(height: 24),
                _buildLearningResourcesSection(viewModel),
              ],
              const SizedBox(height: 40), // Bottom padding
            ],
          ),
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _DesignColors.textPrimary,
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
        Container(
          margin: const EdgeInsets.only(bottom: 4),
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
            border: isExpanded
                ? Border.all(color: _DesignColors.primary, width: 1.5)
                : Border.all(color: Colors.transparent),
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
                                  ? _DesignColors.success.withOpacity(0.1)
                                  : _DesignColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isFirst ? Icons.check_circle : Icons.circle_outlined,
                              color: isFirst ? _DesignColors.success : _DesignColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stage.jobTitle,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _DesignColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  stage.estimatedTimeframe,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _DesignColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: _DesignColors.textSecondary,
                          ),
                        ],
                      ),

                      // Badges
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildInfoChip(
                            Icons.code,
                            '${stage.requiredSkills.length} skills',
                            _DesignColors.info,
                          ),
                          _buildInfoChip(
                            Icons.attach_money,
                            stage.salaryRange,
                            _DesignColors.success,
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
      margin: const EdgeInsets.only(left: 32, bottom: 4),
      height: 20,
      width: 2,
      color: _DesignColors.primary.withOpacity(0.3),
    );
  }

  Widget _buildExpandedStageContent(RoadmapStage stage) {
    return Container(
      decoration: BoxDecoration(
        color: _DesignColors.background.withOpacity(0.5),
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
              color: _DesignColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stage.responsibilities,
            style: const TextStyle(
              fontSize: 13,
              color: _DesignColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Required Skills',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _DesignColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: stage.requiredSkills.map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _DesignColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  skill,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _DesignColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillGapSection(CareerRoadmapViewModel viewModel) {
    final readiness = viewModel.careerReadinessPercentage;

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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Skill Gap Analysis',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _DesignColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: readiness / 100,
                      strokeWidth: 10,
                      backgroundColor: _DesignColors.background,
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
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _DesignColors.textPrimary,
                        ),
                      ),
                      const Text(
                        'Ready',
                        style: TextStyle(
                          fontSize: 12,
                          color: _DesignColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (viewModel.criticalSkillGaps > 0) ...[
            _buildSkillGapCategory(
              'Critical Skills',
              viewModel.criticalSkillGaps,
              _DesignColors.error,
              viewModel.getSkillGapsByPriority('Critical'),
            ),
            const SizedBox(height: 16),
          ],

          if (viewModel.highSkillGaps > 0) ...[
            _buildSkillGapCategory(
              'Important Skills',
              viewModel.highSkillGaps,
              Colors.orange,
              viewModel.getSkillGapsByPriority('High'),
            ),
            const SizedBox(height: 16),
          ],

          if (viewModel.totalSkillGaps > 0 && !viewModel.hasLearningResources) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: viewModel.isLoadingResources
                    ? null
                    : () => _generateLearningResources(viewModel),
                icon: viewModel.isLoadingResources
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.school, size: 18),
                label: const Text('Find Learning Resources'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _DesignColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
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
              width: 8,
              height: 8,
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
                color: _DesignColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '$count missing',
              style: const TextStyle(
                fontSize: 12,
                color: _DesignColors.textSecondary,
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Text(
                gap.skillName,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book, color: _DesignColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Learning Resources',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _DesignColors.textPrimary,
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
    );
  }

  Widget _buildResourceCard(LearningResourceEntry resource) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DesignColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.play_lesson, color: _DesignColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.courseName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _DesignColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  resource.provider,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _DesignColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: resource.cost == 0 ? _DesignColors.success.withOpacity(0.1) : _DesignColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        resource.cost == 0 ? 'Free' : 'Paid',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: resource.cost == 0 ? _DesignColors.success : Colors.orange,
                        ),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => _launchUrl(resource.courseLink),
                      child: const Row(
                        children: [
                          Text(
                            'View Course',
                            style: TextStyle(
                              fontSize: 12,
                              color: _DesignColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, size: 10, color: _DesignColors.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

  Color _getReadinessColor(double readiness) {
    if (readiness >= 80) return _DesignColors.success;
    if (readiness >= 50) return _DesignColors.warning; // or Orange
    return _DesignColors.error;
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    }
  }

  Future<void> _generateLearningResources(CareerRoadmapViewModel viewModel) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_DesignColors.primary),
        ),
      ),
    );

    final success = await viewModel.generateLearningResources();

    if (mounted) Navigator.pop(context);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? 'Failed to find resources'),
          backgroundColor: _DesignColors.error,
        ),
      );
    }
  }
}