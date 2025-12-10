import 'package:flutter/material.dart';
import 'package:path_wise/view/career/career_view.dart';
import 'package:path_wise/view/career/job_view.dart';
import 'package:path_wise/view/interview/interview_home_view.dart';
import 'package:path_wise/view/profile/profile_overview_view.dart';
import 'package:path_wise/view/resume/resume_home_view.dart';
import 'package:path_wise/view/roadmap/careerroadmap_list_view.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Ensure intl is in pubspec.yaml, widely used in Flutter
import '../utils/app_color.dart';
import '../viewModel/dashboard_view_model.dart';
import '../viewModel/auth_view_model.dart';
import '../viewModel/profile_view_model.dart';
import '../widgets/random_circle_background.dart';
import 'ai_match_screen.dart';
import 'program_list_screen.dart';
import 'university_list_screen.dart';
import 'mbti_test_screen.dart';
import 'riasec_test_screen.dart';
import 'big_five_test_screen.dart';
import 'comparison_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authVM = context.read<AuthViewModel>();
      final dashboardVM = context.read<DashboardViewModel>();

      if (authVM.currentUser != null) {
        // First refresh user data from Firestore to ensure we have latest role
        await authVM.refreshCurrentUser();
        // Then initialize dashboard with the refreshed user data
        if (authVM.currentUser != null) {
          dashboardVM.init(authVM.currentUser!);
        }
      }
    });
  }

  void _handleNavigation(BuildContext context, String route) {
    switch (route) {
      case '/university_list':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const UniversityListScreen()));
        break;
      case '/program_list':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ProgramListScreen()));
        break;
      case '/ai_match':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AIMatchScreen()));
        break;
      case '/compare':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const ComparisonScreen(initialItems: [])));
        break;
      case '/mbti':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MBTITestScreen()));
        break;
      case '/riasec':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const RiasecTestScreen()));
        break;
      case '/big_five':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const BigFiveTestScreen()));
        break;
      case '/job_list':
        Navigator.push(context,MaterialPageRoute(builder: (_) => const JobView()));
        break;
      case '/ai_job_match':
        Navigator.push(context,MaterialPageRoute(builder: (_) => const CareerDiscoveryView()));
        break;
      case '/resume':
        Navigator.push(context,MaterialPageRoute(builder: (_) => const ResumeListPage()));
        break;
      case '/interview':
        Navigator.push(context,MaterialPageRoute(builder: (_) => const InterviewHomePage()));
        break;
      case '/roadmap':
        Navigator.push(context,MaterialPageRoute(builder: (_) => const RoadmapListView()));
        break;
      case '/profile':
        Navigator.push(context,MaterialPageRoute(builder: (_) => const ProfileOverviewScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Consumer<DashboardViewModel>(
        builder: (context, viewModel, _) {
          return RefreshIndicator(
            edgeOffset: kToolbarHeight + MediaQuery.of(context).padding.top,
            onRefresh: () async {
              final authVM = context.read<AuthViewModel>();
              if (authVM.currentUser != null) {
                // Force re-fetch user data from repository to get latest role
                await authVM.refreshCurrentUser();
                viewModel.init(authVM.currentUser!);
              }
            },
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                _buildModernAppBar(context),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: Column(
                      children: [
                        _buildEnhancedWelcomeCard(viewModel),
                        const SizedBox(height: 32),
                        _buildSectionHeader(
                            'Explore ${viewModel.currentMode == DashboardMode.education ? "Education" : "Career"}',
                            Icons.explore_rounded),
                        const SizedBox(height: 16),
                        _buildFeaturesList(
                          viewModel.currentMode == DashboardMode.education
                              ? viewModel.educationFeatures
                              : viewModel.careerFeatures,
                        ),
                        const SizedBox(height: 32),
                        _buildSectionHeader(
                            'Personal Growth', Icons.psychology_rounded),
                        const SizedBox(height: 16),
                        _buildFeaturesList(viewModel.sharedFeatures),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: const Color(0xFFF8F9FD),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: true, // Centers the title widget in the app bar
      title: Row(
        mainAxisSize: MainAxisSize.min, // Ensures the Row wraps its content for proper centering
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.school_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'PathWise',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.logout_rounded,
                color: AppColors.error, size: 20),
            tooltip: 'Logout',
            onPressed: () async {
              final authViewModel =
              Provider.of<AuthViewModel>(context, listen: false);
              await authViewModel.logout();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedWelcomeCard(DashboardViewModel viewModel) {
    final profileVM = context.watch<ProfileViewModel>();
    final photoUrl = profileVM.profile?.profilePictureUrl;

    final user = viewModel.currentUser;
    final isEdu = viewModel.currentMode == DashboardMode.education;
    final dateStr = DateFormat('EEE, d MMM').format(DateTime.now());

    return Container(
      width: double.infinity,
      // 1. Outer Container for Constraints and Shadow
      constraints: const BoxConstraints(minHeight: 200),
      decoration: BoxDecoration(
        // Solid background color fallback for shadow
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      // 2. ClipRRect to clip everything inside to the rounded corners
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // 3. Layer 1: Background Gradient (Fills the whole card)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, Color(0xFF8E87FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            // 4. Layer 2: Decorative Circles (Positioned relative to card edges)
            Positioned(
              top: -40,
              right: -30,
              child: CircleAvatar(
                radius: 70,
                backgroundColor: Colors.white.withOpacity(0.1),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -20,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white.withOpacity(0.1),
              ),
            ),

            // 5. Layer 3: Content (With Padding applied here instead of outer container)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Row: Date and Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          dateStr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      // Toggle Switch
                      _buildCompactToggle(viewModel, isEdu),
                    ],
                  ),
                  const SizedBox(height: 20), // Spacing

                  // Bottom Row: User Info, Message, and Profile Picture
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Text Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, ${user?.lastName} ${user?.firstName ?? "Guest"} !',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: 22, // Increased font size
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isEdu
                                  ? 'Find your dream university'
                                  : 'Build your career path',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28, // Significantly larger slogan
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Profile Picture Placeholder
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          // ✅ NEW: Load network image if available
                          backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                              ? NetworkImage(photoUrl)
                              : null,
                          // ✅ NEW: Show text only if no image
                          child: (photoUrl == null || photoUrl.isEmpty)
                              ? Text(
                            (user?.firstName?.isNotEmpty == true)
                                ? user!.firstName[0].toUpperCase()
                                : "U",
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary),
                          )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactToggle(DashboardViewModel viewModel, bool isEdu) {
    return Container(
      height: 40, // Standard height for better tap area
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleItem(
            'Education',
            isEdu,
                () => !isEdu ? viewModel.toggleMode() : null,
          ),
          _buildToggleItem(
            'Career',
            !isEdu,
                () => isEdu ? viewModel.toggleMode() : null,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.8),
            fontSize: 13, // Readable font size
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 22, color: AppColors.primary),
        const SizedBox(width: 10),
        Flexible( // Prevents overflow on small screens
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesList(List<DashboardItem> items) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _HorizontalDashboardCard(
          item: items[index],
          onTap: () => _handleNavigation(context, items[index].route),
        );
      },
    );
  }
}

class _HorizontalDashboardCard extends StatelessWidget {
  final DashboardItem item;
  final VoidCallback onTap;

  const _HorizontalDashboardCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon Container with soft background matching item color
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.color,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 17, // Slightly increased
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600], // Darker grey for better contrast
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Arrow Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}