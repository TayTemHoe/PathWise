// lib/screens/program_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../model/program.dart';
import '../services/share_service.dart';
import '../utils/app_color.dart';
import '../viewModel/program_detail_view_model.dart';
import '../widgets/app_loading_screen.dart';
import '../widgets/expandable_html_content.dart';
import '../widgets/info_row.dart';
import '../widgets/fee_card.dart';
import '../widgets/random_circle_background.dart';
import '../widgets/program_admission_card.dart';
import '../widgets/related_programs_card.dart';
import '../widgets/share_button_widget.dart';
import '../widgets/share_card_widgets.dart';

class ProgramDetailScreen extends StatefulWidget {
  final String programId;

  const ProgramDetailScreen({
    super.key,
    required this.programId,
  });

  @override
  State<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends State<ProgramDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _availableTabCount = 0;
  final List<String> _availableTabs = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<ProgramDetailViewModel>();
      viewModel.loadProgramDetails(widget.programId).then((_) {
        _determineAvailableTabs();
      });
    });
  }

  void _determineAvailableTabs() {
    final viewModel = context.read<ProgramDetailViewModel>();
    final program = viewModel.program;

    if (program == null) return;

    _availableTabs.clear();

    // Overview tab is always available
    _availableTabs.add('Overview');

    // Admissions tab - check if there are admissions or entry requirements
    if (viewModel.admissions.isNotEmpty ||
        (program.entryRequirement != null && program.entryRequirement!.isNotEmpty)) {
      _availableTabs.add('Admissions');
    }

    // Programs tab - check if there are related programs
    if (viewModel.relatedProgramsByLevel.isNotEmpty) {
      _availableTabs.add('Programs');
    }

    setState(() {
      _availableTabCount = _availableTabs.length;
      _tabController = TabController(length: _availableTabCount, vsync: this);
    });
  }

  @override
  void dispose() {
    if (_availableTabCount > 0) {
      _tabController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<ProgramDetailViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const AppLoadingContent(
              statusText: 'Loading program details...',
            );
          }

          if (viewModel.error != null) {
            return _buildErrorState(viewModel);
          }

          final program = viewModel.program;
          if (program == null) {
            return _buildEmptyState();
          }

          if (_availableTabCount == 0) {
            return const Center(child: CircularProgressIndicator());
          }

          return RandomCircleBackground(
            gradientColors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.7),
            ],
            circleColor: Colors.white.withOpacity(0.1),
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  _buildSliverAppBar(),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildProgramHeader(program, viewModel),
                        const SizedBox(height: 16),
                        _buildTabBar(),
                      ],
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: _buildTabViews(program, viewModel),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildTabViews(ProgramModel program, ProgramDetailViewModel viewModel) {
    List<Widget> tabs = [];

    for (String tabName in _availableTabs) {
      switch (tabName) {
        case 'Overview':
          tabs.add(_buildOverviewTab(program, viewModel));
          break;
        case 'Admissions':
          tabs.add(_buildAdmissionsTab(program, viewModel));
          break;
        case 'Programs':
          tabs.add(_buildProgramsTab(viewModel));
          break;
      }
    }

    return tabs;
  }

  Widget _buildErrorState(ProgramDetailViewModel viewModel) {
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
              viewModel.error ?? 'Failed to load program details',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                viewModel.loadProgramDetails(widget.programId);
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
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
            Icon(
              Icons.school_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Program not found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The program you\'re looking for doesn\'t exist or has been removed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: const Text(
        "Program Details",
        style: TextStyle(
          color: AppColors.textPrimary,
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
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Consumer<ProgramDetailViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.program == null) return const SizedBox.shrink();

            return AppBarShareButton(
              onPressed: () => _showShareOptions(viewModel),
              tooltip: 'Share Program',
            );
          },
        ),
      ],
    );
  }

  void _showShareOptions(ProgramDetailViewModel viewModel) async {
    final program = viewModel.program!;
    final university = viewModel.university;
    final branch = viewModel.branch;

    String? branchLocation;
    if (branch != null) {
      branchLocation = branch.city.isNotEmpty
          ? '${branch.city}, ${branch.country}'
          : branch.country;
    }

    final result = await ShareService.instance.shareProgram(
      program: program,
      universityName: university?.universityName,
      branchLocation: branchLocation,
    );
  }

  Widget _buildProgramHeader(ProgramModel program, ProgramDetailViewModel viewModel) {
    final university = viewModel.university;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        children: [
          // University Logo
          if (university != null) ...[
            Hero(
              tag: 'program_logo_${program.programId}',
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
                    errorWidget: (context, url, error) => Icon(
                      Icons.school,
                      size: 50,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Program Name
          Text(
            program.programName,
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
              if (program.subjectArea != null)
                _buildBadge(
                  AppColors.secondary,
                  Icons.category,
                  program.subjectArea!,
                ),
              if (program.studyLevel != null)
                _buildBadge(
                  AppColors.accent,
                  Icons.school,
                  program.studyLevel!,
                ),
              if (program.hasSubjectRanking)
                _buildBadge(
                  program.isTopRanked
                      ? _getTopRankColor(program.minSubjectRanking!)
                      : AppColors.primary,
                  program.isTopRanked ? Icons.star : Icons.emoji_events,
                  program.formattedSubjectRanking,
                  isTopRanked: program.isTopRanked,
                ),
            ],
          ),

          // Top 3 Rankings Highlight
          if (program.hasSubjectRanking && program.isTop100) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.15),
                    AppColors.primary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.workspace_premium,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      program.isTopRanked
                          ? 'Top 3 in ${program.subjectArea}'
                          : 'Top 100 in ${program.subjectArea}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
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
          Icon(
            icon,
            size: 16,
            color: isTopRanked ? Colors.white : color,
          ),
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
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
        tabs: _availableTabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }

  Widget _buildOverviewTab(ProgramModel program, ProgramDetailViewModel viewModel) {
    final university = viewModel.university;
    final branch = viewModel.branch;

    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Program Information Section
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
                    'Program Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (program.durationMonths != null)
                    InfoRow(
                      icon: Icons.schedule,
                      label: 'Duration',
                      value: program.formattedDuration,
                    ),
                  if (program.subjectArea != null)
                    InfoRow(
                      icon: Icons.category,
                      label: 'Subject Area',
                      value: program.subjectArea!,
                    ),
                  if (program.studyLevel != null)
                    InfoRow(
                      icon: Icons.school,
                      label: 'Study Level',
                      value: program.studyLevel!,
                    ),
                  if (program.studyMode != null)
                    InfoRow(
                      icon: Icons.location_on,
                      label: 'Study Mode',
                      value: program.studyMode!,
                    ),
                  if (program.intakePeriod.isNotEmpty)
                    InfoRow(
                      icon: Icons.calendar_today,
                      label: 'Intake Periods',
                      value: program.intakePeriod.join(', '),
                    ),
                  if (university != null && branch != null)
                    InfoRow(
                      icon: Icons.business,
                      label: 'Institution',
                      value: _formatInstitutionInfo(university.universityName, branch),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Program Description
            if (program.progDescription.isNotEmpty) ...[
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
                      'Program Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ExpandableHtmlContent(
                      htmlData: program.progDescription,
                      collapsedMaxLines: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Tuition Fees Section
            if (program.minDomesticTuitionFee != null ||
                program.minInternationalTuitionFee != null) ...[
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
                    if (program.minDomesticTuitionFee != null)
                      FeeCard(
                        title: 'Domestic Students',
                        icon: Icons.home,
                        fee: program.minDomesticTuitionFee,
                        color: AppColors.primary,
                      ),
                    if (program.minDomesticTuitionFee != null &&
                        program.minInternationalTuitionFee != null)
                      const SizedBox(height: 12),
                    if (program.minInternationalTuitionFee != null)
                      FeeCard(
                        title: 'International Students',
                        icon: Icons.public,
                        fee: program.minInternationalTuitionFee,
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
                              'Fees shown are minimum starting prices and may vary. Contact the university for detailed fee information.',
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdmissionsTab(ProgramModel program, ProgramDetailViewModel viewModel) {
    final admissions = viewModel.admissions;
    final hasAdmissions = admissions.isNotEmpty;
    final hasEntryRequirement = program.entryRequirement != null &&
        program.entryRequirement!.isNotEmpty;
    print("Admissions: $hasAdmissions");
    if (!hasAdmissions && !hasEntryRequirement) {
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
                  'No admission information available',
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 20.0,
          right: 20.0,
          bottom: 20.0,
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Entry Requirements
            if (hasEntryRequirement) ...[
              if (hasAdmissions) const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Entry Requirements',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ExpandableHtmlContent(
                      htmlData: program.entryRequirement!,
                      collapsedMaxLines: 6,
                    ),
                  ],
                ),
              ),
            ],

            // Admission Requirements
            if (hasAdmissions) ...[
              Container(
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
                          Icon(
                            Icons.assignment_turned_in,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Admission Requirements',
                            style: TextStyle(
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
                              '${admissions.length}',
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
                      itemCount: admissions.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: Colors.grey[200],
                      ),
                      itemBuilder: (context, index) {
                        return ProgramAdmissionCard(admission: admissions[index]);
                      },
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

  Widget _buildProgramsTab(ProgramDetailViewModel viewModel) {
    final relatedPrograms = viewModel.relatedProgramsByLevel;

    if (relatedPrograms.isEmpty) {
      return Container(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  'No related programs available',
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
        padding: const EdgeInsets.all(16),
        itemCount: relatedPrograms.length,
        itemBuilder: (context, index) {
          final level = relatedPrograms.keys.elementAt(index);
          final programs = relatedPrograms[level]!;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
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
                          builder: (context) => ProgramDetailScreen(
                            programId: program.programId,
                          ),
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

  String _formatInstitutionInfo(String universityName, dynamic branch) {
    // Remove duplicate university name from branch name
    String branchName = branch.branchName;

    // Check if branch name contains university name
    if (branchName.toLowerCase().contains(universityName.toLowerCase())) {
      // Remove university name from branch name
      branchName = branchName
          .replaceAll(universityName, '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      // Remove leading/trailing separators
      branchName = branchName.replaceAll(RegExp(r'^[,\-\s]+|[,\-\s]+$'), '').trim();
    }

    // Build the location string
    List<String> parts = [universityName];

    if (branchName.isNotEmpty && branchName != universityName) {
      parts.add(branchName);
    }

    if (branch.city != null && branch.city.isNotEmpty) {
      parts.add(branch.city);
    }

    if (branch.country != null && branch.country.isNotEmpty) {
      parts.add(branch.country);
    }

    return parts.join(', ');
  }

  Color _getTopRankColor(int ranking) {
    if (ranking == 1) return AppColors.topRankedGold;
    if (ranking == 2) return AppColors.topRankedSilver;
    if (ranking == 3) return AppColors.topRankedBronze;
    return AppColors.primary;
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