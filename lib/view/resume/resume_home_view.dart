// lib/view/resume/resume_home_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/viewModel/resume_view_model.dart';
import 'package:path_wise/viewModel/profile_view_model.dart';
import 'package:path_wise/model/resume_model.dart';
import 'package:path_wise/view/resume/resume_create_view.dart';
import 'package:path_wise/view/resume/resume_customize_view.dart';
import 'package:intl/intl.dart';

import '../../utils/app_color.dart';

// Defining KYYAP Design Colors locally
class _DesignColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color background = Color(0xFFF5F7FA);
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color cardBackground = Colors.white;
  static const Color success = Color(0xFF00B894);
  static const Color info = Color(0xFF74B9FF);
  static const Color warning = Color(0xFFFDCB6E);
  static const Color error = Color(0xFFD63031);
  static Color shadow = Colors.black.withOpacity(0.08);
}

class ResumeListPage extends StatefulWidget {
  const ResumeListPage({Key? key}) : super(key: key);

  @override
  State<ResumeListPage> createState() => _ResumeListPageState();
}

class _ResumeListPageState extends State<ResumeListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load both profile and resumes
      context.read<ProfileViewModel>().loadAll();
      context.read<ResumeViewModel>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DesignColors.background,
      appBar: AppBar(
        backgroundColor: _DesignColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Resume Builder',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _DesignColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
              Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: _DesignColors.textSecondary),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer2<ResumeViewModel, ProfileViewModel>(
          builder: (context, resumeVM, profileVM, child) {
            if (resumeVM.isLoading || profileVM.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_DesignColors.primary),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                await profileVM.refresh();
                await resumeVM.refresh();
              },
              color: _DesignColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCreateNewCard(context, profileVM, resumeVM),
                      const SizedBox(height: 24),
                      _buildStatsRow(resumeVM),
                      const SizedBox(height: 24),
                      _buildYourResumesSection(context, resumeVM),
                      const SizedBox(height: 80), // Bottom padding
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCreateNewCard(BuildContext context, ProfileViewModel profileVM, ResumeViewModel resumeVM) {
    final isProfileComplete = _isProfileComplete(profileVM);

    return Container(
      decoration: BoxDecoration(
        color: _DesignColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _DesignColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!isProfileComplete) {
              _showIncompleteProfileDialog(context, profileVM);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TemplateSelectionPage(),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _DesignColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: _DesignColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create New Resume',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _DesignColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Build a professional resume from scratch',
                            style: TextStyle(
                              fontSize: 13,
                              color: _DesignColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!isProfileComplete) {
                        _showIncompleteProfileDialog(context, profileVM);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TemplateSelectionPage(),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _DesignColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Start Building',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(ResumeViewModel viewModel) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '${viewModel.resumeCount}',
            'Resumes Created',
            _DesignColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            '4',
            'Templates Available',
            _DesignColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _DesignColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _DesignColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: _DesignColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildYourResumesSection(BuildContext context, ResumeViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Resumes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _DesignColors.textPrimary,
              ),
            ),
            if (viewModel.hasResumes)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _DesignColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${viewModel.resumeCount} ${viewModel.resumeCount == 1 ? 'resume' : 'resumes'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _DesignColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (!viewModel.hasResumes)
          _buildEmptyState()
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: viewModel.resumes.length,
            itemBuilder: (context, index) {
              return _buildResumeCard(context, viewModel, viewModel.resumes[index]);
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      width: double.infinity,
      decoration: BoxDecoration(
        color: _DesignColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'No resumes yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _DesignColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first professional resume to get started',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _DesignColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeCard(
      BuildContext context,
      ResumeViewModel viewModel,
      ResumeDoc resume,
      ) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final updatedDate = resume.updatedAt != null
        ? dateFormat.format(resume.updatedAt!)
        : 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _DesignColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _DesignColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resume.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _DesignColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_getTemplateName(resume.template)} • Updated $updatedDate',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _DesignColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: _DesignColors.textSecondary,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  onPressed: () => _confirmDelete(context, viewModel, resume),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildActionButton(
                  'Edit',
                  Icons.edit_outlined,
                  _DesignColors.primary,
                      () {
                    viewModel.setCurrentResume(resume);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomizeResumePage(
                          resume: resume,
                          isEditing: true,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  'PDF',
                  Icons.download_outlined,
                  _DesignColors.success,
                  viewModel.isDownloading
                      ? null
                      : () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => _buildLoadingDialog('Downloading resume...'),
                    );

                    final path = await viewModel.downloadResume(resume);

                    if (context.mounted) {
                      Navigator.pop(context);

                      if (path != null && viewModel.successMessage != null) {
                        showDialog(
                          context: context,
                          builder: (context) => _buildSuccessDialog(path),
                        );
                      } else if (viewModel.error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(viewModel.error!),
                            backgroundColor: _DesignColors.error,
                          ),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  'Share',
                  Icons.share_outlined,
                  _DesignColors.info,
                  viewModel.isSharing
                      ? null
                      : () async {
                    await viewModel.shareResume(resume);
                    if (viewModel.successMessage != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(viewModel.successMessage!),
                          backgroundColor: _DesignColors.success,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String label,
      IconData icon,
      Color color,
      VoidCallback? onPressed,
      ) {
    return Expanded(
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingDialog(String message) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_DesignColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _DesignColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessDialog(String filePath) {
    final fileName = filePath.split('/').last;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _DesignColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: _DesignColors.success, size: 32),
            ),
            const SizedBox(height: 20),
            const Text(
              'Download Successful!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _DesignColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _DesignColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder_outlined, size: 20, color: _DesignColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fileName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _DesignColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _DesignColors.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ResumeViewModel viewModel, ResumeDoc resume) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Resume'),
        content: Text(
          'Are you sure you want to delete "${resume.title}"?',
          style: const TextStyle(color: _DesignColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: _DesignColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_DesignColors.error),
                  ),
                ),
              );

              final success = await viewModel.deleteResume(resume.id);

              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pop(); // Close loading

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Resume deleted successfully'),
                      backgroundColor: _DesignColors.success,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(viewModel.error ?? 'Failed to delete'),
                      backgroundColor: _DesignColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _DesignColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  bool _isProfileComplete(ProfileViewModel vm) {
    final p = vm.profile;
    if (p == null) return false;
    return (p.name?.isNotEmpty ?? false) &&
        (p.email?.isNotEmpty ?? false) &&
        ((vm.skills.isNotEmpty) || (vm.education.isNotEmpty));
  }

  void _showIncompleteProfileDialog(BuildContext context, ProfileViewModel profileVM) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: _DesignColors.warning),
            SizedBox(width: 8),
            Text('Profile Incomplete'),
          ],
        ),
        content: const Text(
          'Complete your profile for a better resume experience. Some fields are missing.',
          style: TextStyle(color: _DesignColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _DesignColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TemplateSelectionPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _DesignColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Continue Anyway'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: _DesignColors.primary),
            SizedBox(width: 12),
            Text('Help', style: TextStyle(color: _DesignColors.textPrimary)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpStep('1', 'Complete your profile information.'),
              _buildHelpStep('2', 'Select "Create New Resume".'),
              _buildHelpStep('3', 'Customize and download your PDF.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it', style: TextStyle(color: _DesignColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: _DesignColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: _DesignColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  String _getTemplateName(ResumeTemplateType template) {
    switch (template) {
      case ResumeTemplateType.tech:
        return 'Modern Tech';
      case ResumeTemplateType.business:
        return 'Classic Business';
      case ResumeTemplateType.creative:
        return 'Creative';
      case ResumeTemplateType.academic:
        return 'Academic';
    }
  }
}