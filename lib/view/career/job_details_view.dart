// lib/view/career/job_details_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_wise/model/job_models.dart';
import 'package:path_wise/viewModel/job_view_model.dart';
import 'package:path_wise/viewModel/profile_view_model.dart';

// Defining KYYAP Design Colors locally
class _DesignColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color background = Color(0xFFF5F7FA);
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color cardBackground = Colors.white;
  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFFDCB6E);
  static const Color info = Color(0xFF74B9FF);
  static Color shadow = Colors.black.withOpacity(0.08);
}

class JobDetailsView extends StatelessWidget {
  final JobModel job;

  const JobDetailsView({Key? key, required this.job}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DesignColors.background,
      appBar: AppBar(
        backgroundColor: _DesignColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _DesignColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Job Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _DesignColors.textPrimary,
          ),
        ),
        actions: [
          Consumer<JobViewModel>(
            builder: (context, jobVM, _) {
              final isSaved = jobVM.isJobSaved(job.jobId);
              return IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: isSaved ? _DesignColors.primary : _DesignColors.textSecondary,
                ),
                onPressed: () {
                  final user = context.read<ProfileViewModel>().uid;
                  if (user != null) {
                    jobVM.toggleJobSave(user, job);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isSaved ? 'Job removed from saved' : 'Job saved successfully'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: isSaved ? Colors.grey : _DesignColors.success,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please log in to save jobs')),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildTags(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Job Description'),
                    const SizedBox(height: 12),
                    Text(
                      job.jobDescription,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: _DesignColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (job.jobHighlightsQualifications != null &&
                        job.jobHighlightsQualifications!.isNotEmpty) ...[
                      _buildSectionTitle('Qualifications'),
                      const SizedBox(height: 12),
                      ...job.jobHighlightsQualifications!.map(
                            (q) => _buildBulletPoint(q),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (job.jobHighlightsResponsibilities != null &&
                        job.jobHighlightsResponsibilities!.isNotEmpty) ...[
                      _buildSectionTitle('Responsibilities'),
                      const SizedBox(height: 12),
                      ...job.jobHighlightsResponsibilities!.map(
                            (r) => _buildBulletPoint(r),
                      ),
                      const SizedBox(height: 24),
                    ],
                    _buildSectionTitle('About Company'),
                    const SizedBox(height: 12),
                    _buildCompanyInfo(),
                    const SizedBox(height: 100), // Bottom padding for FAB
                  ],
                ),
              ),
            ),
            _buildApplyButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _DesignColors.shadow,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: job.employerLogo != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                job.employerLogo!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.business, size: 40, color: Colors.grey),
              ),
            )
                : const Icon(Icons.business, size: 40, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Text(
            job.jobTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _DesignColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            job.companyName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _DesignColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: _DesignColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${job.jobLocation.city}, ${job.jobLocation.state}, ${job.jobLocation.country}',
                style: const TextStyle(
                  fontSize: 14,
                  color: _DesignColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        if (job.isRemote) _buildTag('Remote', _DesignColors.success),
        _buildTag(
          job.requiredExperience.experienceLevel ?? 'Entry Level',
          _DesignColors.info,
        ),
        if (job.jobEmploymentTypes.isNotEmpty)
          _buildTag(job.jobEmploymentTypes.first, _DesignColors.warning),
        _buildTag(
          job.getFormattedSalary(),
          _DesignColors.primary,
          isOutlined: true,
        ),
      ],
    );
  }

  Widget _buildTag(String text, Color color, {bool isOutlined = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: isOutlined ? Border.all(color: color) : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: _DesignColors.textPrimary,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: _DesignColors.primary)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: _DesignColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _DesignColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: job.employerLogo != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                job.employerLogo!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.business, color: Colors.grey),
              ),
            )
                : const Icon(Icons.business, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.companyName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _DesignColors.textPrimary,
                  ),
                ),
                if (job.employerWebsite != null)
                  GestureDetector(
                    onTap: () => _launchUrl(job.employerWebsite!),
                    child: const Text(
                      'Visit Website',
                      style: TextStyle(
                        fontSize: 12,
                        color: _DesignColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () => _launchUrl(job.jobApplyLink),
          style: ElevatedButton.styleFrom(
            backgroundColor: _DesignColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Apply Now',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $urlString';
    }
  }
}