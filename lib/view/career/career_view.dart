// lib/view/career__view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/ViewModel/career_view_model.dart';
import 'package:path_wise/ViewModel/profile_view_model.dart';
import 'package:path_wise/model/career_suggestion.dart';
import 'package:path_wise/view/career/job_view.dart';

class CareerDiscoveryView extends StatefulWidget {
  const CareerDiscoveryView({Key? key}) : super(key: key);

  @override
  State<CareerDiscoveryView> createState() => _CareerDiscoveryViewState();
}

class _CareerDiscoveryViewState extends State<CareerDiscoveryView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize career view model
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final careerVM = context.read<CareerViewModel>();
      final profileVM = context.read<ProfileViewModel>();
      careerVM.initialize(profileVM.uid);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAIPredictionTab(),
                _buildJobMatchingTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF7C3AED), Color(0xFF9F7AEA)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 40, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Career Discovery',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Color(0xFF7C3AED),
        unselectedLabelColor: Colors.grey,
        indicatorColor: Color(0xFF7C3AED),
        indicatorWeight: 3,
        labelStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          Tab(text: 'AI Prediction'),
          Tab(text: 'Job Matching'),
        ],
      ),
    );
  }

  Widget _buildAIPredictionTab() {
    return Consumer2<ProfileViewModel, CareerViewModel>(
      builder: (context, pvm, cvm, _) {
        final completionPercent = pvm.profile?.completionPercent ?? 0.0;
        final hasLatestSuggestion = cvm.hasLatestSuggestion;

        return SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              _buildProfileCompletionCard(completionPercent, pvm),
              SizedBox(height: 20),

              if (!hasLatestSuggestion && !cvm.isGenerating)
                _buildGetSuggestionsButton(context, pvm, cvm, completionPercent)
              else if (cvm.isGenerating)
                _buildLoadingWidget()
              else if (hasLatestSuggestion)
                  _buildCareerMatchesSection(cvm),

              if (cvm.hasError)
                Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: _buildErrorMessage(cvm.errorMessage!),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileCompletionCard(double completionPercent, ProfileViewModel pvm) {
    final percentage = (completionPercent).toInt();
    final isComplete = completionPercent >= 0.6;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFEC4899).withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile Completion',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completionPercent,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          SizedBox(height: 12),
          Text(
            isComplete
                ? 'Great! Your profile is ready for AI analysis'
                : 'Complete personality assessment to improve accuracy',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.95),
            ),
          ),
          if (!isComplete) ...[
            SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                // Navigate to profile completion
                // You can implement navigation logic here
              },
              icon: Icon(Icons.edit, color: Colors.white, size: 18),
              label: Text(
                'Complete Profile',
                style: TextStyle(color: Colors.white),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGetSuggestionsButton(
      BuildContext context,
      ProfileViewModel pvm,
      CareerViewModel cvm,
      double completionPercent,
      ) {
    final isEnabled = completionPercent >= 0.6;

    return Center(
      child: Column(
        children: [
          SizedBox(height: 40),
          Icon(
            Icons.auto_awesome,
            size: 80,
            color: Color(0xFF7C3AED).withOpacity(0.3),
          ),
          SizedBox(height: 20),
          Text(
            'Discover Your Career Path',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Get AI-powered career suggestions\nbased on your personality and skills',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: isEnabled
                ? () async {
              final success = await cvm.generateCareerSuggestions(
                userId: pvm.uid,
                profileViewModel: pvm,
              );

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Career suggestions generated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
                : null,
            icon: Icon(Icons.psychology, size: 24),
            label: Text(
              'Get My Career Suggestions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              disabledBackgroundColor: Colors.grey[300],
            ),
          ),
          if (!isEnabled) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Complete at least 60% of your profile to get suggestions',
                      style: TextStyle(
                        color: Colors.orange[900],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 60),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
            strokeWidth: 3,
          ),
          SizedBox(height: 20),
          Text(
            'Analyzing your profile...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This may take a few moments',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareerMatchesSection(CareerViewModel cvm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Career Matches',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            IconButton(
              onPressed: () {
                // Refresh suggestions
                final pvm = context.read<ProfileViewModel>();
                cvm.generateCareerSuggestions(
                  userId: pvm.uid,
                  profileViewModel: pvm,
                );
              },
              icon: Icon(Icons.refresh),
              color: Color(0xFF7C3AED),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          'Based on your personality and skills analysis',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: cvm.latestSuggestion!.matches.length,
          itemBuilder: (context, index) {
            final match = cvm.latestSuggestion!.matches[index];
            return _buildCareerCard(match);
          },
        ),
      ],
    );
  }

  Widget _buildCareerCard(CareerMatch match) {
    final minSalary = match.avgSalaryMYR['min']?.toInt() ?? 0;
    final maxSalary = match.avgSalaryMYR['max']?.toInt() ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  match.jobTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${match.fitScore}% Match',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            match.shortDescription,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(
                'Avg. Salary',
                'RM ${(minSalary / 1000).toStringAsFixed(1)}k',
                Icons.attach_money,
              ),
              SizedBox(width: 12),
              _buildInfoChip(
                'Growth',
                match.jobGrowth,
                Icons.trending_up,
              ),
              SizedBox(width: 12),
              _buildInfoChip(
                'Jobs Available',
                '1,247', // You can calculate this from your data
                Icons.work_outline,
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Navigate to job search with this career
                    _showJobMatchingDialog(match);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFF7C3AED),
                    side: BorderSide(color: Color(0xFF7C3AED)),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('View Jobs'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Show detailed career information
                    _showCareerDetailsDialog(match);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('View Details'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: Colors.grey[600]),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobMatchingTab() {
    return JobView(); // Integrated Job View
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red[900],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCareerDetailsDialog(CareerMatch match) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(match.jobTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Job Description',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(match.jobsDescription),
              SizedBox(height: 16),
              Text(
                'Why This Matches You',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              ...match.reasons.map((reason) => Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(reason)),
                  ],
                ),
              )),
              SizedBox(height: 16),
              Text(
                'Top Skills Needed',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: match.topSkillsNeeded.map((skill) => Chip(
                  label: Text(skill, style: TextStyle(fontSize: 12)),
                  backgroundColor: Color(0xFF7C3AED).withOpacity(0.1),
                  labelStyle: TextStyle(color: Color(0xFF7C3AED)),
                )).toList(),
              ),
              SizedBox(height: 16),
              Text(
                'Suggested Next Steps',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              ...match.suggestedNextSteps.asMap().entries.map((entry) => Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${entry.key + 1}. ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(entry.value)),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showJobMatchingDialog(CareerMatch match) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Job Matching'),
        content: Text(
          'Job matching feature will show available positions for ${match.jobTitle}.\n\nThis feature is coming soon!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}