import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/viewModel/profile_view_model.dart';
import 'package:path_wise/model/user_profile.dart';

import '../../utils/app_color.dart';

class EditSkillsScreen extends StatefulWidget {
  const EditSkillsScreen({super.key});

  @override
  State<EditSkillsScreen> createState() => _EditSkillsScreenState();
}

class _EditSkillsScreenState extends State<EditSkillsScreen> {
  static const _tabs = ['Technical', 'Soft', 'Languages', 'Industry'];

  //  Design Colors
  final Color _primaryColor = const Color(0xFF6C63FF);
  final Color _textColor = const Color(0xFF1A1A1A);
  final Color _backgroundColor = Colors.white;

  @override
  void initState() {
    super.initState();
    // Force reload data to ensure fresh state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileViewModel>().loadAll();
    });
  }

  // Robust helper to match categories even if they have small differences (e.g., "Language" vs "Languages")
  List<Skill> _filterSkills(List<Skill> allSkills, String category) {
    return allSkills.where((s) {
      final dataCat = (s.category ?? '').trim();
      final targetCat = category.trim();

      // 1. Exact Match
      if (dataCat == targetCat) return true;

      // 2. Case Insensitive Match
      if (dataCat.toLowerCase() == targetCat.toLowerCase()) return true;

      // 3. Singular/Plural Match (Common issue: "Language" vs "Languages")
      if (targetCat == 'Languages' && dataCat.toLowerCase() == 'language') return true;
      if (dataCat == 'Languages' && targetCat.toLowerCase() == 'language') return true;

      return false;
    }).toList()
      ..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Consumer<ProfileViewModel>(
        builder: (context, vm, _) {
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
                'Skills & Expertise',
                style: TextStyle(
                  color: _textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Center( // Centers the TabBar
                    child: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.center, // Ensures tabs are centered
                      padding: EdgeInsets.zero,
                      labelColor: _primaryColor,
                      unselectedLabelColor: Colors.grey[500],
                      indicatorColor: _primaryColor,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                      tabs: _tabs.map((t) => Tab(text: t)).toList(),
                    ),
                  ),
                ),
              ),
            ),
            body: Stack(
              children: [
                TabBarView(
                  children: _tabs.map((tab) {
                    // Use the robust filter logic
                    final list = _filterSkills(vm.skills, tab);

                    return _SkillsCategoryPage(
                      category: tab,
                      skills: list,
                      primaryColor: _primaryColor,
                      onAdd: () => _showAddOrEditSheet(context, vm, category: tab),
                      onEdit: (skill) => _showAddOrEditSheet(context, vm, category: tab, existing: skill),
                      onDelete: (skill) async {
                        final ok = await _confirmDelete(context, skill.name ?? 'this skill');
                        if (!ok) return;
                        await vm.deleteSkill(skill.id);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Skill deleted'),
                            backgroundColor: Color(0xFFD63031),
                          ),
                        );
                      },
                      onRefresh: () => vm.loadAll(),
                    );
                  }).toList(),
                ),
                if (vm.isLoading)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      color: _primaryColor,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
              ],
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
    final formKey = GlobalKey<FormState>();

    // Controllers
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final certCtrl = TextEditingController(text: existing?.verification?.certificateUrl ?? '');
    final portCtrl = TextEditingController(text: existing?.verification?.portfolioUrl ?? '');

    int level = existing?.level ?? 3;

    // Capture initial state for unsaved changes check
    final initialName = existing?.name ?? '';
    final initialCert = existing?.verification?.certificateUrl ?? '';
    final initialPort = existing?.verification?.portfolioUrl ?? '';
    final initialLevel = existing?.level ?? 3;

    bool hasUnsavedChanges() {
      if (nameCtrl.text != initialName) return true;
      if (certCtrl.text != initialCert) return true;
      if (portCtrl.text != initialPort) return true;
      if (level != initialLevel) return true;
      return false;
    }

    Future<bool> handleSave() async {
      if (!formKey.currentState!.validate()) return false;

      // Calculate order: if existing, keep it. If new, put it at the end.
      // Note: If 'order' is missing in DB for other items, they won't show up in fetched list due to orderBy('order').
      // We ensure new items have an order.
      final newOrder = existing?.order ?? (vm.skills.length + 1);

      final draft = Skill(
        id: existing?.id ?? 'TEMP',
        name: nameCtrl.text.trim(),
        category: category, // Matches the tab name exactly
        level: level,
        levelText: _levelText(level),
        verification: Verification(
          certificateUrl: _emptyToNull(certCtrl.text.trim()),
          portfolioUrl: _emptyToNull(portCtrl.text.trim()),
        ),
        order: newOrder,
      );

      bool ok;
      if (existing == null) {
        ok = await vm.addSkill(draft);
      } else {
        ok = await vm.saveSkill(draft);
      }

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(vm.error ?? 'Failed to save skill')),
        );
      }
      return ok;
    }

    Future<void> showUnsavedDialog() async {
      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Unsaved Changes', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('You have unsaved changes. Do you want to save them before leaving?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close dialog
                Navigator.pop(context); // Close sheet (Discard)
              },
              child: const Text('Continue', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Close dialog
                final success = await handleSave();
                if (success && context.mounted) {
                  Navigator.pop(context); // Close sheet (Saved)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(existing == null ? 'Skill added' : 'Skill updated'),
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
                  // Drag Handle
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
                      child: Form(
                        key: formKey,
                        child: StatefulBuilder(
                          builder: (context, setState) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      existing == null ? 'Add $category Skill' : 'Edit $category Skill',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                                _StyledField(
                                  label: 'Skill Name *',
                                  controller: nameCtrl,
                                  hint: 'e.g., Python, Team Leadership',
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                                const SizedBox(height: 20),
                                const Text('Proficiency Level', style: TextStyle(fontWeight: FontWeight.w500)),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                  ),
                                  child: Row(
                                    children: [
                                      _StarRating(
                                        value: level,
                                        onChanged: (v) => setState(() => level = v),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          _levelText(level),
                                          style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _StyledField(
                                  label: 'Certification URL (Optional)',
                                  controller: certCtrl,
                                  keyboardType: TextInputType.url,
                                  hint: 'https://example.com/certificate',
                                  prefixIcon: const Icon(Icons.link, color: Colors.grey),
                                ),
                                const SizedBox(height: 20),
                                _StyledField(
                                  label: 'Portfolio URL (Optional)',
                                  controller: portCtrl,
                                  keyboardType: TextInputType.url,
                                  hint: 'https://yourportfolio.com',
                                  prefixIcon: const Icon(Icons.language, color: Colors.grey),
                                ),
                                const SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: vm.savingSkill ? null : () async {
                                      final success = await handleSave();
                                      if (success && context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Skill saved'), backgroundColor: const Color(0xFF00B894)),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6C63FF),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: vm.savingSkill
                                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Text('Save Skill', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      side: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF1A1A1A))),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
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

  static Future<bool> _confirmDelete(BuildContext context, String title) async {
    return await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Skill?'),
        content: Text('Remove "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD63031)),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }
}

class _SkillsCategoryPage extends StatelessWidget {
  const _SkillsCategoryPage({
    required this.category,
    required this.skills,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
    required this.primaryColor,
  });

  final String category;
  final List<Skill> skills;
  final VoidCallback onAdd;
  final Function(Skill) onEdit;
  final Function(Skill) onDelete;
  final VoidCallback onRefresh;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$category Skills',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: Icon(Icons.add_circle_outline, color: primaryColor, size: 20),
              label: Text('Add New', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (skills.isEmpty)
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
                Icon(Icons.lightbulb_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No $category skills added yet',
                  style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                // Refresh button to help if data is missing
                TextButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh Data'),
                ),
              ],
            ),
          )
        else
          ...skills.map((s) => _SkillCard(
            skill: s,
            primaryColor: primaryColor,
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
    required this.primaryColor,
  });

  final Skill skill;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final level = skill.level ?? 0;
    final hasCert = (skill.verification?.certificateUrl ?? '').isNotEmpty;
    final hasPort = (skill.verification?.portfolioUrl ?? '').isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                  child: Text(
                    skill.name ?? '(no name)',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _StarRating(value: level, enabled: false),
                const SizedBox(width: 8),
                Text(
                  _levelText(level),
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
            if (hasCert || hasPort) ...[
              const SizedBox(height: 12),
              Divider(color: Colors.grey[100]),
              if (hasCert) _MiniInfoRow(icon: Icons.verified, label: 'Certificate', value: 'Linked', color: primaryColor),
              if (hasPort) _MiniInfoRow(icon: Icons.link, label: 'Portfolio', value: 'Linked', color: primaryColor),
            ]
          ],
        ),
      ),
    );
  }
}

class _MiniInfoRow extends StatelessWidget {
  const _MiniInfoRow({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text('$label:', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(width: 6),
          Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({required this.value, this.onChanged, this.enabled = true});
  final int value;
  final ValueChanged<int>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final fill = i < value;
        return GestureDetector(
          onTap: enabled ? () => onChanged?.call(i + 1) : null,
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              fill ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 24,
              color: fill ? const Color(0xFFFFB74D) : Colors.grey[300],
            ),
          ),
        );
      }),
    );
  }
}

class _StyledField extends StatelessWidget {
  const _StyledField({required this.label, required this.controller, this.hint, this.validator, this.prefixIcon, this.keyboardType});
  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 16, color: Colors.grey[500]),
            prefixIcon: prefixIcon,
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2)),
          ),
        ),
      ],
    );
  }
}

String _levelText(int level) {
  switch (level) {
    case 1: return 'Beginner';
    case 2: return 'Basic';
    case 3: return 'Intermediate';
    case 4: return 'Advanced';
    case 5: return 'Expert';
    default: return 'Not set';
  }
}

String? _emptyToNull(String? s) => (s == null || s.isEmpty) ? null : s;