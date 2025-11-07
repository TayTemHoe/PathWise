// lib/views/resume_builder/resume_list_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/ViewModel/resume_view_model.dart';
import 'package:path_wise/ViewModel/profile_view_model.dart';
import 'package:path_wise/model/resume_model.dart';
import 'package:intl/intl.dart';

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Consumer2<ResumeViewModel, ProfileViewModel>(
                    builder: (context, resumeVM, profileVM, child) {
                      if (resumeVM.isLoading || profileVM.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          await profileVM.refresh();
                          await resumeVM.refresh();
                        },
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
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Resume Builder',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCreateNewCard(BuildContext context, ProfileViewModel profileVM, ResumeViewModel resumeVM) {
    final profile = profileVM.profile;
    final isProfileComplete = _isProfileComplete(profileVM);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Navigator.pushNamed(context, '/resume/template-selection');
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
                        color: const Color(0xFF7C3AED).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: Color(0xFF7C3AED),
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
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Build a professional resume from scratch',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      if (!isProfileComplete) {
                        _showIncompleteProfileDialog(context, profileVM);
                      } else {
                        Navigator.pushNamed(context, '/resume/template-selection');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Start Building',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
            const Color(0xFF7C3AED),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            '4',
            'Templates Available',
            const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYourResumesSection(BuildContext context, ResumeViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Resumes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No resumes yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first professional resume',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_getTemplateName(resume.template)} • Updated $updatedDate',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildActionButton(
                  'Edit',
                  Icons.edit_outlined,
                  const Color(0xFF7C3AED),
                      () {
                    viewModel.setCurrentResume(resume);
                    Navigator.pushNamed(context, '/resume/edit', arguments: resume);
                  },
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  'PDF',
                  Icons.download_outlined,
                  const Color(0xFF10B981),
                  viewModel.isDownloading
                      ? null
                      : () async {
                    await viewModel.downloadResume(resume);
                  },
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  'Share',
                  Icons.share_outlined,
                  const Color(0xFF3B82F6),
                  viewModel.isSharing
                      ? null
                      : () async {
                    await viewModel.shareResume(resume);
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
        height: 40,
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
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
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
    final missingFields = <String>[];
    final p = profileVM.profile;

    if (p?.name?.isEmpty ?? true) missingFields.add('Name');
    if (p?.email?.isEmpty ?? true) missingFields.add('Email');
    if (profileVM.skills.isEmpty && profileVM.education.isEmpty) {
      missingFields.add('Skills or Education');
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Incomplete Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Some profile information is missing. Complete your profile for a better resume or continue with available data.',
            ),
            if (missingFields.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Missing fields:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...missingFields.map((field) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.close, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(field),
                  ],
                ),
              )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to profile page
              // Navigator.pushNamed(context, '/profile');
            },
            child: const Text('Complete Profile'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/resume/template-selection');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
            ),
            child: const Text('Continue Anyway'),
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