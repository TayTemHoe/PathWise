import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/model/user_profile.dart';
import 'package:path_wise/ViewModel/profile_view_model.dart';

class EditExperienceScreen extends StatelessWidget {
  const EditExperienceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, vm, _) {
        final total = vm.experience.length;

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
              'Work Experience',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              // little summary pill
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _StatPill(title: 'Work Experience', value: '$total'),
                    const Spacer(),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // header + add
              Row(
                children: [
                  const Flexible(
                    child: Text(
                      'Professional Experience',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddOrEditSheet(context, vm),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Experience'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEEF2FF),
                      foregroundColor: const Color(0xFF4338CA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12),

              if (vm.experience.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'No work experience yet. Tap "Add Experience" to create one.',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                )
              else
                ...vm.experience.map((exp) => _ExperienceCard(
                  exp: exp,
                  onEdit: () => _showAddOrEditSheet(context, vm, existing: exp),
                  onDelete: () async {
                    final ok = await _confirmDelete(
                        context, exp.jobTitle ?? 'this entry');
                    if (!ok) return;
                    await vm.deleteExperience(exp.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Experience deleted')),
                    );
                  },
                )),

              const SizedBox(height: 20),
              const _ExperienceTipsCard(),
            ],
          ),
        );
      },
    );
  }

  // ---------- ADD / EDIT SHEET ----------
  static Future<void> _showAddOrEditSheet(
      BuildContext context,
      ProfileViewModel vm, {
        Experience? existing,
      }) async {
    final formKey = GlobalKey<FormState>();

    final jobCtrl = TextEditingController(text: existing?.jobTitle ?? '');
    final companyCtrl = TextEditingController(text: existing?.company ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final locationCtrl =
    TextEditingController(text: _joinCityCountry(existing?.city, existing?.country));

    String? employmentType = _sanitizeDropdownValue(
      existing?.employmentType,
      _employmentTypes,
    );
    String? industry = _sanitizeDropdownValue(
      _normalizeIndustry(existing?.industry),
      _industries,
    );

    Timestamp? startDate = existing?.startDate;
    Timestamp? endDate = existing?.endDate;
    bool isCurrent = existing?.isCurrent ?? false;

    // Achievements: 3-box input -> combined into single string "title | metric | impact"
    final achTitleCtrl = TextEditingController();
    final achMetricCtrl = TextEditingController();
    final achImpactCtrl = TextEditingController();
    // if existing has one combined description, try to split to prefill first field only
    if ((existing?.achievements?.description ?? '').isNotEmpty) {
      final parts = existing!.achievements!.description!.split('|').map((e) => e.trim()).toList();
      if (parts.isNotEmpty) achTitleCtrl.text = parts[0];
      if (parts.length > 1) achMetricCtrl.text = parts[1];
      if (parts.length > 2) achImpactCtrl.text = parts[2];
    }
    final List<String> skillsUsed = [...(existing?.achievements?.skillsUsed ?? [])];
    final skillInputCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final viewInsets = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  existing == null
                                      ? 'Add Work Experience'
                                      : 'Edit Work Experience',
                                  style: const TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.w800),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                              )
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Job Title
                          const _FieldLabel('Job Title *'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: jobCtrl,
                            validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                            decoration: _inputDecoration(hint: 'e.g., Frontend Developer'),
                          ),
                          const SizedBox(height: 14),

                          // Company
                          const _FieldLabel('Company Name *'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: companyCtrl,
                            validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                            decoration:
                            _inputDecoration(hint: 'e.g., Tech Solutions Sdn Bhd'),
                          ),
                          const SizedBox(height: 14),

                          // Emp Type + Industry (sanitized values)
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _FieldLabel('Employment Type *'),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<String>(
                                      value: _employmentTypes.contains(employmentType)
                                          ? employmentType
                                          : null,
                                      items: _employmentTypes
                                          .map((e) =>
                                          DropdownMenuItem(value: e, child: Text(e)))
                                          .toList(),
                                      onChanged: (v) => setState(() => employmentType = v),
                                      validator: (v) =>
                                      (v == null || v.isEmpty) ? 'Required' : null,
                                      decoration: _inputDecoration(hint: 'Select type'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _FieldLabel('Industry *'),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<String>(
                                      value: _industries.contains(industry) ? industry : null,
                                      items: _industries
                                          .map((e) =>
                                          DropdownMenuItem(value: e, child: Text(e)))
                                          .toList(),
                                      onChanged: (v) => setState(() => industry = v),
                                      validator: (v) =>
                                      (v == null || v.isEmpty) ? 'Required' : null,
                                      decoration:
                                      _inputDecoration(hint: 'Select industry'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Dates
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _FieldLabel('Start Date *'),
                                    const SizedBox(height: 6),
                                    _DateButton(
                                      date: startDate,
                                      onPick: (ts) => setState(() => startDate = ts),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _FieldLabel('End Date'),
                                    const SizedBox(height: 6),
                                    _DateButton(
                                      date: endDate,
                                      enabled: !isCurrent,
                                      onPick: (ts) => setState(() => endDate = ts),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Switch(
                                value: isCurrent,
                                onChanged: (v) {
                                  setState(() {
                                    isCurrent = v;
                                    if (isCurrent) endDate = null;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              const Flexible(
                                child: Text(
                                  'Currently working here',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Location
                          const _FieldLabel('Location *'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: locationCtrl,
                            validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                            decoration:
                            _inputDecoration(hint: 'e.g., Kuala Lumpur, Malaysia'),
                          ),
                          const SizedBox(height: 14),

                          // Job Description -> experience.description
                          const _FieldLabel('Job Description *'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: descCtrl,
                            maxLines: 4,
                            validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                            decoration: _inputDecoration(
                                hint:
                                'Describe your role, responsibilities, and impact...'),
                          ),
                          const SizedBox(height: 16),

                          // Key Achievements (3 boxes -> combined with " | ")
                          const _FieldLabel('Key Achievements (Optional)'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: achTitleCtrl,
                            decoration: _inputDecoration(
                                hint: 'Title/What (e.g., Improved app performance)'),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: achMetricCtrl,
                            decoration: _inputDecoration(
                                hint: 'Metric (e.g., +40% faster load times)'),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: achImpactCtrl,
                            decoration: _inputDecoration(
                                hint: 'Business impact (optional)'),
                          ),
                          const SizedBox(height: 12),

                          // Skills used chips
                          const Text('Skills Used/Developed',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          if (skillsUsed.isNotEmpty)
                            Wrap(
                              spacing: 6,
                              runSpacing: -8,
                              children: skillsUsed
                                  .map((s) => Chip(
                                label: Text(s),
                                deleteIcon:
                                const Icon(Icons.close, size: 18),
                                onDeleted: () {
                                  setState(() => skillsUsed.remove(s));
                                },
                              ))
                                  .toList(),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: skillInputCtrl,
                                  decoration: _inputDecoration(
                                    hint: 'Enter a skill (e.g., React)',
                                  ),
                                  onSubmitted: (_) {
                                    final v = skillInputCtrl.text.trim();
                                    if (v.isEmpty) return;
                                    setState(() {
                                      skillsUsed.add(v);
                                      skillInputCtrl.clear();
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  final v = skillInputCtrl.text.trim();
                                  if (v.isEmpty) return;
                                  setState(() {
                                    skillsUsed.add(v);
                                    skillInputCtrl.clear();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7C4DFF),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Add'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (!formKey.currentState!.validate()) return;
                                    if (startDate == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('Start Date is required')),
                                      );
                                      return;
                                    }

                                    final (city, country) =
                                    _splitCityCountry(locationCtrl.text.trim());

                                    // combine 3 achievement inputs → single description (optional)
                                    final achParts = [
                                      achTitleCtrl.text.trim(),
                                      achMetricCtrl.text.trim(),
                                      achImpactCtrl.text.trim(),
                                    ].where((e) => e.isNotEmpty).toList();
                                    final combinedAch =
                                    achParts.isEmpty ? null : achParts.join(' | ');

                                    final draft = Experience(
                                      id: existing?.id ?? 'TEMP',
                                      jobTitle: jobCtrl.text.trim(),
                                      company: companyCtrl.text.trim(),
                                      employmentType: employmentType,
                                      industry: industry,
                                      startDate: startDate,
                                      endDate: isCurrent ? null : endDate,
                                      isCurrent: isCurrent,
                                      city: city,
                                      country: country,
                                      // IMPORTANT: job description -> experience.description
                                      description: descCtrl.text.trim(),
                                      achievements: (combinedAch == null &&
                                          skillsUsed.isEmpty)
                                          ? null
                                          : ExpAchievements(
                                        description: combinedAch,
                                        skillsUsed:
                                        skillsUsed.isEmpty ? null : skillsUsed,
                                      ),
                                      order: existing?.order ??
                                          (vm.experience.length + 1),
                                    );

                                    bool ok;
                                    if (existing == null) {
                                      ok = await vm.addExperience(draft);
                                    } else {
                                      ok = await vm.saveExperience(draft);
                                    }

                                    if (!context.mounted) return;
                                    if (ok) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(existing == null
                                                ? 'Experience added'
                                                : 'Experience updated')),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(vm.error ??
                                              'Failed to save experience'),
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7C4DFF),
                                    foregroundColor: Colors.white,
                                    padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Save Experience'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<bool> _confirmDelete(BuildContext c, String title) async {
    return await showDialog<bool>(
      context: c,
      builder: (c) => AlertDialog(
        title: const Text('Delete Experience?'),
        content: Text('Remove "$title" from your profile?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    ) ??
        false;
  }
}

// ---------- Cards, helpers, constants ----------

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
        children: [
          Text(value,
              style:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({
    required this.exp,
    required this.onEdit,
    required this.onDelete,
  });

  final Experience exp;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final loc = _joinCityCountry(exp.city, exp.country);
    final dateText = [
      _fmtDate(exp.startDate),
      exp.isCurrent == true ? 'Present' : _fmtDate(exp.endDate),
    ].where((e) => e != null && e.isNotEmpty).join(' – ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: -6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        exp.jobTitle ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      if (exp.isCurrent == true)
                        _Badge(text: 'Current', bg: 0xFFE8FFF3, fg: 0xFF059669),
                      if ((exp.employmentType ?? '').isNotEmpty)
                        _Badge(text: exp.employmentType!, bg: 0xFFEFF6FF, fg: 0xFF2563EB),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit',
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  tooltip: 'Delete',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              exp.company ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_clock, size: 16, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 6),
                    Text(dateText, style: const TextStyle(color: Color(0xFF6B7280))),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 16, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 4),
                    Text(loc, style: const TextStyle(color: Color(0xFF6B7280))),
                  ],
                ),
                if ((exp.industry ?? '').isNotEmpty)
                  _Badge(text: _normalizeIndustry(exp.industry)!, bg: 0xFFF3E8FF, fg: 0xFF7C3AED),
              ],
            ),
            if ((exp.description ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(exp.description!,
                  style: const TextStyle(color: Color(0xFF374151), height: 1.35)),
            ],
            if (exp.achievements != null &&
                ((exp.achievements!.description ?? '').isNotEmpty ||
                    (exp.achievements!.skillsUsed?.isNotEmpty ?? false)))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Key Achievements',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    if ((exp.achievements!.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(exp.achievements!.description!,
                          style: const TextStyle(color: Color(0xFF111827))),
                    ],
                    if (exp.achievements!.skillsUsed?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: exp.achievements!.skillsUsed!
                            .map((s) => Chip(label: Text(s)))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.bg, required this.fg});
  final String text;
  final int bg;
  final int fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Color(bg),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Color(fg),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ExperienceTipsCard extends StatelessWidget {
  const _ExperienceTipsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💼 Experience Tips',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))),
          SizedBox(height: 8),
          _Tip('• Include all relevant work experience, including internships'),
          _Tip('• Focus on achievements rather than just responsibilities'),
          _Tip('• Quantify your impact with numbers and metrics when possible'),
          _Tip('• List skills that are relevant to your target roles'),
          _Tip('• Keep descriptions concise but impactful'),
          _Tip('• Order experiences by start date (most recent first)'),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(text, style: const TextStyle(color: Color(0xFF1F2937))),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.w600));
}

InputDecoration _inputDecoration({String? hint}) => const InputDecoration(
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

// --- constants & helpers ---

const _employmentTypes = <String>[
  'Full-time',
  'Part-time',
  'Contract',
  'Internship',
  'Freelance',
  'Temporary',
  'Volunteer',
];

/// include both "Information Technology" and short "IT" to avoid value mismatch
const _industries = <String>[
  'Technology',
  'Information Technology', // long form
  'IT',                      // alias value that might exist in DB
  'Finance',
  'Healthcare',
  'Education',
  'Manufacturing',
  'Retail',
  'Consulting',
  'Media & Communications',
  'Real Estate',
  'Transportation',
  'Energy',
  'Government',
  'Non-profit',
  'Agriculture',
  'Construction',
  'Hospitality',
  'Logistics',
  'Telecommunications',
];

String? _sanitizeDropdownValue(String? v, List<String> items) {
  if (v == null) return null;
  return items.contains(v) ? v : null;
}

/// normalize common aliases (e.g. "IT" -> "Information Technology")
String? _normalizeIndustry(String? v) {
  if (v == null) return null;
  final t = v.trim();
  if (t.toLowerCase() == 'it') return 'Information Technology';
  return t;
}

String _fmtDate(Timestamp? ts) {
  if (ts == null) return '';
  final d = ts.toDate();
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  final yyyy = d.year.toString();
  return '$dd/$mm/$yyyy';
}

(String, String) _splitCityCountry(String? text) {
  final t = (text ?? '').trim();
  if (t.isEmpty) return ('', '');
  final parts = t.split(',');
  final city = parts.isNotEmpty ? parts.first.trim() : '';
  final country = parts.length > 1 ? parts.sublist(1).join(',').trim() : '';
  return (city, country);
}

String _joinCityCountry(String? city, String? country) {
  final a = (city ?? '').trim();
  final b = (country ?? '').trim();
  if (a.isEmpty && b.isEmpty) return '';
  if (a.isEmpty) return b;
  if (b.isEmpty) return a;
  return '$a, $b';
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.date,
    required this.onPick,
    this.enabled = true,
  });

  final Timestamp? date;
  final ValueChanged<Timestamp?> onPick;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: !enabled
          ? null
          : () async {
        final now = DateTime.now();
        final initial =
            date?.toDate() ?? DateTime(now.year, now.month, now.day);
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime(1960),
          lastDate: DateTime(now.year + 6),
          initialDate: initial,
        );
        if (picked != null) {
          final ts = Timestamp.fromDate(
              DateTime(picked.year, picked.month, picked.day));
          onPick(ts);
        }
      },
      child: Container(
        height: 48,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(
          date == null ? 'dd/mm/yyyy' : _fmtDate(date),
          style: TextStyle(
            color: enabled ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }
}
