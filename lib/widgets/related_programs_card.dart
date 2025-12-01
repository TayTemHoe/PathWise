// lib/widgets/related_program_card.dart
import 'package:flutter/material.dart';
import '../model/program.dart';
import '../utils/app_color.dart';
import '../utils/formatters.dart';

class RelatedProgramCard extends StatelessWidget {
  final ProgramModel program;
  final VoidCallback onTap;

  const RelatedProgramCard({
    Key? key,
    required this.program,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Left side - Program info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Program name
                    Text(
                      program.programName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Info chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (program.durationMonths != null)
                          _buildInfoChip(
                            Icons.schedule,
                            Formatters.formatDuration(program.durationMonths),
                          ),
                        if (program.studyMode != null)
                          _buildInfoChip(
                            Icons.location_on_outlined,
                            program.studyMode!,
                          ),
                        if (program.hasSubjectRanking)
                          _buildRankingChip(program),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Right side - Arrow icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingChip(ProgramModel program) {
    Color rankColor = AppColors.primary;
    if (program.isTopRanked) {
      if (program.minSubjectRanking == 1) {
        rankColor = AppColors.topRankedGold;
      } else if (program.minSubjectRanking == 2) {
        rankColor = AppColors.topRankedSilver;
      } else if (program.minSubjectRanking == 3) {
        rankColor = AppColors.topRankedBronze;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: rankColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: rankColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            program.isTopRanked ? Icons.star : Icons.emoji_events,
            size: 14,
            color: rankColor,
          ),
          const SizedBox(width: 4),
          Text(
            program.formattedSubjectRanking,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: rankColor,
            ),
          ),
        ],
      ),
    );
  }
}