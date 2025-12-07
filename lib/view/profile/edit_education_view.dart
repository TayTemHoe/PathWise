import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/viewModel/profile_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/ai_match_model.dart';
import '../../utils/app_color.dart';
import '../../viewModel/ai_match_view_model.dart';
import '../../widgets/academic_records_card.dart';
import '../../widgets/ai_match_pages/academic_record_dialog.dart';

/// Edit Education Screen
/// Displays ALL academic records from Firestore (vm.education)
/// Unlike education_snapshot_page which filters by current education level
class EditEducationScreen extends StatefulWidget {
  const EditEducationScreen({super.key});

  @override
  State<EditEducationScreen> createState() => _EditEducationScreenState();
}

class _EditEducationScreenState extends State<EditEducationScreen> {
  final Color _primaryColor = const Color(0xFF6C63FF);
  final Color _textColor = const Color(0xFF1A1A1A);
  final Color _backgroundColor = Colors.white;

  @override
  void initState() {
    super.initState();
    // Force reload on init to ensure fresh data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<ProfileViewModel>(context, listen: false);
      vm.loadUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, vm, _) {
        // Display ALL education records from Firestore (no filtering)
        final allEducationRecords = vm.education;
        final eduCount = allEducationRecords.length;

        // Debug: Print records to verify data completeness
        debugPrint('=== Edit Education View ===');
        debugPrint('Total records: $eduCount');
        for (var i = 0; i < allEducationRecords.length; i++) {
          final record = allEducationRecords[i];
          debugPrint('Record ${i + 1}: ${record.id}');
          debugPrint('  Level: ${record.level}');
          debugPrint('  Institution: ${record.institution}');
          debugPrint('  Program Name: ${record.programName}');
          debugPrint('  Major: ${record.major}');
          debugPrint('  Research Area: ${record.researchArea}');
          debugPrint('  Exam Type: ${record.examType}');
          debugPrint('  Stream: ${record.stream}');
          debugPrint('  Class of Award: ${record.classOfAward}');
          debugPrint('  Honors: ${record.honors}');
          debugPrint('  Classification: ${record.classification}');
          debugPrint('  Thesis Title: ${record.thesisTitle}');
          debugPrint('  CGPA: ${record.cgpa}');
          debugPrint('  Start Date: ${record.startDate}');
          debugPrint('  End Date: ${record.endDate}');
          debugPrint('  Subjects: ${record.subjects.length}');
        }

        return Scaffold(
          backgroundColor: _backgroundColor,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: _backgroundColor,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: AppColors.textPrimary,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Education Background',
              style: TextStyle(
                color: _textColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          body: vm.isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: _primaryColor),
                      SizedBox(height: 16),
                      Text(
                        'Loading education records...',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await vm.loadUserProfile();
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Stats Card
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$eduCount',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: _primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  eduCount == 1
                                      ? 'Education Entry'
                                      : 'Education Entries',
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
                                color: _primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.school,
                                color: _primaryColor,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Header with Add Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Your Education',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _textColor,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _showAddOrEditSheet(context, vm),
                            icon: Icon(
                              Icons.add_circle_outline,
                              color: _primaryColor,
                              size: 20,
                            ),
                            label: Text(
                              'Add New',
                              style: TextStyle(
                                color: _primaryColor,
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
                      ),
                      const SizedBox(height: 16),

                      // Empty State
                      if (allEducationRecords.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No education history yet',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap "Add New" to get started',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      // Education Records List - Display ALL records using AcademicRecordCard
                      else
                        ...allEducationRecords.asMap().entries.map((entry) {
                          final index = entry.key;
                          final record = entry.value;

                          return AcademicRecordCard(
                            key: ValueKey('edu_${record.id}'),
                            record: record,
                            index: index,
                            primaryColor: _primaryColor,
                            isDefault: index == 0,
                            showDefaultBadge: false,
                            onEdit: () => _showAddOrEditSheet(
                              context,
                              vm,
                              existing: record,
                            ),
                            onDelete: () async {
                              final confirmed = await _confirmDelete(
                                context,
                                record.level,
                              );
                              if (!confirmed) return;

                              await vm.deleteEducation(record.id);

                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '${record.level} deleted successfully',
                                      ),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFFD63031),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            },
                            // ✅ NEW: Add onSetCurrent callback
                            onSetCurrent: record.isCurrent == true
                                ? null
                                : () async {
                              // 1. Update Firestore via ProfileViewModel
                              final success = await vm.setCurrentEducation(record.id);

                              if (!context.mounted) return;

                              if (success) {
                                // 2. Reload Profile to get fresh 'isCurrent' flags
                                await vm.loadUserProfile();

                                // 3. ✅ CRITICAL FIX: Await the sync to ensure save completes
                                if (context.mounted) {
                                  final aiMatchVM = Provider.of<AIMatchViewModel>(
                                    context,
                                    listen: false,
                                  );

                                  debugPrint('🔄 Syncing current education to AI Match...');

                                  // ✅ AWAIT the sync operation
                                  await aiMatchVM.syncFromUserProfile(vm.profile);

                                  debugPrint('✅ Current education synced to AI Match & saved to SharedPrefs');

                                  // Verify the saved data
                                  final userId = aiMatchVM.userId;
                                  if (userId != null) {
                                    final prefs = await SharedPreferences.getInstance();
                                    final savedRecords = prefs.getString('ai_match_academic_records_$userId');
                                    debugPrint('🔍 Verification - SharedPrefs records: $savedRecords');
                                  }
                                }

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.star, color: Colors.white, size: 18),
                                          const SizedBox(width: 10),
                                          Text('${record.level} set as current education'),
                                        ],
                                      ),
                                      backgroundColor: Colors.amber[700],
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            },
                          );
                        }),

                      const SizedBox(height: 32),
                      _EducationTipsCard(primaryColor: _primaryColor),
                    ],
                  ),
                ),
        );
      },
    );
  }

  /// Show dialog for adding new or editing existing education record
  Future<void> _showAddOrEditSheet(
    BuildContext context,
    ProfileViewModel vm, {
    AcademicRecord? existing,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AcademicRecordDialog(
        existingRecord: existing,
        showLevelDropdown: true,
        // Show dropdown in edit view for full flexibility
        onSave: (record) async {
          debugPrint('💾 Saving record in dialog...');
          debugPrint('  Level: ${record.level}');
          debugPrint('  Program: ${record.programName}');
          debugPrint('  Major: ${record.major}');
          debugPrint('  Class of Award: ${record.classOfAward}');

          bool success;
          if (existing != null) {
            final updatedRecord = record.copyWith(
              id: existing.id,
              createdAt: existing.createdAt,
            );
            success = await vm.saveEducation(updatedRecord);
          } else {
            success = await vm.addEducation(record);
          }

          if (context.mounted && success) {
            Navigator.pop(context);

            // ✅ MODIFIED: Sync immediately on Add/Update
            await vm.loadUserProfile();
            if (context.mounted) {
              Provider.of<AIMatchViewModel>(
                context,
                listen: false,
              ).syncFromUserProfile(vm.profile);
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  existing != null
                      ? 'Updated successfully'
                      : 'Added successfully',
                ),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(vm.error ?? 'Failed to save education record'),
                  ],
                ),
                backgroundColor: Colors.red[600],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        },
      ),
    );
  }

  /// Confirm deletion dialog
  Future<bool> _confirmDelete(BuildContext context, String level) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
                const SizedBox(width: 12),
                const Text('Delete Education?'),
              ],
            ),
            content: Text(
              'Remove "$level" from your profile? This action cannot be undone.',
              style: const TextStyle(height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD63031),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}

/// Education Tips Card Widget
class _EducationTipsCard extends StatelessWidget {
  const _EducationTipsCard({required this.primaryColor});

  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
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
              Icon(Icons.lightbulb_outline, color: primaryColor, size: 22),
              const SizedBox(width: 8),
              Text(
                'Pro Tips',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _TipRow('List your most recent degree first.'),
          const _TipRow(
            'Include relevant coursework if you are a fresh graduate.',
          ),
          const _TipRow('Keep your information accurate and up-to-date.'),
          const _TipRow(
            'Add all education levels for better matching recommendations.',
          ),
        ],
      ),
    );
  }
}

/// Individual Tip Row Widget
class _TipRow extends StatelessWidget {
  const _TipRow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
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
}
