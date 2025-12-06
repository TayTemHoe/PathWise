// lib/view/profile/edit_language_preferences_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/ai_match_model.dart';
import '../../utils/app_color.dart';
import '../../viewModel/profile_view_model.dart';
import '../../viewModel/ai_match_view_model.dart';
import '../../widgets/ai_match_pages/english_test_dialog.dart';

class EditLanguagePreferencesScreen extends StatefulWidget {
  const EditLanguagePreferencesScreen({Key? key}) : super(key: key);

  @override
  State<EditLanguagePreferencesScreen> createState() =>
      _EditLanguagePreferencesScreenState();
}

class _EditLanguagePreferencesScreenState
    extends State<EditLanguagePreferencesScreen> {
  List<EnglishTest> _languageTests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLanguageTests();
  }

  Future<void> _loadLanguageTests() async {
    setState(() => _isLoading = true);

    try {
      final aiMatchVM = context.read<AIMatchViewModel>();
      await aiMatchVM.loadProgress(forceRefresh: true);

      setState(() {
        _languageTests = List.from(aiMatchVM.englishTests);
        _isLoading = false;
      });

      debugPrint('✅ Loaded ${_languageTests.length} language tests');
    } catch (e) {
      debugPrint('❌ Error loading language tests: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF5F7FA),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Language Proficiency',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadLanguageTests,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildStatsCard(),
                  const SizedBox(height: 24),
                  _buildSectionHeader(),
                  const SizedBox(height: 16),
                  if (_languageTests.isEmpty)
                    _buildEmptyState()
                  else
                    ..._buildTestCards(),
                  const SizedBox(height: 16),
                  _buildTipsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_languageTests.length}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF6C63FF),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Test Results',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.translate_rounded,
              color: Color(0xFF6C63FF),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Your Test Results',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        TextButton.icon(
          onPressed: () => _showLanguageTestDialog(),
          icon: const Icon(
            Icons.add_circle_outline,
            color: Color(0xFF6C63FF),
            size: 20,
          ),
          label: const Text(
            'Add New',
            style: TextStyle(
              color: Color(0xFF6C63FF),
              fontWeight: FontWeight.w600,
            ),
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.translate_rounded,
              size: 64,
              color: Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Test Results Added',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your language test results to enhance your profile',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTestCards() {
    return _languageTests.asMap().entries.map((entry) {
      final index = entry.key;
      final test = entry.value;
      return _buildTestCard(test, index);
    }).toList();
  }

  Widget _buildTestCard(EnglishTest test, int index) {
    final testColor = _getTestColor(test.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [testColor, testColor.withOpacity(0.6)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
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
                        ),
                        borderRadius: BorderRadius.circular(10),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${test.year}',
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
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 20),
                      color: Colors.blue[600],
                      onPressed: () =>
                          _showLanguageTestDialog(test: test, index: index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      color: Colors.red[400],
                      onPressed: () => _confirmDelete(test, index),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(height: 1, color: Colors.grey[200]),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              testColor.withOpacity(0.15),
                              testColor.withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.stars_rounded,
                              size: 24,
                              color: testColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Score',
                              style: TextStyle(
                                fontSize: 11,
                                color: testColor.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              test.result.toString(),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: testColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _getScoreLevelColor(
                          test.type,
                          test.result,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getScoreLevelColor(
                            test.type,
                            test.result,
                          ).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _getScoreLevelIcon(test.type, test.result),
                            size: 24,
                            color: _getScoreLevelColor(test.type, test.result),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getScoreLevel(test.type, test.result),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getScoreLevelColor(
                                test.type,
                                test.result,
                              ),
                            ),
                          ),
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

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: const Color(0xFF6C63FF),
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                'Pro Tips',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6C63FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _tipRow('Keep your test results up to date'),
          _tipRow('Add multiple tests to strengthen your profile'),
          _tipRow('Most universities require proof of English proficiency'),
        ],
      ),
    );
  }

  Widget _tipRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•',
            style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF4B5563), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageTestDialog({EnglishTest? test, int? index}) {
    final aiMatchVM = context.read<AIMatchViewModel>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EnglishTestDialog(
        viewModel: aiMatchVM,
        initialTest: test,
        editingIndex: index,
      ),
    ).then((_) => _loadLanguageTests());
  }

  Future<void> _confirmDelete(EnglishTest test, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
            const SizedBox(width: 12),
            const Text('Delete Test Result?'),
          ],
        ),
        content: Text('Remove ${test.type} from your profile?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final aiMatchVM = context.read<AIMatchViewModel>();
      aiMatchVM.removeEnglishTest(index);
      await _loadLanguageTests();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                const Text('Test result deleted'),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  // Helper methods
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
        return const Color(0xFF6C63FF);
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
}
