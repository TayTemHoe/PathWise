import 'package:flutter/material.dart';
import '../../utils/app_color.dart';

class QuestionNavigationWidget extends StatelessWidget {
  final int currentIndex;
  final int totalQuestions;
  final bool hasAnsweredCurrent;
  final bool canSubmit;
  final bool isSubmitting;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  const QuestionNavigationWidget({
    Key? key,
    required this.currentIndex,
    required this.totalQuestions,
    required this.hasAnsweredCurrent,
    required this.canSubmit,
    required this.isSubmitting,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLastQuestion = currentIndex >= totalQuestions - 1;
    final isFirstQuestion = currentIndex == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
        child: Row(
          children: [
            if (!isFirstQuestion)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPrevious,
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  label: const Text('Previous'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            if (!isFirstQuestion) const SizedBox(width: 12),

            Expanded(
              flex: isFirstQuestion ? 1 : 1,
              // FIXED: Show Submit button if it's the last question, regardless of canSubmit state
              // Disable it if canSubmit is false
              child: isLastQuestion
                  ? ElevatedButton.icon(
                onPressed: (canSubmit && !isSubmitting) ? onSubmit : null,
                icon: isSubmitting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(Icons.check_circle_rounded, size: 20),
                label: Text(isSubmitting ? 'Submitting...' : 'Submit Test'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
                  : ElevatedButton.icon(
                onPressed: hasAnsweredCurrent ? onNext : null,
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                label: const Text('Next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
  }
}