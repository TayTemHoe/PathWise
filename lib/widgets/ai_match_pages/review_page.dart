import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/ai_match_model.dart';
import '../../utils/app_color.dart';
import '../../viewModel/ai_match_view_model.dart';

class ReviewPage extends StatelessWidget {
  const ReviewPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AIMatchViewModel>(
      builder: (context, viewModel, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header
              _buildPageHeader(),
              const SizedBox(height: 20),

              // Summary Stats
              _buildSummaryStats(viewModel),
              const SizedBox(height: 24),

              // Education Section
              _buildSectionCard(
                title: 'Education Background',
                icon: Icons.school_rounded,
                color: AppColors.primary,
                onEdit: () => viewModel.goToPage(0),
                child: _buildEducationContent(viewModel),
              ),
              const SizedBox(height: 16),

              // Academic Records Section
              _buildSectionCard(
                title: 'Academic Records',
                icon: Icons.workspace_premium_rounded,
                color: Colors.blue,
                onEdit: () => viewModel.goToPage(0),
                child: _buildAcademicRecordsContent(viewModel),
              ),
              const SizedBox(height: 16),

              // English Tests Section
              _buildSectionCard(
                title: 'English Proficiency',
                icon: Icons.language_rounded,
                color: Colors.orange,
                onEdit: () => viewModel.goToPage(1),
                child: _buildEnglishTestsContent(viewModel),
              ),
              const SizedBox(height: 16),

              // Interests Section
              _buildSectionCard(
                title: 'Interests & Activities',
                icon: Icons.favorite_rounded,
                color: Colors.pink,
                onEdit: () => viewModel.goToPage(2),
                child: _buildInterestsContent(viewModel),
              ),
              const SizedBox(height: 16),

              // Personality Section
              _buildSectionCard(
                title: 'Personality Profile',
                icon: Icons.psychology_rounded,
                color: Colors.purple,
                onEdit: () => viewModel.goToPage(3),
                child: _buildPersonalityContent(viewModel),
              ),
              const SizedBox(height: 16),

              // Preferences Section
              _buildSectionCard(
                title: 'Study Preferences',
                icon: Icons.tune_rounded,
                color: Colors.teal,
                onEdit: () => viewModel.goToPage(4),
                child: _buildPreferencesContent(viewModel),
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.fact_check_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Review Your Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Please verify all details before generating matches',
                style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryStats(AIMatchViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.check_circle_rounded,
              value: '${_getCompletionCount(viewModel)}/6',
              label: 'Sections\nCompleted',
              color: Colors.green,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.grey[300],
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.workspace_premium_rounded,
              value: '${viewModel.academicRecords.length}',
              label: 'Academic\nRecords',
              color: Colors.blue,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.grey[300],
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.language_rounded,
              value: '${viewModel.englishTests.length}',
              label: 'English\nTests',
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: color.withOpacity(0.8),
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onEdit,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: color.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded, size: 16, color: color),
                          const SizedBox(width: 6),
                          Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildEducationContent(AIMatchViewModel viewModel) {
    final educationLevel = viewModel.educationLevel;
    final otherText = viewModel.otherEducationLevelText;

    if (educationLevel == null) {
      return _buildEmptyState('No education level selected', Icons.warning_amber_rounded);
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.school_rounded, color: AppColors.primary, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Education Level',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                educationLevel == EducationLevel.other && otherText != null
                    ? otherText
                    : educationLevel.label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.check_circle_rounded, color: Colors.green[600], size: 28),
      ],
    );
  }

  Widget _buildAcademicRecordsContent(AIMatchViewModel viewModel) {
    if (viewModel.academicRecords.isEmpty) {
      return _buildEmptyState('No academic records added', Icons.warning_amber_rounded);
    }

    return Column(
      children: viewModel.academicRecords.asMap().entries.map((entry) {
        final index = entry.key;
        final record = entry.value;
        return Container(
          margin: EdgeInsets.only(bottom: index < viewModel.academicRecords.length - 1 ? 16 : 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[600]!, Colors.blue[400]!],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Record ${index + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      record.level,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),

              if (record.examType != null && record.examType!.toLowerCase() != record.level.toLowerCase()) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.verified_rounded, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Type: ${record.examType}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              if (record.institution != null && record.institution!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.business_rounded, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        record.institution!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              if (record.programName != null || record.researchArea != null || record.major != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.book_rounded, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          record.programName ?? record.researchArea ?? record.major ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[900],
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (record.thesisTitle != null && record.thesisTitle!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.purple[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.description_outlined, size: 16, color: Colors.purple[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          record.thesisTitle!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple[900],
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (record.cgpa != null && record.cgpa! > 0)
                    _buildInfoChip(Icons.stars_rounded, 'CGPA ${record.cgpa!.toStringAsFixed(2)}', Colors.green),
                  if (record.totalScore != null && record.totalScore! > 0)
                    _buildInfoChip(Icons.emoji_events_rounded, 'Score ${record.totalScore!.toStringAsFixed(0)}', Colors.amber),
                  if (record.graduationYear != null)
                    _buildInfoChip(Icons.event_rounded, '${record.graduationYear}', Colors.blue),
                  if (record.stream != null && record.stream!.isNotEmpty)
                    _buildInfoChip(Icons.category_rounded, record.stream!, Colors.teal),
                  if (record.honors != null && record.honors!.isNotEmpty)
                    _buildInfoChip(Icons.workspace_premium_rounded, record.honors!, Colors.amber),
                  if (record.classOfAward != null && record.classOfAward!.isNotEmpty)
                    _buildInfoChip(Icons.military_tech_rounded, record.classOfAward!, Colors.amber),
                  if (record.classification != null && record.classification!.isNotEmpty)
                    _buildInfoChip(Icons.verified_rounded, record.classification!, Colors.green),
                ],
              ),

              if (record.subjects.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.subject_rounded, size: 16, color: Colors.grey[700]),
                          const SizedBox(width: 8),
                          Text(
                            '${record.subjects.length} Subject(s)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: record.subjects.map((subject) {
                          return Container(
                            constraints: const BoxConstraints(maxWidth: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[400]!),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    subject.name,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getGradeColor(subject.grade),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    subject.grade,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEnglishTestsContent(AIMatchViewModel viewModel) {
    if (viewModel.englishTests.isEmpty) {
      return _buildEmptyState('No English tests added', Icons.warning_amber_rounded);
    }

    return Column(
      children: viewModel.englishTests.asMap().entries.map((entry) {
        final index = entry.key;
        final test = entry.value;
        return Container(
          margin: EdgeInsets.only(bottom: index < viewModel.englishTests.length - 1 ? 16 : 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getTestColor(test.type).withOpacity(0.3), width: 2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_getTestColor(test.type), _getTestColor(test.type).withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getTestIcon(test.type), color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.type,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (test.year != null)
                      Text(
                        'Year: ${test.year}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _getTestColor(test.type).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _getTestColor(test.type).withOpacity(0.3)),
                ),
                child: Text(
                  test.result.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getTestColor(test.type),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInterestsContent(AIMatchViewModel viewModel) {
    if (viewModel.interests.isEmpty) {
      return _buildEmptyState('No interests selected', Icons.warning_amber_rounded);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.favorite_rounded, size: 18, color: Colors.pink[600]),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${viewModel.interests.length} interest(s) selected',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.pink[700],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: viewModel.interests.map((interest) {
            return Container(
              constraints: const BoxConstraints(maxWidth: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink[100]!, Colors.pink[50]!],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.pink[300]!, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getInterestIcon(interest), size: 16, color: Colors.pink[700]),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      interest,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.pink[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPersonalityContent(AIMatchViewModel viewModel) {
    final personality = viewModel.personalityProfile;

    if (personality == null || !personality.hasData) {
      return _buildEmptyState('No personality data provided (Optional)', Icons.info_outline);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (personality.mbti != null && personality.mbti!.isNotEmpty) ...[
          _buildPersonalityItem('MBTI Type', personality.mbti!, Icons.psychology_rounded, Colors.purple),
          const SizedBox(height: 16),
        ],
        if (personality.riasec != null && personality.riasec!.isNotEmpty) ...[
          _buildPersonalityScores('RIASEC Scores', personality.riasec!, Icons.work_rounded, Colors.blue),
          const SizedBox(height: 16),
        ],
        if (personality.ocean != null && personality.ocean!.isNotEmpty) ...[
          _buildPersonalityScores('OCEAN Traits', personality.ocean!, Icons.favorite_rounded, Colors.pink),
        ],
      ],
    );
  }

  Widget _buildPersonalityItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalityScores(String label, Map<String, double> scores, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: scores.entries.map((entry) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${entry.key}:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    entry.value.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPreferencesContent(AIMatchViewModel viewModel) {
    final prefs = viewModel.preferences;
    bool hasAnyPreferences =
        prefs.studyLevel.isNotEmpty ||
            prefs.tuitionMax != null ||
            prefs.locations.isNotEmpty ||
            prefs.mode.isNotEmpty ||
            prefs.scholarshipRequired ||
            prefs.workStudyImportant ||
            prefs.hasSpecialNeeds;

    if (!hasAnyPreferences) {
      return _buildEmptyState('No preferences specified', Icons.info_outline);
    }

    return Column(
      children: [
        if (prefs.studyLevel.isNotEmpty)
          _buildPreferenceItem(
            Icons.school_rounded,
            'Study Level',
            prefs.studyLevel.join(', '),
            Colors.blue,
          ),
        if (prefs.locations.isNotEmpty) ...[
          if (prefs.studyLevel.isNotEmpty) const SizedBox(height: 14),
          _buildPreferenceItem(
            Icons.location_on_rounded,
            'Preferred Locations',
            prefs.locations.join(', '),
            Colors.green,
          ),
        ],
        if (prefs.mode.isNotEmpty) ...[
          if (prefs.studyLevel.isNotEmpty || prefs.locations.isNotEmpty) const SizedBox(height: 14),
          _buildPreferenceItem(
            Icons.laptop_rounded,
            'Study Mode',
            prefs.mode.join(', '),
            Colors.purple,
          ),
        ],
        if (prefs.tuitionMax != null || prefs.tuitionMin != null) ...[
          if (prefs.studyLevel.isNotEmpty || prefs.locations.isNotEmpty || prefs.mode.isNotEmpty)
            const SizedBox(height: 14),
          _buildPreferenceItem(
            Icons.attach_money_rounded,
            'Tuition Fee (MYR)',
            'RM ${(prefs.tuitionMin ?? 0).toStringAsFixed(0)} - RM ${prefs.tuitionMax!.toStringAsFixed(0)}',
            Colors.orange,
          ),
        ],
        if (prefs.scholarshipRequired) ...[
          if (prefs.studyLevel.isNotEmpty || prefs.locations.isNotEmpty || prefs.mode.isNotEmpty || prefs.tuitionMax != null)
            const SizedBox(height: 14),
          _buildPreferenceItem(
            Icons.card_giftcard_rounded,
            'Scholarship',
            'Required',
            Colors.amber,
          ),
        ],
        if (prefs.workStudyImportant) ...[
          if (prefs.studyLevel.isNotEmpty|| prefs.locations.isNotEmpty || prefs.mode.isNotEmpty ||
              prefs.tuitionMax != null || prefs.scholarshipRequired)
            const SizedBox(height: 14),
          _buildPreferenceItem(
            Icons.work_outline_rounded,
            'Work-Study',
            'Important',
            Colors.indigo,
          ),
        ],
        if (prefs.hasSpecialNeeds) ...[
          if (prefs.studyLevel.isNotEmpty || prefs.locations.isNotEmpty || prefs.mode.isNotEmpty ||
              prefs.tuitionMax != null || prefs.scholarshipRequired || prefs.workStudyImportant)
            const SizedBox(height: 14),
          _buildPreferenceItem(
            Icons.accessible_rounded,
            'Special Needs Support',
            prefs.specialNeedsDetails ?? 'Required',
            Colors.teal,
          ),
        ],
      ],
    );
  }

  Widget _buildPreferenceItem(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
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
      constraints: const BoxConstraints(maxWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid, width: 1.5),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.grey[500]),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  int _getCompletionCount(AIMatchViewModel viewModel) {
    int count = 0;
    if (viewModel.educationLevel != null) count++;
    if (viewModel.academicRecords.isNotEmpty) count++;
    if (viewModel.englishTests.isNotEmpty) count++;
    if (viewModel.interests.isNotEmpty) count++;
    if (viewModel.personalityProfile?.hasData == true) count++;
    if (viewModel.preferences.studyLevel.isNotEmpty ||
        viewModel.preferences.locations.isNotEmpty ||
        viewModel.preferences.mode.isNotEmpty ||
        viewModel.preferences.tuitionMax != null) {
      count++;
    }
    return count;
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

  IconData _getInterestIcon(String interest) {
    final iconMap = {
      'Coding': Icons.code,
      'Lab Work': Icons.science,
      'Public Speaking': Icons.record_voice_over,
      'Leadership': Icons.groups,
      'Designing': Icons.design_services,
      'Teaching': Icons.school,
      'Writing': Icons.edit,
      'Data Analysis': Icons.analytics,
      'Problem Solving': Icons.psychology,
      'Research': Icons.search,
      'Creativity': Icons.palette,
      'Business': Icons.business,
    };
    return iconMap[interest] ?? Icons.star_rounded;
  }

  Color _getGradeColor(String grade) {
    final upperGrade = grade.toUpperCase();
    if (upperGrade.contains('A') || upperGrade == '7' || upperGrade == 'A1' || upperGrade == 'A2') {
      return Colors.green[600]!;
    } else if (upperGrade.contains('B') || upperGrade == '6' || upperGrade == '5' ||
        upperGrade == 'B3' || upperGrade == 'B4') {
      return Colors.blue[600]!;
    } else if (upperGrade.contains('C') || upperGrade == '4' || upperGrade == '3' ||
        upperGrade == 'C5' || upperGrade == 'C6') {
      return Colors.orange[600]!;
    } else {
      return Colors.grey[600]!;
    }
  }
}