// lib/view/mbti_result_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/share_service.dart';
import '../utils/app_color.dart';
import '../viewModel/mbti_test_view_model.dart';
import '../viewModel/ai_match_view_model.dart';
import '../model/ai_match_model.dart';
import '../widgets/share_button_widget.dart';
import '../widgets/share_card_widgets.dart';
import 'mbti_test_screen.dart';
import 'dart:math' as math;

class MBTIResultScreen extends StatefulWidget {
  const MBTIResultScreen({Key? key}) : super(key: key);

  @override
  State<MBTIResultScreen> createState() => _MBTIResultScreenState();
}

class _MBTIResultScreenState extends State<MBTIResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.7, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MBTITestViewModel>(
      builder: (context, viewModel, _) {
        final result = viewModel.result;

        if (result == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Test Result')),
            body: const Center(child: Text('No result available')),
          );
        }

        return WillPopScope(
          onWillPop: () async {
            Navigator.of(context).pop(true);  // ✅ Always return true to refresh
            return false;
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => Navigator.of(context).pop(true),
              ),
              title: const Text(
                'MBTI Results',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    _buildPersonalityTypeCard(result),
                    const SizedBox(height: 24),
                    _buildTraitsList(result),
                    const SizedBox(height: 24),
                    _buildActionButtons(context, viewModel, result),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPersonalityTypeCard(result) {
    return SlideTransition(
      position: _slideAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 40,
                offset: const Offset(0, 10),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    // SVG Avatar
                    if (result.avatarSrcStatic != null &&
                        result.avatarSrcStatic.isNotEmpty)
                      Container(
                        height: 180,
                        width: 180,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: WebViewWidget(
                            controller: WebViewController()
                              ..setJavaScriptMode(JavaScriptMode.unrestricted)
                              ..setBackgroundColor(Colors.transparent)
                              ..loadRequest(Uri.parse(result.avatarSrcStatic)),
                          ),
                        ),
                      ),

                    const SizedBox(height: 28),

                    // Title
                    Text(
                      'YOUR MBTI TYPE IS:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: .5,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // MBTI Code badges (Modern)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = constraints.maxWidth;

                        // Responsive sizing
                        final isSmall = screenWidth < 350;
                        final badgeSize = isSmall ? 44.0 : 58.0;
                        final dashSize = isSmall ? 34.0 : 42.0;
                        final fontSize = isSmall ? 22.0 : 28.0;

                        final code = result.fullCode;
                        final parts = code.split('-');
                        final mainCode = parts.first.split('');
                        final suffix = parts.length > 1 ? parts.last : "";

                        return Wrap(
                          spacing: 2,
                          runSpacing: 14,
                          alignment: WrapAlignment.center,

                          children: [
                            // ---- Main MBTI letters ----
                            ...mainCode.asMap().entries.map((entry) {
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.85, end: 1.0),
                                duration: Duration(
                                  milliseconds: (400 + entry.key * 120).toInt(),
                                ),
                                curve: Curves.easeOutBack,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: _buildBadge(
                                      width: badgeSize,
                                      height: badgeSize,
                                      text: entry.value,
                                      fontSize: fontSize,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppColors.primary.withOpacity(0.95),
                                          AppColors.primary.withOpacity(0.75),
                                        ],
                                      ),
                                      shadowColor: AppColors.primary,
                                    ),
                                  );
                                },
                              );
                            }),

                            // ---- Dash “-” ----
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.8, end: 1.0),
                              duration: const Duration(milliseconds: 650),
                              curve: Curves.easeOutBack,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: _buildBadge(
                                    width: dashSize,
                                    height: badgeSize,
                                    text: "-",
                                    fontSize: fontSize,
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary.withOpacity(0.10),
                                        AppColors.primary.withOpacity(0.06),
                                      ],
                                    ),
                                    textColor: Colors.black54,
                                    border: Border.all(
                                      color: AppColors.primary.withOpacity(.2),
                                      width: 1.5,
                                    ),
                                  ),
                                );
                              },
                            ),

                            // ---- A / T suffix ----
                            if (suffix.isNotEmpty)
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.85, end: 1.0),
                                duration: const Duration(milliseconds: 750),
                                curve: Curves.easeOutBack,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: _buildBadge(
                                      width: badgeSize,
                                      height: badgeSize,
                                      text: suffix,
                                      fontSize: fontSize,
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFF8A00),
                                          Color(0xFFFF6A00),
                                        ],
                                      ),
                                      shadowColor: const Color(0xFFFF8A00),
                                    ),
                                  );
                                },
                              ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Description with Read More/Less
                    _ExpandableText(text: result.snippet, maxLines: 3),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required double width,
    required double height,
    required String text,
    required double fontSize,
    required Gradient gradient,
    Color textColor = Colors.white,
    Color shadowColor = Colors.black12,
    Border? border,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: border,
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildTraitsList(result) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              'Your Personality Traits',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ...result.traits.asMap().entries.map((entry) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: (400 + entry.key * 100).toInt()),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: _buildModernTraitCard(entry.value),
                  ),
                );
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildModernTraitCard(trait) {
    Color getColorFromName(String colorName) {
      switch (colorName.toLowerCase()) {
        case 'blue':
          return const Color(0xFF4C9AFF);
        case 'yellow':
          return const Color(0xFFFFAB00);
        case 'green':
          return const Color(0xFF36B37E);
        case 'purple':
          return const Color(0xFF6554C0);
        case 'red':
          return const Color(0xFFFF5630);
        default:
          return Colors.grey;
      }
    }

    final color = getColorFromName(trait.color);
    final percentage = trait.pct / 100;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background progress bar
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: percentage,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.08),
                            color.withOpacity(0.04),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [color, color.withOpacity(0.8)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _getIconForTrait(trait.key),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Labels
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trait.label.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: color.withOpacity(0.7),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                trait.trait,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Percentage badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color, color.withOpacity(0.8)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '${trait.pct}%',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Progress bar
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: percentage),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return FractionallySizedBox(
                              widthFactor: value,
                              alignment: Alignment.centerLeft,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [color, color.withOpacity(0.7)],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Description
                    Text(
                      trait.snippet,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    MBTITestViewModel viewModel,
    result,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Save button with gradient
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => _saveToProfile(context, result.fullCode),
              icon: const Icon(Icons.bookmark_rounded, size: 22),
              label: const Text(
                'Save to Profile',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Secondary actions row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _shareResult(context, result),
                  icon: const Icon(Icons.share_rounded, size: 20),
                  label: const Text(
                    'Share',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showRetakeConfirmation(context, viewModel),
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text(
                    'Retake',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[300]!, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIconForTrait(String key) {
    switch (key.toLowerCase()) {
      case 'introverted':
      case 'extraverted':
        return Icons.person_outline_rounded;
      case 'observant':
      case 'intuitive':
        return Icons.visibility_rounded;
      case 'thinking':
      case 'feeling':
        return Icons.favorite_rounded;
      case 'prospecting':
      case 'judging':
        return Icons.explore_rounded;
      case 'assertive':
      case 'turbulent':
        return Icons.trending_up_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  void _saveToProfile(BuildContext context, String mbtiType) async {
    final viewModel = Provider.of<AIMatchViewModel>(context, listen: false);

    // 1. Show "Saving..." snackbar immediately
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
            ),
            SizedBox(width: 16),
            Text('Saving result...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      // 2. Load latest data to prevent overwriting other fields
      await viewModel.loadProgress();

      // 3. Prepare updated profile
      final currentProfile = viewModel.personalityProfile ?? PersonalityProfile();
      final baseType = mbtiType.split('-').first;

      final updatedProfile = PersonalityProfile(
        mbti: baseType,               // Update MBTI
        riasec: currentProfile.riasec, // Keep existing
        ocean: currentProfile.ocean,   // Keep existing
      );

      // 4. Update ViewModel
      viewModel.setPersonalityProfile(updatedProfile);

      // 5. FORCE SAVE to storage and wait for it to complete
      await viewModel.saveProgress();

      if (!context.mounted) return;

      // 6. Show Success message
      ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide "Saving..."
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'MBTI result saved successfully!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: const Color(0xFF36B37E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );

      // 7. Return to previous screen immediately
      // The delay ensures the user sees the success flash briefly before leaving
      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          Navigator.of(context).pop(true);  // ✅ Return true to refresh
        }
      });

    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving result: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shareResult(BuildContext context, result) async {
    final shareResult = await ShareService.instance.shareMBTIResult(
      result: result,
    );

    // if (!shareResult.success && mounted) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text('Failed to share: ${shareResult.error ?? "Unknown error"}'),
    //       backgroundColor: Colors.red,
    //     ),
    //   );
    // }
  }

  void _showRetakeConfirmation(
    BuildContext context,
    MBTITestViewModel viewModel,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        padding: const EdgeInsets.all(28),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.restart_alt_rounded,
                  size: 48,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Retake Test?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This will clear your current results and start fresh. Your progress cannot be recovered.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[300]!, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await viewModel.restartTest();
                        if (context.mounted) {
                          Navigator.of(context).pop(false);
                        }

                        // ✅ Now push ONE fresh test screen
                        if (context.mounted) {
                          await Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const MBTITestScreen(),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Retake Test',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Expandable text widget with Read More/Less functionality
class _ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;

  const _ExpandableText({required this.text, this.maxLines = 3});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _isExpanded = false;
  bool _isTextOverflowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTextOverflow();
    });
  }

  void _checkTextOverflow() {
    final textSpan = TextSpan(
      text: widget.text,
      style: TextStyle(
        fontSize: 15,
        color: AppColors.textSecondary,
        height: 1.6,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      maxLines: widget.maxLines,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: MediaQuery.of(context).size.width - 96);

    if (mounted) {
      setState(() {
        _isTextOverflowing = textPainter.didExceedMaxLines;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.justify,
              maxLines: _isExpanded ? null : widget.maxLines,
              overflow: _isExpanded ? null : TextOverflow.ellipsis,
            ),
          ),
          if (_isTextOverflowing)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isExpanded ? 'Read Less' : 'Read More',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Animated circle widget for background decoration
class _AnimatedCircle extends StatefulWidget {
  final double size;
  final int delay;
  final AnimationController controller;

  const _AnimatedCircle({
    required this.size,
    required this.delay,
    required this.controller,
  });

  @override
  State<_AnimatedCircle> createState() => _AnimatedCircleState();
}

class _AnimatedCircleState extends State<_AnimatedCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
