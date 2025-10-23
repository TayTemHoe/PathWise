import 'package:flutter/material.dart';
import 'package:path_wise/model/user_profile.dart';

/// ========================= Header: Profile Completion =========================
class HeaderCompletionCard extends StatelessWidget {
  final double percent;
  final String subtitle;

  const HeaderCompletionCard({
    required this.percent,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Profile Completion', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: Colors.grey.shade200,
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

/// ========================= Section Card: Personal Info, Skills, etc =========================
class SectionCard extends StatelessWidget {
  final IconData leadingIcon;
  final Color leadingColor;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final VoidCallback onEdit;
  final Widget? trailing; // Add trailing widget

  const SectionCard({
    required this.leadingIcon,
    required this.leadingColor,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.onEdit,
    this.trailing, // Optional trailing widget
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 4,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: leadingColor,
          child: Icon(leadingIcon, color: Colors.white),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing,
        onTap: onEdit,
      ),
    );
  }
}

/// ========================= Personality Chips (MBTI, RIASEC) =========================
class PersonalityChips extends StatelessWidget {
  final Personality? personality;

  const PersonalityChips({this.personality});

  @override
  Widget build(BuildContext context) {
    if (personality == null) return const SizedBox.shrink();

    final mbti = personality?.mbti ?? '';
    final riasec = personality?.riasec?.join(', ') ?? '';

    return Row(
      children: [
        if (mbti.isNotEmpty) _Chip(label: 'MBTI: $mbti'),
        if (riasec.isNotEmpty) _Chip(label: 'RIASEC: $riasec'),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Text(label),
        backgroundColor: Colors.blue.shade100,
      ),
    );
  }
}

/// ========================= Bottom Navigation =========================
class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
