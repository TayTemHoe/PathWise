import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// adjust imports to your paths
import 'package:path_wise/model/user_profile.dart';
import 'package:path_wise/viewmodel/profile_view_model.dart';

class EditPreferencesScreen extends StatelessWidget {
  const EditPreferencesScreen({super.key});

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
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7C4DFF), Color(0xFF6EA8FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Career Preferences',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),

      // 🔁 Rebuild only when preferences change inside the VM
      body: Selector<ProfileViewModel, Preferences?>(
        selector: (_, vm) {
          final prof = vm.profile ?? vm.user; // support both naming styles
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
  // local state
  late List<String> desiredRoles;
  late List<String> industries;
  late List<String> preferredLocations;
  late bool willingToRelocate;
  late String remoteAcceptance; // Yes / HybridOnly / No
  late List<String> workEnvironment; // keep one value as [value]
  late String companySize; // Startup / Small / Medium / Large / Any
  late String salaryType; // Monthly / Annual
  late int salaryMin;
  late int salaryMax;
  String? salaryCurrency;
  late List<String> benefitsPriority;

  final _newRoleCtrl = TextEditingController();
  final _newLocationCtrl = TextEditingController();
  bool _saving = false;

  void _loadFrom(Preferences p) {
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
    benefitsPriority = [...(p.salary?.benefitsPriority ?? const [])];
  }

  @override
  void initState() {
    super.initState();
    _loadFrom(widget.initial);
  }

  @override
  void didUpdateWidget(covariant _PreferencesForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // if VM fed a new preferences object, rehydrate local state
    if (oldWidget.initial.toFirestore().toString() !=
        widget.initial.toFirestore().toString()) {
      _loadFrom(widget.initial);
    }
  }

  @override
  void dispose() {
    _newRoleCtrl.dispose();
    _newLocationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summarySalary = _formatSalaryRange(
      currency: salaryCurrency,
      type: salaryType,
      min: salaryMin,
      max: salaryMax,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 380;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            // Compact, overflow-safe header using Wrap
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _StatPill(title: 'Target Roles', value: '${desiredRoles.length}'),
                      _StatPill(title: 'Preferred Industries', value: '${industries.length}'),
                    ],
                  ),
                  if (salaryMin > 0) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Salary Expectation: $summarySalary',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      softWrap: true,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            _jobPreferences(),
            _industryPreferences(),
            _locationPreferences(),
            _workEnvSection(),
            _salaryBenefitsSection(summarySalary),

            const SizedBox(height: 16),

            // Overflow-safe actions: Wrap on small screens, Row on wide
            if (isNarrow)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _saveBtn(),
                  _cancelBtn(),
                ],
              )
            else
              Row(
                children: [
                  Expanded(child: _saveBtn()),
                  const SizedBox(width: 12),
                  Expanded(child: _cancelBtn()),
                ],
              ),
          ],
        );
      },
    );
  }

  // ---- Sections -------------------------------------------------------------

  Widget _jobPreferences() => _Section(
    icon: Icons.track_changes_rounded,
    title: 'Job Preferences',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('Desired Job Titles *'),
        const SizedBox(height: 4),
        const Text(
          'Add the specific roles you’re interested in',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
        ),
        const SizedBox(height: 8),
        if (desiredRoles.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: desiredRoles
                .map((r) => InputChip(
              label: Text(r, overflow: TextOverflow.ellipsis),
              onDeleted: () => setState(() => desiredRoles.remove(r)),
            ))
                .toList(),
          ),
        const SizedBox(height: 8),
        // Use Flexible widths to prevent overflow
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newRoleCtrl,
                decoration: _input('Enter job title (e.g., Senior Developer)'),
                onSubmitted: (_) => _addRole(),
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 76, maxWidth: 96),
              child: ElevatedButton(onPressed: _addRole, child: const Text('Add')),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _industryPreferences() => _Section(
    icon: Icons.apartment_rounded,
    title: 'Industry Preferences *',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select the industries you’re interested in working in',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: -4,
          children: _industryOptions
              .map((idLabel) => FilterChip(
            label: Text(idLabel.$2),
            selected: industries.contains(idLabel.$1),
            onSelected: (s) => setState(() {
              if (s) {
                industries.add(idLabel.$1);
              } else {
                industries.remove(idLabel.$1);
              }
            }),
          ))
              .toList(),
        ),
        const SizedBox(height: 8),
        Text(
          'Selected: ${industries.length} '
              '${industries.length == 1 ? 'industry' : 'industries'}',
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
        ),
      ],
    ),
  );

  Widget _locationPreferences() => _Section(
    icon: Icons.place_outlined,
    title: 'Location Preferences *',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('Preferred Work Locations'),
        const SizedBox(height: 6),
        if (preferredLocations.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: preferredLocations
                .map((loc) => InputChip(
              label: Text(loc, overflow: TextOverflow.ellipsis),
              onDeleted: () => setState(() => preferredLocations.remove(loc)),
            ))
                .toList(),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newLocationCtrl,
                decoration: _input('Enter location (e.g., Kuala Lumpur)'),
                onSubmitted: (_) => _addLocation(),
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 76, maxWidth: 96),
              child: ElevatedButton(
                onPressed: _addLocation,
                child: const Text('Add'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: willingToRelocate,
          onChanged: (v) => setState(() => willingToRelocate = v),
          title: const Text('Willing to relocate for the right opportunity'),
        ),
        const SizedBox(height: 8),
        const _Label('Remote Work Preference'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _remoteOptions
              .map((opt) => ChoiceChip(
            label: Text(opt.$2),
            selected: remoteAcceptance == opt.$1,
            onSelected: (_) => setState(() => remoteAcceptance = opt.$1),
          ))
              .toList(),
        ),
      ],
    ),
  );

  Widget _workEnvSection() => _Section(
    icon: Icons.home_work_outlined,
    title: 'Work Environment',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('Work Type Preference'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _workTypes
              .map((w) => ChoiceChip(
            label: Text(w),
            selected: workEnvironment.isNotEmpty && workEnvironment.first == w,
            onSelected: (_) => setState(() => workEnvironment = [w]),
          ))
              .toList(),
        ),
        const SizedBox(height: 12),
        const _Label('Company Size Preference'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _companySizes
              .map((s) => ChoiceChip(
            label: Text(s),
            selected: companySize == s,
            onSelected: (_) => setState(() => companySize = s),
          ))
              .toList(),
        ),
      ],
    ),
  );

  Widget _salaryBenefitsSection(String summarySalary) => _Section(
    icon: Icons.attach_money_rounded,
    title: 'Salary & Benefits',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('Salary Expectations *'),
        const SizedBox(height: 6),

        // two dropdowns kept inside a Row with Expanded -> safe
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: salaryCurrency,
                items: const [
                  DropdownMenuItem(value: 'MYR', child: Text('MYR (Ringgit)')),
                  DropdownMenuItem(value: 'SGD', child: Text('SGD')),
                  DropdownMenuItem(value: 'USD', child: Text('USD')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                ],
                onChanged: (v) => setState(() => salaryCurrency = v),
                decoration: _input('Currency (optional)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: salaryType,
                items: const [
                  DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                  DropdownMenuItem(value: 'Annual', child: Text('Annual')),
                ],
                onChanged: (v) => setState(() => salaryType = v ?? 'Monthly'),
                decoration: _input('Type'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        _LabeledSlider(
          label: 'Minimum Salary: ${_symbol(salaryCurrency)}${_fmtMoney(salaryMin)}',
          min: salaryType == 'Monthly' ? 1000 : 12000,
          max: salaryType == 'Monthly' ? 50000 : 600000,
          step: salaryType == 'Monthly' ? 500 : 5000,
          value: salaryMin.toDouble(),
          onChanged: (v) {
            setState(() {
              salaryMin = v.round();
              if (salaryMax < salaryMin) salaryMax = salaryMin;
            });
          },
        ),
        const SizedBox(height: 8),
        _LabeledSlider(
          label: 'Preferred Maximum: ${_symbol(salaryCurrency)}${_fmtMoney(salaryMax)}',
          min: salaryMin.toDouble(),
          max: salaryType == 'Monthly' ? 100000 : 1200000,
          step: salaryType == 'Monthly' ? 500 : 5000,
          value: salaryMax.toDouble(),
          onChanged: (v) => setState(() => salaryMax = v.round()),
        ),
        const SizedBox(height: 8),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Your Salary Range\n$summarySalary',
            style: const TextStyle(color: Color(0xFF374151)),
            softWrap: true,
          ),
        ),
        const SizedBox(height: 16),

        const _Label('Important Benefits'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          runSpacing: -4,
          children: _benefitOptions
              .map((idLabel) => FilterChip(
            label: Text(idLabel.$2),
            selected: benefitsPriority.contains(idLabel.$1),
            onSelected: (s) => setState(() {
              if (s) {
                benefitsPriority.add(idLabel.$1);
              } else {
                benefitsPriority.remove(idLabel.$1);
              }
            }),
          ))
              .toList(),
        ),
        const SizedBox(height: 8),
        Text(
          'Selected: ${benefitsPriority.length} '
              '${benefitsPriority.length == 1 ? 'benefit' : 'benefits'}',
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
        ),
      ],
    ),
  );

  // ---- Actions --------------------------------------------------------------

  Widget _saveBtn() => ElevatedButton(
    onPressed: _saving
        ? null
        : () async {
      if (desiredRoles.isEmpty ||
          industries.isEmpty ||
          preferredLocations.isEmpty ||
          salaryMin <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please complete roles, industries, locations, and salary.',
            ),
          ),
        );
        return;
      }

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
          benefitsPriority: benefitsPriority,
        ),
      );

      setState(() => _saving = true);
      final ok =
      await context.read<ProfileViewModel>().updatePreferences(updated);
      if (!mounted) return;
      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Preferences saved' : 'Failed to save')),
      );
      if (ok) Navigator.pop(context);
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF7C4DFF),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: _saving
        ? const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    )
        : const Text('Save Career Preferences'),
  );

  Widget _cancelBtn() => OutlinedButton(
    onPressed: () => Navigator.pop(context),
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: const Text('Cancel'),
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

// ===== Small widgets & theme helpers ========================================

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.child});
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.w600));
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.title, required this.value});
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.label,
    required this.min,
    required this.max,
    required this.step,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double min;
  final double max;
  final double step;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final divs = ((max - min) / step).round().clamp(1, 1000);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, overflow: TextOverflow.ellipsis),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divs,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

InputDecoration _input(String hint) => const InputDecoration(
  filled: true,
  fillColor: Color(0xFFF9FAFB),
  border: OutlineInputBorder(
    borderSide: BorderSide(color: Color(0xFFE5E7EB)),
    borderRadius: BorderRadius.all(Radius.circular(10)),
  ),
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Color(0xFFE5E7EB)),
    borderRadius: BorderRadius.all(Radius.circular(10)),
  ),
  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
).copyWith(hintText: hint);

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

// Money helpers
String _symbol(String? code) {
  switch (code) {
    case 'MYR':
      return 'RM';
    case 'SGD':
      return 'S\$';
    case 'USD':
      return '\$';
    case 'EUR':
      return '€';
    default:
      return '';
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

// Benefits list
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
