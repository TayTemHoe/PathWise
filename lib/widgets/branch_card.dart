// lib/widgets/branch_card.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_wise/model/university.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/branch.dart';
import '../utils/app_color.dart';

class BranchCard extends StatelessWidget {
  final BranchModel branch;
  final UniversityModel university;

  const BranchCard({
    Key? key,
    required this.branch,
    required this.university,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with branch name
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.location_city,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    branch.branchName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                // Country
                _buildInfoRow(
                  Icons.public,
                  'Country',
                  branch.country,
                  AppColors.secondary,
                ),

                if (branch.city.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.location_on,
                    'City',
                    branch.city,
                    AppColors.accent,
                  ),
                ],

                const SizedBox(height: 16),

                // View on Map Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openMap(university.universityName, branch.branchName, branch.city, branch.country),
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text(
                      'View on Map',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: AppColors.primary.withOpacity(0.5),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 25, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openMap(String uniName, String branchName, String city, String country) async {
    final queryParts = [uniName, branchName, city, country]
        .where((part) => part.isNotEmpty)
        .toList();

    // Join them with a comma and space
    // e.g., "My University, Main Campus, Big City, Country"
    final String query = queryParts.join(', ');

    // 2. URL-encode the final query
    final String encodedQuery = Uri.encodeComponent(query);

    // 3. Create the cross-platform URLs
    final Uri googleMapsUrl = Uri.parse(
      // The 'q' parameter is what Google Maps uses for its search query
        'https://www.google.com/maps/search/?api=1&query=$encodedQuery'
    );

    final Uri appleMapsUrl = Uri.parse(
      // Apple Maps uses a 'q' parameter as well
        'https://maps.apple.com/?q=$encodedQuery'
    );

    Uri urlToLaunch;

    // 4. Pick the best map for the platform
    if (Platform.isIOS) {
      urlToLaunch = appleMapsUrl;
    } else {
      // Android and web will default to Google Maps
      urlToLaunch = googleMapsUrl;
    }

    // 5. Launch the URL
    try {
      await launchUrl(urlToLaunch, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Could not launch $urlToLaunch: $e');
      // Optional: Try the other map service as a fallback
      try {
        Uri fallbackUrl = Platform.isIOS ? googleMapsUrl : appleMapsUrl;
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      } catch (e2) {
        print('Could not launch fallback map: $e2');
      }
    }
  }
}