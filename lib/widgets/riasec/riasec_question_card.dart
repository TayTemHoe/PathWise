import 'package:flutter/material.dart';
import '../../model/riasec_model.dart';
import '../../utils/app_color.dart';

class RiasecQuestionCard extends StatelessWidget {
  final RiasecQuestion question;
  final List<RiasecAnswerOption> answerOptions;
  final int questionNumber;
  final int totalQuestions;
  final int? selectedValue;
  final Function(int) onAnswerSelected;

  const RiasecQuestionCard({
    Key? key,
    required this.question,
    required this.answerOptions,
    required this.questionNumber,
    required this.totalQuestions,
    required this.selectedValue,
    required this.onAnswerSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question number and area badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue,
                      Colors.blue.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Question $questionNumber / $totalQuestions',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getAreaColor(question.area).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getAreaColor(question.area).withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  _getAreaName(question.area),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getAreaColor(question.area),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              if (selectedValue != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green[300]!, width: 2),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.green[700],
                    size: 20,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Question card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getAreaColor(question.area).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getAreaIcon(question.area),
                    color: _getAreaColor(question.area),
                    size: 28,
                  ),
                ),

                const SizedBox(height: 20),

                // Question text
                Text(
                  question.text,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'How would you feel about doing this activity?',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Answer options
          ...answerOptions.map((option) {
            return _buildAnswerOption(
              option: option,
              isSelected: selectedValue == option.value,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAnswerOption({
    required RiasecAnswerOption option,
    required bool isSelected,
  }) {
    Color getColorForValue(int value) {
      switch (value) {
        case 1: return Colors.red;
        case 2: return Colors.orange;
        case 3: return Colors.grey;
        case 4: return Colors.lightBlue;
        case 5: return Colors.green;
        default: return Colors.grey;
      }
    }

    IconData getIconForValue(int value) {
      switch (value) {
        case 1: return Icons.sentiment_very_dissatisfied;
        case 2: return Icons.sentiment_dissatisfied;
        case 3: return Icons.sentiment_neutral;
        case 4: return Icons.sentiment_satisfied;
        case 5: return Icons.sentiment_very_satisfied;
        default: return Icons.sentiment_neutral;
      }
    }

    final color = getColorForValue(option.value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => onAnswerSelected(option.value),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: color.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
                : [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Radio indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? color : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? color : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                )
                    : null,
              ),

              const SizedBox(width: 16),

              // Emoji icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.2)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  getIconForValue(option.value),
                  color: isSelected ? color : Colors.grey[600],
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Option text
              Expanded(
                child: Text(
                  option.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? color : AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAreaColor(String area) {
    switch (area.toLowerCase()) {
      case 'realistic': return const Color(0xFF2196F3);
      case 'investigative': return const Color(0xFF9C27B0);
      case 'artistic': return const Color(0xFFFF9800);
      case 'social': return const Color(0xFF4CAF50);
      case 'enterprising': return const Color(0xFFF44336);
      case 'conventional': return const Color(0xFF795548);
      default: return Colors.grey;
    }
  }

  String _getAreaName(String area) {
    return area.substring(0, 1).toUpperCase();
  }

  IconData _getAreaIcon(String area) {
    switch (area.toLowerCase()) {
      case 'realistic': return Icons.build_rounded;
      case 'investigative': return Icons.science_rounded;
      case 'artistic': return Icons.palette_rounded;
      case 'social': return Icons.groups_rounded;
      case 'enterprising': return Icons.trending_up_rounded;
      case 'conventional': return Icons.description_rounded;
      default: return Icons.work_outline;
    }
  }
}