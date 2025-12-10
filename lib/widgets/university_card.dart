import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_wise/model/branch.dart';
import '../model/university.dart';
import '../utils/app_color.dart';
import '../utils/currency_utils.dart';

class UniversityCard extends StatelessWidget {
  final UniversityModel university;
  final List<BranchModel> branches;
  final VoidCallback onTap;
  final VoidCallback onCompare;
  final VoidCallback onViewPrograms;
  final bool isInCompareList;
  final bool canCompare;
  final bool isLoadingBranches;
  final Future<int> programCount;
  final int? countryRank;

  const UniversityCard({
    super.key,
    required this.university,
    required this.onTap,
    required this.onCompare,
    required this.onViewPrograms,
    required this.isInCompareList,
    required this.canCompare,
    required this.branches,
    required this.isLoadingBranches,
    required this.programCount,
    this.countryRank,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRank = countryRank ?? university.minRanking;
    final isTop3 = effectiveRank != null && effectiveRank <= 3;

    // ✅ Use enhanced design for Top 3 (passing the effective rank)
    if (isTop3) {
      return _buildTop3Card(context, effectiveRank);
    }

    // Standard card design for others
    return _buildStandardCard(context);
  }

  Widget _buildTop3Card(BuildContext context, int rank) {
    final rankColor = _getTopRankColor(rank);

    // --- Fee Logic (Kept exactly as provided) ---
    bool hasMalaysianBranch = branches.isNotEmpty &&
        branches.any((b) => b.country.toLowerCase() == 'malaysia');

    double? domesticFeeMYR;
    double? internationalFeeMYR;

    if (university.domesticTuitionFee != null) {
      domesticFeeMYR = CurrencyUtils.convertToMYR(university.domesticTuitionFee);
    }

    if (university.internationalTuitionFee != null) {
      internationalFeeMYR = CurrencyUtils.convertToMYR(
        university.internationalTuitionFee,
      );
    }

    String feeLabel;
    double? feeAmount;

    if (hasMalaysianBranch && domesticFeeMYR != null) {
      feeLabel = 'Dom. Fees';
      feeAmount = domesticFeeMYR;
    } else if (!hasMalaysianBranch && internationalFeeMYR != null) {
      feeLabel = 'Int\'l Fees';
      feeAmount = internationalFeeMYR;
    } else if (domesticFeeMYR != null) {
      feeLabel = 'Dom. Fees';
      feeAmount = domesticFeeMYR;
    } else if (internationalFeeMYR != null) {
      feeLabel = 'Int\'l Fees';
      feeAmount = internationalFeeMYR;
    } else {
      feeLabel = '';
      feeAmount = null;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white, // ✅ Changed to White Background
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: rankColor.withOpacity(0.5),
            width: 2 // ✅ Subtle border matching rank color
        ),
        boxShadow: [
          BoxShadow(
            color: rankColor.withOpacity(0.15), // ✅ Soft colored glow
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Stack( // ✅ Used Stack to position badge Top-Right
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildBranchInfo(),
                    const SizedBox(height: 20),

                    // --- Statistics Logic (Kept exactly as provided) ---
                    FutureBuilder<int>(
                      future: programCount,
                      builder: (context, snapshot) {
                        int? count;
                        if (snapshot.hasData && snapshot.data! > 0) {
                          count = snapshot.data!;
                        }

                        final bool hasPrograms = count != null && count > 0;
                        final bool hasOtherStats = feeAmount != null ||
                            university.totalStudents != null;

                        Widget statsWidget;
                        if (!hasPrograms && !hasOtherStats) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            statsWidget = const Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          } else {
                            statsWidget = const SizedBox.shrink();
                          }
                        } else {
                          statsWidget = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasOtherStats || hasPrograms)
                                _buildStatistics(
                                  hasPrograms,
                                  count,
                                  feeLabel,
                                  feeAmount,
                                ),
                            ],
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            statsWidget,
                            const SizedBox(height: 16),
                            _buildActionButtons(context, count),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              Positioned(
                top: 0,
                right: 12, // Shifted slightly from right edge for aesthetic
                child: _buildRankBadge(rank, rankColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ Smaller, Compact "Bookmark" Style Badge
  Widget _buildRankBadge(int rank, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        // Only round bottom corners to create a "hanging banner/bookmark" look
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column( // ✅ Changed to Column for Vertical Alignment
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getRankIcon(rank),
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(height: 2),
          Text(
            '#$rank',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Standard card design
  Widget _buildStandardCard(BuildContext context) {
    final isTopRanked = university.isTopRanked;

    bool hasMalaysianBranch = branches.isNotEmpty &&
        branches.any((b) => b.country.toLowerCase() == 'malaysia');

    double? domesticFeeMYR;
    double? internationalFeeMYR;

    if (university.domesticTuitionFee != null) {
      domesticFeeMYR = CurrencyUtils.convertToMYR(university.domesticTuitionFee);
    }

    if (university.internationalTuitionFee != null) {
      internationalFeeMYR = CurrencyUtils.convertToMYR(
        university.internationalTuitionFee,
      );
    }

    String feeLabel;
    double? feeAmount;

    if (hasMalaysianBranch && domesticFeeMYR != null) {
      feeLabel = 'Dom. Fees';
      feeAmount = domesticFeeMYR;
    } else if (!hasMalaysianBranch && internationalFeeMYR != null) {
      feeLabel = 'Int\'l Fees';
      feeAmount = internationalFeeMYR;
    } else if (domesticFeeMYR != null) {
      feeLabel = 'Dom. Fees';
      feeAmount = domesticFeeMYR;
    } else if (internationalFeeMYR != null) {
      feeLabel = 'Int\'l Fees';
      feeAmount = internationalFeeMYR;
    } else {
      feeLabel = '';
      feeAmount = null;
    }

    // Logic for standard card fallback color (if needed)
    final rankForColor = countryRank ?? university.minRanking ?? 999;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isTopRanked
                ? _getTopRankColor(rankForColor).withOpacity(0.2)
                : Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: isTopRanked
            ? Border.all(color: _getTopRankColor(rankForColor), width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildBranchInfo(),
                const SizedBox(height: 12),
                FutureBuilder<int>(
                  future: programCount,
                  builder: (context, snapshot) {
                    int? count;
                    if (snapshot.hasData && snapshot.data! > 0) {
                      count = snapshot.data!;
                    }

                    final bool hasPrograms = count != null && count > 0;
                    final bool hasOtherStats =
                        feeAmount != null || university.totalStudents != null;

                    Widget statsWidget;
                    if (!hasPrograms && !hasOtherStats) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        statsWidget = const Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      } else {
                        statsWidget = const SizedBox.shrink();
                      }
                    } else {
                      statsWidget = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasOtherStats || hasPrograms)
                            _buildStatistics(
                              hasPrograms,
                              count,
                              feeLabel,
                              feeAmount,
                            ),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        statsWidget,
                        const SizedBox(height: 12),
                        _buildActionButtons(context, count),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // For standard card header, fallback to minRanking if countryRank not present
    final rank = countryRank ?? university.minRanking;

    return Row(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: rank != null && rank <= 3
                  ? [_getTopRankColor(rank), _getTopRankColor(rank).withOpacity(0.7)]
                  : [Colors.grey[300]!, Colors.grey[200]!],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(2),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(
                imageUrl: university.universityLogo,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.school,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUniversityInfo(),
              const SizedBox(height: 6),
              Text(
                university.universityName,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUniversityInfo() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (university.minRanking != null) _buildRankingBadge(),
        // _buildInfoChip(
        //   icon: Icons.business,
        //   label: university.institutionType,
        //   color: AppColors.secondary,
        // ),
        if (university.totalFacultyStaff != null)
          _buildInfoChip(
            icon: Icons.group,
            label: _formatNumber(university.totalFacultyStaff!),
            color: AppColors.primary,
          ),
      ],
    );
  }

  Widget _buildRankingBadge() {
    final isTopRanked = university.isTopRanked;
    final rank = countryRank ?? university.minRanking ?? 999;

    String rankingText;
    // Logic to show rank range or single rank
    if (university.maxRanking == null ||
        university.minRanking == university.maxRanking) {
      rankingText = 'QS #${university.minRanking}';
    } else {
      rankingText = 'QS #${university.minRanking}–${university.maxRanking}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: rank <= 3
            ? LinearGradient(
          colors: [
            _getTopRankColor(rank),
            _getTopRankColor(rank).withOpacity(0.8),
          ],
        )
            : null,
        color: rank <= 3 ? null : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        boxShadow: rank <= 3
            ? [
          BoxShadow(
            color: _getTopRankColor(rank).withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ]
            : null,
        border: Border.all(color: AppColors.secondary.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (rank <= 3)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.star, size: 14, color: Colors.white),
            ),
          Text(
            rankingText,
            style: TextStyle(
              color: rank <= 3 ? Colors.white : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchInfo() {
    if (branches.isEmpty) {
      if (isLoadingBranches) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Loading branch information...',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      } else {
        return const SizedBox.shrink();
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.05),
            AppColors.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.location_city,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _formatLocation(branches.first),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (branches.length > 1) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Text(
                '+ ${branches.length - 1} more',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatistics(
      bool hasProgramStat,
      int? programCount,
      String feeLabel,
      double? feeAmount,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (hasProgramStat) ...[
            _buildStat(
              icon: Icons.school,
              label: 'Programs',
              value: _formatNumber(programCount ?? 0),
            ),
            if (feeAmount != null || university.totalStudents != null)
              Container(width: 1, height: 30, color: Colors.grey[300]),
          ],
          if (feeAmount != null) ...[
            _buildStat(
              icon: Icons.attach_money,
              label: feeLabel,
              value: CurrencyUtils.formatMYR(feeAmount, compact: true),
            ),
            if (hasProgramStat || university.totalStudents != null)
              Container(width: 1, height: 30, color: Colors.grey[300]),
          ],
          if (university.totalStudents != null) ...[
            _buildStat(
              icon: Icons.groups,
              label: 'Students',
              value: _formatNumber(university.totalStudents!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, int? programCount) {
    final bool hasPrograms = programCount != null && programCount > 0;

    return Row(
      children: [
        if (hasPrograms)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onViewPrograms,
              icon: const Icon(Icons.school, size: 16),
              label: const Text(
                'Programs',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary.withOpacity(0.1),
                foregroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: AppColors.secondary.withOpacity(0.3)),
                ),
              ),
            ),
          ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.info_outline, size: 16),
            label: const Text(
              'Details',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          // Visual Logic: Grey background if limit reached (!canCompare) & not in list
          color: isInCompareList
              ? AppColors.accent
              : (canCompare ? Colors.white : Colors.grey[200]),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            // 🔴 CHANGE HERE: Always trigger onCompare.
            // The check for the limit happens inside the parent screen's callback.
            onTap: onCompare,

            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  // Visual Logic: Grey border if limit reached
                  color: isInCompareList
                      ? AppColors.accent
                      : (canCompare ? AppColors.accent : Colors.grey[300]!),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isInCompareList
                    ? Icons.check_circle
                    : Icons.compare_arrows_outlined,
                // Visual Logic: Grey icon if limit reached
                color: isInCompareList
                    ? Colors.white
                    : (canCompare ? AppColors.accent : Colors.grey[400]),
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatLocation(BranchModel branch) {
    final city = branch.city.trim().replaceAll(RegExp(r'^,+|,+$'), '').trim();
    final country = branch.country.trim().replaceAll(RegExp(r'^,+|,+$'), '').trim();

    if (city.isNotEmpty && country.isNotEmpty) {
      return '$city, $country';
    } else if (city.isNotEmpty) {
      return city;
    } else if (country.isNotEmpty) {
      return country;
    } else {
      return 'Location not specified';
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toString();
  }

  // ✅ UPDATED: Accepts rank argument to support Global fallback
  IconData _getRankIcon(int rank) {
    if (rank == 1) return Icons.emoji_events; // Trophy for #1
    if (rank == 2) return Icons.military_tech; // Medal for #2
    if (rank == 3) return Icons.workspace_premium; // Badge for #3
    return Icons.star;
  }

  // ✅ UPDATED: Accepts rank argument to support Global fallback
  Color _getTopRankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700); // Gold
    if (rank == 2) return const Color(0xFFC0C0C0); // Silver
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze

    return AppColors.primary;
  }
}