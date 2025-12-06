import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/ai_match_model.dart';
import '../../utils/app_color.dart';
import '../../viewModel/ai_match_view_model.dart';
import 'english_test_dialog.dart';

class EnglishTestsPage extends StatelessWidget {
  const EnglishTestsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AIMatchViewModel>(
      builder: (context, viewModel, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(viewModel),

              if (viewModel.englishTests.isEmpty) ...[
                const SizedBox(height: 20),
                _buildInfoCard(),
                const SizedBox(height: 16),
                _buildEmptyState(context, viewModel),
              ] else
                ...[
                  _buildTestsList(viewModel, context),
                  _buildAddButton(context, viewModel),
                ],
            ],
          ),
        );
      },
    );
  }

  // ... [Keep _buildInfoCard, _buildSectionHeader, _buildEmptyState as they were]
  // ... [Keep _buildAddButton as is]

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Add your English proficiency test results. Most universities require proof of English proficiency.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(AIMatchViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.language, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (viewModel.englishTests.isEmpty) ...[
                    const SizedBox(height: 8),
                  ],
                  Text(
                    'English Proficiency Tests',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (viewModel.englishTests.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'You have ${viewModel.englishTests.length} test record(s) saved.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, AIMatchViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.translate_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No English Tests Added Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your English proficiency test results to continue',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showEnglishTestDialog(context, viewModel),
              icon: const Icon(Icons.add_circle_outline, size: 22),
              label: const Text(
                'Add English Test',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
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
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, AIMatchViewModel viewModel) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showEnglishTestDialog(context, viewModel),
        icon: const Icon(Icons.add_circle_outline, size: 20),
        label: const Text(
          'Add Another Test Result',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // MODIFIED: Added optional parameters for editing
  void _showEnglishTestDialog(
      BuildContext context,
      AIMatchViewModel viewModel, {
        EnglishTest? test,
        int? index,
      }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EnglishTestDialog(
        viewModel: viewModel,
        initialTest: test,
        editingIndex: index,
      ),
    );

    // ✅ Force refresh after dialog closes
    if (context.mounted) {
      await viewModel.loadProgress(forceRefresh: true);
    }
  }

  Widget _buildTestsList(AIMatchViewModel viewModel, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...viewModel.englishTests.asMap().entries.map((entry) {
          final index = entry.key;
          final test = entry.value;
          return _buildTestCard(viewModel, test, index, context);
        }),
      ],
    );
  }

  Widget _buildTestCard(
      AIMatchViewModel viewModel,
      EnglishTest test,
      int index,
      BuildContext context,
      ) {
    final testColor = _getTestColor(test.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [testColor, testColor.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: testColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _getTestIcon(test.type),
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            test.type,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (test.year != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              'Year: ${test.year}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getTestDescription(test.type),
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // ADDED: Edit Button
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 20),
                color: Colors.blue[600],
                tooltip: 'Edit',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.only(right: 8),
                onPressed: () {
                  _showEnglishTestDialog(
                      context,
                      viewModel,
                      test: test,
                      index: index
                  );
                },
              ),

              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                color: Colors.red[400],
                tooltip: 'Remove',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Remove Test?'),
                      content: const Text('Are you sure you want to remove this test result?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () {
                            viewModel.removeEnglishTest(index);
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          // ... rest of card content (score display etc) same as before ...
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        testColor.withOpacity(0.15),
                        testColor.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: testColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stars_rounded, size: 20, color: testColor),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          Text(
                            'Overall Score',
                            style: TextStyle(
                              fontSize: 10,
                              color: testColor.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            test.result.toString(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: testColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _getScoreLevelColor(test.type, test.result).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getScoreLevelColor(test.type, test.result).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getScoreLevelIcon(test.type, test.result),
                      size: 20,
                      color: _getScoreLevelColor(test.type, test.result),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getScoreLevel(test.type, test.result),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getScoreLevelColor(test.type, test.result),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: Colors.blue[700]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _getScoreRangeInfo(test.type),
                    style: TextStyle(fontSize: 10, color: Colors.blue[900]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTestColor(String testType) {
    switch (testType.toLowerCase()) {
      case 'ielts':
        return Colors.red[600]!;
      case 'toefl':
        return Colors.blue[600]!;
      case 'muet':
        return Colors.purple[600]!;
      case 'cambridge':
        return Colors.green[600]!;
      case 'igcse english':
        return Colors.orange[600]!;
      default:
        return AppColors.primary;
    }
  }

  String _getTestDescription(String testType) {
    switch (testType.toLowerCase()) {
      case 'ielts':
        return 'International English Language Testing System';
      case 'toefl':
        return 'Test of English as a Foreign Language';
      case 'muet':
        return 'Malaysian University English Test';
      case 'cambridge':
        return 'Cambridge English Qualification';
      case 'igcse english':
        return 'International GCSE English';
      default:
        return 'English Proficiency Test';
    }
  }

  String _getScoreLevel(String testType, dynamic score) {
    final scoreStr = score.toString().toLowerCase();

    switch (testType.toLowerCase()) {
      case 'ielts':
        final ieltsScore = double.tryParse(scoreStr) ?? 0;
        if (ieltsScore >= 8.0) return 'Excellent';
        if (ieltsScore >= 7.0) return 'Very Good';
        if (ieltsScore >= 6.0) return 'Good';
        if (ieltsScore >= 5.0) return 'Moderate';
        return 'Limited';

      case 'toefl':
        final toeflScore = int.tryParse(scoreStr) ?? 0;
        if (toeflScore >= 110) return 'Excellent';
        if (toeflScore >= 90) return 'Very Good';
        if (toeflScore >= 70) return 'Good';
        if (toeflScore >= 50) return 'Moderate';
        return 'Limited';

      case 'muet':
        String cleanScore = scoreStr.replaceAll(RegExp(r'[^0-9.]'), '');
        double muetScore = double.tryParse(cleanScore) ?? 0;

        if (muetScore >= 5.0) return 'Excellent';
        if (muetScore >= 4.0) return 'Very Good';
        if (muetScore >= 3.0) return 'Good';
        if (muetScore >= 2.0) return 'Moderate';
        return 'Limited';

      case 'cambridge':
        final cambScore = int.tryParse(scoreStr) ?? 0;
        if (cambScore >= 200) return 'Excellent';
        if (cambScore >= 180) return 'Very Good';
        if (cambScore >= 160) return 'Good';
        if (cambScore >= 140) return 'Moderate';
        return 'Limited';

      default:
        return 'Scored';
    }
  }

  Color _getScoreLevelColor(String testType, dynamic score) {
    final level = _getScoreLevel(testType, score);

    switch (level) {
      case 'Excellent':
        return Colors.green[700]!;
      case 'Very Good':
        return Colors.green[600]!;
      case 'Good':
        return Colors.blue[600]!;
      case 'Moderate':
        return Colors.orange[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getScoreLevelIcon(String testType, dynamic score) {
    final level = _getScoreLevel(testType, score);

    switch (level) {
      case 'Excellent':
        return Icons.emoji_events_rounded;
      case 'Very Good':
        return Icons.star_rounded;
      case 'Good':
        return Icons.thumb_up_rounded;
      case 'Moderate':
        return Icons.check_circle_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _getScoreRangeInfo(String testType) {
    switch (testType.toLowerCase()) {
      case 'ielts':
        return 'Band score range: 1.0 (Non-user) to 9.0 (Expert)';
      case 'toefl':
        return 'Score range: 0 (Minimal) to 120 (Advanced)';
      case 'muet':
        return 'Band range: 1 (Very Limited) to 6 (Highly Proficient)';
      case 'cambridge':
        return 'Score range: 80 (Beginner) to 230 (Proficient)';
      case 'igcse english':
        return 'Grade range: A* (Highest) to G (Lowest)';
      default:
        return 'English proficiency test result';
    }
  }

  IconData _getTestIcon(String testType) {
    switch (testType.toLowerCase()) {
      case 'ielts':
        return Icons.flag_rounded;
      case 'toefl':
        return Icons.school_rounded;
      case 'muet':
        return Icons.assignment_turned_in_rounded;
      case 'cambridge':
        return Icons.verified_rounded;
      case 'igcse english':
        return Icons.menu_book_rounded;
      default:
        return Icons.language_rounded;
    }
  }
}