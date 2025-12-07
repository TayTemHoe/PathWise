import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/ai_match_model.dart';
import '../utils/app_color.dart';

class AcademicRecordCard extends StatelessWidget {
  final AcademicRecord record;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSetCurrent; // ✅ NEW
  final bool isDefault;
  final bool showDefaultBadge;
  final Color primaryColor;

  const AcademicRecordCard({
    Key? key,
    required this.record,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    this.onSetCurrent, // ✅ NEW
    this.isDefault = false,
    this.showDefaultBadge = false,
    this.primaryColor = const Color(0xFF6C63FF),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: record.isCurrent == true ? Colors.amber[700]! : const Color(0xFFE5E7EB),
          width: record.isCurrent == true ? 2 : (isDefault ? 2 : 1),
        ),
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
          // Top Accent
          Container(
            height: 3,
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
                        color: primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.school_rounded, color: primaryColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  record.level,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              if (record.isCurrent == true) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.amber),
                                  ),
                                  child: const Text(
                                    'CURRENT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ),
                              ]
                            ],
                          ),
                          if (record.examType != null &&
                              record.examType!.toLowerCase() != record.level.toLowerCase()) ...[
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
                    // Menu
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onSelected: (v) {
                        if (v == 'edit') onEdit();
                        if (v == 'delete') onDelete();
                        if (v == 'set_current') {
                          if (onSetCurrent != null) onSetCurrent!();
                        }
                      },
                      itemBuilder: (context) => [
                        // ✅ NEW: Only show "Set as Current" if it's NOT already current
                        if (record.isCurrent != true)
                          PopupMenuItem(
                            value: 'set_current',
                            child: Row(
                              children: [
                                Icon(Icons.star_border, size: 18, color: Colors.amber[700]),
                                const SizedBox(width: 12),
                                Text('Set as Current', style: TextStyle(color: Colors.amber[900])),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18, color: Colors.grey),
                              SizedBox(width: 12),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Institution
                if (record.institution != null && record.institution!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_city_rounded, size: 14, color: Colors.grey[500]),
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

                // Program / Major / Research Area
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
                            Icon(Icons.menu_book_rounded, size: 15, color: Colors.blue[700]),
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
                          record.programName ?? record.researchArea ?? record.major ?? '',
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

                // Thesis
                if (record.thesisTitle != null && record.thesisTitle!.isNotEmpty) ...[
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
                            Icon(Icons.description_outlined, size: 15, color: Colors.purple[700]),
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

                // Metrics Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (record.startDate != null && record.endDate != null)
                      _buildMetricPill(
                        icon: Icons.date_range_rounded,
                        label: _formatDateRange(record.startDate!, record.endDate!),
                        color: Colors.blue[600]!,
                        maxWidth: 200,
                      ),
                    if (record.cgpa != null && record.cgpa! > 0)
                      _buildMetricPill(
                        icon: Icons.stars_rounded,
                        label: 'CGPA ${record.cgpa!.toStringAsFixed(2)}',
                        color: AppColors.primary,
                      ),
                    if (record.totalScore != null && record.totalScore! > 0)
                      _buildMetricPill(
                        icon: Icons.emoji_events_rounded,
                        label: 'Score ${record.totalScore!.toStringAsFixed(0)}',
                        color: AppColors.primary,
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
                    if (record.classOfAward != null && record.classOfAward!.isNotEmpty)
                      _buildMetricPill(
                        icon: Icons.military_tech_rounded,
                        label: record.classOfAward!,
                        color: Colors.amber[700]!,
                        maxWidth: 180,
                      ),
                    if (record.classification != null && record.classification!.isNotEmpty)
                      _buildMetricPill(
                        icon: Icons.verified_rounded,
                        label: record.classification!,
                        color: Colors.green[600]!,
                      ),
                  ],
                ),

                // Subjects List
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

  String _formatDateRange(Timestamp startDate, Timestamp endDate) {
    final startStr = DateFormat('MMM yyyy').format(startDate.toDate());
    final endStr = DateFormat('MMM yyyy').format(endDate.toDate());

    return '$startStr - $endStr';
  }

  String _getProgramLabel(String level) {
    final l = level.toLowerCase();
    if (l.contains('phd')) return 'RESEARCH AREA';
    if (l.contains('master')) return 'RESEARCH AREA';
    if (l.contains('bachelor')) return 'MAJOR';
    if (l.contains('diploma')) return 'PROGRAMME';
    if (l.contains('foundation')) return 'PROGRAMME';
    return 'FIELD OF STUDY';
  }

  String _getThesisLabel(String level) {
    final l = level.toLowerCase();
    if (l.contains('phd')) return 'DISSERTATION TITLE';
    if (l.contains('master')) return 'THESIS TITLE';
    return 'RESEARCH TITLE';
  }

  String _formatHonors(String honors) {
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
      constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth) : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
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
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.subject_rounded, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                'Subjects',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${subjects.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: subjects.map((s) => _buildSubjectChip(s)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectChip(SubjectGrade subject) {
    Color gradeColor;
    final g = subject.grade.toUpperCase();
    if (g.startsWith('A') || g == '7') {
      gradeColor = Colors.green[600]!;
    } else if (g.startsWith('B') || g == '6' || g == '5') {
      gradeColor = Colors.blue[600]!;
    } else if (g.startsWith('C') || g == '4' || g == '3') {
      gradeColor = Colors.orange[600]!;
    } else {
      gradeColor = Colors.grey[600]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
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
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: gradeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              subject.grade,
              style: const TextStyle(
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
}