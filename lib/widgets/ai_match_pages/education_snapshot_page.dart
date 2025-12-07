import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../model/ai_match_model.dart';
import '../../utils/app_color.dart';
import '../../viewModel/ai_match_view_model.dart';
import '../../viewModel/profile_view_model.dart';
import '../../view/profile/edit_education_view.dart';
import '../academic_records_card.dart';
import '../form_components.dart';
import 'academic_record_dialog.dart';

class EducationSnapshotPage extends StatefulWidget {
  const EducationSnapshotPage({Key? key}) : super(key: key);

  @override
  State<EducationSnapshotPage> createState() => _EducationSnapshotPageState();
}

class _EducationSnapshotPageState extends State<EducationSnapshotPage> {
  @override
  void initState() {
    super.initState();
    // ✅ NEW: Force reload from SharedPreferences on page load
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final aiMatchVM = Provider.of<AIMatchViewModel>(context, listen: false);
      final profileVM = Provider.of<ProfileViewModel>(context, listen: false);

      debugPrint('🔄 EducationSnapshotPage: Force reloading current education...');

      // 1. Reload from SharedPreferences with force refresh
      await aiMatchVM.loadProgress(forceRefresh: true);

      // 2. If still empty, try syncing from Profile
      if (aiMatchVM.educationLevel == null && profileVM.profile != null) {
        debugPrint('⚠️ No data in SharedPrefs, syncing from Profile...');
        aiMatchVM.syncFromUserProfile(profileVM.profile);
      }

      debugPrint('✅ Current education loaded: ${aiMatchVM.educationLevel?.label}');
    });
  }

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
                context, // ✅ Pass context
                'Current Education Level',
                'Select your highest completed or current education level',
                viewModel, // ✅ Pass viewModel
              ),
              const SizedBox(height: 16),
              _buildEducationLevelGrid(context, viewModel),

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

  Widget _buildSectionHeader(
      BuildContext context,
      String title,
      String subtitle,
      AIMatchViewModel viewModel,
      ) {
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
            // ✅ NEW: Add "Change" button
            if (viewModel.educationLevel != null)
              TextButton.icon(
                onPressed: () => _navigateToEditEducation(context),
                icon: Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                label: Text(
                  'Change',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  // ✅ NEW: Navigate to Edit Education View
  void _navigateToEditEducation(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EditEducationScreen(),
      ),
    );

    // ✅ FIX: Sync state when returning from Edit screen
    if (context.mounted) {
      final aiMatchVM = Provider.of<AIMatchViewModel>(context, listen: false);
      final profileVM = Provider.of<ProfileViewModel>(context, listen: false);

      // 1. Reload Profile from Firestore to get the latest 'is_current' flags
      await profileVM.loadUserProfile();

      // 2. Sync AI Match VM state from the fresh Profile data
      aiMatchVM.syncFromUserProfile(profileVM.profile);
    }
  }

  Widget _buildEducationLevelGrid(
      BuildContext context,
      AIMatchViewModel viewModel,
      ) {
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
              context: context, // ✅ Pass context
              label: level.label,
              level: level,
              isSelected: isSelected,
              viewModel: viewModel, // ✅ Pass viewModel
              onTap: () {
                HapticFeedback.lightImpact();
                _handleLevelSelection(context, viewModel, level);
              },
            );
          }).toList(),
        );
      },
    );
  }

  // ✅ NEW: Handle level selection with validation
  void _handleLevelSelection(
      BuildContext context,
      AIMatchViewModel viewModel,
      EducationLevel level,
      ) async {
    // Check if user is trying to select a different level when records exist
    if (viewModel.educationLevel != null &&
        viewModel.educationLevel != level &&
        viewModel.academicRecords.isNotEmpty) {

      // Show warning modal
      final shouldChange = await _showLevelChangeWarning(context, level);

      if (!shouldChange) return;
    }

    viewModel.setEducationLevel(level);
  }

  // ✅ NEW: Show modern warning modal
  Future<bool> _showLevelChangeWarning(
      BuildContext context,
      EducationLevel newLevel,
      ) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 48),
              ),
              const SizedBox(height: 20),
              Text('Change Education Level?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Text(
                'You can only have one current education level at a time.\n\nTo change to "${newLevel.label}", please use the "Change" button and set a different education record as current from your profile.',
                style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, false);
                        _navigateToEditEducation(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Go to Edit', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ) ?? false;
  }

  Widget _buildEducationLevelCard({
    required BuildContext context,
    required String label,
    required EducationLevel level,
    required bool isSelected,
    required AIMatchViewModel viewModel,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
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
      BuildContext context,
      AIMatchViewModel viewModel,
      ) {
    // Filter Logic: Show only records matching current education level
    final currentLevelLabel = viewModel.educationLevel?.label;
    final filteredRecords = viewModel.academicRecords.where((r) {
      return r.level == currentLevelLabel;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (filteredRecords.isEmpty) ...[
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

        if (filteredRecords.isNotEmpty) ...[
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
                child: Icon(
                  Icons.checklist_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
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
                      '${filteredRecords.length} record(s) for ${viewModel.educationLevel?.label}',
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

          // Use the shared AcademicRecordCard widget
          ...filteredRecords.map((record) {
            // Find real index for update/delete operations
            final realIndex = viewModel.academicRecords.indexOf(record);

            return AcademicRecordCard(
              record: record,
              index: realIndex,
              primaryColor: AppColors.primary,
              onEdit: () => _showAcademicRecordDialog(
                context,
                viewModel,
                existingRecord: record,
                index: realIndex,
              ),
              onDelete: () =>
                  _showDeleteConfirmation(context, viewModel, realIndex),
            );
          }).toList(),
        ],
      ],
    );
  }

  void _showAcademicRecordDialog(
      BuildContext context,
      AIMatchViewModel viewModel, {
        AcademicRecord? existingRecord,
        int? index,
      }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AcademicRecordDialog(
        existingRecord: existingRecord,
        showLevelDropdown: false,
        preselectedLevel: viewModel.educationLevel,
        // ✅ NO CHANGES NEEDED: The dialog now handles "Other" text internally
        onSave: (record) async {
          final newRecord = record.copyWith(isCurrent: true);
          final profileVM = Provider.of<ProfileViewModel>(context, listen: false);

          bool success;
          if (existingRecord != null) {
            success = await profileVM.saveEducation(newRecord);
          } else {
            success = await profileVM.addEducation(newRecord);
          }

          if (context.mounted && success) {
            await profileVM.loadUserProfile();
            await viewModel.syncFromUserProfile(profileVM.profile);

            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Academic record saved & set as current!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(message, style: const TextStyle(fontSize: 13)),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context,
      AIMatchViewModel viewModel,
      int index,
      ) async {
    final record = viewModel.academicRecords[index];

    // ✅ NEW: Modern confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red[700],
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Delete Academic Record?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'This will permanently delete "${record.level}". This action cannot be undone.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    // ✅ NEW: Delete from both Firebase AND SharedPreferences
    final profileVM = Provider.of<ProfileViewModel>(context, listen: false);

    // Show loading indicator
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    try {
      // 1. Delete from Firebase
      final success = await profileVM.deleteEducation(record.id);

      if (!success) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(profileVM.error ?? 'Failed to delete record'),
              backgroundColor: Colors.red[600],
            ),
          );
        }
        return;
      }

      // 2. Remove from AIMatchViewModel (memory)
      viewModel.removeAcademicRecord(index);

      // 3. Save to SharedPreferences (this will update the stored data)
      await viewModel.saveProgress();

      // 4. Reload profile to ensure sync
      await profileVM.loadUserProfile();

      if (context.mounted) {
        Navigator.pop(context); // Close loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Record deleted Successfully',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }
}