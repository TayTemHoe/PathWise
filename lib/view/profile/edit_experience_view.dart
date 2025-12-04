import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/model/user_profile.dart';
import 'package:path_wise/viewModel/profile_view_model.dart';

import '../../utils/app_color.dart';

class EditExperienceScreen extends StatelessWidget {
  const EditExperienceScreen({super.key});

  // KYYAP Style Constants
  final Color _primaryColor = const Color(0xFF6C63FF);
  final Color _textColor = const Color(0xFF1A1A1A);
  final Color _backgroundColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, vm, _) {
        final total = vm.experience.length;

        return Scaffold(
          backgroundColor: _backgroundColor,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: _backgroundColor,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(
                  Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Work Experience',
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
                          '$total',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: _primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Experiences Listed',
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
                      child: Icon(Icons.work, color: _primaryColor, size: 24),
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
                    'Professional History',
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

              if (vm.experience.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.work_outline, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'No work experience added yet',
                        style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              else
                ...vm.experience.map((exp) => _ExperienceCard(
                  exp: exp,
                  primaryColor: _primaryColor,
                  onEdit: () => _showAddOrEditSheet(context, vm, existing: exp),
                  onDelete: () async {
                    final ok = await _confirmDelete(
                        context, exp.jobTitle ?? 'this entry', _primaryColor);
                    if (!ok) return;
                    await vm.deleteExperience(exp.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Experience deleted'),
                        backgroundColor: Color(0xFFD63031),
                      ),
                    );
                  },
                )),

              const SizedBox(height: 32),
              _ExperienceTipsCard(primaryColor: _primaryColor),
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

    // Controllers
    final jobCtrl = TextEditingController(text: existing?.jobTitle ?? '');
    final companyCtrl = TextEditingController(text: existing?.company ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final locationCtrl = TextEditingController(text: _joinCityCountry(existing?.city, existing?.country));

    // Achievement Logic
    final achTitleCtrl = TextEditingController();
    final achMetricCtrl = TextEditingController();
    final achImpactCtrl = TextEditingController();
    // Parse existing achievements description
    if ((existing?.achievements?.description ?? '').isNotEmpty) {
      final parts = existing!.achievements!.description!.split('|').map((e) => e.trim()).toList();
      if (parts.isNotEmpty) achTitleCtrl.text = parts[0];
      if (parts.length > 1) achMetricCtrl.text = parts[1];
      if (parts.length > 2) achImpactCtrl.text = parts[2];
    }

    final List<String> skillsUsed = [...(existing?.achievements?.skillsUsed ?? [])];
    final skillInputCtrl = TextEditingController();

    // Dropdowns
    String? employmentType = _sanitizeDropdownValue(existing?.employmentType, _employmentTypes);
    String? industry = _sanitizeDropdownValue(_normalizeIndustry(existing?.industry), _industries);

    // Dates
    Timestamp? startDate = existing?.startDate;
    Timestamp? endDate = existing?.endDate;
    bool isCurrent = existing?.isCurrent ?? false;

    // --- Dirty Checking Logic ---
    final initialJob = existing?.jobTitle ?? '';
    final initialCompany = existing?.company ?? '';
    final initialDesc = existing?.description ?? '';
    final initialLoc = _joinCityCountry(existing?.city, existing?.country);
    final initialType = existing?.employmentType;
    final initialIndustry = _normalizeIndustry(existing?.industry);
    final initialStart = existing?.startDate;
    final initialEnd = existing?.endDate;
    final initialIsCurrent = existing?.isCurrent ?? false;
    // Achievements initial state
    final initialAchTitle = achTitleCtrl.text;
    final initialAchMetric = achMetricCtrl.text;
    final initialAchImpact = achImpactCtrl.text;
    final initialSkillsLength = skillsUsed.length;

    bool hasUnsavedChanges() {
      if (jobCtrl.text != initialJob) return true;
      if (companyCtrl.text != initialCompany) return true;
      if (descCtrl.text != initialDesc) return true;
      if (locationCtrl.text != initialLoc) return true;
      if (employmentType != initialType) return true;
      if (industry != initialIndustry) return true;
      if (startDate != initialStart) return true;
      if (endDate != initialEnd) return true;
      if (isCurrent != initialIsCurrent) return true;
      if (achTitleCtrl.text != initialAchTitle) return true;
      if (achMetricCtrl.text != initialAchMetric) return true;
      if (achImpactCtrl.text != initialAchImpact) return true;
      if (skillsUsed.length != initialSkillsLength) return true;
      return false;
    }

    // Save Logic
    Future<bool> handleSave() async {
      if (!formKey.currentState!.validate()) return false;
      if (startDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Start Date is required')),
        );
        return false;
      }

      final (city, country) = _splitCityCountry(locationCtrl.text.trim());

      final achParts = [
        achTitleCtrl.text.trim(),
        achMetricCtrl.text.trim(),
        achImpactCtrl.text.trim(),
      ].where((e) => e.isNotEmpty).toList();
      final combinedAch = achParts.isEmpty ? null : achParts.join(' | ');

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
        description: descCtrl.text.trim(),
        achievements: (combinedAch == null && skillsUsed.isEmpty)
            ? null
            : ExpAchievements(
          description: combinedAch,
          skillsUsed: skillsUsed.isEmpty ? null : skillsUsed,
        ),
        order: existing?.order ?? (vm.experience.length + 1),
      );

      bool ok;
      if (existing == null) {
        ok = await vm.addExperience(draft);
      } else {
        ok = await vm.saveExperience(draft);
      }

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(vm.error ?? 'Failed to save experience')),
        );
      }
      return ok;
    }

    // Unsaved Changes Dialog
    Future<void> showUnsavedDialog() async {
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
                Navigator.pop(dialogContext); // Close dialog
                Navigator.pop(context); // Close sheet (discard)
              },
              child: const Text('Continue', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Close dialog
                final success = await handleSave();
                if (success && context.mounted) {
                  Navigator.pop(context); // Close sheet (saved)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(existing == null ? 'Experience added' : 'Experience updated'),
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
      enableDrag: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) async {
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
                                    Flexible(
                                      child: Text(
                                        existing == null ? 'Add Work Experience' : 'Edit Work Experience',
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1A1A1A)
                                        ),
                                        overflow: TextOverflow.ellipsis,
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

                                // Job Title
                                _StyledField(
                                  label: 'Job Title *',
                                  controller: jobCtrl,
                                  hint: 'e.g., Frontend Developer',
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                                const SizedBox(height: 20),

                                // Company
                                _StyledField(
                                  label: 'Company Name *',
                                  controller: companyCtrl,
                                  hint: 'e.g., Tech Solutions Sdn Bhd',
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                  prefixIcon: const Icon(Icons.business_outlined, color: Colors.grey),
                                ),
                                const SizedBox(height: 20),

                                // Employment Type & Industry
                                Row(
                                  children: [
                                    Expanded(
                                      child: _StyledDropdown<String>(
                                        label: 'Employment Type *',
                                        value: _employmentTypes.contains(employmentType) ? employmentType : null,
                                        hint: 'Select',
                                        items: _employmentTypes,
                                        onChanged: (v) => setState(() => employmentType = v),
                                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _StyledDropdown<String>(
                                        label: 'Industry *',
                                        value: _industries.contains(industry) ? industry : null,
                                        hint: 'Select',
                                        items: _industries,
                                        onChanged: (v) => setState(() => industry = v),
                                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                      ),
                                    ),
                                  ],
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
                                        label: 'End Date',
                                        date: endDate,
                                        enabled: !isCurrent,
                                        onPick: (ts) => setState(() => endDate = ts),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text(
                                    'Currently working here',
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

                                // Location
                                _StyledField(
                                  label: 'Location *',
                                  controller: locationCtrl,
                                  hint: 'e.g., Kuala Lumpur, Malaysia',
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                  prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.grey),
                                ),
                                const SizedBox(height: 20),

                                // Job Description
                                _StyledField(
                                  label: 'Job Description *',
                                  controller: descCtrl,
                                  hint: 'Describe your role, responsibilities, and impact...',
                                  maxLines: 4,
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                                const SizedBox(height: 24),

                                // Key Achievements
                                const Text(
                                  'Key Achievements (Optional)',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                                ),
                                const SizedBox(height: 12),
                                _StyledField(
                                  label: 'Title / What',
                                  controller: achTitleCtrl,
                                  hint: 'e.g., Improved app performance',
                                ),
                                const SizedBox(height: 12),
                                _StyledField(
                                  label: 'Metric',
                                  controller: achMetricCtrl,
                                  hint: 'e.g., +40% faster load times',
                                ),
                                const SizedBox(height: 12),
                                _StyledField(
                                  label: 'Business Impact',
                                  controller: achImpactCtrl,
                                  hint: 'e.g., Increased user retention',
                                ),

                                const SizedBox(height: 24),

                                // Skills Used
                                const Text('Skills Used/Developed', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                if (skillsUsed.isNotEmpty)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 0,
                                    children: skillsUsed.map((s) => Chip(
                                      label: Text(s, style: const TextStyle(fontSize: 12)),
                                      backgroundColor: const Color(0xFFEEF2FF),
                                      deleteIcon: const Icon(Icons.close, size: 16, color: Color(0xFF6C63FF)),
                                      onDeleted: () => setState(() => skillsUsed.remove(s)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      side: BorderSide.none,
                                    )).toList(),
                                  ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _StyledField(
                                        label: '',
                                        controller: skillInputCtrl,
                                        hint: 'Enter a skill (e.g., React)',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
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
                                        backgroundColor: const Color(0xFF6C63FF),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                      ),
                                      child: const Text('Add'),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 32),

                                // Action Buttons
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final success = await handleSave();
                                      if (success && context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(existing == null ? 'Experience added' : 'Experience updated'),
                                            backgroundColor: const Color(0xFF00B894),
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6C63FF),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text(
                                      'Save Experience',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      if (hasUnsavedChanges()) {
                                        await showUnsavedDialog();
                                      } else {
                                        Navigator.pop(context);
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.grey[300]!),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Experience?'),
        content: Text('Remove "$title" from your profile?'),
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

// ---------- WIDGETS ----------

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({
    required this.exp,
    required this.onEdit,
    required this.onDelete,
    required this.primaryColor,
  });

  final Experience exp;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final loc = _joinCityCountry(exp.city, exp.country);
    final dateText = [
      _fmtDate(exp.startDate),
      exp.isCurrent == true ? 'Present' : _fmtDate(exp.endDate),
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
                        exp.jobTitle ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exp.company ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
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

            // Metadata Row
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _MetaRow(icon: Icons.calendar_today, text: dateText),
                _MetaRow(icon: Icons.location_on_outlined, text: loc),
                if ((exp.employmentType ?? '').isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      exp.employmentType!,
                      style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            if ((exp.description ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                exp.description!,
                style: const TextStyle(color: Color(0xFF4B5563), height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
    );
  }
}

// Styled Input Components

class _StyledField extends StatelessWidget {
  const _StyledField({
    required this.label,
    required this.controller,
    this.hint,
    this.validator,
    this.prefixIcon,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A1A)),
          decoration: InputDecoration(
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
          ),
        ),
      ],
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          decoration: InputDecoration(
            hintText: hint,
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
          ),
          items: items.map((e) => DropdownMenuItem<T>(
            value: e,
            child: Text(e.toString(), style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A1A)), overflow: TextOverflow.ellipsis),
          )).toList(),
          onChanged: onChanged,
          validator: validator,
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
              decoration: InputDecoration(
                hintText: 'DD/MM/YYYY',
                prefixIcon: Icon(Icons.calendar_today, color: enabled ? Colors.grey : Colors.grey[300]),
                filled: true,
                fillColor: enabled ? const Color(0xFFF9FAFB) : Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExperienceTipsCard extends StatelessWidget {
  const _ExperienceTipsCard({required this.primaryColor});
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
          const _TipRow('Include internships if you are a recent graduate.'),
          const _TipRow('Focus on achievements (e.g., "Increased sales by 20%").'),
          const _TipRow('Keep descriptions concise and impactful.'),
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

const _industries = <String>[
  'Technology',
  'Information Technology',
  'IT',
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