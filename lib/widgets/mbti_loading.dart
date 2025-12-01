import 'dart:async';
import 'package:flutter/material.dart';
import '../../utils/app_color.dart';

class CalculatingResultWidget extends StatefulWidget {
  const CalculatingResultWidget({Key? key}) : super(key: key);

  @override
  State<CalculatingResultWidget> createState() => _CalculatingResultWidgetState();
}

class _CalculatingResultWidgetState extends State<CalculatingResultWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int _textIndex = 0;
  Timer? _textTimer;

  // Rotating messages to keep the user engaged
  final List<String> _loadingMessages = [
    "Analyzing your responses...",
    "Mapping cognitive functions...",
    "Identifying personality traits...",
    "Calculating match percentage...",
    "Finalizing your profile..."
  ];

  @override
  void initState() {
    super.initState();

    // 1. Setup Breathing/Pulsing Animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 2. Setup Text Rotation
    _textTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      if (mounted) {
        setState(() {
          _textIndex = (_textIndex + 1) % _loadingMessages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white, // Or AppColors.background
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Central Graphic
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer ripples
              _buildRipple(delay: 0),
              _buildRipple(delay: 500),

              // Main Core Icon
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.7),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 48),

          // Rotating Text with Fade Animation
          SizedBox(
            height: 60, // Fixed height to prevent jumping
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.2),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Text(
                _loadingMessages[_textIndex],
                key: ValueKey<int>(_textIndex),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Subtext
          Text(
            "Please wait a moment",
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 32),

          // Linear Progress Indicator
          SizedBox(
            width: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRipple({required int delay}) {
    return _PulsingCircle(
      startDelay: delay,
      color: AppColors.primary.withOpacity(0.1),
    );
  }
}

// Helper widget for the background ripples
class _PulsingCircle extends StatefulWidget {
  final int startDelay;
  final Color color;

  const _PulsingCircle({
    required this.startDelay,
    required this.color,
  });

  @override
  State<_PulsingCircle> createState() => _PulsingCircleState();
}

class _PulsingCircleState extends State<_PulsingCircle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 3.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: widget.startDelay), () {
      if (mounted) _controller.repeat();
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
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 80, // Same size as main circle
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withOpacity(
                widget.color.opacity * _opacityAnimation.value,
              ),
            ),
          ),
        );
      },
    );
  }
}