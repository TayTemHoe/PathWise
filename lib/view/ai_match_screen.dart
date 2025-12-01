// lib/view/ai_match_screen.dart - UPDATED WITH PREVIOUS BUTTON & EXIT ICON
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_color.dart';
import '../viewModel/ai_match_view_model.dart';
import '../widgets/ai_match_pages/education_snapshot_page.dart';
import '../widgets/ai_match_pages/english_tests_page.dart';
import '../widgets/ai_match_pages/interests_page.dart';
import '../widgets/ai_match_pages/personality_page.dart';
import '../widgets/ai_match_pages/preferences_page.dart';
import '../widgets/ai_match_pages/results_page.dart';
import '../widgets/ai_match_pages/review_page.dart';
import '../widgets/app_loading_screen.dart';

class AIMatchScreen extends StatefulWidget {
  const AIMatchScreen({Key? key}) : super(key: key);

  @override
  State<AIMatchScreen> createState() => _AIMatchScreenState();
}

class _AIMatchScreenState extends State<AIMatchScreen>
    with TickerProviderStateMixin {
  late final AIMatchViewModel _viewModel;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _viewModel = AIMatchViewModel();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _viewModel.initialize();
      if (mounted) {
        setState(() => _isLoading = false);
        _fadeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AIMatchViewModel>.value(
      value: _viewModel,
      child: Consumer<AIMatchViewModel>(
        builder: (context, viewModel, _) {
          final steps = _getSteps();
          final currentStep = viewModel.currentPage;
          final totalSteps = steps.length;

          return WillPopScope(
            onWillPop: () async {
              if (viewModel.currentPage > 0 && viewModel.currentPage < 6) {
                _showExitConfirmation(viewModel);
                return false;
              }
              return true;
            },
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              backgroundColor: AppColors.background,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  automaticallyImplyLeading: false,
                  titleSpacing: 0,
                  title: Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Back/Close button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (viewModel.currentPage > 0) {
                                viewModel.previousPage();
                                _fadeController.reset();
                                _fadeController.forward();
                              } else {
                                _showExitConfirmation(viewModel);
                              }
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                viewModel.currentPage > 0
                                    ? Icons.arrow_back_rounded
                                    : Icons.close_rounded,
                                color: AppColors.textPrimary,
                                size: 22,
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Progress indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.1),
                                AppColors.primary.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.list_alt_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Step ${currentStep + 1} of $totalSteps',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // Exit button (replaces bookmark)
                        if (viewModel.currentPage < 6)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showExitConfirmation(viewModel),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.logout_rounded,
                                  color: Colors.red[700],
                                  size: 22,
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 42),
                      ],
                    ),
                  ),
                ),
              ),
              body: SafeArea(
                bottom: true,
                child: _isLoading
                    ? _buildLoadingState()
                    : _buildMainContent(
                    viewModel, steps, currentStep, totalSteps),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: const AppLoadingContent(
        statusText: 'Loading progress data...',
      ),
    );
  }

  Widget _buildMainContent(
      AIMatchViewModel viewModel,
      List<StepInfo> steps,
      int currentStep,
      int totalSteps,
      ) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Modern Header with Progress
                _buildModernHeader(viewModel, steps, currentStep, totalSteps),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildCurrentPage(viewModel),
                ),
              ],
            ),
          ),
        ),

        // Bottom Navigation (Stays fixed at the bottom)
        if (viewModel.currentPage < 6) _buildBottomNavigation(viewModel),
      ],
    );
  }

  Widget _buildModernHeader(
      AIMatchViewModel viewModel,
      List<StepInfo> steps,
      int currentStep,
      int totalSteps,
      ) {
    final progress = (currentStep + 1) / totalSteps;

    return Container(
      padding: const EdgeInsets.only(top: 5),
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        children: [
          // Step cards row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: List.generate(totalSteps, (index) {
                final isCompleted = index < currentStep;
                final isCurrent = index == currentStep;
                final step = steps[index];

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index < totalSteps - 1 ? 6 : 0,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: isCurrent
                            ? LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                            : null,
                        color: isCurrent
                            ? null
                            : isCompleted
                            ? AppColors.primary.withOpacity(0.12)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCurrent
                              ? AppColors.primary
                              : isCompleted
                              ? AppColors.primary.withOpacity(0.25)
                              : Colors.grey[300]!,
                          width: isCurrent ? 2 : 1,
                        ),
                        boxShadow: isCurrent
                            ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                            : null,
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              step.icon,
                              color: isCurrent
                                  ? Colors.white
                                  : isCompleted
                                  ? AppColors.primary
                                  : Colors.grey[400],
                              size: isCurrent ? 24 : 20,
                            ),
                          ),
                          if (isCompleted && !isCurrent)
                            Positioned(
                              top: 3,
                              right: 3,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Progress bar with percentage
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                              height: 6,
                              width: constraints.maxWidth * progress,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(AIMatchViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Previous Button (only show if not on first page)
              if (viewModel.currentPage > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      viewModel.previousPage();
                      _fadeController.reset();
                      _fadeController.forward();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.arrow_back_rounded,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Previous',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Spacing between buttons
              if (viewModel.currentPage > 0) const SizedBox(width: 12),

              // Continue/Generate Button
              Expanded(
                child: ElevatedButton(
                  onPressed: viewModel.canProceed
                      ? () {
                    _handleContinue(viewModel);
                    _fadeController.reset();
                    _fadeController.forward();
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[500],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        viewModel.currentPage == 5
                            ? 'Generate Matches'
                            : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        viewModel.currentPage == 5
                            ? Icons.rocket_launch_rounded
                            : Icons.arrow_forward_rounded,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPage(AIMatchViewModel viewModel) {
    switch (viewModel.currentPage) {
      case 0:
        return const EducationSnapshotPage();
      case 1:
        return const EnglishTestsPage();
      case 2:
        return const InterestsPage();
      case 3:
        return const PersonalityPage();
      case 4:
        return const PreferencesPage();
      case 5:
        return const ReviewPage();
      case 6:
        return const ResultsPage();
      default:
        return const SizedBox();
    }
  }

  void _handleContinue(AIMatchViewModel viewModel) {
    if (viewModel.currentPage == 5) {
      viewModel.generateMatches();
    } else {
      viewModel.nextPage();
    }
  }

  List<StepInfo> _getSteps() {
    return [
      StepInfo(
        icon: Icons.school_rounded,
        title: 'Education Profile',
        subtitle: 'Your education level and academic records',
      ),
      StepInfo(
        icon: Icons.translate_rounded,
        title: 'English & Tests',
        subtitle: 'Language proficiency and test scores',
      ),
      StepInfo(
        icon: Icons.lightbulb_rounded,
        title: 'Interests & Goals',
        subtitle: 'What motivates and inspires you',
      ),
      StepInfo(
        icon: Icons.psychology_rounded,
        title: 'Personality Profile',
        subtitle: 'Help us understand you better',
      ),
      StepInfo(
        icon: Icons.tune_rounded,
        title: 'Study Preferences',
        subtitle: 'Your ideal learning environment',
      ),
      StepInfo(
        icon: Icons.fact_check_rounded,
        title: 'Review & Submit',
        subtitle: 'Confirm all your information',
      ),
      StepInfo(
        icon: Icons.emoji_events_rounded,
        title: 'Your Matches',
        subtitle: 'Personalized recommendations for you',
      ),
    ];
  }

  void _showExitConfirmation(AIMatchViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.logout_rounded, color: Colors.red[700]),
            ),
            const SizedBox(width: 12),
            const Text('Exit Form?'),
          ],
        ),
        content: const Text(
          'Your progress is automatically saved. You can continue from where you left off anytime.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}

class StepInfo {
  final IconData icon;
  final String title;
  final String subtitle;

  StepInfo({required this.icon, required this.title, required this.subtitle});
}