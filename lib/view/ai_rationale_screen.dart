import 'package:flutter/material.dart';
import '../model/ai_match_model.dart';
import '../services/share_service.dart';
import '../utils/app_color.dart';
import '../viewModel/ai_match_view_model.dart';
import '../widgets/ai_match_pages/ai_recommendation_widgets.dart';
import '../widgets/share_button_widget.dart';
import '../widgets/share_card_widgets.dart';

class AIRationaleScreen extends StatefulWidget {
  final AIMatchViewModel viewModel;
  final int programCount;

  const AIRationaleScreen({
    super.key,
    required this.viewModel,
    required this.programCount,
  });

  @override
  State<AIRationaleScreen> createState() => _AIRationaleScreenState();
}

class _AIRationaleScreenState extends State<AIRationaleScreen> {
  final Map<String, bool> _expandedCards = {};

  void _onExpandChanged(String key, bool value) {
    setState(() {
      _expandedCards[key] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Safety check
    if (widget.viewModel.matchResponse == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('AI Match Rationale'),
          backgroundColor: AppColors.background,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'No AI match data available',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final recommendations =
        widget.viewModel.matchResponse!.recommendedSubjectAreas;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'AI Match Rationale',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 20, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'AI',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        actions: [
          AppBarShareButton(
            onPressed: _showShareOptions,
            tooltip: 'Share AI Recommendations',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success header with FIXED program count
            AIRecommendationWidgets.buildSuccessHeader(
              recommendations.length,
              widget.programCount, // ✅ Use passed program count
            ),

            const SizedBox(height: 24),

            // Section title
            _buildSectionTitle(
              'Your Top Subject Matches',
              Icons.emoji_events_rounded,
            ),

            const SizedBox(height: 16),

            // Recommendation cards
            ...recommendations.asMap().entries.map((entry) {
              return AIRecommendationWidgets.buildRecommendationCard(
                entry.value,
                entry.key + 1,
                _expandedCards,
                _onExpandChanged,
              );
            }),

            const SizedBox(height: 24),

            // Info box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'These recommendations are based on your academic background, interests, personality profile, and study preferences.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[900],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareOptions() async {
    final recommendations = widget.viewModel.matchResponse!.recommendedSubjectAreas;

    final result = await ShareService.instance.shareAIMatchResults(
      recommendations: recommendations,
      programCount: widget.programCount,
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
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
}
