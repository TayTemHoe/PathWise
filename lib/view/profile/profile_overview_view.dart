import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/routes.dart';
import 'package:path_wise/ViewModel/profile_view_model.dart';
import 'package:path_wise/model/user_profile.dart';

class ProfileOverviewScreen extends StatelessWidget {
  const ProfileOverviewScreen({super.key});

  // Replace the Scaffold's body structure:
  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, vm, _) {
        final p = vm.profile;
        final skills = vm.skills;
        final edus = vm.education;
        final exps = vm.experience;

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 40),
                        const Expanded(
                          child: Text(
                            'My Profile',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.help_outline, color: Colors.white),
                          onPressed: () {
                            _showHelpDialog(context);
                          },
                        ),
                      ],
                    ),
                  ),

                  // Content with rounded corners
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: RefreshIndicator(
                        onRefresh: vm.loadAll,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: vm.isLoading
                                  ? const Padding(
                                padding: EdgeInsets.only(top: 100),
                                child: Center(child: CircularProgressIndicator()),
                              )
                                  : Padding(
                                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                                child: Column(
                                  children: [
                                    _HeaderCard(
                                      name: p?.name ?? '-',
                                      location: _composeLocation(p),
                                      lastUpdated: _formatDate(p?.lastUpdated),
                                      photoUrl: p?.profilePictureUrl,
                                      onChangePhoto: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Open photo picker...'),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    _CompletionCard(
                                      percent: (p?.completionPercent ?? 0)
                                          .toInt(),
                                    ),
                                    const SizedBox(height: 12),

                                    // ======= Sections =======
                                    _SectionCard(
                                      icon: Icons.person_outline,
                                      iconBg: const Color(0xFFEFF4FF),
                                      iconColor: const Color(0xFF4F46E5),
                                      title: 'Personal Information',
                                      subtitle: 'Basic details and contact information',
                                      isComplete: _isPersonalComplete(p),
                                      onTap: () => Navigator.pushNamed(
                                          context, AppRoutes.editPersonal),
                                    ),
                                    _SectionCard(
                                      icon: Icons.star_border_rounded,
                                      iconBg: const Color(0xFFEFF6FF),
                                      iconColor: const Color(0xFF3B82F6),
                                      title: 'Skills & Expertise',
                                      subtitle:
                                      '${skills.length} ${skills.length == 1 ? 'skill' : 'skills'} across categories',
                                      isComplete: skills.isNotEmpty,
                                      onTap: () => Navigator.pushNamed(
                                          context, AppRoutes.editSkills),
                                    ),
                                    _SectionCard(
                                      icon: Icons.school_outlined,
                                      iconBg: const Color(0xFFECFDF5),
                                      iconColor: const Color(0xFF10B981),
                                      title: 'Education',
                                      subtitle:
                                      '${edus.length} education entr${edus.length == 1 ? 'y' : 'ies'}',
                                      isComplete: edus.isNotEmpty,
                                      onTap: () => Navigator.pushNamed(
                                          context, AppRoutes.editEducation),
                                    ),
                                    _SectionCard(
                                      icon: Icons.work_outline_rounded,
                                      iconBg: const Color(0xFFFDF2F8),
                                      iconColor: const Color(0xFFEC4899),
                                      title: 'Work Experience',
                                      subtitle:
                                      '${exps.length} work experience${exps.length == 1 ? '' : 's'}',
                                      isComplete: exps.isNotEmpty,
                                      onTap: () => Navigator.pushNamed(
                                          context, AppRoutes.editExperience),
                                    ),
                                    _SectionCard(
                                      icon: Icons.settings_suggest_outlined,
                                      iconBg: const Color(0xFFFFFBEB),
                                      iconColor: const Color(0xFFF59E0B),
                                      title: 'Career Preferences',
                                      subtitle: _prefsSummary(p),
                                      isComplete: _hasPreferences(p),
                                      onTap: () => Navigator.pushNamed(
                                          context, AppRoutes.editPreferences),
                                    ),
                                    _SectionCard(
                                      icon: Icons.psychology_alt_outlined,
                                      iconBg: const Color(0xFFF5F3FF),
                                      iconColor: const Color(0xFF8B5CF6),
                                      title: 'Personality Assessment',
                                      subtitle: _personalitySummary(p),
                                      isComplete: _hasPersonality(p),
                                      onTap: () => Navigator.pushNamed(
                                          context, AppRoutes.editPersonality),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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

  // ===== Helpers =====
  static String _composeLocation(UserProfile? p) {
    final city = (p?.city ?? '').trim();
    final state = (p?.state ?? '').trim();
    final country = (p?.country ?? '').trim();

    // Prefer "City, Country" like mockup
    if (city.isNotEmpty && country.isNotEmpty) return '$city, $country';
    if (state.isNotEmpty && country.isNotEmpty) return '$state, $country';
    return city.isNotEmpty
        ? city
        : state.isNotEmpty
        ? state
        : country.isNotEmpty
        ? country
        : '-';
  }

  static String? _formatDate(Timestamp? ts) {
    if (ts == null) return null;
    return DateFormat('dd/MM/yyyy').format(ts.toDate());
  }

  static bool _isPersonalComplete(UserProfile? p) {
    if (p == null) return false;
    final checks = [
      (p.name ?? '').isNotEmpty,
      (p.email ?? '').isNotEmpty,
      (p.phone ?? '').isNotEmpty,
      p.dob != null,
      (p.gender ?? '').isNotEmpty,
      (p.city ?? '').isNotEmpty || (p.state ?? '').isNotEmpty || (p.country ?? '').isNotEmpty,
    ];
    return checks.every((e) => e);
  }

  static String _prefsSummary(UserProfile? p) {
    if (p == null || p.preferences == null) {
      return 'Job search preferences and career goals';
    }

    final prefs = p.preferences!;
    final roles = prefs.desiredJobTitles ?? const [];
    final locs = prefs.preferredLocations ?? const [];

    if (roles.isEmpty && locs.isEmpty) {
      return 'Job search preferences and career goals';
    }

    if (roles.isNotEmpty && locs.isNotEmpty) {
      return '${roles.first} • ${locs.first}';
    }

    return roles.isNotEmpty
        ? roles.take(2).join(', ')
        : locs.take(2).join(', ');
  }

  static bool _hasPreferences(UserProfile? p) {
    if (p == null || p.preferences == null) return false;

    final prefs = p.preferences!;
    return (prefs.desiredJobTitles?.isNotEmpty == true) ||
        (prefs.industries?.isNotEmpty == true) ||
        (prefs.workEnvironment?.isNotEmpty == true) ||
        (prefs.preferredLocations?.isNotEmpty == true) ||
        (prefs.willingToRelocate != null) ||
        ((prefs.remoteAcceptance ?? '').isNotEmpty) ||
        (prefs.salary != null);
  }


  static String _personalitySummary(UserProfile? p) {
    final mbti = p?.mbti ?? '';
    final riasec = p?.riasec ?? '';
    if (mbti.isEmpty && riasec.isEmpty) {
      return 'MBTI, RIASEC, and personality insights';
    }
    if (mbti.isNotEmpty && riasec.isNotEmpty) {
      return 'MBTI: $mbti   •   RIASEC: $riasec';
    }
    return mbti.isNotEmpty ? 'MBTI: $mbti' : 'RIASEC: $riasec';
  }

  static bool _hasPersonality(UserProfile? p) {
    return (p?.mbti ?? '').isNotEmpty || (p?.riasec?.isNotEmpty == true);
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Color(0xFF8B5CF6)),
            SizedBox(width: 12),
            Text('How to complete your profile', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpStep('1', 'Fill in your personal information and contact details'),
              _buildHelpStep('2', 'Add your skills and areas of expertise'),
              _buildHelpStep('3', 'Include your education background'),
              _buildHelpStep('4', 'Add your work experience history'),
              _buildHelpStep('5', 'Set your career preferences and goals'),
              _buildHelpStep('6', 'Complete personality assessments (MBTI, RIASEC)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFF8B5CF6),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

}

// ===============================
// Widgets
// ===============================

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.name,
    required this.location,
    required this.lastUpdated,
    required this.photoUrl,
    required this.onChangePhoto,
  });

  final String name;
  final String location;
  final String? lastUpdated;
  final String? photoUrl;
  final VoidCallback onChangePhoto;

  @override
  Widget build(BuildContext context) {
    final initials = (name.isNotEmpty)
        ? name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .map((e) => e[0])
        .take(2)
        .join()
        .toUpperCase()
        : 'A';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Color(0xFFFFFFFF),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFFE5E7EB),
                  backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                      ? NetworkImage(photoUrl!)
                      : null,
                  child: (photoUrl == null || photoUrl!.isEmpty)
                      ? Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w700,
                    ),
                  )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: InkWell(
                    onTap: onChangePhoto,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.photo_camera_outlined, size: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      )),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: Color(0xFF6B7280)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Color(0xFF6B7280), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (lastUpdated != null)
                    Row(
                      children: [
                        const Icon(Icons.schedule_outlined,
                            size: 14, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 4),
                        Text(
                          'Last updated: $lastUpdated',
                          style: const TextStyle(
                              color: Color(0xFF9CA3AF), fontSize: 12),
                        ),
                      ],
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.percent});
  final int percent;

  @override
  Widget build(BuildContext context) {
    final remain = (100 - percent).clamp(0, 100);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Color(0xFFFFFFFF),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Chip(text: '${percent.toStringAsFixed(0)}% Complete'),
                const SizedBox(width: 8),
                const Text('Profile Completion',
                    style:
                    TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: percent / 100.0,
                backgroundColor: const Color(0xFFE5E7EB),
                color: const Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Keep going! You're doing great.",
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                ),
                Text(
                  '${remain.toStringAsFixed(0)}% to go',
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isComplete,
    required this.onTap,
    this.iconBg = const Color(0xFFF3F4F6),
    this.iconColor = const Color(0xFF111827),
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isComplete;
  final VoidCallback onTap;
  final Color iconBg;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(top: 10),
      color: Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(10),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          color: Color(0xFF6B7280), fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isComplete
                    ? const Color(0xFF10B981)
                    : const Color(0xFFD1D5DB),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.edit_outlined, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFB45309),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
