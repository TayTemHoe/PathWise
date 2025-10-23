import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:path_wise/ViewModel/profile_view_model.dart';
import 'package:path_wise/model/user_profile.dart';

class ProfileOverviewScreen extends StatelessWidget {
  const ProfileOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, vm, _) {
        final profile = vm.profile;
        final pi = profile?.personalInfo;
        final prefs = profile?.preferences;
        final skills = vm.skills;
        final education = vm.education;
        final experience = vm.experience;

        final completion = (profile?.completionPercent ?? 0).clamp(0, 100);
        final lastUpdated = _fmtDate(profile?.lastUpdated);

        return Scaffold(
          backgroundColor: Colors.grey[50],
          bottomNavigationBar: _BottomNav(currentIndex: 4),
          body: RefreshIndicator(
            onRefresh: vm.refreshAll,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _HeaderCard(
                    name: pi?.name ?? '—',
                    location: _composeLocation(pi?.location),
                    lastUpdated: lastUpdated,
                    imageUrl: pi?.profilePictureUrl,
                    onChangePhoto: () {
                      // TODO: open image picker then vm.uploadProfilePicture(file)
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: _CompletionCard(
                    completion: completion.toDouble(),
                    encouragement:
                    "Keep going! You're doing great. ${(100 - completion).toStringAsFixed(0)}% to go",
                  ),
                ),

                // Sections
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList.separated(
                    itemCount: 6,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      switch (index) {
                        case 0:
                          return _SectionTile(
                            leadingIcon: Icons.person_outline_rounded,
                            title: 'Personal Information',
                            subtitle: 'Basic details and contact information',
                            isDone: _isPersonalDone(profile),
                            onEdit: () {
                              // Navigator.pushNamed(context, '/edit-personal');
                            },
                          );
                        case 1:
                          return _SectionTile(
                            leadingIcon: Icons.star_border_rounded,
                            title: 'Skills & Expertise',
                            subtitle:
                            '${skills.length} skill${skills.length == 1 ? '' : 's'} across ${_skillCategories(skills)} categories',
                            isDone: skills.isNotEmpty,
                            onEdit: () {
                              // Navigator.pushNamed(context, '/edit-skills');
                            },
                          );
                        case 2:
                          return _SectionTile(
                            leadingIcon: Icons.school_outlined,
                            title: 'Education',
                            subtitle:
                            '${education.length} education entr${education.length == 1 ? 'y' : 'ies'}',
                            isDone: education.isNotEmpty,
                            onEdit: () {
                              // Navigator.pushNamed(context, '/edit-education');
                            },
                          );
                        case 3:
                          return _SectionTile(
                            leadingIcon: Icons.work_outline_rounded,
                            title: 'Work Experience',
                            subtitle:
                            '${experience.length} work experience${experience.length == 1 ? '' : 's'}',
                            isDone: experience.isNotEmpty,
                            onEdit: () {
                              // Navigator.pushNamed(context, '/edit-experience');
                            },
                          );
                        case 4:
                          return _SectionTile(
                            leadingIcon: Icons.tune_rounded,
                            title: 'Career Preferences',
                            subtitle: 'Job search preferences and career goals',
                            isDone: _isPreferencesDone(prefs),
                            onEdit: () {
                              // Navigator.pushNamed(context, '/edit-preferences');
                            },
                          );
                        default:
                          return _SectionTile(
                            leadingIcon: Icons.psychology_alt_outlined,
                            title: 'Personality Assessment',
                            subtitle: _personalityLine(profile?.personality),
                            chips: _personalityChips(profile?.personality),
                            isDone: (profile?.personality?.mbti?.isNotEmpty ?? false) ||
                                (profile?.personality?.riasec.isNotEmpty ?? false),
                            onEdit: () {
                              // Navigator.pushNamed(context, '/edit-personality');
                            },
                          );
                      }
                    },
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    return DateFormat('dd/MM/yyyy').format(d);
  }

  static String _composeLocation(LocationVO? loc) {
    if (loc == null) return '—';
    final parts = [loc.city, loc.state].where((e) => (e ?? '').isNotEmpty).join(', ');
    final country = (loc.country ?? '').isNotEmpty ? loc.country! : '';
    return [parts, country].where((e) => e.isNotEmpty).join(', ');
  }

  static bool _isPersonalDone(UserProfile? p) {
    final pi = p?.personalInfo;
    if (pi == null) return false;
    return (pi.name?.isNotEmpty ?? false) &&
        (pi.email?.isNotEmpty ?? false) &&
        (pi.phone?.isNotEmpty ?? false) &&
        (pi.location?.city?.isNotEmpty ?? false) &&
        (pi.location?.country?.isNotEmpty ?? false);
  }

  static bool _isPreferencesDone(Preferences? pref) {
    if (pref == null) return false;
    return (pref.desiredJobTitles.isNotEmpty) &&
        (pref.industries.isNotEmpty) &&
        (pref.workEnvironment.isNotEmpty);
  }

  static int _skillCategories(List<Skill> skills) {
    return skills.map((s) => s.category).toSet().length;
  }

  static String _personalityLine(Personality? p) {
    if (p == null) return 'MBTI, RIASEC, and personality insights';
    final mbti = (p.mbti ?? '').isNotEmpty ? 'MBTI: ${p.mbti}' : null;
    final riasec = p.riasec.isNotEmpty ? 'RIASEC: ${p.riasec.join(', ')}' : null;
    return [mbti, riasec].where((e) => (e ?? '').isNotEmpty).join('   ');
  }

  static List<String> _personalityChips(Personality? p) {
    if (p == null) return [];
    final chips = <String>[];
    if ((p.mbti ?? '').isNotEmpty) chips.add('MBTI: ${p.mbti}');
    if (p.riasec.isNotEmpty) chips.add('RIASEC: ${p.riasec.join('-')}');
    return chips;
  }
}

/// ============================ Header ===========================================

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.name,
    required this.location,
    required this.lastUpdated,
    required this.imageUrl,
    required this.onChangePhoto,
  });

  final String name;
  final String location;
  final String lastUpdated;
  final String? imageUrl;
  final VoidCallback onChangePhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C4DFF), Color(0xFF7C4DFF), Color(0xFF8E24AA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'My Profile',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage your professional information',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 16),

          // Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFFECEBFF),
                      backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty)
                          ? NetworkImage(imageUrl!) as ImageProvider
                          : null,
                      child: (imageUrl == null || imageUrl!.isEmpty)
                          ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'A',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5E5CE6)),
                      )
                          : null,
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: InkWell(
                        onTap: onChangePhoto,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A))),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 16, color: Colors.black54),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              location.isNotEmpty ? location : '—',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: Colors.black87),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.history, size: 16, color: Colors.black54),
                          const SizedBox(width: 4),
                          Text(
                            'Last updated: $lastUpdated',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================ Completion Card ==================================

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({
    required this.completion,
    required this.encouragement,
  });

  final double completion;
  final String encouragement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentLabel = '${completion.toStringAsFixed(0)}% Complete';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge + label
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEAD6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  percentLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFFB55B00),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (completion / 100).clamp(0, 1),
              minHeight: 10,
              backgroundColor: const Color(0xFFE8E8EE),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1F1F39)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            encouragement,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

/// ============================ Section Tile =====================================

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.leadingIcon,
    required this.title,
    required this.subtitle,
    required this.isDone,
    this.chips,
    required this.onEdit,
  });

  final IconData leadingIcon;
  final String title;
  final String subtitle;
  final bool isDone;
  final List<String>? chips;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F3FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(leadingIcon, color: const Color(0xFF5E5CE6)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // title + status + edit
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                        if (isDone)
                          const Icon(Icons.check_circle, color: Color(0xFF22C55E))
                        else
                          const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: onEdit,
                          child: const Icon(Icons.edit_outlined, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black87,
                      ),
                    ),
                    if (chips != null && chips!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: -6,
                        children: chips!
                            .map((c) => Chip(
                          label: Text(c),
                          labelStyle: const TextStyle(fontSize: 12),
                          backgroundColor: const Color(0xFFF2F3FF),
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                        ))
                            .toList(),
                      )
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ============================ Bottom Nav (mock) =================================

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex});
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.search), label: 'Career'),
        NavigationDestination(icon: Icon(Icons.route_outlined), label: 'Roadmap'),
        NavigationDestination(icon: Icon(Icons.description_outlined), label: 'Resume'),
        NavigationDestination(icon: Icon(Icons.forum_outlined), label: 'Interview'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
      onDestinationSelected: (i) {
        // TODO: handle nav route changes
      },
    );
  }
}
