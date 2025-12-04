import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_wise/viewModel/profile_view_model.dart';
import 'package:path_wise/model/user_profile.dart';

class EditEducationScreen extends StatelessWidget {
  const EditEducationScreen({super.key});

  // KYYAP Style Constants
  final Color _primaryColor = const Color(0xFF6C63FF);
  final Color _textColor = const Color(0xFF1A1A1A);
  final Color _backgroundColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, vm, _) {
        final eduCount = vm.education.length;

        return Scaffold(
          backgroundColor: _backgroundColor,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: _backgroundColor,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Education Background',
              style: TextStyle(
                color: _textColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          body: ListView(
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$eduCount',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: _primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Education Entries',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.school, color: _primaryColor, size: 24),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Education',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddOrEditSheet(context, vm),
                    icon: Icon(Icons.add_circle_outline, color: _primaryColor, size: 20),
                    label: Text(
                      'Add New',
                      style: TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),

              if (vm.education.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB), style: BorderStyle.solid),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.school_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'No education history yet',
                        style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              else
                ...vm.education.map((e) => _EducationCard(
                  edu: e,
                  primaryColor: _primaryColor,
                  onEdit: () => _showAddOrEditSheet(context, vm, existing: e),
                  onDelete: () async {
                    final ok = await _confirmDelete(context, e.institution ?? 'this entry', _primaryColor);
                    if (!ok) return;
                    await vm.deleteEducation(e.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Education entry deleted'),
                        backgroundColor: Color(0xFFD63031),
                      ),
                    );
                  },
                )),

              const SizedBox(height: 32),

              // Tips Section
              _EducationTipsCard(primaryColor: _primaryColor),
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

    // Controllers
    final institutionCtrl = TextEditingController(text: existing?.institution ?? '');
    final fieldCtrl = TextEditingController(text: existing?.fieldOfStudy ?? '');
    final gpaCtrl = TextEditingController(text: existing?.gpa ?? '');
    final locationCtrl = TextEditingController(
      text: _joinCityCountry(existing?.city, existing?.country),
    );

    // Initial State Values for dirty checking
    final initialInstitution = existing?.institution ?? '';
    final initialField = existing?.fieldOfStudy ?? '';
    final initialGpa = existing?.gpa ?? '';
    final initialLocation = _joinCityCountry(existing?.city, existing?.country);
    final initialDegree = existing?.degreeLevel;
    final initialStartDate = existing?.startDate;
    final initialEndDate = existing?.endDate;
    final initialIsCurrent = existing?.isCurrent ?? false;

    String? degreeLevel = existing?.degreeLevel;
    Timestamp? startDate = existing?.startDate;
    Timestamp? endDate = existing?.endDate;
    bool isCurrent = existing?.isCurrent ?? false;

    // Helper to check for unsaved changes
    bool hasUnsavedChanges() {
      if (institutionCtrl.text.trim() != initialInstitution) return true;
      if (fieldCtrl.text.trim() != initialField) return true;
      if (gpaCtrl.text.trim() != initialGpa) return true;
      if (locationCtrl.text.trim() != initialLocation) return true;
      if (degreeLevel != initialDegree) return true;
      if (startDate != initialStartDate) return true;
      if (endDate != initialEndDate) return true;
      if (isCurrent != initialIsCurrent) return true;
      return false;
    }

    // ✅ FIXED: Added flag to prevent duplicate saves
    bool isSaving = false;

    // Save Function logic
    Future<bool> handleSave() async {
      // ✅ Prevent duplicate saves
      if (isSaving) return false;

      if (!formKey.currentState!.validate()) return false;

      // ✅ Validate Start Date
      if (startDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Start Date is required'))
        );
        return false;
      }

      // ✅ Validate End Date if not current
      if (!isCurrent && endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('End Date is required (or mark as current)'))
        );
        return false;
      }

      // ✅ Validate Date Logic
      if (!isCurrent && endDate != null && startDate != null) {
        if (endDate!.toDate().isBefore(startDate!.toDate())) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('End Date must be after Start Date'))
          );
          return false;
        }
      }

      isSaving = true; // Set flag

      final (city, country) = _splitCityCountry(locationCtrl.text.trim());

      final draft = Education(
        id: existing?.id ?? 'TEMP',
        institution: institutionCtrl.text.trim(),
        degreeLevel: degreeLevel,
        fieldOfStudy: fieldCtrl.text.trim(),
        startDate: startDate,
        endDate: isCurrent ? null : endDate,
        isCurrent: isCurrent,
        gpa: gpaCtrl.text.trim().isEmpty ? null : gpaCtrl.text.trim(),
        city: city,
        country: country,
        order: existing?.order ?? (vm.education.length + 1),
      );

      bool ok;
      if (existing == null) {
        ok = await vm.addEducation(draft);
      } else {
        ok = await vm.saveEducation(draft);
      }

      isSaving = false; // Reset flag

      if (ok) {
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(vm.error ?? 'Failed to save education')),
        );
        return false;
      }
    }

    // Unsaved Changes Dialog
    Future<void> showUnsavedDialog() async {
      await showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismiss by tapping outside
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
                Navigator.pop(dialogContext); // Close dialog
                Navigator.pop(context); // Close sheet
              },
              child: const Text('Discard', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Close dialog first
                final success = await handleSave();
                if (success && context.mounted) {
                  Navigator.pop(context); // Close sheet on success
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(existing == null ? 'Education added successfully' : 'Education updated successfully'),
                      backgroundColor: const Color(0xFF00B894),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isDismissible: false, // Prevent dismiss by tapping outside
      enableDrag: false, // Disable drag to force using close button
      builder: (context) {
        return PopScope(
          canPop: false, // Disable default pop
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            if (hasUnsavedChanges()) {
              await showUnsavedDialog();
            } else {
              Navigator.pop(context);
            }
          },
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: StatefulBuilder(
                        builder: (context, setState) {
                          return Form(
                            key: formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      existing == null ? 'Add Education' : 'Edit Education',
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A1A1A)
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () async {
                                        if (hasUnsavedChanges()) {
                                          await showUnsavedDialog();
                                        } else {
                                          Navigator.pop(context);
                                        }
                                      },
                                      icon: const Icon(Icons.close, color: Colors.grey),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Institution
                                _StyledField(
                                  label: 'Institution Name *',
                                  controller: institutionCtrl,
                                  hint: 'e.g., University of Malaya',
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Institution name is required' : null,
                                ),
                                const SizedBox(height: 20),

                                // Degree Level
                                _StyledDropdown<String>(
                                  label: 'Degree Level *',
                                  value: degreeLevel,
                                  hint: 'Select degree level',
                                  items: const ['HighSchool', 'Diploma', 'Bachelor', 'Master', 'PhD', 'Other'],
                                  onChanged: (v) => setState(() => degreeLevel = v),
                                  validator: (v) => (v == null || v.isEmpty) ? 'Degree level is required' : null,
                                ),
                                const SizedBox(height: 20),

                                // Field of Study
                                _StyledDropdown<String>(
                                  label: 'Field of Study *',
                                  value: _fieldOptions.contains(fieldCtrl.text) ? fieldCtrl.text : null,
                                  hint: 'Select field of study',
                                  items: _fieldOptions,
                                  onChanged: (v) {
                                    fieldCtrl.text = v ?? '';
                                    setState(() {});
                                  },
                                  validator: (_) => (fieldCtrl.text.trim().isEmpty) ? 'Field of study is required' : null,
                                ),
                                const SizedBox(height: 20),

                                // Dates
                                Row(
                                  children: [
                                    Expanded(
                                      child: _StyledDateField(
                                        label: 'Start Date *',
                                        date: startDate,
                                        onPick: (ts) => setState(() => startDate = ts),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _StyledDateField(
                                        label: 'End Date *',
                                        date: endDate,
                                        enabled: !isCurrent,
                                        onPick: (ts) => setState(() => endDate = ts),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Current Switch
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text(
                                    'Currently studying here',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                  activeColor: const Color(0xFF6C63FF),
                                  value: isCurrent,
                                  onChanged: (v) {
                                    setState(() {
                                      isCurrent = v;
                                      if (isCurrent) endDate = null;
                                    });
                                  },
                                ),

                                const SizedBox(height: 12),

                                // GPA
                                _StyledField(
                                  label: 'Grade/CGPA (Optional)',
                                  controller: gpaCtrl,
                                  hint: 'e.g., 3.8',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                                const SizedBox(height: 20),

                                // Location
                                _StyledField(
                                  label: 'Location *',
                                  controller: locationCtrl,
                                  hint: 'e.g., Kuala Lumpur, Malaysia',
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Location is required' : null,
                                  prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.grey),
                                ),
                                const SizedBox(height: 32),

                                // Action Buttons
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: (vm.savingEducation || isSaving)
                                        ? null
                                        : () async {
                                      final success = await handleSave();
                                      if (success && context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(existing == null ? 'Education added successfully' : 'Education updated successfully'),
                                            backgroundColor: const Color(0xFF00B894),
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6C63FF),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      disabledBackgroundColor: Colors.grey[300],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: (vm.savingEducation || isSaving)
                                        ? const SizedBox(
                                      width: 24, height: 24,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                        : const Text(
                                      'Save Education',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: OutlinedButton(
                                    onPressed: (vm.savingEducation || isSaving) ? null : () async {
                                      if (hasUnsavedChanges()) {
                                        await showUnsavedDialog();
                                      } else {
                                        Navigator.pop(context);
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.grey[300]!),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF1A1A1A))),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<bool> _confirmDelete(BuildContext c, String title, Color primary) async {
    return await showDialog<bool>(
      context: c,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Education?'),
        content: Text('Remove "$title" from your profile? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD63031),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }
}

// ======= KYYAP Styled Components =======

class _EducationCard extends StatelessWidget {
  const _EducationCard({
    required this.edu,
    required this.onEdit,
    required this.onDelete,
    required this.primaryColor,
  });

  final Education edu;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final loc = _joinCityCountry(edu.city, edu.country);
    final dateText = [
      _fmtDate(edu.startDate),
      edu.isCurrent == true ? 'Present' : _fmtDate(edu.endDate),
    ].where((e) => e != null && e.isNotEmpty).join(' – ');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${edu.degreeLevel ?? ''}${(edu.degreeLevel != null && (edu.fieldOfStudy ?? '').isNotEmpty) ? " in " : ""}${edu.fieldOfStudy ?? ''}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        edu.institution ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6C63FF),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18, color: Color(0xFF6B7280)),
                          SizedBox(width: 12),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Color(0xFFD63031)),
                          SizedBox(width: 12),
                          Text('Delete', style: TextStyle(color: Color(0xFFD63031))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey[100]),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(dateText, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    loc,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if ((edu.gpa ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.grade, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text('CGPA: ${edu.gpa}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StyledDropdown<T> extends StatelessWidget {
  const _StyledDropdown({
    required this.label,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final T? value;
  final String hint;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          decoration: _inputDecoration(hint: hint),
          items: items.map((e) =>
              DropdownMenuItem<T>(
                value: e,
                child: Text(e.toString(), style: const TextStyle(
                    fontSize: 16, color: Color(0xFF1A1A1A))),
              )).toList(),
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }
}

class _StyledField extends StatelessWidget {
  const _StyledField({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.validator,
    this.prefixIcon,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A1A)),
          decoration: _inputDecoration(hint: hint, prefixIcon: prefixIcon),
        ),
      ],
    );
  }
}

class _StyledDateField extends StatelessWidget {
  const _StyledDateField({
    required this.label,
    required this.date,
    required this.onPick,
    this.enabled = true,
  });

  final String label;
  final Timestamp? date;
  final ValueChanged<Timestamp?> onPick;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: enabled ? const Color(0xFF1A1A1A) : Colors.grey[400],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
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
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(primary: Color(0xFF6C63FF)),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              final ts = Timestamp.fromDate(DateTime(picked.year, picked.month, picked.day));
              onPick(ts);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: IgnorePointer(
            child: TextFormField(
              controller: TextEditingController(text: _fmtDate(date)),
              style: TextStyle(
                  fontSize: 16,
                  color: enabled ? const Color(0xFF1A1A1A) : Colors.grey[400]
              ),
              decoration: _inputDecoration(
                hint: 'DD/MM/YYYY',
                prefixIcon: Icon(Icons.calendar_today, color: enabled ? Colors.grey : Colors.grey[300]),
              ).copyWith(
                filled: true,
                fillColor: enabled ? const Color(0xFFF9FAFB) : Colors.grey[100],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EducationTipsCard extends StatelessWidget {
  const _EducationTipsCard({required this.primaryColor});
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: primaryColor, size: 22),
              const SizedBox(width: 8),
              Text(
                'Pro Tips',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _TipRow('List your most recent degree first.'),
          const _TipRow('Include relevant coursework if you are a fresh graduate.'),
          const _TipRow('Keep your information accurate and up-to-date.'),
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
          const Text('•', style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.4)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: Color(0xFF4B5563), height: 1.4)),
          ),
        ],
      ),
    );
  }
}

// Helpers

InputDecoration _inputDecoration({String? hint, Widget? prefixIcon}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontSize: 16, color: Colors.grey[500]),
    prefixIcon: prefixIcon,
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
  );
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

// Data Options
const List<String> _fieldOptions = [
  'Computer Science', 'Information Technology', 'Software Engineering',
  'Data Science', 'Artificial Intelligence', 'Cybersecurity',
  'Business Administration', 'Finance', 'Accounting', 'Marketing',
  'Electrical Engineering', 'Mechanical Engineering', 'Civil Engineering',
  'Mathematics', 'Physics', 'Chemistry', 'Biology',
  'Psychology', 'Design', 'Law', 'Medicine', 'Nursing',
];