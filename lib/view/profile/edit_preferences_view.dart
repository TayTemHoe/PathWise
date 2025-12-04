import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/model/user_profile.dart';
import 'package:path_wise/viewModel/profile_view_model.dart';

class EditPreferencesScreen extends StatelessWidget {
  const EditPreferencesScreen({super.key});

  // KYYAP Style Constants
  final Color _backgroundColor = Colors.white;
  final Color _textColor = const Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    // If provider not found, show helpful message instead of throwing
    ProfileViewModel vm;
    try {
      vm = context.watch<ProfileViewModel>();
    } catch (_) {
      return Scaffold(
        appBar: AppBar(title: const Text('Career Preferences')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Provider<ProfileViewModel> not found above this screen.\n'
                  'Wrap MaterialApp with ChangeNotifierProvider OR push this screen using ChangeNotifierProvider.value.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _backgroundColor,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Career Preferences',
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      // 🔧 FIX: Use both profile and user to get preferences
      body: Selector<ProfileViewModel, Preferences?>(
        selector: (_, vm) {
          // Try both profile and user
          final prof = vm.profile ?? vm.user;
          return prof?.preferences;
        },
        builder: (context, prefs, _) {
          final initial = prefs ?? const Preferences();
          // key changes when prefs content changes -> form rehydrates
          final formKey = ValueKey(initial.toFirestore().toString());
          return _PreferencesForm(key: formKey, initial: initial);
        },
      ),
    );
  }
}

class _PreferencesForm extends StatefulWidget {
  const _PreferencesForm({super.key, required this.initial});
  final Preferences initial;

  @override
  State<_PreferencesForm> createState() => _PreferencesFormState();
}

class _PreferencesFormState extends State<_PreferencesForm> {
  // Style Constants
  final Color _primaryColor = const Color(0xFF6C63FF);
  final Color _textColor = const Color(0xFF1A1A1A);

  // local state
  late List<String> desiredRoles;
  late List<String> industries;
  late List<String> preferredLocations;
  late bool willingToRelocate;
  late String remoteAcceptance; // Yes / HybridOnly / No
  late List<String> workEnvironment;
  late String companySize;
  late String salaryType; // Monthly / Annual
  late int salaryMin;
  late int salaryMax;
  String? salaryCurrency;
  late List<String> benefitsPriority;

  // Initial State for dirty checking
  late Preferences _initialState;

  final _newRoleCtrl = TextEditingController();
  final _newLocationCtrl = TextEditingController();
  bool _saving = false;

  void _loadFrom(Preferences p) {
    _initialState = p;

    desiredRoles = [...(p.desiredJobTitles ?? const [])];
    industries = [...(p.industries ?? const [])];
    preferredLocations = [...(p.preferredLocations ?? const [])];
    willingToRelocate = p.willingToRelocate ?? false;
    remoteAcceptance = p.remoteAcceptance ?? 'HybridOnly';
    workEnvironment = [...(p.workEnvironment ?? const [])];
    if (workEnvironment.isEmpty) workEnvironment = ['Hybrid'];
    companySize = p.companySize ?? 'Any';
    salaryType = p.salary?.type ?? 'Monthly';
    salaryMin = p.salary?.min ?? 0;
    salaryMax = p.salary?.max ?? (salaryType == 'Monthly' ? 10000 : 120000);

    // 🔧 FIX: Load currency from saved preferences, default to MYR if not set
    salaryCurrency = p.salary?.currency ?? 'MYR';

    benefitsPriority = [...(p.salary?.benefitsPriority ?? const [])];
  }

  @override
  void initState() {
    super.initState();
    _loadFrom(widget.initial);
  }

  bool _hasUnsavedChanges() {
    bool listsDiffer(List<String> a, List<String> b) {
      if (a.length != b.length) return true;
      final setA = Set.of(a);
      final setB = Set.of(b);
      return !setA.containsAll(setB);
    }

    if (listsDiffer(desiredRoles, _initialState.desiredJobTitles ?? [])) return true;
    if (listsDiffer(industries, _initialState.industries ?? [])) return true;
    if (listsDiffer(preferredLocations, _initialState.preferredLocations ?? [])) return true;
    if (willingToRelocate != (_initialState.willingToRelocate ?? false)) return true;
    if (remoteAcceptance != (_initialState.remoteAcceptance ?? 'HybridOnly')) return true;

    List<String> initialWorkEnv = _initialState.workEnvironment ?? [];
    if (initialWorkEnv.isEmpty) initialWorkEnv = ['Hybrid'];
    if (listsDiffer(workEnvironment, initialWorkEnv)) return true;

    if (companySize != (_initialState.companySize ?? 'Any')) return true;

    final initialMin = _initialState.salary?.min ?? 0;
    if (salaryMin != initialMin) return true;
    if (salaryType != (_initialState.salary?.type ?? 'Monthly')) return true;

    // 🔧 FIX: Check currency changes
    if (salaryCurrency != (_initialState.salary?.currency ?? 'MYR')) return true;

    if (salaryMax != (_initialState.salary?.max ?? (salaryType == 'Monthly' ? 10000 : 120000))) return true;

    if (listsDiffer(benefitsPriority, _initialState.salary?.benefitsPriority ?? [])) return true;

    return false;
  }

  @override
  void didUpdateWidget(covariant _PreferencesForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 🔧 FIX: Reload form when widget changes (after save completes)
    if (oldWidget.initial.toFirestore().toString() !=
        widget.initial.toFirestore().toString()) {
      debugPrint('🔄 Preferences changed, reloading form');
      setState(() {
        _loadFrom(widget.initial);
      });
    }
  }

  @override
  void dispose() {
    _newRoleCtrl.dispose();
    _newLocationCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (desiredRoles.isEmpty ||
        industries.isEmpty ||
        preferredLocations.isEmpty ||
        salaryMin <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete roles, industries, locations, and salary.'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
      return;
    }

    // 🔧 FIX: Include currency in the save
    final updated = Preferences(
      desiredJobTitles: desiredRoles,
      industries: industries,
      preferredLocations: preferredLocations,
      willingToRelocate: willingToRelocate,
      remoteAcceptance: remoteAcceptance,
      workEnvironment: workEnvironment,
      companySize: companySize,
      salary: PrefSalary(
        min: salaryMin,
        max: salaryMax,
        type: salaryType,
        currency: salaryCurrency, // 🔧 Now saving currency
        benefitsPriority: benefitsPriority,
      ),
    );

    setState(() => _saving = true);

    debugPrint('💾 Saving preferences: ${updated.toFirestore()}');

    final ok = await context.read<ProfileViewModel>().updatePreferences(updated);

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      // 🔧 FIX: Reload profile data from Firestore after save
      debugPrint('✅ Preferences saved, reloading profile...');
      await context.read<ProfileViewModel>().loadAll();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences saved successfully'),
          backgroundColor: Color(0xFF00B894),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save preferences'),
          backgroundColor: Color(0xFFD63031),
        ),
      );
    }
  }

  Future<void> _showUnsavedDialog() async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Unsaved Changes', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'You have unsaved changes. Do you want to save them before leaving?',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('Discard', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _handleSave();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summarySalary = _formatSalaryRange(
      currency: salaryCurrency,
      type: salaryType,
      min: salaryMin,
      max: salaryMax,
    );

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (_hasUnsavedChanges()) {
          await _showUnsavedDialog();
        } else {
          Navigator.pop(context);
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Stats Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _StatItem(value: '${desiredRoles.length}', label: 'Roles', primaryColor: _primaryColor),
                          const SizedBox(width: 24),
                          _StatItem(value: '${industries.length}', label: 'Industries', primaryColor: _primaryColor),
                        ],
                      ),
                      if (salaryMin > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.monetization_on_outlined, size: 16, color: _primaryColor),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  summarySalary,
                                  style: TextStyle(color: _textColor, fontSize: 13, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.tune, color: _primaryColor, size: 24),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          _jobPreferences(),
          const SizedBox(height: 24),
          _industryPreferences(),
          const SizedBox(height: 24),
          _locationPreferences(),
          const SizedBox(height: 24),
          _workEnvSection(),
          const SizedBox(height: 24),
          _salaryBenefitsSection(summarySalary),

          const SizedBox(height: 32),

          // Actions
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _saving ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: () async {
                if (_hasUnsavedChanges()) {
                  await _showUnsavedDialog();
                } else {
                  Navigator.pop(context);
                }
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Cancel', style: TextStyle(color: _textColor, fontSize: 16, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Sections Refactored with KYYAP Style ----

  Widget _jobPreferences() => _SectionContainer(
    title: 'Job Preferences',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('Desired Job Titles *'),
        const SizedBox(height: 8),
        if (desiredRoles.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: desiredRoles.map((r) => _StyledChip(
              label: r,
              onDeleted: () => setState(() => desiredRoles.remove(r)),
              primaryColor: _primaryColor,
            )).toList(),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StyledTextField(
                controller: _newRoleCtrl,
                hint: 'e.g., Senior Developer',
                onSubmitted: (_) => _addRole(),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _addRole,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _industryPreferences() => _SectionContainer(
    title: 'Industry Preferences *',
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
    Text(
    'Select the industries you"re interested in working in' ,
    style: TextStyle(color: Colors.grey[600], fontSize: 14),
  ),
  const SizedBox(height: 12),
  Wrap(
  spacing: 8,
  runSpacing: 8,
  children: _industryOptions.map((idLabel) => ChoiceChip(
  label: Text(idLabel.$2),
  selected: industries.contains(idLabel.$1),
  selectedColor: _primaryColor.withOpacity(0.1),
  labelStyle: TextStyle(
  color: industries.contains(idLabel.$1) ? _primaryColor : Colors.grey[700],
  fontWeight: industries.contains(idLabel.$1) ? FontWeight.bold : FontWeight.normal,
  ),
  backgroundColor: Colors.white,
  shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(20),
  side: BorderSide(
  color: industries.contains(idLabel.$1) ? _primaryColor : Colors.grey[300]!
  ),
  ),
  onSelected: (s) => setState(() {
  if (s) industries.add(idLabel.$1);
  else industries.remove(idLabel.$1);
  }),
  )).toList(),
  ),
  ],
  ),
  );

  Widget _locationPreferences() => _SectionContainer(
  title: 'Location Preferences *',
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  const _Label('Preferred Work Locations'),
  const SizedBox(height: 8),
  if (preferredLocations.isNotEmpty)
  Wrap(
  spacing: 8,
  runSpacing: 8,
  children: preferredLocations.map((loc) => _StyledChip(
  label: loc,
  onDeleted: () => setState(() => preferredLocations.remove(loc)),
  primaryColor: _primaryColor,
  )).toList(),
  ),
  const SizedBox(height: 12),
  Row(
  children: [
  Expanded(
  child: _StyledTextField(
  controller: _newLocationCtrl,
  hint: 'e.g., Kuala Lumpur',
  onSubmitted: (_) => _addLocation(),
  ),
  ),
  const SizedBox(width: 12),
  ElevatedButton(
  onPressed: _addLocation,
  style: ElevatedButton.styleFrom(
  backgroundColor: _primaryColor,
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  child: const Text('Add', style: TextStyle(color: Colors.white)),
  ),
  ],
  ),
  const SizedBox(height: 16),
  SwitchListTile(
  contentPadding: EdgeInsets.zero,
  value: willingToRelocate,
  activeColor: _primaryColor,
  onChanged: (v) => setState(() => willingToRelocate = v),
  title: const Text('Willing to relocate', style: TextStyle(fontWeight: FontWeight.w500)),
  ),
  const SizedBox(height: 12),
  const _Label('Remote Work Preference'),
  const SizedBox(height: 8),
  Wrap(
  spacing: 8,
  children: _remoteOptions.map((opt) => ChoiceChip(
  label: Text(opt.$2),
  selected: remoteAcceptance == opt.$1,
  selectedColor: _primaryColor.withOpacity(0.1),
  labelStyle: TextStyle(
  color: remoteAcceptance == opt.$1 ? _primaryColor : Colors.grey[700],
  fontWeight: FontWeight.bold,
  ),
  backgroundColor: Colors.white,
  shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(8),
  side: BorderSide(
  color: remoteAcceptance == opt.$1 ? _primaryColor : Colors.grey[300]!
  ),
  ),
  onSelected: (_) => setState(() => remoteAcceptance = opt.$1),
  )).toList(),
  ),
  ],
  ),
  );

  Widget _workEnvSection() => _SectionContainer(
  title: 'Work Environment',
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  const _Label('Work Type Preference'),
  const SizedBox(height: 8),
  Wrap(
  spacing: 8,
  runSpacing: 8,
  children: _workTypes.map((w) => ChoiceChip(
  label: Text(w),
  selected: workEnvironment.isNotEmpty && workEnvironment.first == w,
  selectedColor: _primaryColor.withOpacity(0.1),
  labelStyle: TextStyle(
  color: (workEnvironment.isNotEmpty && workEnvironment.first == w) ? _primaryColor : Colors.grey[700],
  fontWeight: FontWeight.bold,
  ),
  backgroundColor: Colors.white,
  shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(8),
  side: BorderSide(
  color: (workEnvironment.isNotEmpty && workEnvironment.first == w) ? _primaryColor : Colors.grey[300]!
  ),
  ),
  onSelected: (_) => setState(() => workEnvironment = [w]),
  )).toList(),
  ),
  const SizedBox(height: 16),
  const _Label('Company Size Preference'),
  const SizedBox(height: 8),
  Wrap(
  spacing: 8,
  runSpacing: 8,
  children: _companySizes.map((s) => ChoiceChip(
  label: Text(s),
  selected: companySize == s,
  selectedColor: _primaryColor.withOpacity(0.1),
  labelStyle: TextStyle(
  color: companySize == s ? _primaryColor : Colors.grey[700],
  fontWeight: FontWeight.bold,
  ),
  backgroundColor: Colors.white,
  shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(8),
  side: BorderSide(
  color: companySize == s ? _primaryColor : Colors.grey[300]!
  ),
  ),
  onSelected: (_) => setState(() => companySize = s),
  )).toList(),
  ),
  ],
  ),
  );

  Widget _salaryBenefitsSection(String summarySalary) => _SectionContainer(
  title: 'Salary & Benefits',
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  const _Label('Salary Expectations *'),
  const SizedBox(height: 12),
  Row(
  children: [
  Expanded(
  child: _StyledDropdown<String>(
  value: salaryCurrency,
  hint: 'Currency',
  items: const ['MYR', 'SGD', 'USD', 'EUR'],
  onChanged: (v) => setState(() {
  salaryCurrency = v;
  debugPrint('💱 Currency changed to: $v');
  }),
  ),
  ),
  const SizedBox(width: 12),
  Expanded(
  child: _StyledDropdown<String>(
  value: salaryType,
  hint: 'Type',
  items: const ['Monthly', 'Annual'],
  onChanged: (v) => setState(() => salaryType = v ?? 'Monthly'),
  ),
  ),
  ],
  ),
  const SizedBox(height: 20),
  _LabeledSlider(
  label: 'Minimum Salary',
  valText: '${_symbol(salaryCurrency)}${_fmtMoney(salaryMin)}',
  min: salaryType == 'Monthly' ? 1000 : 12000,
  max: salaryType == 'Monthly' ? 50000 : 600000,
  value: salaryMin.toDouble(),
  primaryColor: _primaryColor,
  onChanged: (v) {
  setState(() {
  salaryMin = v.round();
  if (salaryMax < salaryMin) salaryMax = salaryMin;
  });
  },
  ),
  const SizedBox(height: 16),
  _LabeledSlider(
  label: 'Preferred Maximum',
  valText: '${_symbol(salaryCurrency)}${_fmtMoney(salaryMax)}',
  min: salaryMin.toDouble(),
  max: salaryType == 'Monthly' ? 100000 : 1200000,
  value: salaryMax.toDouble(),
  primaryColor: _primaryColor,
  onChanged: (v) => setState(() => salaryMax = v.round()),
  ),
  const SizedBox(height: 20),
  Container(
  width: double.infinity,
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
  color: _primaryColor.withOpacity(0.05),
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: _primaryColor.withOpacity(0.1)),
  ),
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Text('Target Range', style: TextStyle(fontSize: 12, color: _primaryColor)),
  const SizedBox(height: 4),
  Text(
  summarySalary,
  style: TextStyle(color: _textColor, fontSize: 16, fontWeight: FontWeight.bold),
  ),
  ],
  ),
  ),
  const SizedBox(height: 24),
  const _Label('Important Benefits'),
  const SizedBox(height: 12),
  Wrap(
  spacing: 8,
  runSpacing: 8,
  children: _benefitOptions.map((idLabel) => ChoiceChip(
  label: Text(idLabel.$2),
  selected: benefitsPriority.contains(idLabel.$1),
  selectedColor: _primaryColor.withOpacity(0.1),
  labelStyle: TextStyle(
  color: benefitsPriority.contains(idLabel.$1) ? _primaryColor : Colors.grey[700],
  fontWeight: benefitsPriority.contains(idLabel.$1) ? FontWeight.bold : FontWeight.normal,
  ),
  backgroundColor: Colors.white,
  shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(20),
  side: BorderSide(
  color: benefitsPriority.contains(idLabel.$1) ? _primaryColor : Colors.grey[300]!
  ),
  ),
  onSelected: (s) => setState(() {
  if (s) {
  benefitsPriority.add(idLabel.$1);
  debugPrint('➕ Added benefit: ${idLabel.$1}');
  } else {
  benefitsPriority.remove(idLabel.$1);
  debugPrint('➖ Removed benefit: ${idLabel.$1}');
  }
  }),
  )).toList(),
  ),
  ],
  ),
  );

  // ---- Helpers --------------------------------------------------------------

  void _addRole() {
  final v = _newRoleCtrl.text.trim();
  if (v.isEmpty) return;
  if (!desiredRoles.contains(v)) setState(() => desiredRoles.add(v));
  _newRoleCtrl.clear();
  }

  void _addLocation() {
  final v = _newLocationCtrl.text.trim();
  if (v.isEmpty) return;
  if (!preferredLocations.contains(v)) setState(() => preferredLocations.add(v));
  _newLocationCtrl.clear();
  }
}

// ===== Common Widgets =====

class _SectionContainer extends StatelessWidget {
  const _SectionContainer({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label, required this.primaryColor});
  final String value;
  final String label;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: primaryColor)),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xFF1A1A1A)));
}

class _StyledChip extends StatelessWidget {
  const _StyledChip({required this.label, required this.onDeleted, required this.primaryColor});
  final String label;
  final VoidCallback onDeleted;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 13)),
      backgroundColor: const Color(0xFFEEF2FF),
      deleteIcon: Icon(Icons.close, size: 16, color: primaryColor),
      onDeleted: onDeleted,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide.none,
    );
  }
}

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({required this.controller, required this.hint, required this.onSubmitted});
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 16, color: Colors.grey[500]),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2)),
      ),
      onSubmitted: onSubmitted,
    );
  }
}

class _StyledDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  const _StyledDropdown({required this.value, required this.hint, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.toString(), overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.label,
    required this.valText,
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
    required this.primaryColor,
  });

  final String label;
  final String valText;
  final double min;
  final double max;
  final double value;
  final ValueChanged<double> onChanged;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final safeMin = min;
    final safeMax = max > min ? max : min + 1000;
    final divisions = ((safeMax - safeMin) / (safeMax - safeMin > 50000 ? 5000 : 500)).clamp(1, 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            Text(valText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryColor)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: primaryColor,
            inactiveTrackColor: primaryColor.withOpacity(0.2),
            thumbColor: primaryColor,
            overlayColor: primaryColor.withOpacity(0.1),
          ),
          child: Slider(
            value: value.clamp(safeMin, safeMax),
            min: safeMin,
            max: safeMax,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// Options
final List<(String, String)> _industryOptions = [
  ('technology', 'Technology & Software'),
  ('fintech', 'Financial Technology'),
  ('finance', 'Banking & Finance'),
  ('healthcare', 'Healthcare & Medical'),
  ('ecommerce', 'E-commerce & Retail'),
  ('education', 'Education & EdTech'),
  ('media', 'Media & Entertainment'),
  ('consulting', 'Consulting'),
  ('manufacturing', 'Manufacturing'),
  ('automotive', 'Automotive'),
  ('energy', 'Energy & Utilities'),
  ('real-estate', 'Real Estate'),
  ('transportation', 'Transportation & Logistics'),
  ('gaming', 'Gaming'),
  ('agriculture', 'Agriculture'),
  ('government', 'Government & Public Sector'),
  ('nonprofit', 'Non-profit'),
  ('telecommunications', 'Telecommunications'),
];

final List<(String, String)> _remoteOptions = [
  ('Yes', 'Yes'),
  ('HybridOnly', 'Hybrid Only'),
  ('No', 'No'),
];

final _workTypes = ['Office', 'Remote', 'Hybrid', 'Any'];
final _companySizes = ['Startup', 'Small', 'Medium', 'Large', 'Any'];

String _symbol(String? code) {
  switch (code) {
    case 'MYR': return 'RM';
    case 'SGD': return 'SGD';
    case 'USD': return 'USD' ;
    case 'EUR': return '€';
    default: return '';
  }
}

String _fmtMoney(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final idx = s.length - i;
    buf.write(s[i]);
    if (idx > 1 && idx % 3 == 1) buf.write(',');
  }
  return buf.toString();
}

String _formatSalaryRange({
  required String? currency,
  required String type,
  required int min,
  required int max,
}) {
  final sym = _symbol(currency);
  final unit = type == 'Monthly' ? '/month' : '/year';
  return '$sym${_fmtMoney(min)} - $sym${_fmtMoney(max)} $unit';
}

final List<(String, String)> _benefitOptions = [
  ('health', 'Health Insurance'),
  ('remote', 'Remote Work Support'),
  ('bonus', 'Performance Bonus'),
  ('flexible', 'Flexible Hours'),
  ('education', 'Education / Upskilling Support'),
  ('vacation', 'Extra Paid Vacation'),
  ('retirement', 'Retirement / EPF Contributions'),
  ('equipment', 'Company Laptop & Tools'),
  ('transport', 'Transport Allowance'),
  ('wellness', 'Wellness Program'),
  ('parental', 'Parental Leave'),
  ('meal', 'Meal Allowance'),
  ('insurance', 'Life Insurance'),
  ('stock', 'Stock Options / ESOP'),
];