import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../model/ai_match_model.dart';
import '../../utils/app_color.dart';
import '../../view/mbti_test_screen.dart';
import '../../view/big_five_test_screen.dart';
import '../../view/riasec_test_screen.dart';
import '../../viewModel/ai_match_view_model.dart';
import '../form_components.dart';

class PersonalityPage extends StatefulWidget {
  final bool showHeader;

  const PersonalityPage({
    Key? key,
    this.showHeader = true,
  }) : super(key: key);

  @override
  State<PersonalityPage> createState() => _PersonalityPageState();
}

class _PersonalityPageState extends State<PersonalityPage> with WidgetsBindingObserver, RouteAware {
  String? _selectedMBTI;

  // Local state for sliders
  final Map<String, double> _riasecScores = {
    'R': 0.5, 'I': 0.5, 'A': 0.5, 'S': 0.5, 'E': 0.5, 'C': 0.5,
  };

  final Map<String, double> _oceanScores = {
    'O': 0.5, 'C': 0.5, 'E': 0.5, 'A': 0.5, 'N': 0.5,
  };

  final List<String> _mbtiTypes = [
    'ISTJ', 'ISFJ', 'INFJ', 'INTJ',
    'ISTP', 'ISFP', 'INFP', 'INTP',
    'ESTP', 'ESFP', 'ENFP', 'ENTP',
    'ESTJ', 'ESFJ', 'ENFJ', 'ENTJ',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initial load with delay to ensure ViewModel is ready
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadFromViewModelAsync();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadFromViewModelAsync();
    }
  }

  // FIXED: Async load with proper error handling
  Future<void> _loadFromViewModelAsync() async {
    if (!mounted) return;

    try {
      final vm = context.read<AIMatchViewModel>();

      // CRITICAL: Force reload from storage first
      await vm.loadProgress(forceRefresh: true);

      final profile = vm.personalityProfile;

      debugPrint('🔍 Loading personality data...');
      debugPrint('   MBTI: ${profile?.mbti}');
      debugPrint('   RIASEC: ${profile?.riasec}');
      debugPrint('   OCEAN: ${profile?.ocean}');

      if (profile == null) {
        debugPrint('⚠️ No personality profile found');
        return;
      }

      if (!mounted) return;

      setState(() {
        _selectedMBTI = profile.mbti;

        if (profile.riasec != null) {
          _riasecScores.clear();
          _riasecScores.addAll(profile.riasec!);
          debugPrint('✅ RIASEC loaded: $_riasecScores');
        } else {
          _riasecScores.updateAll((key, value) => 0.5);
          debugPrint('🔄 RIASEC reset to defaults');
        }

        if (profile.ocean != null) {
          _oceanScores.clear();
          _oceanScores.addAll(profile.ocean!);
          debugPrint('✅ OCEAN loaded: $_oceanScores');
        } else {
          _oceanScores.updateAll((key, value) => 0.5);
          debugPrint('🔄 OCEAN reset to defaults');
        }
      });

      debugPrint('✅ Personality data loaded successfully');
    } catch (e) {
      debugPrint('❌ Error loading personality data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHeader)
            _buildSectionHeader('Personality Assessment (Optional)', Icons.person),

          if (widget.showHeader)
            const SizedBox(height: 16),

          const SizedBox(height: 16),
          _buildMBTISection(),

          const SizedBox(height: 32),
          _buildUpdatedRIASECSection(),

          const SizedBox(height: 32),
          _buildBigFiveSection(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildMBTISection() {
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
          const SectionHeader(
            title: 'MBTI Personality Type',
            icon: Icons.category,
          ),

          const SizedBox(height: 16),

          // Option 1: Take the test
          InkWell(
            onTap: () => _navigateToMBTITest(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple[100]!,
                    Colors.purple[50]!,
                  ],
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
                    child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Take 16 Personalities Test',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple[900]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Discover your personality type • 10-15 min',
                          style: TextStyle(fontSize: 13, color: Colors.purple[700]),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: Colors.purple[600], size: 20),
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
                child: Text('OR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
              ),
              Expanded(child: Divider(color: Colors.grey[300])),
            ],
          ),

          const SizedBox(height: 16),

          CustomDropdownField<String>(
            label: 'Enter Your MBTI Type Manually',
            value: _selectedMBTI,
            items: _mbtiTypes,
            hint: 'Select if you already know your type',
            onChanged: (value) {
              setState(() => _selectedMBTI = value);
              _savePersonalityData(context.read<AIMatchViewModel>());
            },
          ),

          if (_selectedMBTI != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.purple[50], borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.purple[700], size: 16),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text('Selected: $_selectedMBTI', style: TextStyle(color: Colors.purple[900], fontWeight: FontWeight.w500, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUpdatedRIASECSection() {
    final labels = {'R': 'Realistic', 'I': 'Investigative', 'A': 'Artistic', 'S': 'Social', 'E': 'Enterprising', 'C': 'Conventional'};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'RIASEC / Holland Code', icon: Icons.work_outline),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _navigateToRiasecTest(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blue[100]!, Colors.blue[50]!]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[300]!, width: 2),
              ),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue[600], borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.work_outline_rounded, color: Colors.white, size: 28)),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Take RIASEC Test', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[900])), const SizedBox(height: 4), Text('Discover your career interests • 10-15 min', style: TextStyle(fontSize: 13, color: Colors.blue[700]))])),
                  Icon(Icons.arrow_forward_ios_rounded, color: Colors.blue[600], size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [Expanded(child: Divider(color: Colors.grey[300])), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('OR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600]))), Expanded(child: Divider(color: Colors.grey[300]))]),
          const SizedBox(height: 16),
          Text('Adjust sliders manually (0.0 - 1.0)', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 20),
          ...labels.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildSliderItem(
                key: entry.key,
                label: entry.value,
                value: _riasecScores[entry.key]!,
                color: Colors.blue,
                onChanged: (value) => setState(() => _riasecScores[entry.key] = value),
                onChangeEnd: (value) => _savePersonalityData(context.read<AIMatchViewModel>()),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBigFiveSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Big Five (OCEAN)', icon: Icons.favorite_rounded),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _navigateToBigFiveTest(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.teal[100]!, Colors.teal[50]!]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal[300]!, width: 2),
              ),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.teal[600], borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 28)),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Take Big Five Test', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal[900])), const SizedBox(height: 4), Text('Comprehensive personality assessment • 15-20 min', style: TextStyle(fontSize: 13, color: Colors.teal[700]))])),
                  Icon(Icons.arrow_forward_ios_rounded, color: Colors.teal[600], size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [Expanded(child: Divider(color: Colors.grey[300])), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('OR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600]))), Expanded(child: Divider(color: Colors.grey[300]))]),
          const SizedBox(height: 16),
          Text('Adjust sliders manually (0.0 - 1.0)', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 20),
          ...{'O': 'Openness', 'C': 'Conscientiousness', 'E': 'Extraversion', 'A': 'Agreeableness', 'N': 'Neuroticism'}.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildSliderItem(
                key: entry.key,
                label: entry.value,
                value: _oceanScores[entry.key]!,
                color: Colors.teal,
                onChanged: (value) => setState(() => _oceanScores[entry.key] = value),
                onChangeEnd: (value) => _savePersonalityData(context.read<AIMatchViewModel>()),
              ),
            );
          }),
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
    ValueChanged<double>? onChangeEnd,
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
                  Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Center(child: Text(key, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)))),
                  const SizedBox(width: 12),
                  Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), constraints: const BoxConstraints(maxWidth: 100), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [Flexible(child: Text(formattedValue, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14), overflow: TextOverflow.ellipsis)), const SizedBox(width: 4), Text('($percentage)', style: TextStyle(fontSize: 11, color: color))])),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(data: SliderTheme.of(context).copyWith(activeTrackColor: color, inactiveTrackColor: color.withOpacity(0.2), thumbColor: color, overlayColor: color.withOpacity(0.2), trackHeight: 6, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10), overlayShape: const RoundSliderOverlayShape(overlayRadius: 20)), child: Slider(value: value, min: 0.0, max: 1.0, divisions: 100, onChanged: onChanged, onChangeEnd: onChangeEnd)),
      ],
    );
  }

  void _savePersonalityData(AIMatchViewModel viewModel) {
    final riasecHasData = _riasecScores.values.any((v) => v != 0.5);
    final oceanHasData = _oceanScores.values.any((v) => v != 0.5);
    final profile = PersonalityProfile(
        mbti: _selectedMBTI,
        riasec: riasecHasData ? Map.from(_riasecScores) : null,
        ocean: oceanHasData ? Map.from(_oceanScores) : null
    );
    viewModel.setPersonalityProfile(profile);
  }

  Future<void> _navigateToMBTITest(BuildContext context) async {
    debugPrint('🚀 Navigating to MBTI test...');

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const MBTITestScreen()),
    );

    // CRITICAL: Wait a moment for save operations to complete, then reload
    debugPrint('🔙 Returned from MBTI test');
    await Future.delayed(const Duration(milliseconds: 300));
    await _loadFromViewModelAsync();
  }

  Future<void> _navigateToRiasecTest(BuildContext context) async {
    debugPrint('🚀 Navigating to RIASEC test...');

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RiasecTestScreen()),
    );

    // CRITICAL: Wait a moment for save operations to complete, then reload
    debugPrint('🔙 Returned from RIASEC test');
    await Future.delayed(const Duration(milliseconds: 300));
    await _loadFromViewModelAsync();
  }

  Future<void> _navigateToBigFiveTest(BuildContext context) async {
    debugPrint('🚀 Navigating to Big Five test...');

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const BigFiveTestScreen()),
    );

    // CRITICAL: Wait a moment for save operations to complete, then reload
    debugPrint('🔙 Returned from Big Five test');
    await Future.delayed(const Duration(milliseconds: 300));
    await _loadFromViewModelAsync();
  }
}