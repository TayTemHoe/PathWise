import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../model/ai_match_model.dart';
import '../../utils/app_color.dart';
import '../../viewModel/ai_match_view_model.dart';
import '../form_components.dart';
import 'academic_record_dialog.dart';

class EducationSnapshotPage extends StatelessWidget {
  const EducationSnapshotPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AIMatchViewModel>(
      builder: (context, viewModel, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'Current Education Level',
                'Select your highest completed or current education level',
              ),
              const SizedBox(height: 16),
              _buildEducationLevelGrid(context, viewModel),

              if (viewModel.educationLevel == EducationLevel.other) ...[
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Specify Education Level',
                  controller: TextEditingController(
                    text: viewModel.otherEducationLevelText,
                  ),
                  hint: 'e.g., Certificate, Professional Course',
                  prefixIcon: Icons.edit,
                  isRequired: true,
                  onChanged: (value) =>
                      viewModel.setOtherEducationLevelText(value),
                ),
              ],

              if (viewModel.educationLevel != null) ...[
                const SizedBox(height: 16),
                _buildAcademicRecordsSection(context, viewModel),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.school_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Current Education Level',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildEducationLevelGrid(
      BuildContext context, AIMatchViewModel viewModel) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.8,
          children: EducationLevel.values.map((level) {
            final isSelected = viewModel.educationLevel == level;
            return _buildEducationLevelCard(
              label: level.label,
              isSelected: isSelected,
              onTap: () {
                HapticFeedback.lightImpact();

                if (viewModel.academicRecords.isNotEmpty &&
                    viewModel.educationLevel != level) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.white,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Please remove existing academic records before changing education level',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.orange[700],
                      behavior: SnackBarBehavior.floating,
                      action: SnackBarAction(
                        label: 'Clear All',
                        textColor: Colors.white,
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orange,
                                  ),
                                  SizedBox(width: 12),
                                  Text('Clear All Records?'),
                                ],
                              ),
                              content: Text(
                                'This will remove all ${viewModel.academicRecords.length} academic record(s).',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    viewModel.clearAllAcademicRecords();
                                    viewModel.setEducationLevel(level);
                                    Navigator.pop(ctx);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[600],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text('Clear All'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      duration: Duration(seconds: 4),
                    ),
                  );
                  return;
                }

                viewModel.setEducationLevel(level);
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildEducationLevelCard({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        padding: const EdgeInsets.all(12),
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildAcademicRecordsSection(
      BuildContext context, AIMatchViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (viewModel.academicRecords.isEmpty) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAcademicRecordDialog(context, viewModel),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text(
                'Add Academic Record',
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
          ),
        ],

        if (viewModel.academicRecords.isNotEmpty) ...[
          const SizedBox(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.checklist_rounded,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Academic Records',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${viewModel.academicRecords.length} record(s) saved',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...viewModel.academicRecords.asMap().entries.map((entry) {
            final index = entry.key;
            final record = entry.value;
            return _buildRecordCard(context, viewModel, record, index);
          }),
        ],
      ],
    );
  }

  void _showAcademicRecordDialog(
      BuildContext context, AIMatchViewModel viewModel,
      {AcademicRecord? existingRecord, int? index}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AcademicRecordDialog(
        viewModel: viewModel,
        existingRecord: existingRecord,
        recordIndex: index,
      ),
    );
  }

  Widget _buildRecordCard(
      BuildContext context,
      AIMatchViewModel viewModel,
      AcademicRecord record,
      int index,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
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
          // Top accent
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.6)
                ],
              ),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.school_rounded,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.level,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (record.examType != null &&
                              record.examType!.toLowerCase() !=
                                  record.level.toLowerCase()) ...[
                            const SizedBox(height: 3),
                            Text(
                              record.examType!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Edit button
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      color: AppColors.primary,
                      onPressed: () => _showAcademicRecordDialog(
                        context,
                        viewModel,
                        existingRecord: record,
                        index: index,
                      ),
                      tooltip: 'Edit record',
                    ),
                    // Delete button
                    IconButton(
                      icon:
                      const Icon(Icons.delete_outline_rounded, size: 20),
                      color: Colors.red[400],
                      onPressed: () =>
                          _showDeleteConfirmation(context, viewModel, index),
                      tooltip: 'Delete record',
                    ),
                  ],
                ),

                // Institution
                if (record.institution != null &&
                    record.institution!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_city_rounded,
                          size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          record.institution!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),
                Divider(height: 1, color: Colors.grey[200]),
                const SizedBox(height: 16),

                // Programme/Research/Major card
                if (record.programName != null ||
                    record.researchArea != null ||
                    record.major != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[100]!, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.menu_book_rounded,
                                size: 15, color: Colors.blue[700]),
                            const SizedBox(width: 6),
                            Text(
                              _getProgramLabel(record.level),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          record.programName ??
                              record.researchArea ??
                              record.major ??
                              '',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[900],
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Thesis/Dissertation
                if (record.thesisTitle != null &&
                    record.thesisTitle!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple[100]!, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.description_outlined,
                                size: 15, color: Colors.purple[700]),
                            const SizedBox(width: 6),
                            Text(
                              _getThesisLabel(record.level),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.purple[700],
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          record.thesisTitle!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple[900],
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Metrics pills
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (record.cgpa != null && record.cgpa! > 0)
                      _buildMetricPill(
                        icon: Icons.stars_rounded,
                        label: 'CGPA ${record.cgpa!.toStringAsFixed(2)}',
                        color: AppColors.primary,
                      ),
                    if (record.totalScore != null && record.totalScore! > 0)
                      _buildMetricPill(
                        icon: Icons.emoji_events_rounded,
                        label:
                        'Score ${record.totalScore!.toStringAsFixed(0)}',
                        color: AppColors.primary,
                      ),
                    if (record.graduationYear != null)
                      _buildMetricPill(
                        icon: Icons.event_rounded,
                        label: '${record.graduationYear}',
                        color: Colors.blue[600]!,
                      ),
                    if (record.stream != null && record.stream!.isNotEmpty)
                      _buildMetricPill(
                        icon: Icons.category_rounded,
                        label: record.stream!,
                        color: Colors.teal[600]!,
                        maxWidth: 200,
                      ),
                    if (record.honors != null && record.honors!.isNotEmpty)
                      _buildMetricPill(
                        icon: Icons.workspace_premium_rounded,
                        label: _formatHonors(record.honors!),
                        color: Colors.amber[700]!,
                        maxWidth: 180,
                      ),
                    if (record.classOfAward != null &&
                        record.classOfAward!.isNotEmpty)
                      _buildMetricPill(
                        icon: Icons.military_tech_rounded,
                        label: record.classOfAward!,
                        color: Colors.amber[700]!,
                        maxWidth: 180,
                      ),
                    if (record.classification != null &&
                        record.classification!.isNotEmpty)
                      _buildMetricPill(
                        icon: Icons.verified_rounded,
                        label: record.classification!,
                        color: Colors.green[600]!,
                      ),
                  ],
                ),

                // Subjects
                if (record.subjects.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSubjectsSection(record.subjects),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getProgramLabel(String level) {
    final levelLower = level.toLowerCase();
    if (levelLower.contains('phd')) return 'RESEARCH AREA';
    if (levelLower.contains('master')) return 'RESEARCH AREA';
    if (levelLower.contains('bachelor')) return 'MAJOR';
    if (levelLower.contains('diploma')) return 'PROGRAMME';
    if (levelLower.contains('foundation')) return 'PROGRAMME';
    if (levelLower.contains('matriculation')) return 'PROGRAMME';
    return 'FIELD OF STUDY';
  }

  String _getThesisLabel(String level) {
    final levelLower = level.toLowerCase();
    if (levelLower.contains('phd')) return 'DISSERTATION TITLE';
    if (levelLower.contains('master')) return 'THESIS TITLE';
    return 'RESEARCH TITLE';
  }

  String _formatHonors(String honors) {
    // Shorten long honor names for display
    return honors
        .replaceAll('Second Class Upper Division', 'Second Upper')
        .replaceAll('Second Class Lower Division', 'Second Lower');
  }

  Widget _buildMetricPill({
    required IconData icon,
    required String label,
    required Color color,
    double? maxWidth,
  }) {
    return Container(
      constraints:
      maxWidth != null ? BoxConstraints(maxWidth: maxWidth) : null,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: -0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsSection(List<SubjectGrade> subjects) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.subject_rounded,
                size: 16,
                color: Colors.grey[700],
              ),
              SizedBox(width: 8),
              Text(
                'Subjects',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(width: 6),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${subjects.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: subjects.map((subject) => _buildSubjectChip(subject)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectChip(SubjectGrade subject) {
    final gradeColor = _getGradeColor(subject.grade);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 120),
            child: Text(
              subject.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                letterSpacing: -0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: gradeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              subject.grade,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context,
      AIMatchViewModel viewModel,
      int index,
      ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
            SizedBox(width: 12),
            Text('Delete Record?'),
          ],
        ),
        content: Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              viewModel.removeAcademicRecord(index);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 18),
                      SizedBox(width: 10),
                      Text('Record deleted successfully'),
                    ],
                  ),
                  backgroundColor: Colors.green[600],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    final upperGrade = grade.toUpperCase();

    if (upperGrade.contains('A') ||
        upperGrade == '7' ||
        upperGrade == 'A1' ||
        upperGrade == 'A2') {
      return Colors.green[600]!;
    } else if (upperGrade.contains('B') ||
        upperGrade == '6' ||
        upperGrade == '5' ||
        upperGrade == 'B3' ||
        upperGrade == 'B4') {
      return Colors.blue[600]!;
    } else if (upperGrade.contains('C') ||
        upperGrade == '4' ||
        upperGrade == '3' ||
        upperGrade == 'C5' ||
        upperGrade == 'C6') {
      return Colors.orange[600]!;
    } else {
      return Colors.grey[600]!;
    }
  }
}