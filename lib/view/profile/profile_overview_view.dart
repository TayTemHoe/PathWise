// lib/view/profile/profile_overview_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/viewModel/profile_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_wise/view/profile/edit_personal_view.dart';
import 'package:path_wise/view/profile/edit_education_view.dart';
import 'package:path_wise/view/profile/edit_experience_view.dart';
import 'package:path_wise/view/profile/edit_skills_view.dart';
import 'package:path_wise/view/profile/edit_preferences_view.dart';
import 'package:path_wise/view/profile/edit_personality_view.dart';

import '../../utils/app_color.dart';

// Defining KYYAP Design Colors locally
class _DesignColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color background = Color(0xFFF5F7FA);
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color cardBackground = Colors.white;
  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFFDCB6E);
  static const Color error = Color(0xFFD63031);
  static const Color info = Color(0xFF74B9FF);
  static Color shadow = Colors.black.withOpacity(0.08);
}

class ProfileOverviewScreen extends StatefulWidget {
  const ProfileOverviewScreen({Key? key}) : super(key: key);

  @override
  State<ProfileOverviewScreen> createState() => _ProfileOverviewScreenState();
}

class _ProfileOverviewScreenState extends State<ProfileOverviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileViewModel>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DesignColors.background,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _DesignColors.textPrimary,
          ),
        ),
        backgroundColor: _DesignColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
              Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: _DesignColors.textPrimary),
            onPressed: () {
              // TODO: Navigate to settings screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon!')),
              );
            },
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: _DesignColors.error),
            onPressed: () => _confirmLogout(context),
            tooltip: 'Log Out',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Consumer<ProfileViewModel>(
            builder: (context, profileVM, child) {
              if (profileVM.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_DesignColors.primary),
                  ),
                );
              }

              final profile = profileVM.profile;
              final completion = profile?.completionPercent ?? 0;

              return RefreshIndicator(
                onRefresh: () => profileVM.loadAll(),
                color: _DesignColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 40, // Adjust for padding
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildProfileHeader(profile),
                        const SizedBox(height: 24),
                        _buildCompletionCard(completion),
                        const SizedBox(height: 24),
                        _buildQuickStats(profileVM),
                        const SizedBox(height: 24),
                        _buildMenuSection(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(dynamic profile) {
    final String name = profile?.name ?? 'User';
    final String location = '${profile?.city ?? ''}, ${profile?.country ?? ''}'.replaceAll(RegExp(r'^, |,$'), '').trim();
    final String? photoUrl = profile?.profilePictureUrl ?? 'null'; // Assuming profile doesn't have photoUrl yet, or add if available

    // Format last updated date
    String? lastUpdated;
    if (profile?.lastUpdated != null) {
      // Assuming lastUpdated is a Timestamp or similar that can be converted to DateTime
      // If it's already a DateTime or String, adjust accordingly.
      // Using DateTime.now() as fallback/placeholder logic if type is unknown from context,
      // but based on typical patterns:
      try {
        final date = profile!.lastUpdated.toDate();
        lastUpdated = DateFormat('MMM d, yyyy').format(date);
      } catch (e) {
        lastUpdated = 'Recently';
      }
    }

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
      color: Colors.white, // Or _DesignColors.cardBackground
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFFE5E7EB),
                  backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                      ? NetworkImage(photoUrl)
                      : null,
                  child: (photoUrl == null || photoUrl.isEmpty)
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
                  if (location.isNotEmpty)
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

  Widget _buildCompletionCard(double completion) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _DesignColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _DesignColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profile Completion',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _DesignColors.textPrimary,
                ),
              ),
              _buildStatusChip(
                '${completion.toInt()}%',
                completion >= 100 ? _DesignColors.success : _DesignColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: completion / 100,
              backgroundColor: _DesignColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(
                completion >= 100 ? _DesignColors.success : _DesignColors.primary,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            completion < 100
                ? 'Complete your profile to get better job matches.'
                : 'Great job! Your profile is complete.',
            style: const TextStyle(
              fontSize: 12,
              color: _DesignColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(ProfileViewModel vm) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            'Skills',
            '${vm.skills.length}',
            Icons.bolt_rounded,
            _DesignColors.info,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            'Education',
            '${vm.education.length}',
            Icons.school_rounded,
            _DesignColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            'Experience',
            '${vm.experience.length}',
            Icons.work_rounded,
            _DesignColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: _DesignColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _DesignColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _DesignColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: _DesignColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Container(
      decoration: BoxDecoration(
        color: _DesignColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _DesignColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.person_outline,
            title: 'Personal Information',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditPersonalInfoScreen())),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.school_outlined,
            title: 'Education',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditEducationScreen())),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.work_outline,
            title: 'Experience',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditExperienceScreen())),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.bolt_outlined,
            title: 'Skills',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditSkillsScreen())),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.tune_outlined,
            title: 'Job Preferences',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditPreferencesScreen())),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.psychology_outlined,
            title: 'Personality Insights',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditPersonalityScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        // Ensure rounding for first and last items if needed, mostly visual preference
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _DesignColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _DesignColors.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _DesignColors.textPrimary,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: _DesignColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 64, // Aligned with text start
      endIndent: 0,
      color: Color(0xFFF0F0F0),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out'),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: _DesignColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _DesignColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _DesignColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}