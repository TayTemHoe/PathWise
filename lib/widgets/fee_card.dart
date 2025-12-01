// lib/widgets/fee_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_wise/utils/currency_utils.dart';
import 'package:path_wise/utils/formatters.dart';
import '../utils/app_color.dart';

class FeeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? fee;
  final Color color;

  const FeeCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.fee,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final convertedFee = CurrencyUtils.convertToMYR(fee);
    final formattedFee = convertedFee != null
        ? NumberFormat.currency(
        locale: 'ms_MY', // Malaysian locale
        symbol: 'RM ',    // Currency symbol
        decimalDigits: 2 // Two decimal places
    ).format(convertedFee)
        : 'RM 0.00';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.08),
            color.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formattedFee,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
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