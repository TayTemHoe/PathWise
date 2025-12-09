import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_wise/viewModel/profile_view_model.dart';
import 'package:path_wise/viewModel/ai_match_view_model.dart';
import 'package:path_wise/model/ai_match_model.dart';
import 'package:path_wise/utils/app_color.dart';
import 'package:path_wise/view/mbti_test_screen.dart';
import 'package:path_wise/view/big_five_test_screen.dart';
import 'package:path_wise/view/riasec_test_screen.dart';

class EditPersonalityScreen extends StatefulWidget {
  const EditPersonalityScreen({super.key});

  @override
  EditPersonalityScreenState createState() => EditPersonalityScreenState();
}

class EditPersonalityScreenState extends State<EditPersonalityScreen> {
  // MBTI state
  String? _selectedMBTI;
  PersonalityProfile? _lastSyncedProfile;
  bool _hasUnsavedChanges = false;

  // RIASEC state
  final Map<String, double> _riasecScores = {
    'R': 0.5,
    'I': 0.5,
    'A': 0.5,
    'S': 0.5,
    'E': 0.5,
    'C': 0.5,
  };

  // Big Five (OCEAN) state
  final Map<String, double> _oceanScores = {
    'O': 0.5,
    'C': 0.5,
    'E': 0.5,
    'A': 0.5,
    'N': 0.5,
  };

  final List<String> _mbtiTypes = [
    'ISTJ',
    'ISFJ',
    'INFJ',
    'INTJ',
    'ISTP',
    'ISFP',
    'INFP',
    'INTP',
    'ESTP',
    'ESFP',
    'ENFP',
    'ENTP',
    'ESTJ',
    'ESFJ',
    'ENFJ',
    'ENTJ',
  ];

  bool _isLoading = true;
  bool _isSaving = false;
  final Color _textColor = AppColors.textPrimary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPersonalityData();
    });
  }

  /// Load personality data from both ProfileViewModel (Firestore) and AIMatchViewModel (SharedPreferences)
  Future<void> _loadPersonalityData() async {
    setState(() {
      _isLoading = false;
      _hasUnsavedChanges = false; // Add this to reset state
    });
    try {
      final aiMatchVM = context.read<AIMatchViewModel>();
      // If VM has no data, try loading from disk. Otherwise, we trust the VM's current state.
      if (aiMatchVM.personalityProfile == null) {
        await aiMatchVM.loadProgress();
      }
      // The actual UI update will happen via the Consumer in the build method
    } catch (e) {
      debugPrint('❌ Error loading personality data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _syncFromViewModel(PersonalityProfile? profile) {
    // Only sync if the profile exists and is different from what we last saw
    if (profile != null && profile != _lastSyncedProfile) {
      // Use addPostFrameCallback to avoid "setState during build" errors
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedMBTI = profile.mbti;

            if (profile.riasec != null) {
              _riasecScores.clear();
              _riasecScores.addAll(profile.riasec!);
            }

            if (profile.ocean != null) {
              _oceanScores.clear();
              _oceanScores.addAll(profile.ocean!);
            }

            _hasUnsavedChanges = false;
            _lastSyncedProfile = profile;
          });
        }
      });
    }
  }

  /// Save personality data to BOTH Firestore and SharedPreferences
  Future<void> _savePersonalityData() async {
    setState(() => _isSaving = true);

    try {
      final profileVM = context.read<ProfileViewModel>();
      final aiMatchVM = context.read<AIMatchViewModel>();

      // 1. Save to Firestore (via ProfileViewModel)
      debugPrint('💾 Saving to Firestore: MBTI=$_selectedMBTI');
      await profileVM.updatePersonality(
        mbti: _selectedMBTI,
        riasec:
            null, // We keep this null for now unless serializing map to string
      );

      // 2. Update AIMatchViewModel (Memory + SharedPrefs)
      final riasecHasData = _riasecScores.values.any((v) => v != 0.5);
      final oceanHasData = _oceanScores.values.any((v) => v != 0.5);

      final personalityProfile = PersonalityProfile(
        mbti: _selectedMBTI,
        riasec: riasecHasData ? Map.from(_riasecScores) : null,
        ocean: oceanHasData ? Map.from(_oceanScores) : null,
      );

      debugPrint('💾 Saving to AI Match ViewModel & SharedPrefs');

      // This updates memory AND triggers auto-save to SharedPreferences
      aiMatchVM.setPersonalityProfile(personalityProfile);

      // Explicitly force save to disk to ensure sync
      await aiMatchVM.saveProgress();

      if (mounted) {
        setState(() => _hasUnsavedChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Personality data saved successfully'),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error saving personality data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
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
    // 1. Wrap Scaffold in WillPopScope
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
            // 2. Update the back button logic
            onPressed: () async {
              if (await _onWillPop()) {
                if (mounted) Navigator.pop(context);
              }
            },
          ),
          title: Text(
            'Personality Insight',
            style: TextStyle(
              color: _textColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        // ... existing body code (Consumer, Column, etc.)
        body: Consumer<AIMatchViewModel>(
          builder: (context, aiMatchVM, child) {
            // Check for updates every time the ViewModel notifies listeners
            _syncFromViewModel(aiMatchVM.personalityProfile);

            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildInfoCard(),
                      const SizedBox(height: 20),
                      _buildMBTISection(),
                      const SizedBox(height: 20),
                      _buildRIASECSection(),
                      const SizedBox(height: 20),
                      _buildBigFiveSection(),
                      const SizedBox(height: 20),
                      // Remove _buildSaveButton() from here
                    ],
                  ),
                ),
                // Move it here, conditioned on state
                if (_hasUnsavedChanges) _buildSaveButton(),
              ],
            );
          },
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
              'Complete personality tests to get better program recommendations. All tests are optional.',
              style: TextStyle(
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

  Widget _buildMBTISection() {
    return _buildSectionCard(
      title: 'MBTI Personality Type',
      icon: Icons.psychology_rounded,
      color: Colors.purple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Option 1: Take the test
          InkWell(
            onTap: () => _navigateToMBTITest(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[100]!, Colors.purple[50]!],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple[300]!, width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple[600],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Take 16 Personalities Test',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Discover your personality type • 10-15 min',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.purple[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.purple[600],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey[300])),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey[300])),
            ],
          ),

          const SizedBox(height: 16),

          // Option 2: Manual selection
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _selectedMBTI,
            decoration: InputDecoration(
              labelText: 'Select Your MBTI Type',
              hintText: 'Choose if you already know your type',
              filled: true,
              fillColor: Colors.white,
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
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            items: _mbtiTypes.map((type) {
              return DropdownMenuItem(value: type, child: Text(type));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedMBTI = value;
                _hasUnsavedChanges = true; // Add this
              });
            },
          ),

          if (_selectedMBTI != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.purple[700], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Selected: $_selectedMBTI',
                    style: TextStyle(
                      color: Colors.purple[900],
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
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

  Widget _buildRIASECSection() {
    final labels = {
      'R': 'Realistic',
      'I': 'Investigative',
      'A': 'Artistic',
      'S': 'Social',
      'E': 'Enterprising',
      'C': 'Conventional',
    };

    return _buildSectionCard(
      title: 'RIASEC / Holland Code',
      icon: Icons.work_outline,
      color: Colors.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Option 1: Take the test
          InkWell(
            onTap: () => _navigateToRiasecTest(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[100]!, Colors.blue[50]!],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[300]!, width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.work_outline_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Take RIASEC Test',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Discover your career interests • 10-15 min',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey[300])),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey[300])),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            'Adjust sliders manually (0.0 - 1.0)',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),

          ...labels.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildSliderItem(
                key: entry.key,
                label: entry.value,
                value: _riasecScores[entry.key]!,
                color: Colors.blue,
                onChanged: (value) {
                  setState(() => _riasecScores[entry.key] = value);
                  _markAsChanged();
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBigFiveSection() {
    return _buildSectionCard(
      title: 'Big Five (OCEAN)',
      icon: Icons.favorite_rounded,
      color: Colors.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _navigateToBigFiveTest(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal[100]!, Colors.teal[50]!],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal[300]!, width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal[600],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Take Big Five Test',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Comprehensive personality assessment • 15-20 min',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.teal[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.teal[600],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey[300])),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey[300])),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            'Adjust sliders manually (0.0 - 1.0)',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),

          ...{
            'O': 'Openness',
            'C': 'Conscientiousness',
            'E': 'Extraversion',
            'A': 'Agreeableness',
            'N': 'Neuroticism',
          }.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildSliderItem(
                key: entry.key,
                label: entry.value,
                value: _oceanScores[entry.key]!,
                color: Colors.teal,
                onChanged: (value) {
                  setState(() => _oceanScores[entry.key] = value);
                  _markAsChanged();
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildSliderItem({
    required String key,
    required String label,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    final formattedValue = value.toStringAsFixed(2);
    final percentage = '${(value * 100).toStringAsFixed(0)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        key,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formattedValue,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '($percentage)',
                    style: TextStyle(fontSize: 11, color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.2),
            thumbColor: color,
            overlayColor: color.withOpacity(0.2),
            trackHeight: 6,
          ),
          child: Slider(
            value: value,
            min: 0.0,
            max: 1.0,
            divisions: 100,
            onChanged: onChanged,
          ),
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
              onPressed: _isSaving ? null : _savePersonalityData,
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
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Save Personality Data',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  Future<void> _navigateToMBTITest(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const MBTITestScreen()));

    if (mounted) {
      _lastSyncedProfile = null; // Force UI refresh
      final vm = context.read<AIMatchViewModel>();
      _syncFromViewModel(vm.personalityProfile);
    }
  }

  Future<void> _navigateToRiasecTest(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const RiasecTestScreen()));

    if (mounted) {
      _lastSyncedProfile = null;
      final vm = context.read<AIMatchViewModel>();
      _syncFromViewModel(vm.personalityProfile);
    }
  }

  Future<void> _navigateToBigFiveTest(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const BigFiveTestScreen()));

    if (mounted) {
      _lastSyncedProfile = null;
      final vm = context.read<AIMatchViewModel>();
      _syncFromViewModel(vm.personalityProfile);
    }
  }
}
