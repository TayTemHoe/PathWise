// lib/widgets/share_button_widget.dart
import 'package:flutter/material.dart';
import '../services/share_service.dart';
import '../utils/app_color.dart';

/// Reusable Share Button Widget with loading state
class ShareButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String tooltip;
  final IconData icon;
  final Color? color;
  final double? size;
  final bool showLabel;
  final String? label;

  const ShareButton({
    Key? key,
    required this.onPressed,
    this.tooltip = 'Share',
    this.icon = Icons.share_rounded,
    this.color,
    this.size = 24,
    this.showLabel = false,
    this.label,
  }) : super(key: key);

  @override
  State<ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends State<ShareButton> {
  bool _isSharing = false;

  Future<void> _handleShare() async {
    if (_isSharing) return;

    setState(() => _isSharing = true);

    try {
      widget.onPressed();
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showLabel) {
      return ElevatedButton.icon(
        onPressed: _isSharing ? null : _handleShare,
        icon: _isSharing
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.color ?? AppColors.primary,
            ),
          ),
        )
            : Icon(widget.icon, size: widget.size),
        label: Text(widget.label ?? 'Share'),
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.color ?? AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    return IconButton(
      onPressed: _isSharing ? null : _handleShare,
      icon: _isSharing
          ? SizedBox(
        width: widget.size,
        height: widget.size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.color ?? AppColors.primary,
          ),
        ),
      )
          : Icon(
        widget.icon,
        size: widget.size,
        color: widget.color,
      ),
      tooltip: widget.tooltip,
    );
  }
}

/// Share Button for AppBar with styling
class AppBarShareButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;

  const AppBarShareButton({
    Key? key,
    required this.onPressed,
    this.tooltip = 'Share',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ShareButton(
        onPressed: onPressed,
        tooltip: tooltip,
        color: AppColors.textPrimary,
      ),
    );
  }
}