import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_wise/view/program_detail_screen.dart';
import 'package:path_wise/viewModel/university_detail_view_model.dart';
import 'package:path_wise/widgets/program_level_card.dart';
import 'package:path_wise/widgets/branch_card.dart';
import 'package:path_wise/widgets/admission_card.dart';
import 'package:provider/provider.dart';
import '../model/university.dart';
import '../services/share_service.dart';
import '../utils/app_color.dart';
import '../utils/currency_utils.dart';
import '../widgets/app_loading_screen.dart';
import '../widgets/expandable_html_content.dart';
import '../widgets/info_row.dart';
import '../widgets/fee_card.dart';
import '../widgets/random_circle_background.dart';
import '../widgets/related_programs_card.dart';
import '../widgets/share_button_widget.dart';
import '../widgets/share_card_widgets.dart';
import '../widgets/stat_card.dart';

class UniversityDetailScreen extends StatefulWidget {
  final String universityId;

  const UniversityDetailScreen({super.key, required this.universityId});

  @override
  State<UniversityDetailScreen> createState() => _UniversityDetailScreenState();
}

class _UniversityDetailScreenState extends State<UniversityDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _availableTabCount = 0;
  final List<String> _availableTabs = [];
  final GlobalKey _shareCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // Load university details first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<UniversityDetailViewModel>();
      viewModel.loadUniversityDetails(widget.universityId).then((_) {
        // After loading, determine available tabs
        _determineAvailableTabs();
      });
    });
  }

  void _determineAvailableTabs() {
    final viewModel = context.read<UniversityDetailViewModel>();
    final university = viewModel.university;

    if (university == null) return;

    _availableTabs.clear();

    // Overview tab is always available
    _availableTabs.add('Overview');

    // Programs tab - check if there are programs
    if (viewModel.programsByLevel.isNotEmpty) {
      _availableTabs.add('Programs');
    }

    // Branch tab - check if there are branches
    if (viewModel.branches.isNotEmpty) {
      _availableTabs.add('Branches');
    }

    // Admissions tab - check if there are admissions
    if (viewModel.admissions.isNotEmpty) {
      _availableTabs.add('Admissions');
    }

    setState(() {
      _availableTabCount = _availableTabs.length;
      _tabController = TabController(length: _availableTabCount, vsync: this);
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
      backgroundColor: AppColors.background,
      body: Consumer<UniversityDetailViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const AppLoadingContent(
              statusText: 'Loading university details...',
            );
          }

          if (viewModel.error != null) {
            return _buildErrorState(viewModel);
          }

          final university = viewModel.university;
          if (university == null) {
            return _buildEmptyState();
          }

          if (_availableTabCount == 0) {
            return const Center(child: CircularProgressIndicator());
          }

          return RandomCircleBackground(
            // Pass in your app's specific colors
            gradientColors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.7),
            ],
            circleColor: Colors.white.withOpacity(0.1),

            // The main content goes here
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  _buildSliverAppBar(university),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildUniversityHeader(university),
                        const SizedBox(height: 16),
                        _buildTabBar(),
                      ],
                    ),
                  ),
                ];
              },
              body: Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: _buildTabViews(university, viewModel),
                    ),
                  ),
                  // _buildActionButtons(context),
                ],
              ),
            ),
          );
          // --- END OF CHANGE ---
        },
      ),
    );
  }

  List<Widget> _buildTabViews(
    UniversityModel university,
    UniversityDetailViewModel viewModel,
  ) {
    List<Widget> tabs = [];

    for (String tabName in _availableTabs) {
      switch (tabName) {
        case 'Overview':
          tabs.add(_buildOverviewTab(university));
          break;
        case 'Programs':
          tabs.add(_buildProgramsTab(viewModel));
          break;
        case 'Branches':
          tabs.add(_buildBranchesTab(university, viewModel));
          break;
        case 'Admissions':
          tabs.add(_buildAdmissionsTab(viewModel));
          break;
      }
    }

    return tabs;
  }

  Widget _buildErrorState(UniversityDetailViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              viewModel.error ?? 'Failed to load university details',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                viewModel.loadUniversityDetails(widget.universityId);
              },
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Try Again',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'University not found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The university you\'re looking for doesn\'t exist or has been removed.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(UniversityModel university) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: Text(
        "University Details",
        style: const TextStyle(
          color: AppColors.textPrimary, // Use a dark color
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      actions: [
        AppBarShareButton(
          onPressed: () => _showShareOptions(university),
          tooltip: 'Share University',
        ),
      ],
    );
  }

  void _showShareOptions(UniversityModel university) async {
    final result = await ShareService.instance.shareUniversity(
      university: university,
    );

    // if (!result.success && mounted) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text('Failed to share: ${result.error ?? "Unknown error"}'),
    //       backgroundColor: Colors.red,
    //     ),
    //   );
    // }
  }

  Widget _buildUniversityHeader(UniversityModel university) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        children: [
          // Logo with shadow
          Hero(
            tag: 'university_logo_${university.universityId}',
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: university.universityLogo,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) =>
                      Icon(Icons.school, size: 50, color: Colors.grey[400]),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // University Name
          Text(
            university.universityName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 16),

          // Badges Row
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (university.minRanking != null)
                _buildBadge(
                  university.isTopRanked
                      ? _getTopRankColor(university.minRanking.toString())
                      : AppColors.primary,
                  university.isTopRanked ? Icons.star : Icons.emoji_events,
                  university.maxRanking == null ||
                          university.minRanking == university.maxRanking
                      ? 'QS Ranking #${university.minRanking}'
                      : 'QS Ranking #${university.minRanking} - ${university.maxRanking}',
                  isTopRanked: university.isTopRanked,
                ),
              _buildBadge(
                AppColors.secondary,
                Icons.business,
                university.institutionType,
              ),
              if (university.programCount > 0)
                _buildBadge(
                  AppColors.accent,
                  Icons.school,
                  '${university.programCount} Programs',
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Location
          if (university.branches.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      university.branches.first.city.isNotEmpty
                          ? '${university.branches.first.city}, ${university.branches.first.country}'
                          : university.branches.first.country,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (university.branches.length > 1) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${university.branches.length - 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(
    Color color,
    IconData icon,
    String text, {
    bool isTopRanked = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isTopRanked ? color : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: !isTopRanked ? Border.all(color: color.withOpacity(0.3)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isTopRanked ? Colors.white : color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isTopRanked ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12.0),
          topRight: Radius.circular(12.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        tabAlignment: TabAlignment.center,
        indicatorWeight: 3,
        isScrollable: true,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
        tabs: _availableTabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }

  Widget _buildOverviewTab(UniversityModel university) {
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // University Information Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'University Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (university.minRanking != null)
                    InfoRow(
                      icon: Icons.emoji_events,
                      label: 'QS Ranking',
                      value:
                          university.maxRanking == null ||
                              university.minRanking == university.maxRanking
                          ? '#${university.minRanking}'
                          : '#${university.minRanking} - ${university.maxRanking}',
                    ),
                  InfoRow(
                    icon: Icons.business,
                    label: 'Institution Type',
                    value: university.institutionType,
                  ),
                  if (university.programCount > 0)
                    InfoRow(
                      icon: Icons.book,
                      label: 'Total Programs',
                      value: '${university.programCount} programs',
                    ),
                  if (university.branches.length > 1)
                    InfoRow(
                      icon: Icons.location_city,
                      label: 'Campuses',
                      value: '${university.branches.length} locations',
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // About Section
            if (university.uniDescription.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'University Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ExpandableHtmlContent(
                      htmlData: university.uniDescription,
                      collapsedMaxLines: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Tuition Fees Section
            if (university.domesticTuitionFee != null ||
                university.internationalTuitionFee != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tuition Fees',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text(
                      'Starting from',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (university.domesticTuitionFee != null)
                      FeeCard(
                        title: 'Domestic Students',
                        icon: Icons.home,
                        fee: university.domesticTuitionFee,
                        color: AppColors.primary,
                      ),
                    if (university.domesticTuitionFee != null &&
                        university.internationalTuitionFee != null)
                      const SizedBox(height: 12),
                    if (university.internationalTuitionFee != null)
                      FeeCard(
                        title: 'International Students',
                        icon: Icons.public,
                        fee: university.internationalTuitionFee,
                        color: AppColors.secondary,
                      ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.accent.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppColors.accent,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Fees shown are starting prices and may vary by program. Contact the university for detailed fee information.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Statistics Section
            if (university.totalStudents != null ||
                university.internationalStudents != null ||
                university.totalFacultyStaff != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'University Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (university.totalStudents != null)
                      StatCard(
                        title: 'Total Students',
                        value: university.totalStudents!,
                        icon: Icons.people,
                        color: AppColors.primary,
                      ),
                    if (university.totalStudents != null &&
                        university.internationalStudents != null)
                      const SizedBox(height: 12),
                    if (university.internationalStudents != null)
                      StatCard(
                        title: 'International Students',
                        value: university.internationalStudents!,
                        icon: Icons.public,
                        color: AppColors.secondary,
                        subtitle: _calculatePercentage(
                          university.internationalStudents,
                          university.totalStudents,
                        ),
                      ),
                    if (university.totalFacultyStaff != null &&
                        (university.totalStudents != null ||
                            university.internationalStudents != null))
                      const SizedBox(height: 12),
                    if (university.totalFacultyStaff != null)
                      StatCard(
                        title: 'Faculty & Staff',
                        value: university.totalFacultyStaff!,
                        icon: Icons.person,
                        color: AppColors.accent,
                        subtitle: _calculateRatio(
                          university.totalStudents,
                          university.totalFacultyStaff,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgramsTab(UniversityDetailViewModel viewModel) {
    final programsByLevel = viewModel.programsByLevel;

    if (programsByLevel.isEmpty) {
      return Container(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No programs available',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: AppColors.background,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: programsByLevel.length,
        itemBuilder: (context, index) {
          final level = programsByLevel.keys.elementAt(index);
          final programs = programsByLevel[level]!;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.all(16),
                childrenPadding: EdgeInsets.zero,
                initiallyExpanded: viewModel.isLevelExpanded(level),
                onExpansionChanged: (expanded) {
                  viewModel.toggleLevel(level);
                },
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getLevelIcon(level),
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                title: Text(
                  '$level Programs',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${programs.length} ${programs.length == 1 ? 'program' : 'programs'}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                children: programs.map((program) {
                  return RelatedProgramCard(
                    program: program,
                    onTap: () {
                      // Navigate to the selected program's details
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProgramDetailScreen(programId: program.programId),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBranchesTab(
    UniversityModel university,
    UniversityDetailViewModel viewModel,
  ) {
    final branches = viewModel.branches;

    if (branches.isEmpty) {
      return Container(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_city_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  'No branches available',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: AppColors.background,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: branches.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return BranchCard(branch: branches[index], university: university);
        },
      ),
    );
  }

  Widget _buildAdmissionsTab(UniversityDetailViewModel viewModel) {
    final admissions = viewModel.admissions;

    if (admissions.isEmpty) {
      return Container(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  'No admission requirements available',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Group admissions by type
    final groupedAdmissions = <String, List<dynamic>>{};
    for (var admission in admissions) {
      final type = admission.admissionType ?? 'General';
      if (!groupedAdmissions.containsKey(type)) {
        groupedAdmissions[type] = [];
      }
      groupedAdmissions[type]!.add(admission);
    }

    return Container(
      color: AppColors.background,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: groupedAdmissions.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final type = groupedAdmissions.keys.elementAt(index);
          final typeAdmissions = groupedAdmissions[type]!;

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.school, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '$type Requirements',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${typeAdmissions.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: typeAdmissions.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Colors.grey[200]),
                  itemBuilder: (context, admIndex) {
                    return AdmissionCard(admission: typeAdmissions[admIndex]);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget _buildActionButtons(BuildContext context) {
  //   return Container(
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.05),
  //           blurRadius: 10,
  //           offset: const Offset(0, -2),
  //         ),
  //       ],
  //     ),
  //     padding: const EdgeInsets.all(20),
  //     child: Row(
  //       children: [
  //         Expanded(
  //           child: ElevatedButton.icon(
  //             onPressed: () {
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 const SnackBar(
  //                   content: Text('Accommodation feature coming soon'),
  //                   behavior: SnackBarBehavior.floating,
  //                 ),
  //               );
  //             },
  //             icon: const Icon(Icons.home, color: Colors.white, size: 20),
  //             label: const Text(
  //               'Accommodation',
  //               style: TextStyle(
  //                 fontWeight: FontWeight.bold,
  //                 color: Colors.white,
  //                 fontSize: 14,
  //               ),
  //             ),
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: AppColors.primary,
  //               padding: const EdgeInsets.symmetric(vertical: 16),
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               elevation: 0,
  //             ),
  //           ),
  //         ),
  //         const SizedBox(width: 12),
  //         Expanded(
  //           child: OutlinedButton.icon(
  //             onPressed: () {
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 const SnackBar(
  //                   content: Text('Virtual tour feature coming soon'),
  //                   behavior: SnackBarBehavior.floating,
  //                 ),
  //               );
  //             },
  //             icon: const Icon(
  //               Icons.threed_rotation,
  //               color: AppColors.secondary,
  //               size: 20,
  //             ),
  //             label: const Text(
  //               'Virtual Tour',
  //               style: TextStyle(
  //                 fontWeight: FontWeight.bold,
  //                 color: AppColors.secondary,
  //                 fontSize: 14,
  //               ),
  //             ),
  //             style: OutlinedButton.styleFrom(
  //               padding: const EdgeInsets.symmetric(vertical: 16),
  //               side: const BorderSide(color: AppColors.secondary, width: 2),
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Color _getTopRankColor(String ranking) {
    final rank = int.tryParse(ranking) ?? 999;
    if (rank == 1) return AppColors.topRankedGold;
    if (rank == 2) return AppColors.topRankedSilver;
    if (rank == 3) return AppColors.topRankedBronze;
    return AppColors.primary;
  }

  String? _calculatePercentage(int? part, int? total) {
    if (part == null || total == null || total == 0) return null;
    final percentage = (part / total * 100).toStringAsFixed(1);
    return '$percentage% of total students';
  }

  String? _calculateRatio(int? students, int? staff) {
    if (students == null || staff == null || staff == 0) return null;
    final ratio = (students / staff).toStringAsFixed(1);
    return 'Student-to-Faculty Ratio: $ratio:1';
  }

  IconData _getLevelIcon(String level) {
    switch (level.toLowerCase()) {
      case 'diploma':
        return Icons.school;
      case 'degree':
        return Icons.school_outlined;
      case 'masters':
        return Icons.workspace_premium;
      case 'phd':
        return Icons.menu_book;
      default:
        return Icons.book;
    }
  }
}
