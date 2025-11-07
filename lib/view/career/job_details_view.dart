// lib/view/job_details_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/model/job_models.dart';
import 'package:path_wise/ViewModel/job_view_model.dart';
import 'package:path_wise/ViewModel/profile_view_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class JobDetailsView extends StatefulWidget {
  final JobModel job;

  const JobDetailsView({
    Key? key,
    required this.job,
  }) : super(key: key);

  @override
  State<JobDetailsView> createState() => _JobDetailsViewState();
}

class _JobDetailsViewState extends State<JobDetailsView> {
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingActions = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Hide floating action buttons when scrolling down
    if (_scrollController.position.pixels > 100 && _showFloatingActions) {
      setState(() => _showFloatingActions = false);
    } else if (_scrollController.position.pixels <= 100 && !_showFloatingActions) {
      setState(() => _showFloatingActions = true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildJobHeader(),
                    SizedBox(height: 8),
                    _buildJobOverview(),
                    SizedBox(height: 8),
                    _buildJobDescription(),
                    SizedBox(height: 8),
                    _buildQualifications(),
                    SizedBox(height: 8),
                    _buildResponsibilities(),
                    SizedBox(height: 8),
                    _buildBenefitsSection(),
                    SizedBox(height: 8),
                    _buildCompanyInfo(),
                    SizedBox(height: 100), // Space for bottom actions
                  ],
                ),
              ),
            ],
          ),
          _buildBottomActionBar(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Color(0xFF7C3AED),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Job Details',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.share, color: Colors.white),
          onPressed: _shareJob,
        ),
      ],
    );
  }

  Widget _buildJobHeader() {
    final isNewJob = DateTime.now().difference(widget.job.postedAt).inDays <= 7;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Company Logo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: widget.job.employerLogo != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                widget.job.employerLogo!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.business, size: 40, color: Colors.grey[400]);
                },
              ),
            )
                : Icon(Icons.business, size: 40, color: Colors.grey[400]),
          ),
          SizedBox(height: 16),
          // Job Title with NEW badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  widget.job.jobTitle,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isNewJob) ...[
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 8),
          // Company Name
          Text(
            widget.job.companyName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7C3AED),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          // Location and Posted Date
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  '${widget.job.jobLocation.city}, ${widget.job.jobLocation.state}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              SizedBox(width: 4),
              Text(
                widget.job.getTimeSincePosted(),
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Match Percentage Badge (95% Match)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Color(0xFF10B981)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: Color(0xFF10B981), size: 18),
                SizedBox(width: 6),
                Text(
                  '95% Match',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobOverview() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Job Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildOverviewItem(
                  icon: Icons.payments_outlined,
                  iconColor: Color(0xFF10B981),
                  label: 'Salary',
                  value: widget.job.getFormattedSalary(),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildOverviewItem(
                  icon: Icons.work_outline,
                  iconColor: Color(0xFF7C3AED),
                  label: 'Work Mode',
                  value: widget.job.isRemote ? 'Hybrid' : 'On-site',
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildOverviewItem(
                  icon: Icons.schedule,
                  iconColor: Colors.orange,
                  label: 'Employment Type',
                  value: widget.job.jobEmploymentTypes.isNotEmpty
                      ? widget.job.jobEmploymentTypes.first
                      : 'Full-time',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildOverviewItem(
                  icon: Icons.bar_chart,
                  iconColor: Colors.blue,
                  label: 'Level',
                  value: widget.job.requiredExperience.experienceLevel ?? 'Senior',
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildOverviewItem(
                  icon: Icons.apartment,
                  iconColor: Colors.teal,
                  label: 'Department',
                  value: 'Engineering',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildOverviewItem(
                  icon: Icons.badge_outlined,
                  iconColor: Colors.deepPurple,
                  label: 'Job ID',
                  value: widget.job.jobId.substring(0, 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildJobDescription() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Job Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Text(
            widget.job.jobDescription,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualifications() {
    if (widget.job.jobHighlightsQualifications.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: Color(0xFF7C3AED), size: 22),
              SizedBox(width: 8),
              Text(
                'Qualifications & Requirements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...widget.job.jobHighlightsQualifications.map((qual) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Color(0xFF7C3AED),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      qual,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildResponsibilities() {
    if (widget.job.jobHighlightsResponsibilities.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_outlined, color: Colors.orange, size: 22),
              SizedBox(width: 8),
              Text(
                'Key Responsibilities',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...widget.job.jobHighlightsResponsibilities.map((resp) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      resp,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection() {
    if (widget.job.jobBenefits.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard, color: Color(0xFF10B981), size: 22),
              SizedBox(width: 8),
              Text(
                'Benefits & Perks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.job.jobBenefits.map((benefit) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Color(0xFF10B981).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, color: Color(0xFF10B981), size: 16),
                    SizedBox(width: 6),
                    Text(
                      benefit,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyInfo() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business, color: Colors.blue, size: 22),
              SizedBox(width: 8),
              Text(
                'Company Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildCompanyInfoRow(
            icon: Icons.apartment,
            label: 'Company',
            value: widget.job.companyName,
          ),
          if (widget.job.employerCompanyType != null) ...[
            SizedBox(height: 12),
            _buildCompanyInfoRow(
              icon: Icons.category,
              label: 'Industry',
              value: widget.job.employerCompanyType!,
            ),
          ],
          SizedBox(height: 12),
          _buildCompanyInfoRow(
            icon: Icons.location_city,
            label: 'Location',
            value: widget.job.jobLocation.toString(),
          ),
          if (widget.job.employerWebsite != null) ...[
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _launchWebsite(widget.job.employerWebsite!),
                icon: Icon(Icons.language, size: 18),
                label: Text('Visit Company Website'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Color(0xFF7C3AED),
                  side: BorderSide(color: Color(0xFF7C3AED)),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompanyInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Consumer<JobViewModel>(
        builder: (context, jobVM, _) {
          final isSaved = jobVM.isJobSaved(widget.job.jobId);

          return Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Save Job Button
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSaved ? Color(0xFF7C3AED) : Colors.grey[300]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: isSaved ? Color(0xFF7C3AED) : Colors.grey[600],
                        size: 26,
                      ),
                      onPressed: () async {
                        final profileVM = context.read<ProfileViewModel>();
                        await jobVM.toggleJobSave(profileVM.uid, widget.job);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isSaved ? 'Job removed from saved' : 'Job saved successfully!',
                            ),
                            duration: Duration(seconds: 2),
                            backgroundColor: isSaved ? Colors.orange : Color(0xFF10B981),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  // Apply Now Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _applyNow,
                      icon: Icon(Icons.send, size: 20),
                      label: Text(
                        'Apply Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Action methods
  void _shareJob() {
    final shareText = '''
Check out this job opportunity!

${widget.job.jobTitle}
${widget.job.companyName}
${widget.job.jobLocation.city}, ${widget.job.jobLocation.state}
Salary: ${widget.job.getFormattedSalary()}

Apply here: ${widget.job.jobApplyLink}
    '''.trim();

    Share.share(shareText, subject: 'Job Opportunity: ${widget.job.jobTitle}');
  }

  void _applyNow() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.open_in_new, color: Color(0xFF7C3AED)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'External Application',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'You\'ll be redirected to ${widget.job.companyName}\'s website to complete your application.',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _launchJobApplication();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF7C3AED),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchJobApplication() async {
    final uri = Uri.parse(widget.job.jobApplyLink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open application link'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _launchWebsite(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open website'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}