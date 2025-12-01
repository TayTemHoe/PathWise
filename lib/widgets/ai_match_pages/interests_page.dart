import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/app_color.dart';
import '../../viewModel/ai_match_view_model.dart';

class InterestsPage extends StatefulWidget {
  const InterestsPage({Key? key}) : super(key: key);

  @override
  State<InterestsPage> createState() => _InterestsPageState();
}

class _InterestsPageState extends State<InterestsPage> {
  final TextEditingController _customInterestController = TextEditingController();
  final FocusNode _customInterestFocus = FocusNode();
  String? _customInterestError;

  // Added a constant for easy maintenance
  final int _maxInterests = 6;

  static const List<Map<String, dynamic>> predefinedInterests = [
    {'name': 'Coding', 'icon': Icons.code},
    {'name': 'Lab Work', 'icon': Icons.science},
    {'name': 'Public Speaking', 'icon': Icons.record_voice_over},
    {'name': 'Leadership', 'icon': Icons.groups},
    {'name': 'Designing', 'icon': Icons.design_services},
    {'name': 'Teaching', 'icon': Icons.school},
    {'name': 'Writing', 'icon': Icons.edit},
    {'name': 'Data Analysis', 'icon': Icons.analytics},
    {'name': 'Problem Solving', 'icon': Icons.psychology},
    {'name': 'Research', 'icon': Icons.search},
    {'name': 'Creativity', 'icon': Icons.palette},
    {'name': 'Business', 'icon': Icons.business},
  ];

  @override
  void dispose() {
    _customInterestController.dispose();
    _customInterestFocus.dispose();
    super.dispose();
  }

  bool _validateCustomInterest(String value, List<String> currentInterests) {
    if (value.isEmpty) {
      setState(() => _customInterestError = null);
      return false;
    }

    if (value.length < 2) {
      setState(() => _customInterestError = 'Interest must be at least 2 characters');
      return false;
    }

    if (value.length > 30) {
      setState(() => _customInterestError = 'Interest must be less than 30 characters');
      return false;
    }

    // Check for duplicates (case-insensitive)
    final normalizedValue = value.trim().toLowerCase();
    final isDuplicate = currentInterests.any(
          (interest) => interest.toLowerCase() == normalizedValue,
    );

    if (isDuplicate) {
      setState(() => _customInterestError = 'This interest is already added');
      return false;
    }

    setState(() => _customInterestError = null);
    return true;
  }

  void _addCustomInterest(AIMatchViewModel viewModel) {
    final value = _customInterestController.text.trim();

    if (_validateCustomInterest(value, viewModel.interests)) {
      // CHANGED: Limit check uses _maxInterests (6)
      if (viewModel.interests.length >= _maxInterests) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Maximum $_maxInterests interests allowed', // Dynamic text
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      // Add the custom interest
      viewModel.toggleInterest(value);
      _customInterestController.clear();
      _customInterestFocus.unfocus();

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Added "$value" to your interests',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AIMatchViewModel>(
      builder: (context, viewModel, _) {
        final selectedCount = viewModel.interests.length;
        // CHANGED: Check against _maxInterests (6)
        final canAddMore = selectedCount < _maxInterests;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.favorite,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'What activities do you enjoy?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Select from suggestions or add your own interests',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 20),

              // Counter Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  // CHANGED: Logic checks against _maxInterests (6)
                  color: selectedCount >= _maxInterests
                      ? Colors.orange.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selectedCount >= _maxInterests
                        ? Colors.orange.withOpacity(0.3)
                        : AppColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selectedCount >= _maxInterests
                          ? Icons.check_circle_rounded
                          : Icons.favorite_rounded,
                      size: 16,
                      color: selectedCount >= _maxInterests
                          ? Colors.orange[700]
                          : AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      // CHANGED: Display correct limit
                      '$selectedCount / $_maxInterests selected',
                      style: TextStyle(
                        color: selectedCount >= _maxInterests
                            ? Colors.orange[700]
                            : AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Custom Interest Input Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue[200]!,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.add_circle_outline,
                            size: 20, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Add Your Own Interest',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customInterestController,
                            focusNode: _customInterestFocus,
                            enabled: canAddMore,
                            maxLength: 30,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              hintText: 'e.g., Photography, Gaming, Cooking',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500],
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              counterText: '',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.blue[600]!,
                                  width: 2,
                                ),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              errorText: _customInterestError,
                              errorStyle: const TextStyle(fontSize: 11),
                            ),
                            onChanged: (value) {
                              _validateCustomInterest(value, viewModel.interests);
                            },
                            onSubmitted: canAddMore
                                ? (_) => _addCustomInterest(viewModel)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: canAddMore && _customInterestController.text.trim().isNotEmpty
                              ? Colors.blue[600]
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: canAddMore && _customInterestController.text.trim().isNotEmpty
                                ? () => _addCustomInterest(viewModel)
                                : null,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!canAddMore) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 14, color: Colors.orange[700]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Maximum limit reached. Remove some interests to add more.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange[800],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Predefined Interests Section
              Row(
                children: [
                  Icon(Icons.category_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Suggested Interests',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Predefined Interests Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: predefinedInterests.length,
                    itemBuilder: (context, index) {
                      final option = predefinedInterests[index];
                      final isSelected = viewModel.interests.contains(
                        option['name'],
                      );
                      final canSelect = canAddMore || isSelected;

                      return InkWell(
                        onTap: canSelect
                            ? () {
                          viewModel.toggleInterest(
                            option['name'] as String,
                          );
                        }
                            : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      // CHANGED: Display correct limit in grid warning
                                      'Maximum $_maxInterests interests allowed',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.orange[700],
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : canSelect
                                  ? Colors.grey[300]!
                                  : Colors.grey[200]!,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                option['icon'] as IconData,
                                color: isSelected
                                    ? AppColors.primary
                                    : canSelect
                                    ? AppColors.textSecondary
                                    : Colors.grey[400],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  option['name'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.primary
                                        : canSelect
                                        ? AppColors.textPrimary
                                        : Colors.grey[400],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              // Selected Interests Display (if any custom ones)
              if (viewModel.interests.any((interest) =>
              !predefinedInterests.any((p) => p['name'] == interest))) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 18, color: Colors.amber[700]),
                    const SizedBox(width: 8),
                    const Text(
                      'Your Custom Interests',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: viewModel.interests
                      .where((interest) => !predefinedInterests
                      .any((p) => p['name'] == interest))
                      .map((interest) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber[100]!,
                            Colors.amber[50]!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.amber[300]!,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded,
                              size: 16, color: Colors.amber[700]),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: Text(
                              interest,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber[900],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => viewModel.toggleInterest(interest),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Colors.amber[700],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}