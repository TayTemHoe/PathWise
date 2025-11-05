import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../model/program.dart';
import '../model/branch.dart';
import '../model/university.dart';
import '../utils/app_color.dart';
import '../utils/currency_utils.dart';

class ProgramCard extends StatelessWidget {
  final ProgramModel program;
  final UniversityModel? university;
  final BranchModel? branch;
  final VoidCallback onTap;
  final VoidCallback onCompare;
  final bool isInCompareList;
  final bool canCompare;
  final bool isLoadingDetails;

  const ProgramCard({
    super.key,
    required this.program,
    this.university,
    this.branch,
    required this.onTap,
    required this.onCompare,
    required this.isInCompareList,
    required this.canCompare,
    this.isLoadingDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final isTopRanked = program.isTopRanked;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isTopRanked
                ? _getTopRankColor().withOpacity(0.2)
                : Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: isTopRanked
            ? Border.all(color: _getTopRankColor(), width: 2)
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
                _buildInstitutionInfo(),
                const SizedBox(height: 12),
                if (program.durationMonths != null || program.intakePeriod.isNotEmpty || _formatTuitionFee() != 'N/A')...[
                  _buildProgramDetails(),
                  const SizedBox(height: 16),
                ],
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Align logo to the top
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: program.isTopRanked
                  ? [_getTopRankColor(), _getTopRankColor().withOpacity(0.7)]
                  : [Colors.grey[300]!, Colors.grey[200]!],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(2),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: university?.universityLogo != null
                  ? CachedNetworkImage(
                imageUrl: university!.universityLogo,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                errorWidget: (context, url, error) =>
                const Icon(
                  Icons.school,
                  color: AppColors.primary,
                  size: 24,
                ),
              )
                  : const Icon(
                Icons.school,
                color: AppColors.primary,
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // MODIFIED: Use a Wrap to hold study level and ranking badge
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (program.studyLevel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppColors.secondary.withOpacity(0.3)),
                      ),
                      child: Text(
                        program.studyLevel!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  // NEW: Call to the new ranking badge
                  _buildRankingBadge(),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                program.programName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              _buildSubjectArea(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectArea() {
    // Check for null or empty string. This is independent.
    if (program.subjectArea == null || program.subjectArea!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4), // Added a little more space
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Vertically center icon and text
        children: [
          const Icon(
            Icons.category_outlined, // A clean, professional icon
            size: 13, // Small and subtle
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 4), // Space between icon and text
          Flexible( // Use Flexible to handle long text gracefully
            child: Text(
              program.subjectArea!, // The subject text itself (no "in")
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis, // Truncate with '...'
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Widget to display just the ranking badge
  Widget _buildRankingBadge() {
    if (!program.hasSubjectRanking) return const SizedBox.shrink();

    final isTop3 = program.minSubjectRanking! <= 3;
    final isTop100 = program.minSubjectRanking! <= 100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Matched padding
      decoration: BoxDecoration(
        gradient: isTop3
            ? LinearGradient(
          colors: [_getTopRankColor(), _getTopRankColor().withOpacity(0.8)],
        )
            : null,
        color: isTop3 ? null : (isTop100 ? AppColors.primary.withOpacity(
            0.1) : Colors.grey[100]),
        borderRadius: BorderRadius.circular(6), // Matched radius
        boxShadow: isTop3
            ? [
          BoxShadow(
            color: _getTopRankColor().withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ]
            : null,
        border: Border.all(
          color: isTop3
              ? _getTopRankColor()
              : (isTop100 ? AppColors.primary : Colors.grey[300]!),
          width: 1, // Thinner border
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isTop3)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.star,
                size: 12, // Smaller icon
                color: Colors.white,
              ),
            ),
          Text(
            program.formattedSubjectRanking, // Display only the ranking
            style: TextStyle(
              color: isTop3 ? Colors.white : (isTop100
                  ? AppColors.primary
                  : AppColors.textSecondary),
              fontSize: 11, // Matched font size
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstitutionInfo() {
    if (isLoadingDetails || university == null || branch == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Loading institution details...',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
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
              Icons.location_on,
              size: 12,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _formatInstitutionLine(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatInstitutionLine() {
    if (university == null || branch == null)
      return 'Institution details loading...';

    final uniName = university!.universityName.trim();
    final branchName = branch!.branchName.trim();
    final city = branch!.city.trim().replaceAll(RegExp(r'^,+|,+$'), '').trim();
    final country = branch!
        .country
        .trim()
        .replaceAll(RegExp(r'^,+|,+$'), '')
        .trim();

    // Remove redundancy if branch name contains university name
    String displayName;
    if (branchName.toLowerCase().contains(uniName.toLowerCase())) {
      displayName = branchName;
    } else {
      displayName = uniName;
    }

    // Build location string
    List<String> parts = [displayName];
    if (city.isNotEmpty && city != ',') parts.add(city);
    if (country.isNotEmpty && country != ',') parts.add(country);

    return parts.join(', ').replaceAll(RegExp(r',\s*,'), ',').trim();
  }

  Widget _buildProgramDetails() {
    return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            if (program.durationMonths != null) ...[
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.schedule,
                  label: 'Duration',
                  value: program.formattedDuration,
                ),
              ),
              Container(width: 1, height: 30, color: Colors.grey[300]),
            ],

            if (program.intakePeriod.isNotEmpty) ...[
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.calendar_today,
                  label: 'Intake',
                  value: _formatIntakePeriods(),
                ),
              ),
              Container(width: 1, height: 30, color: Colors.grey[300]),
            ],

            if (_formatTuitionFee() != 'N/A') ...[
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.attach_money,
                  label: 'From',
                  value: _formatTuitionFee(),
                ),
              ),
            ],
          ],
        )
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatIntakePeriods() {
    if (program.intakePeriod.length <= 2) {
      return program.intakePeriod.join(', ');
    }
    return '${program.intakePeriod.take(2).join(', ')}+';
  }

  String _formatTuitionFee() {
    if (branch == null) return 'Loading...';

    final isMalaysian = branch!.country.toLowerCase() == 'malaysia';

    String? feeStr;
    if (isMalaysian && program.minDomesticTuitionFee != null) {
      feeStr = program.minDomesticTuitionFee;
    } else if (!isMalaysian && program.minInternationalTuitionFee != null) {
      feeStr = program.minInternationalTuitionFee;
    } else if (program.minDomesticTuitionFee != null) {
      feeStr = program.minDomesticTuitionFee;
    } else if (program.minInternationalTuitionFee != null) {
      feeStr = program.minInternationalTuitionFee;
    }

    if (feeStr == null) return 'N/A';

    final feeInMYR = CurrencyUtils.convertToMYR(feeStr);
    if (feeInMYR == null || feeInMYR <= 0) return 'N/A';

    return CurrencyUtils.formatMYR(feeInMYR, compact: true);
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
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
          color: isInCompareList
              ? AppColors.accent
              : (canCompare ? Colors.white : Colors.grey[200]),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: (canCompare || isInCompareList) ? onCompare : null,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
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

  Color _getTopRankColor() {
    if (program.minSubjectRanking == 1) return const Color(0xFFFFD700); // Gold
    if (program.minSubjectRanking == 2) return const Color(0xFFC0C0C0); // Silver
    if (program.minSubjectRanking == 3) return const Color(0xFFCD7F32); // Bronze
    return AppColors.primary;
  }
}