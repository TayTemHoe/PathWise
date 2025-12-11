// lib/view/career/career_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/viewModel/career_view_model.dart';
import 'package:path_wise/viewModel/profile_view_model.dart';
import 'package:path_wise/view/career/job_view.dart';
import 'package:path_wise/model/career_suggestion.dart';
import 'package:path_wise/view/profile/profile_overview_view.dart';

import '../../utils/app_color.dart';

// Defining Design Colors locally
class _DesignColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color background = Color(0xFFF5F7FA);
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color cardBackground = Colors.white;
  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFFDCB6E);
  static const Color error = Color(0xFFD63031);
  static const Color info = Color(0xFF74B9FF);
  static Color shadow = Colors.black.withOpacity(0.08);
}

class CareerDiscoveryView extends StatefulWidget {
  const CareerDiscoveryView({Key? key}) : super(key: key);

  @override
  State<CareerDiscoveryView> createState() => _CareerDiscoveryViewState();
}

class _CareerDiscoveryViewState extends State<CareerDiscoveryView> {
  // Track expanded state for each card
  final Map<int, bool> _expandedCards = {};

  @override
  void initState() {
    super.initState();
    // Auto-fetch suggestions when the view initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
    });
  }

  Future<void> _fetchInitialData() async {
    final careerVM = context.read<CareerViewModel>();
    final profileVM = context.read<ProfileViewModel>();

    // Ensure profile is loaded first as we need UID
    if (profileVM.uid == null) {
      await profileVM.loadAll();
    }

    if (profileVM.uid != null) {
      // Fetch existing suggestions from Firestore (history) without triggering AI
      if (!careerVM.hasLatestSuggestion) {
        await careerVM.fetchLatestSuggestion(profileVM.uid!);
      }
    }
  }

  void _toggleCardExpansion(int index) {
    setState(() {
      _expandedCards[index] = !(_expandedCards[index] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DesignColors.background,
      appBar: AppBar(
        title: const Text(
          'AI Career Discovery',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _DesignColors.textPrimary,
          ),
        ),
        backgroundColor: _DesignColors.background,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(
              Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<CareerViewModel>(
        builder: (context, careerVM, child) {
          // Show loading state immediately when isLoading is true
          if (careerVM.isLoading) {
            return _buildLoadingState();
          }

          // Show empty state if no data and not loading
          if (!careerVM.hasLatestSuggestion) {
            return _buildEmptyState(context);
          }

          // Show results
          return _buildResultsList(context, careerVM);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: _DesignColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_DesignColors.primary),
                strokeWidth: 4,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'AI is analyzing your profile...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _DesignColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'We are generating personalized career paths, matching skills, and identifying growth opportunities for you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _DesignColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _DesignColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 64,
                color: _DesignColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Discover Your Ideal Career',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _DesignColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Our AI analyzes your skills, education, and interests to predict the best career paths for you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _DesignColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _confirmGenerate(context), // Trigger generation explicitly
                icon: const Icon(Icons.analytics_outlined, color: Colors.white),
                label: const Text(
                  'Predict',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _DesignColors.primary,
                  elevation: 4,
                  shadowColor: _DesignColors.primary.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(BuildContext context, CareerViewModel careerVM) {
    final matches = careerVM.latestSuggestion!.matches;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _DesignColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _DesignColors.success.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: _DesignColors.success),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Analysis Complete! Here are your top career matches.',
                    style: TextStyle(
                      color: _DesignColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top Recommendations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _DesignColors.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () => _confirmRegenerate(context),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Regenerate'),
                style: TextButton.styleFrom(
                  foregroundColor: _DesignColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              final isExpanded = _expandedCards[index] ?? false;
              return _buildCareerCard(context, match, index, isExpanded);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCareerCard(BuildContext context, CareerMatch match, int index, bool isExpanded) {
    // Determine confidence color based on fit score
    Color scoreColor = _DesignColors.success;
    if (match.fitScore < 80) scoreColor = _DesignColors.warning;
    if (match.fitScore < 60) scoreColor = _DesignColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: _DesignColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _DesignColors.shadow,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Section (Title, Score, Badges) - Always Visible
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _DesignColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#${index + 1}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _DesignColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.jobTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _DesignColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Short Description from Model
                      Text(
                        match.shortDescription,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _DesignColors.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      // Tags Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildScoreTag(match.fitScore, scoreColor),
                          if (match.avgSalaryMYR != null)
                            _buildInfoTag(
                              'MYR ${match.avgSalaryMYR!['min'] ?? 0} - ${match.avgSalaryMYR!['max'] ?? 0}',
                              Icons.attach_money,
                              _DesignColors.success,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Expandable Content Sections
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Job Description (Detailed)
                  if (match.jobsDescription != null && match.jobsDescription!.isNotEmpty) ...[
                    const Text(
                      'About this Role',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _DesignColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      match.jobsDescription!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _DesignColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Why this fits you (Reasons List)
                  if (match.reasons.isNotEmpty) ...[
                    const Text(
                      'Why it fits you',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _DesignColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...match.reasons.map((reason) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: _DesignColors.primary, height: 1.4)),
                          Expanded(
                            child: Text(
                              reason,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: _DesignColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                    const SizedBox(height: 20),
                  ],

                  // Skills & Growth Row
                  if (match.topSkillsNeeded.isNotEmpty || match.jobGrowth != null) ...[
                    const Divider(),
                    const SizedBox(height: 16),

                    // Top Skills
                    if (match.topSkillsNeeded.isNotEmpty) ...[
                      const Text(
                        'Top Skills Needed',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _DesignColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: match.topSkillsNeeded.map((skill) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _DesignColors.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            skill,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _DesignColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Growth Potential
                    if (match.jobGrowth != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.trending_up, size: 20, color: _DesignColors.info),
                          const SizedBox(width: 8),
                          const Text(
                            'Growth Potential: ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _DesignColors.textPrimary,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              match.jobGrowth!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: _DesignColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],

                  // Next Steps
                  if (match.suggestedNextSteps != null && match.suggestedNextSteps!.isNotEmpty) ...[
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Suggested Next Steps',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _DesignColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...match.suggestedNextSteps!.map((step) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: _DesignColors.primary)),
                          Expanded(
                            child: Text(
                              step,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: _DesignColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),

          // 3. View More Button & Find Jobs Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                // View More Button
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleCardExpansion(index),
                    icon: Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: _DesignColors.primary,
                    ),
                    label: Text(
                      isExpanded ? 'View Less' : 'View More',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _DesignColors.primary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _DesignColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Find Jobs Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JobView(prefilledQuery: match.jobTitle),
                        ),
                      );
                    },
                    icon: const Icon(Icons.work_outline, size: 20, color: Colors.white),
                    label: const Text(
                      'Find Jobs',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _DesignColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
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

  Widget _buildScoreTag(int score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pie_chart, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$score% Match',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTag(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRegenerate(BuildContext context) async {
    final shouldRegenerate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Regenerate Career Analysis?'),
        content: const Text(
          'This will analyze your profile again and generate new career suggestions. Previous suggestions will be replaced.',
          style: TextStyle(color: _DesignColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _DesignColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _DesignColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Regenerate', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldRegenerate == true) {
      _generatePrediction(context);
    }
  }

  Future<void> _confirmGenerate(BuildContext context) async {
    // Check profile completion before proceeding
    final profileVM = context.read<ProfileViewModel>();
    final completion = profileVM.profile?.completionPercent ?? 0;

    // If profile completion is less than 50%, show warning dialog
    if (completion < 50) {
      _showProfileIncompleteDialog(context, completion);
      return;
    }

    final shouldRegenerate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Generate Career Analysis?'),
        content: const Text(
          'This will analyze your profile and generate new career suggestions. Previous suggestions will be replaced.',
          style: TextStyle(color: _DesignColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _DesignColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _DesignColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Predict', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldRegenerate == true) {
      _generatePrediction(context);
    }
  }

  void _showProfileIncompleteDialog(BuildContext context, double completion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _DesignColors.warning, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Profile Incomplete',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your profile is ${completion.toInt()}% complete. You need at least 50% completion to generate career predictions.',
              style: const TextStyle(
                color: _DesignColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _DesignColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _DesignColors.info.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Please complete these sections:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _DesignColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildRequirementItem('Skills', Icons.bolt_outlined),
                  _buildRequirementItem('Education', Icons.school_outlined),
                  _buildRequirementItem('Experience', Icons.work_outline),
                  _buildRequirementItem('Job Preferences', Icons.tune_outlined),
                  _buildRequirementItem('Location', Icons.location_on_outlined),
                  _buildRequirementItem('Personality', Icons.psychology_outlined),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Stay Here',
              style: TextStyle(color: _DesignColors.textSecondary),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileOverviewScreen(),
                ),
              );
            },
            icon: const Icon(Icons.person_outline, size: 18, color: Colors.white),
            label: const Text(
              'Complete Profile',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _DesignColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _DesignColors.info),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: _DesignColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePrediction(BuildContext context) async {
    final careerVM = context.read<CareerViewModel>();
    final profileVM = context.read<ProfileViewModel>();

    if (profileVM.profile == null) {
      await profileVM.loadAll();
    }

    if (profileVM.profile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please complete your profile first'),
            backgroundColor: _DesignColors.warning,
          ),
        );
      }
      return;
    }

    // ✅ SET LOADING STATE IMMEDIATELY BEFORE ASYNC OPERATION
    careerVM.setLoading(true);

    // Trigger AI Generation
    await careerVM.generateCareerSuggestions(
      userId: profileVM.uid,
      profileViewModel: profileVM,
    );

    // Loading will be set to false inside generateCareerSuggestions
  }
}