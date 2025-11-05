import 'package:flutter/material.dart';
import 'package:path_wise/utils/app_color.dart';

class AppLoadingContent extends StatelessWidget {
  final int? progress;
  final String statusText;

  const AppLoadingContent({
    Key? key,
    this.progress,
    required this.statusText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This is the content from your AppLoadingScreen's body
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.school,
              size: 60,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 32),

          // Progress bar
          if (progress != null)
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: progress! / 100.0,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          else
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          const SizedBox(height: 16),

          // Status text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              statusText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Percentage text
          if (progress != null)
            Text(
              '$progress%',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 24),

          // Version info
          Text(
            'PathWise University Guide',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}