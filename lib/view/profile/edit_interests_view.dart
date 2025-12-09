// lib/view/profile/edit_interests_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/viewModel/profile_view_model.dart';
import 'package:path_wise/viewModel/ai_match_view_model.dart';
import 'package:path_wise/utils/app_color.dart';

class EditInterestsScreen extends StatefulWidget {
  const EditInterestsScreen({Key? key}) : super(key: key);

  @override
  State<EditInterestsScreen> createState() => _EditInterestsScreenState();
}

class _EditInterestsScreenState extends State<EditInterestsScreen> {
  final TextEditingController _customInterestController =
      TextEditingController();
  final FocusNode _customInterestFocus = FocusNode();
  String? _customInterestError;

  // Local state to track interests before saving
  final List<String> _selectedInterests = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInterests();
    });
  }

  @override
  void dispose() {
    _customInterestController.dispose();
    _customInterestFocus.dispose();
    super.dispose();
  }

  Future<void> _loadInterests() async {
    setState(() => _isLoading = true);

    try {
      final aiMatchVM = context.read<AIMatchViewModel>();

      // Force reload from SharedPreferences to get latest data
      await aiMatchVM.loadProgress(forceRefresh: true);

      // Copy interests to local state
      _selectedInterests.clear();
      _selectedInterests.addAll(aiMatchVM.interests);

      debugPrint(
        '✅ Loaded ${_selectedInterests.length} interests from AI Match VM',
      );
    } catch (e) {
      debugPrint('❌ Error loading interests: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasUnsavedChanges = false;
        });
      }
    }
  }

  bool _validateCustomInterest(String value) {
    if (value.isEmpty) {
      setState(() => _customInterestError = null);
      return false;
    }

    if (value.length < 2) {
      setState(
        () => _customInterestError = 'Interest must be at least 2 characters',
      );
      return false;
    }

    if (value.length > 30) {
      setState(
        () => _customInterestError = 'Interest must be less than 30 characters',
      );
      return false;
    }

    final normalizedValue = value.trim().toLowerCase();
    final isDuplicate = _selectedInterests.any(
      (interest) => interest.toLowerCase() == normalizedValue,
    );

    if (isDuplicate) {
      setState(() => _customInterestError = 'This interest is already added');
      return false;
    }

    setState(() => _customInterestError = null);
    return true;
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
        _hasUnsavedChanges = true;
      } else if (_selectedInterests.length < _maxInterests) {
        _selectedInterests.add(interest);
        _hasUnsavedChanges = true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
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
      }
    });
  }

  void _addCustomInterest() {
    final value = _customInterestController.text.trim();

    if (_validateCustomInterest(value)) {
      if (_selectedInterests.length >= _maxInterests) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
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
        return;
      }

      setState(() {
        _selectedInterests.add(value);
        _hasUnsavedChanges = true;
      });

      _customInterestController.clear();
      _customInterestFocus.unfocus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 18,
              ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveInterests() async {
    if (!_hasUnsavedChanges) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final aiMatchVM = context.read<AIMatchViewModel>();
      final profileVM = context.read<ProfileViewModel>();

      debugPrint('💾 Saving ${_selectedInterests.length} interests...');

      // Update AI Match ViewModel (this also saves to SharedPreferences)
      aiMatchVM.setInterests(_selectedInterests);
      await aiMatchVM.saveProgress();

      // // Update Profile ViewModel (saves to Firestore)
      // await profileVM.updateInterests(_selectedInterests);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Interests saved successfully'),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
          ),
        );

        setState(() => _hasUnsavedChanges = false);
      }
    } catch (e) {
      debugPrint('❌ Error saving interests: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving interests: $e'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Do you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppColors.textPrimary,
              size: 20,
            ),
            onPressed: () async {
              if (await _onWillPop()) {
                if (mounted) Navigator.pop(context);
              }
            },
          ),
          title: const Text(
            'My Interests',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildInfoCard(),
                        const SizedBox(height: 20),
                        _buildCounterBadge(),
                        const SizedBox(height: 20),
                        _buildCustomInterestInput(),
                        const SizedBox(height: 24),
                        _buildSuggestedInterestsSection(),
                        if (_customInterests.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildCustomInterestsSection(),
                        ],
                      ],
                    ),
                  ),
                  if (_hasUnsavedChanges) ...[_buildSaveButton()],
                ],
              ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Select or add up to $_maxInterests interests that represent what you enjoy doing.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterBadge() {
    final selectedCount = _selectedInterests.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
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
            '$selectedCount / $_maxInterests selected',
            style: TextStyle(
              color: selectedCount >= _maxInterests
                  ? Colors.orange[700]
                  : AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          if (_hasUnsavedChanges) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber[700],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Unsaved',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomInterestInput() {
    final canAddMore = _selectedInterests.length < _maxInterests;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle_outline, size: 20, color: Colors.blue[700]),
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
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
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
                  onChanged: (value) => _validateCustomInterest(value),
                  onSubmitted: canAddMore ? (_) => _addCustomInterest() : null,
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color:
                    canAddMore &&
                        _customInterestController.text.trim().isNotEmpty
                    ? Colors.blue[600]
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap:
                      canAddMore &&
                          _customInterestController.text.trim().isNotEmpty
                      ? _addCustomInterest
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
                Icon(Icons.info_outline, size: 14, color: Colors.orange[700]),
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
    );
  }

  Widget _buildSuggestedInterestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category_rounded, size: 18, color: AppColors.primary),
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
        GridView.builder(
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
            final isSelected = _selectedInterests.contains(option['name']);
            final canSelect =
                _selectedInterests.length < _maxInterests || isSelected;

            return InkWell(
              onTap: () => _toggleInterest(option['name'] as String),
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
        ),
      ],
    );
  }

  Widget _buildCustomInterestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          children: _customInterests.map((interest) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber[100]!, Colors.amber[50]!],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber[300]!, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, size: 16, color: Colors.amber[700]),
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
                    onTap: () => _toggleInterest(interest),
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
    );
  }

  Widget _buildSaveButton() {
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
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveInterests,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[500],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Save Changes',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  List<String> get _customInterests {
    return _selectedInterests
        .where(
          (interest) => !predefinedInterests.any((p) => p['name'] == interest),
        )
        .toList();
  }
}
