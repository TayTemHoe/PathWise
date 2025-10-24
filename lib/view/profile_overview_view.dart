import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:path_wise/viewmodel/profile_view_model.dart';
import 'package:path_wise/model/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileOverviewScreen extends StatelessWidget {
  const ProfileOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, vm, _) {
        final p = vm.profile;
        final skills = vm.skills;
        final edus = vm.education;
        final exps = vm.experience;

        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FC),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            title: const Text(
              'My Profile',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            foregroundColor: const Color(0xFF111827),
          ),
          body: vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
            onRefresh: vm.loadAll,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: avatar, name, location, last updated
                  _HeaderCard(
                    name: p?.name ?? '-',
                    location: _composeLocation(p),
                    lastUpdated: _formatDate(p?.lastUpdated),
                    photoUrl: p?.profilePictureUrl,
                    onChangePhoto: () {
                      // Navigate to your image picker flow or call vm.uploadProfilePicture(...)
                      // Example navigation (replace as needed):
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Open photo picker...')),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Completion card
                  _CompletionCard(
                    percent: (p?.completionPercent ?? 0).clamp(0, 100).toDouble(),
                  ),

                  const SizedBox(height: 12),

                  // Sections (cards)
                  _SectionCard(
                    icon: Icons.person_outline,
                    iconBg: const Color(0xFFEFF4FF),
                    iconColor: const Color(0xFF4F46E5),
                    title: 'Personal Information',
                    subtitle: 'Basic details and contact information',
                    isComplete: _isPersonalComplete(p),
                    onTap: () =>
                        Navigator.pushNamed(context, '/edit-personal'),
                  ),

                  _SectionCard(
                    icon: Icons.star_border_rounded,
                    iconBg: const Color(0xFFEFF6FF),
                    iconColor: const Color(0xFF3B82F6),
                    title: 'Skills & Expertise',
                    subtitle:
                    '${skills.length} ${skills.length == 1 ? 'skill' : 'skills'} across categories',
                    isComplete: skills.isNotEmpty,
                    onTap: () =>
                        Navigator.pushNamed(context, '/edit-skills'),
                  ),

                  _SectionCard(
                    icon: Icons.school_outlined,
                    iconBg: const Color(0xFFECFDF5),
                    iconColor: const Color(0xFF10B981),
                    title: 'Education',
                    subtitle:
                    '${edus.length} education entr${edus.length == 1 ? 'y' : 'ies'}',
                    isComplete: edus.isNotEmpty,
                    onTap: () =>
                        Navigator.pushNamed(context, '/edit-education'),
                  ),

                  _SectionCard(
                    icon: Icons.work_outline_rounded,
                    iconBg: const Color(0xFFFDF2F8),
                    iconColor: const Color(0xFFEC4899),
                    title: 'Work Experience',
                    subtitle:
                    '${exps.length} work experience${exps.length == 1 ? '' : 's'}',
                    isComplete: exps.isNotEmpty,
                    onTap: () =>
                        Navigator.pushNamed(context, '/edit-experience'),
                  ),

                  _SectionCard(
                    icon: Icons.settings_suggest_outlined,
                    iconBg: const Color(0xFFFFFBEB),
                    iconColor: const Color(0xFFF59E0B),
                    title: 'Career Preferences',
                    subtitle: _prefsSummary(p),
                    isComplete: _hasPreferences(p),
                    onTap: () =>
                        Navigator.pushNamed(context, '/edit-preferences'),
                  ),

                  _SectionCard(
                    icon: Icons.psychology_alt_outlined,
                    iconBg: const Color(0xFFF5F3FF),
                    iconColor: const Color(0xFF8B5CF6),
                    title: 'Personality Assessment',
                    subtitle: _personalitySummary(p),
                    isComplete: _hasPersonality(p),
                    onTap: () =>
                        Navigator.pushNamed(context, '/edit-personality'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _composeLocation(UserProfile? p) {
    final city = (p?.city ?? '').trim();
    final country = (p?.country ?? '').trim();
    if (city.isNotEmpty && country.isNotEmpty) return '$city, $country';
    return city.isNotEmpty ? city : (country.isNotEmpty ? country : '-');
  }

  static String? _formatDate(Timestamp? ts) {
    if (ts == null) return null;
    final d = ts.toDate();
    return DateFormat('dd/MM/yyyy').format(d);
  }

  static bool _isPersonalComplete(UserProfile? p) {
    if (p == null) return false;
    final checks = [
      (p.name ?? '').isNotEmpty,
      (p.email ?? '').isNotEmpty,
      (p.phone ?? '').isNotEmpty,
      p.dob != null,
      (p.gender ?? '').isNotEmpty,
      (p.city ?? '').isNotEmpty,
      (p.country ?? '').isNotEmpty,
    ];
    return checks.every((e) => e);
  }

  static String _prefsSummary(UserProfile? p) {
    if (p == null) return 'Job search preferences and career goals';
    final roles = (p.desiredJobTitles ?? []);
    final locs = (p.preferredLocations ?? []);
    if (roles.isEmpty && locs.isEmpty) {
      return 'Job search preferences and career goals';
    }
    if (roles.isNotEmpty && locs.isNotEmpty) {
      return '${roles.take(1).join()} • ${locs.take(1).join()}';
    }
    if (roles.isNotEmpty) return roles.take(2).join(', ');
    return locs.take(2).join(', ');
  }

  static bool _hasPreferences(UserProfile? p) {
    if (p == null) return false;
    return (p.desiredJobTitles?.isNotEmpty == true) ||
        (p.industries?.isNotEmpty == true) ||
        (p.workEnvironment?.isNotEmpty == true) ||
        (p.preferredLocations?.isNotEmpty == true) ||
        p.willingToRelocate != null ||
        (p.remoteAcceptance ?? '').isNotEmpty ||
        p.salary != null;
  }

  static String _personalitySummary(UserProfile? p) {
    final mbti = p?.mbti ?? '';
    final riasec = (p?.riasec?.isNotEmpty == true) ? p!.riasec!.join('/') : '';
    if (mbti.isEmpty && riasec.isEmpty) return 'MBTI, RIASEC, and personality insights';
    if (mbti.isNotEmpty && riasec.isNotEmpty) return 'MBTI: $mbti   •   RIASEC: $riasec';
    if (mbti.isNotEmpty) return 'MBTI: $mbti';
    return 'RIASEC: $riasec';
  }

  static bool _hasPersonality(UserProfile? p) {
    return (p?.mbti ?? '').isNotEmpty || (p?.riasec?.isNotEmpty == true);
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
        ? name.trim().split(RegExp(r'\s+')).map((e) => e[0]).take(2).join().toUpperCase()
        : 'A';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      ? NetworkImage(photoUrl!) as ImageProvider
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
                      Flexible(
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

  final double percent;

  @override
  Widget build(BuildContext context) {
    final remain = (100 - percent).clamp(0, 100);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
