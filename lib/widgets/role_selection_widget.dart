import 'package:flutter/material.dart';
import '../utils/app_color.dart';

class RoleSelectionWidget extends StatelessWidget {
  final String selectedRole;
  final Function(String) onRoleSelected;

  const RoleSelectionWidget({
    Key? key,
    required this.selectedRole,
    required this.onRoleSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'I am looking for...',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRoleCard(
                context: context,
                role: 'education',
                title: 'Education',
                subtitle: 'Find universities & programs',
                icon: Icons.school_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRoleCard(
                context: context,
                role: 'career',
                title: 'Career',
                subtitle: 'Find jobs, build resume & interview simulation',
                icon: Icons.work_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String role,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = selectedRole == role;

    return InkWell(
      onTap: () => onRoleSelected(role),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}