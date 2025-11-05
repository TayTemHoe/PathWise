import 'dart:math' as math;
import 'package:flutter/material.dart';

// Helper class to store circle properties
class _RandomCircle {
  final double left;
  final double top;
  final double radius;

  // Getter for the center point, which simplifies calculations
  Offset get center => Offset(left + radius, top + radius);

  _RandomCircle({
    required this.left,
    required this.top,
    required this.radius,
  });
}

/// A widget that displays a gradient background with randomly positioned,
/// non-overlapping, translucent circles.
class RandomCircleBackground extends StatefulWidget {
  final Widget child;
  final List<Color> gradientColors;
  final Color circleColor;
  final int minCircles;
  final int maxCircles;
  final double minSize;
  final double maxSize;
  final double minPosition;
  final double maxPosition;

  const RandomCircleBackground({
    super.key,
    required this.child,
    this.gradientColors = const [
      Colors.blue,
      Colors.blueAccent,
    ],
    this.circleColor = const Color(0x1AFFFFFF), // Colors.white.withOpacity(0.1)
    this.minCircles = 5,
    this.maxCircles = 10,
    this.minSize = 100.0,
    this.maxSize = 300.0,
    // Note: min/maxPosition now apply to both Top and Left properties.
    this.minPosition = -150.0,
    this.maxPosition = 150.0,
  });

  @override
  State<RandomCircleBackground> createState() => _RandomCircleBackgroundState();
}

class _RandomCircleBackgroundState extends State<RandomCircleBackground> {
  final List<_RandomCircle> _randomCircles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _generateRandomCircles();
  }

  void _generateRandomCircles() {
    _randomCircles.clear();

    int numberOfCircles = widget.minCircles +
        _random.nextInt((widget.maxCircles - widget.minCircles) + 1);
    double positionRange = widget.maxPosition - widget.minPosition;
    double sizeRange = widget.maxSize - widget.minSize;

    // Add a safety break to prevent infinite loops if circles can't fit
    int maxAttempts = numberOfCircles * 20;
    int attempts = 0;

    while (_randomCircles.length < numberOfCircles && attempts < maxAttempts) {
      attempts++;

      // 1. Generate a candidate circle
      final double radius =
          (widget.minSize + _random.nextDouble() * sizeRange) / 2;
      final double left =
          widget.minPosition + _random.nextDouble() * positionRange;
      final double top =
          widget.minPosition + _random.nextDouble() * positionRange;

      final _RandomCircle candidate = _RandomCircle(
        left: left,
        top: top,
        radius: radius,
      );

      // 2. Check for overlap
      if (!_isOverlapping(candidate)) {
        _randomCircles.add(candidate);
      }
    }
  }

  /// Checks if the [candidate] circle overlaps with any [_randomCircles]
  bool _isOverlapping(_RandomCircle candidate) {
    for (final _RandomCircle existing in _randomCircles) {
      // Calculate distance between centers
      final double dx = candidate.center.dx - existing.center.dx;
      final double dy = candidate.center.dy - existing.center.dy;
      final double distance = math.sqrt(dx * dx + dy * dy);

      // If distance is less than the sum of their radii, they overlap
      if (distance < (candidate.radius + existing.radius)) {
        return true; // Overlap detected
      }
    }
    return false; // No overlap
  }

  List<Widget> _buildRandomCircles() {
    return _randomCircles.map((circle) {
      final double size = circle.radius * 2;
      return Positioned(
        top: circle.top,
        left: circle.left,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.circleColor,
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. The Gradient and Circles
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.gradientColors,
            ),
          ),
          child: Stack(
            children: _buildRandomCircles(),
          ),
        ),
        // 2. The Content
        widget.child,
      ],
    );
  }
}