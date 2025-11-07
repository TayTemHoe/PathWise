import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_wise/viewmodel/profile_view_model.dart';
import 'package:path_wise/model/user_profile.dart';

class EditEducationScreen extends StatelessWidget {
  const EditEducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, vm, _) {
        final eduCount = vm.education.length;

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
              'Education Background',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              // Stats pill (Education entries)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _StatPill(
                      title: 'Education Entry',
                      value: '$eduCount',
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section header + Add button
              Row(
                children: [
                  const Icon(Icons.school_outlined, size: 18),
                  const SizedBox(width: 8),
                  const Text('Education',
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showAddOrEditSheet(context, vm),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Education'),
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

              if (vm.education.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'No education added yet. Tap "Add Education" to create one.',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                )
              else
                ...vm.education
                    .map((e) => _EducationCard(
                  edu: e,
                  onEdit: () => _showAddOrEditSheet(context, vm, existing: e),
                  onDelete: () async {
                    final ok = await _confirmDelete(
                        context, e.institution ?? 'this entry');
                    if (!ok) return;
                    await vm.deleteEducation(e.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Education deleted')),
                    );
                  },
                ))
                    .toList(),

              const SizedBox(height: 20),

              // Tips (no certification section per your request)
              EducationTipsCard(),
            ],
          ),
        );
      },
    );
  }

  // Add/Edit bottom sheet
  static Future<void> _showAddOrEditSheet(
      BuildContext context,
      ProfileViewModel vm, {
        Education? existing,
      }) async {
    final formKey = GlobalKey<FormState>();

    final institutionCtrl =
    TextEditingController(text: existing?.institution ?? '');
    final fieldCtrl = TextEditingController(text: existing?.fieldOfStudy ?? '');
    final gpaCtrl = TextEditingController(text: existing?.gpa ?? '');
    final locationCtrl = TextEditingController(
      text: _joinCityCountry(existing?.city, existing?.country),
    );

    String? degreeLevel = existing?.degreeLevel;
    Timestamp? startDate = existing?.startDate;
    Timestamp? endDate = existing?.endDate;
    bool isCurrent = existing?.isCurrent ?? false;

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
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                existing == null
                                    ? 'Add Education'
                                    : 'Edit Education',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                              )
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Institution
                          const _FieldLabel('Institution Name *'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: institutionCtrl,
                            validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                            decoration: _inputDecoration(
                              hint: 'e.g., University of Malaya',
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Degree Level
                          const _FieldLabel('Degree Level *'),
                          const SizedBox(height: 6),
                          _Dropdown<String>(
                            value: degreeLevel,
                            hint: 'Select degree level',
                            items: const [
                              'HighSchool',
                              'Diploma',
                              'Bachelor',
                              'Master',
                              'PhD',
                              'Other',
                            ],
                            onChanged: (v) => setState(() => degreeLevel = v),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 14),

                          // Field of Study
                          const _FieldLabel('Field of Study *'),
                          const SizedBox(height: 6),
                          _Dropdown<String>(
                            // show current value in fieldCtrl if exists
                            value: _fieldOptions.contains(fieldCtrl.text)
                                ? fieldCtrl.text
                                : null,
                            hint: 'Select field of study',
                            items: _fieldOptions,
                            onChanged: (v) {
                              fieldCtrl.text = v ?? '';
                              setState(() {});
                            },
                            validator: (_) => (fieldCtrl.text.trim().isEmpty)
                                ? 'Required'
                                : null,
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
                                      onPick: (ts) =>
                                          setState(() => startDate = ts),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _FieldLabel('End Date *'),
                                    const SizedBox(height: 6),
                                    _DateButton(
                                      date: endDate,
                                      onPick: (ts) =>
                                          setState(() => endDate = ts),
                                      enabled: !isCurrent,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Current toggle
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
                              const Text('Currently studying here'),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // GPA
                          const _FieldLabel('Grade/CGPA (Optional)'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: gpaCtrl,
                            keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: _inputDecoration(
                              hint: 'e.g., 3.8',
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Location
                          const _FieldLabel('Location *'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: locationCtrl,
                            validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                            decoration: _inputDecoration(
                              hint: 'e.g., Kuala Lumpur, Malaysia',
                            ),
                          ),
                          const SizedBox(height: 18),

                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: vm.savingEducation
                                      ? null
                                      : () async {
                                    if (!formKey.currentState!
                                        .validate()) return;
                                    if (startDate == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                          content: Text(
                                              'Start Date is required')));
                                      return;
                                    }
                                    if (!isCurrent && endDate == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                          content: Text(
                                              'End Date is required (or mark as current)')));
                                      return;
                                    }

                                    final (city, country) =
                                    _splitCityCountry(
                                        locationCtrl.text.trim());

                                    final draft = Education(
                                      id: existing?.id ?? 'TEMP',
                                      institution:
                                      institutionCtrl.text.trim(),
                                      degreeLevel: degreeLevel,
                                      fieldOfStudy: fieldCtrl.text.trim(),
                                      startDate: startDate,
                                      endDate: isCurrent ? null : endDate,
                                      isCurrent: isCurrent,
                                      gpa: gpaCtrl.text.trim().isEmpty
                                          ? null
                                          : gpaCtrl.text.trim(),
                                      city: city,
                                      country: country,
                                      // order: keep existing order, else append to tail
                                      order: existing?.order ??
                                          (vm.education.length + 1),
                                    );

                                    bool ok;
                                    if (existing == null) {
                                      ok = await vm.addEducation(draft);
                                    } else {
                                      ok = await vm.saveEducation(draft);
                                    }

                                    if (!context.mounted) return;
                                    if (ok) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                          content: Text(existing ==
                                              null
                                              ? 'Education added'
                                              : 'Education updated')));
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                          content: Text(vm.error ??
                                              'Failed to save education')));
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7C4DFF),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: vm.savingEducation
                                      ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                      : const Text('Add Education'),
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
        title: const Text('Delete Education?'),
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

class EducationTipsCard extends StatelessWidget {
  const EducationTipsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // light blue
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)), // blue-200
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          // Header
          Row(
            children: [
              Icon(Icons.tips_and_updates_outlined,
                  color: Color(0xFF2563EB)), // blue-600
              SizedBox(width: 8),
              Text(
                'Education Tips',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E3A8A), // blue-900
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Tips
          _TipRow('Include all relevant educational qualifications'),
          _TipRow('Add certifications to showcase additional skills'),
          _TipRow('Keep your information current and accurate'),
          _TipRow('Include grades/honors when they strengthen your profile'),
          _TipRow('Professional certifications can be as valuable as degrees'),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•',
            style: TextStyle(
              fontSize: 16,
              height: 1.35,
              color: Color(0xFF1E40AF), // blue-800
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF1F2937), // gray-800
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ======= Widgets & helpers =======

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

class _EducationCard extends StatelessWidget {
  const _EducationCard({
    required this.edu,
    required this.onEdit,
    required this.onDelete,
  });

  final Education edu;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final loc = _joinCityCountry(edu.city, edu.country);
    final dateText = [
      _fmtDate(edu.startDate),
      edu.isCurrent == true ? 'Present' : _fmtDate(edu.endDate),
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
            // title + actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '${edu.degreeLevel ?? ''}${(edu.degreeLevel != null && (edu.fieldOfStudy ?? '').isNotEmpty) ? " in " : ""}${edu.fieldOfStudy ?? ''}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
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
            Text(
              edu.institution ?? '',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.lock_clock, size: 16, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 6),
                Text(dateText, style: const TextStyle(color: Color(0xFF6B7280))),
                const SizedBox(width: 16),
                const Icon(Icons.location_on_outlined,
                    size: 16, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    loc,
                    style: const TextStyle(color: Color(0xFF6B7280)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if ((edu.gpa ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Grade: ${edu.gpa}',
                  style: const TextStyle(color: Color(0xFF6B7280))),
            ],
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.w600));
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  final T? value;
  final String hint;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: _inputDecoration(hint: hint),
      items: items
          .map((e) => DropdownMenuItem<T>(
        value: e,
        child: Text(e.toString()),
      ))
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
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
        final initial = date?.toDate() ?? DateTime(now.year, now.month, now.day);
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime(1960),
          lastDate: DateTime(now.year + 6),
          initialDate: initial,
        );
        if (picked != null) {
          final ts = Timestamp.fromDate(DateTime(picked.year, picked.month, picked.day));
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

// Format dd/MM/yyyy
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

/// Common field-of-study options (extended)
const List<String> _fieldOptions = [
  // Computing & Tech
  'Computer Science',
  'Information Technology',
  'Software Engineering',
  'Data Science',
  'Artificial Intelligence',
  'Cybersecurity',
  'Information Systems',
  'Computer Engineering',
  'Network Engineering',
  'Human-Computer Interaction',
  'Game Development',
  'Cloud Computing',
  'Business Analytics',
  'Machine Learning',
  // Engineering
  'Electrical Engineering',
  'Mechanical Engineering',
  'Civil Engineering',
  'Chemical Engineering',
  'Industrial Engineering',
  'Mechatronics',
  'Biomedical Engineering',
  // Business & Management
  'Business Administration',
  'Finance',
  'Accounting',
  'Marketing',
  'Economics',
  'Entrepreneurship',
  'Supply Chain Management',
  'Human Resource Management',
  'International Business',
  // Sciences
  'Mathematics',
  'Statistics',
  'Physics',
  'Chemistry',
  'Biology',
  'Biotechnology',
  'Environmental Science',
  // Arts & Social Sciences
  'Psychology',
  'Communications',
  'Design',
  'Architecture',
  'Education',
  'Sociology',
  'Political Science',
  'Linguistics',
  'Media Studies',
  'Law',
  'Medicine',
  'Pharmacy',
  'Nursing',
];
