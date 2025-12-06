import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_color.dart';
import '../viewModel/mbti_test_view_model.dart';
import '../widgets/mbti_loading.dart';
import '../widgets/mbti_test/gender_selection_widget.dart';
import '../widgets/mbti_test/progress_indicator_widget.dart';
import '../widgets/mbti_test/question_card_widget.dart';
import '../widgets/mbti_test/question_navigation_widget.dart';
import 'mbti_result_screen.dart';

class MBTITestScreen extends StatefulWidget {
  const MBTITestScreen({Key? key}) : super(key: key);

  @override
  State<MBTITestScreen> createState() => _MBTITestScreenState();
}

class _MBTITestScreenState extends State<MBTITestScreen> {
  late final MBTITestViewModel _viewModel;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _viewModel = MBTITestViewModel();

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
          child: const MBTIResultScreen(),
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
          body: Consumer<MBTITestViewModel>(
            builder: (context, viewModel, _) {
              if (viewModel.isSubmitting) {
                return const CalculatingResultWidget();
              }

              if (viewModel.isLoading) {
                return _buildLoadingState();
              }

              if (viewModel.errorMessage != null) {
                return _buildErrorState(viewModel);
              }

              if (viewModel.selectedGender == null) {
                return GenderSelectionWidget(
                  onGenderSelected: (gender) {
                    viewModel.setGender(gender);
                  },
                );
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
        '16 Personalities Test',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        Consumer<MBTITestViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.selectedGender == null || viewModel.questions.isEmpty) {
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
            'Please wait while we prepare your test',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(MBTITestViewModel viewModel) {
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

  Widget _buildTestContent(MBTITestViewModel viewModel) {
    return Column(
      children: [
        // Progress indicator
        MBTIProgressIndicator(
          current: viewModel.answeredCount,
          total: viewModel.totalQuestions,
          progress: viewModel.progress,
        ),

        // Questions
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            // FIX: Disable scrolling so user MUST use buttons (prevents skipping)
            physics: const NeverScrollableScrollPhysics(),
            itemCount: viewModel.totalQuestions,
            // onPageChanged logic is handled by Navigation buttons now
            itemBuilder: (context, index) {
              return QuestionCardWidget(
                question: viewModel.questions[index],
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
        QuestionNavigationWidget(
          currentIndex: viewModel.currentQuestionIndex,
          totalQuestions: viewModel.totalQuestions,
          hasAnsweredCurrent: viewModel.hasAnsweredCurrent,
          canSubmit: viewModel.canSubmit,
          isSubmitting: viewModel.isSubmitting,
          onPrevious: () {
            viewModel.previousQuestion(); // Update VM state first
            _pageController.animateToPage(
              viewModel.currentQuestionIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          onNext: () {
            viewModel.nextQuestion(); // Update VM state first
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

  Future<void> _showRestartConfirmation(MBTITestViewModel viewModel) {
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