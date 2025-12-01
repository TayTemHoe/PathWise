// lib/widgets/ai_match_pages/results_page.dart - REFACTORED VERSION
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/ai_match_model.dart';
import '../../utils/app_color.dart';
import '../../view/program_list_screen.dart';
import '../../viewModel/ai_match_view_model.dart';
import 'ai_recommendation_widgets.dart'; // Import the reusable widgets

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  // Map to track expanded/collapsed states
  final Map<String, bool> _expandedCards = {};

  // Handler for expand/collapse changes
  void _onExpandChanged(String key, bool value) {
    setState(() {
      _expandedCards[key] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AIMatchViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isGeneratingMatches) {
          return _buildLoadingState(viewModel);
        }

        if (viewModel.errorMessage != null) {
          return _buildErrorState(context, viewModel);
        }

        if (viewModel.matchResponse == null) {
          return _buildEmptyState(context, viewModel);
        }

        return _buildResultsView(context, viewModel);
      },
    );
  }

  Widget _buildLoadingState(AIMatchViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            /// Animated logo
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutBack,
              builder: (context, value, _) {
                return Transform.scale(
                  scale: 0.8 + value * 0.2,
                  child: _circleIcon(
                    icon: Icons.psychology_rounded,
                    size: 64,
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(strokeWidth: 5),
            ),

            const SizedBox(height: 28),

            const Text(
              "Analyzing Your Profile",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              "Our AI is matching your profile with the best programs",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 28),

            _buildLoadingSteps(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSteps() {
    final steps = [
      ("Analyzing academic background", Icons.school_rounded, true),
      ("Evaluating English proficiency", Icons.translate_rounded, true),
      ("Matching interests and personality", Icons.favorite_rounded, true),
      ("Finding best programs", Icons.search_rounded, false),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: steps
            .map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _stepItem(
            text: e.$1,
            icon: e.$2,
            completed: e.$3,
          ),
        ))
            .toList()
          ..removeLast(), // remove last extra spacing
      ),
    );
  }

  Widget _stepItem({
    required String text,
    required IconData icon,
    required bool completed,
  }) {
    return Row(
      children: [
        _stepIcon(completed, icon),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: completed ? FontWeight.w600 : FontWeight.w500,
              color: completed ? Colors.green[700] : AppColors.textPrimary,
            ),
          ),
        ),

        if (!completed)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }

  Widget _circleIcon({required IconData icon, required double size}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size),
    );
  }

  Widget _stepIcon(bool completed, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (completed ? Colors.green : AppColors.primary).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        completed ? Icons.check_rounded : icon,
        color: completed ? Colors.green : AppColors.primary,
        size: 18,
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, AIMatchViewModel viewModel) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red[600],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Something Went Wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                viewModel.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red[900],
                  fontSize: 13,
                  height: 1.5,
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 32),

            // Action buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => viewModel.generateMatches(),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Try Again', style: TextStyle(fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => viewModel.goToPage(5),
                icon: const Icon(Icons.edit_rounded, size: 20),
                label: const Text('Review Information', style: TextStyle(fontSize: 15)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildEmptyState(BuildContext context, AIMatchViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 64,
                color: Colors.grey[400],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'No Results Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Please generate matches to see results',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: () => viewModel.goToPage(5),
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              label: const Text('Go Back', style: TextStyle(fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
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

  Widget _buildResultsView(BuildContext context, AIMatchViewModel viewModel) {
    final recommendations = viewModel.matchResponse!.recommendedSubjectAreas;
    final programs = viewModel.matchedPrograms ?? [];

    // ✅ FIX: Use matchedProgramIds count if matchedPrograms is empty
    final programCount = viewModel.matchedProgramIds?.length ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success header - NOW USING REUSABLE WIDGET WITH CORRECT COUNT
          AIRecommendationWidgets.buildSuccessHeader(
            recommendations.length,
            programCount, // ✅ Use correct count
          ),

          const SizedBox(height: 24),

          // Recommendations section
          _buildSectionTitle('Your Top Subject Matches', Icons.emoji_events_rounded),

          const SizedBox(height: 16),

          // Recommendation cards - NOW USING REUSABLE WIDGET
          ...recommendations.asMap().entries.map((entry) {
            final index = entry.key;
            final rec = entry.value;
            return AIRecommendationWidgets.buildRecommendationCard(
              rec,
              index + 1,
              _expandedCards,
              _onExpandChanged,
            );
          }),

          const SizedBox(height: 32),

          // Programs section - update text to use correct count
          if (programCount > 0) ...[
            _buildProgramsSection(context, programCount, viewModel),
          ] else ...[
            _buildNoProgramsFound(context, viewModel),
          ],
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              icon: const Icon(Icons.home_rounded, size: 20),
              label: const Text(
                'Back to Home',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildProgramsSection(
      BuildContext context,
      int programCount,
      AIMatchViewModel viewModel,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.withOpacity(0.1),
                Colors.green.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Programs Ready!',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'We found $programCount ${programCount == 1 ? "program" : "programs"} matching your profile',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // ✅ FIX: Use pushReplacement to force a fresh screen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ProgramListScreen(
                    aiRecommendations: viewModel.matchResponse!.recommendedSubjectAreas,
                    aiMatchedProgramIds: viewModel.matchedProgramIds,
                    aiUserPreferences: viewModel.preferences,
                    showOnlyRecommended: true,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.school_rounded, size: 20),
            label: const Text(
              'View All Matched Programs',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoProgramsFound(BuildContext context, AIMatchViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[200]!, width: 2),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 56,
            color: Colors.orange[700],
          ),

          const SizedBox(height: 16),

          Text(
            'No Programs Found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.orange[900],
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            'We couldn\'t find programs matching your exact criteria. Try adjusting your preferences or explore programs manually.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.orange[800],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => viewModel.goToPage(4),
              icon: const Icon(Icons.tune_rounded, size: 20),
              label: const Text('Adjust Preferences', style: TextStyle(fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}