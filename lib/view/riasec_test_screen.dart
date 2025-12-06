import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_color.dart';
import '../viewModel/riasec_test_view_model.dart';
import '../widgets/riasec/riasec_progress_indicator.dart';
import '../widgets/riasec/riasec_question_card.dart';
import '../widgets/riasec/riasec_navigation_widget.dart';
import 'riasec_result_screen.dart';

class RiasecTestScreen extends StatefulWidget {
  const RiasecTestScreen({Key? key}) : super(key: key);

  @override
  State<RiasecTestScreen> createState() => _RiasecTestScreenState();
}

class _RiasecTestScreenState extends State<RiasecTestScreen> {
  late final RiasecTestViewModel _viewModel;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _viewModel = RiasecTestViewModel();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _viewModel.initialize();

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _viewModel.currentQuestionIndex > 0 && _pageController.hasClients) {
            _pageController.jumpToPage(_viewModel.currentQuestionIndex);
          }
        });

        if (_viewModel.result != null) {
          _navigateToResult();
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _navigateToResult() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: _viewModel,
          child: const RiasecResultScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: WillPopScope(
        onWillPop: () async {
          final shouldPop = await _showExitConfirmation();
          return shouldPop ?? false;
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(),
          body: Consumer<RiasecTestViewModel>(
            builder: (context, viewModel, _) {
              if (viewModel.isSubmitting) {
                return _buildCalculatingState();
              }

              if (viewModel.isLoading) {
                return _buildLoadingState();
              }

              if (viewModel.errorMessage != null) {
                return _buildErrorState(viewModel);
              }

              if (viewModel.questions.isEmpty) {
                return _buildEmptyState();
              }

              return _buildTestContent(viewModel);
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
        onPressed: () async {
          final shouldPop = await _showExitConfirmation();
          if (shouldPop == true && mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
      title: const Text(
        'RIASEC Career Interest Test',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        Consumer<RiasecTestViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.questions.isEmpty) {
              return const SizedBox(width: 48);
            }

            return IconButton(
              icon: const Icon(Icons.restart_alt_rounded, color: AppColors.primary),
              tooltip: 'Restart Test',
              onPressed: () => _showRestartConfirmation(viewModel),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading Test...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Preparing 60 career interest questions',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutBack,
            builder: (context, value, _) {
              return Transform.scale(
                scale: 0.8 + value * 0.2,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue,
                        Colors.blue.withOpacity(0.6),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.work_outline_rounded,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(strokeWidth: 5),
          ),
          const SizedBox(height: 28),
          const Text(
            "Analyzing Your Interests",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Matching you with ideal careers...",
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(RiasecTestViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Oops! Something Went Wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                viewModel.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red[900],
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                viewModel.clearError();
                viewModel.initialize();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
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
              Icons.quiz_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'No Questions Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your internet connection and try again',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestContent(RiasecTestViewModel viewModel) {
    return Column(
      children: [
        // Progress indicator
        RiasecProgressIndicator(
          current: viewModel.answeredCount,
          total: viewModel.totalQuestions,
          progress: viewModel.progress,
        ),

        // Questions
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            // FIX: Disable scrolling to enforce linear progression
            physics: const NeverScrollableScrollPhysics(),
            itemCount: viewModel.totalQuestions,
            itemBuilder: (context, index) {
              return RiasecQuestionCard(
                question: viewModel.questions[index],
                answerOptions: viewModel.answerOptions,
                questionNumber: index + 1,
                totalQuestions: viewModel.totalQuestions,
                selectedValue: viewModel.getAnswerForQuestion(index),
                onAnswerSelected: (value) {
                  viewModel.goToQuestion(index);
                  viewModel.answerQuestion(value);
                },
              );
            },
          ),
        ),

        // Navigation
        RiasecNavigationWidget(
          currentIndex: viewModel.currentQuestionIndex,
          totalQuestions: viewModel.totalQuestions,
          hasAnsweredCurrent: viewModel.hasAnsweredCurrent,
          canSubmit: viewModel.canSubmit,
          isSubmitting: viewModel.isSubmitting,
          onPrevious: () {
            viewModel.previousQuestion(); // Update VM
            _pageController.animateToPage(
              viewModel.currentQuestionIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          onNext: () {
            viewModel.nextQuestion(); // Update VM
            _pageController.animateToPage(
              viewModel.currentQuestionIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          onSubmit: () async {
            await viewModel.submitTest();
            if (viewModel.result != null && mounted) {
              _navigateToResult();
            }
          },
        ),
      ],
    );
  }

  Future<bool?> _showExitConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
            ),
            const SizedBox(width: 12),
            const Text('Exit Test?'),
          ],
        ),
        content: const Text(
          'Your progress is automatically saved. You can continue from where you left off anytime.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRestartConfirmation(RiasecTestViewModel viewModel) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.restart_alt_rounded, color: Colors.red[700]),
            ),
            const SizedBox(width: 12),
            const Text('Restart Test?'),
          ],
        ),
        content: const Text(
          'This will clear all your answers and you\'ll start from the beginning. This action cannot be undone.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await viewModel.restartTest();
              if (mounted) {
                _pageController.jumpToPage(0);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }
}