// lib/widgets/firebase_request_monitor.dart
import 'package:flutter/material.dart';
import 'package:path_wise/services/firebase_service.dart';
import '../utils/app_color.dart';

/// Debug widget to monitor Firebase request count
/// Only shown in debug mode
class FirebaseRequestMonitor extends StatefulWidget {
  final Widget child;

  const FirebaseRequestMonitor({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<FirebaseRequestMonitor> createState() => _FirebaseRequestMonitorState();
}

class _FirebaseRequestMonitorState extends State<FirebaseRequestMonitor> {
  bool _isExpanded = false;
  int _lastRequestCount = 0;

  @override
  void initState() {
    super.initState();
    // Update every second
    Future.delayed(const Duration(seconds: 1), _updateCount);
  }

  void _updateCount() {
    if (mounted) {
      setState(() {
        _lastRequestCount = FirebaseService.getRequestCount();
      });
      Future.delayed(const Duration(seconds: 1), _updateCount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        // Only show in debug mode
        if (const bool.fromEnvironment('dart.vm.product') == false)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getColorForCount(_lastRequestCount),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _isExpanded ? _buildExpandedView() : _buildCollapsedView(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCollapsedView() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud, color: Colors.white, size: 16),
        const SizedBox(width: 6),
        Text(
          '$_lastRequestCount',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            const Text(
              'Firebase Requests',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Total: $_lastRequestCount',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _getStatusText(_lastRequestCount),
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            FirebaseService.resetRequestCount();
            setState(() {
              _lastRequestCount = 0;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
          ),
          child: const Text(
            'Reset',
            style: TextStyle(color: Colors.white, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Color _getColorForCount(int count) {
    if (count < 50) {
      return Colors.green;
    } else if (count < 100) {
      return Colors.orange;
    } else if (count < 200) {
      return Colors.deepOrange;
    } else {
      return Colors.red;
    }
  }

  String _getStatusText(int count) {
    if (count < 50) {
      return '✅ Excellent';
    } else if (count < 100) {
      return '⚠️ Good';
    } else if (count < 200) {
      return '⚠️ High usage';
    } else {
      return '🚨 Very high!';
    }
  }
}