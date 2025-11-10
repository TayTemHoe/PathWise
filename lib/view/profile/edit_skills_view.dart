import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/ViewModel/profile_view_model.dart';
import 'package:path_wise/model/user_profile.dart';

class EditSkillsScreen extends StatelessWidget {
  const EditSkillsScreen({super.key});

  static const _tabs = ['Technical', 'Soft', 'Languages', 'Industry'];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Consumer<ProfileViewModel>(
        builder: (context, vm, _) {
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
                'Skills & Expertise',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(44),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TabBar(
                    isScrollable: true,
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                    tabs: _tabs.map((t) => Tab(text: t)).toList(),
                  ),
                ),
              ),
            ),
            body: TabBarView(
              children: _tabs.map((tab) {
                final list = vm.skills.where((s) => (s.category ?? '') == tab).toList()
                  ..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));

                return _SkillsCategoryPage(
                  category: tab,
                  skills: list,
                  onAdd: () => _showAddOrEditSheet(context, vm, category: tab),
                  onEdit: (skill) => _showAddOrEditSheet(context, vm, category: tab, existing: skill),
                  onDelete: (skill) async {
                    final ok = await _confirmDelete(context, skill.name ?? 'this skill');
                    if (!ok) return;
                    await vm.deleteSkill(skill.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Skill deleted')),
                    );
                  },
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  static Future<void> _showAddOrEditSheet(
      BuildContext context,
      ProfileViewModel vm, {
        required String category,
        Skill? existing,
      }) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final certCtrl =
    TextEditingController(text: existing?.verification?.certificateUrl ?? '');
    final portCtrl =
    TextEditingController(text: existing?.verification?.portfolioUrl ?? '');
    int level = existing?.level ?? 3; // default mid-level
    final formKey = GlobalKey<FormState>();

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
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          existing == null ? 'Add ${category} Skill' : 'Edit ${category} Skill',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Skill Name *',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: nameCtrl,
                      validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                      decoration: _inputDecoration(),
                    ),
                    const SizedBox(height: 14),
                    const Text('Level',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    StatefulBuilder(
                      builder: (context, setState) {
                        return Row(
                          children: [
                            _StarRating(
                              value: level,
                              onChanged: (v) => setState(() => level = v),
                            ),
                            const SizedBox(width: 12),
                            Text(_levelText(level),
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.w700,
                                )),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text('Certification URL (Optional)',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: certCtrl,
                      keyboardType: TextInputType.url,
                      decoration: _inputDecoration(
                        hint: 'https://example.com/certificate',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Portfolio URL (Optional)',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: portCtrl,
                      keyboardType: TextInputType.url,
                      decoration: _inputDecoration(
                        hint: 'https://yourportfolio.com',
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: vm.savingSkill
                                ? null
                                : () async {
                              if (!formKey.currentState!.validate()) return;

                              final draft = Skill(
                                id: existing?.id ?? 'TEMP',
                                name: nameCtrl.text.trim(),
                                category: category,
                                level: level,
                                levelText: _levelText(level),
                                verification: Verification(
                                  certificateUrl:
                                  _emptyToNull(certCtrl.text.trim()),
                                  portfolioUrl:
                                  _emptyToNull(portCtrl.text.trim()),
                                ),
                                // order: next will be set when creating;
                                order: existing?.order,
                              );

                              if (existing == null) {
                                // create
                                final ok = await vm.addSkill(draft);
                                if (!context.mounted) return;
                                if (ok) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                      content:
                                      Text('Skill added successfully')));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(vm.error ??
                                              'Failed to add skill')));
                                }
                              } else {
                                // update
                                final ok = await vm.saveSkill(draft);
                                if (!context.mounted) return;
                                if (ok) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                      content:
                                      Text('Skill updated successfully')));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(vm.error ??
                                              'Failed to update skill')));
                                }
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
                            child: vm.savingSkill
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                                : Text(existing == null ? 'Save' : 'Save'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding:
                              const EdgeInsets.symmetric(vertical: 14),
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
            ),
          ),
        );
      },
    );
  }

  static Future<bool> _confirmDelete(BuildContext context, String title) async {
    return await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Skill?'),
        content: Text('Remove "$title" from your profile?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    ) ??
        false;
  }

  static InputDecoration _inputDecoration({String? hint}) => const InputDecoration(
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
}

class _SkillsCategoryPage extends StatelessWidget {
  const _SkillsCategoryPage({
    required this.category,
    required this.skills,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final String category;
  final List<Skill> skills;
  final VoidCallback onAdd;
  final Function(Skill) onEdit;
  final Function(Skill) onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(
          children: [
            Text(
              '$category Skills',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Skill'),
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
        if (skills.isEmpty)
          _EmptyHint(category: category)
        else
          ...skills.map((s) => _SkillCard(
            skill: s,
            onEdit: () => onEdit(s),
            onDelete: () => onDelete(s),
          )),
      ],
    );
  }
}

class _SkillCard extends StatelessWidget {
  const _SkillCard({
    required this.skill,
    required this.onEdit,
    required this.onDelete,
  });

  final Skill skill;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final level = skill.level ?? 0;
    final hasCert = (skill.verification?.certificateUrl ?? '').isNotEmpty;
    final hasPort = (skill.verification?.portfolioUrl ?? '').isNotEmpty;

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
                  child: Text(
                    skill.name ?? '(no name)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
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
                  icon: const Icon(Icons.close, color: Colors.redAccent),
                  tooltip: 'Delete',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _StarRating(value: level, enabled: false),
                const SizedBox(width: 8),
                Text(
                  _levelText(level),
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (hasCert || hasPort) ...[
              const SizedBox(height: 10),
              if (hasCert)
                _MiniInfoRow(
                  icon: Icons.verified_outlined,
                  label: 'Certificate',
                  value: skill.verification!.certificateUrl!,
                ),
              if (hasPort)
                _MiniInfoRow(
                  icon: Icons.link_outlined,
                  label: 'Portfolio',
                  value: skill.verification!.portfolioUrl!,
                ),
            ]
          ],
        ),
      ),
    );
  }
}

class _MiniInfoRow extends StatelessWidget {
  const _MiniInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Color(0xFF374151)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.category});
  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'No $category skills yet. Tap "Add Skill" to create one.',
        style: const TextStyle(color: Color(0xFF6B7280)),
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({
    required this.value,
    this.onChanged,
    this.enabled = true,
  });

  final int value; // 0..5
  final ValueChanged<int>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final fill = i < value;
        return InkWell(
          onTap: enabled ? () => onChanged?.call(i + 1) : null,
          child: Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Icon(
              fill ? Icons.star : Icons.star_border,
              size: 20,
              color: const Color(0xFFF59E0B),
            ),
          ),
        );
      }),
    );
  }
}

String _levelText(int level) {
  switch (level) {
    case 1:
      return 'Beginner';
    case 2:
      return 'Basic';
    case 3:
      return 'Intermediate';
    case 4:
      return 'Advanced';
    case 5:
      return 'Expert';
    default:
      return 'Not set';
  }
}

String? _emptyToNull(String? s) => (s == null || s.isEmpty) ? null : s;
