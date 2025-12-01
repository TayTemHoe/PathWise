import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/app_color.dart';

class ExpandableHtmlContent extends StatefulWidget {
  const ExpandableHtmlContent({
    Key? key,
    required this.htmlData,
    this.collapsedMaxLines = 6,
  }) : super(key: key);

  final String htmlData;
  final int collapsedMaxLines;

  @override
  _ExpandableHtmlContentState createState() => _ExpandableHtmlContentState();
}

class _ExpandableHtmlContentState extends State<ExpandableHtmlContent> {
  bool _isExpanded = false;
  bool _isOverflowing = false;
  bool _isCalculating = true; // Start in calculating state

  // Estimate the height of a single line of text.
  // This is used to calculate the collapsed height.
  // 14 (fontSize) * 1.6 (lineHeight) = 22.4
  static const double _estimatedLineHeight = 22.4;

  double get _collapsedHeight => _estimatedLineHeight * widget.collapsedMaxLines;

  // Define the styles once to reuse in both visible and measurement widgets
  late final Map<String, Style> _htmlStyles;

  @override
  void initState() {
    super.initState();
    _htmlStyles = {
      "body": Style(
        fontSize: FontSize(14),
        color: AppColors.textSecondary,
        lineHeight: const LineHeight(1.6),
        margin: Margins.zero,
        padding: HtmlPaddings.zero,
        // We DO NOT use maxLines or textOverflow here
      ),
      "p": Style(
        margin: Margins.only(bottom: 8),
        padding: HtmlPaddings.zero,
      ),
      "ul": Style(
        margin: Margins.only(left: 16, bottom: 8),
        padding: HtmlPaddings.zero,
      ),
      "ol": Style(
        margin: Margins.only(left: 16, bottom: 8),
        padding: HtmlPaddings.zero,
      ),
      "li": Style(
        margin: Margins.only(bottom: 4),
        padding: HtmlPaddings.zero,
      ),
      "a": Style(
        color: AppColors.primary,
        textDecoration: TextDecoration.underline,
      ),
      "h1": Style(
        fontSize: FontSize(20),
        fontWeight: FontWeight.bold,
        margin: Margins.only(top: 8, bottom: 8),
      ),
      "h2": Style(
        fontSize: FontSize(18),
        fontWeight: FontWeight.bold,
        margin: Margins.only(top: 8, bottom: 8),
      ),
      "h3": Style(
        fontSize: FontSize(16),
        fontWeight: FontWeight.bold,
        margin: Margins.only(top: 8, bottom: 8),
      ),
      "b": Style(fontWeight: FontWeight.bold),
      "strong": Style(fontWeight: FontWeight.bold),
      "i": Style(fontStyle: FontStyle.italic),
      "em": Style(fontStyle: FontStyle.italic),
      "br": Style(margin: Margins.only(bottom: 4)),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // This stack is used for measurement
        Stack(
          children: [
            // This is the *visible* widget.
            // It's animated and constrained.
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  // If expanded or still calculating, show everything.
                  // If collapsed, constrain the height.
                  maxHeight: _isExpanded || _isCalculating
                      ? double.infinity
                      : _collapsedHeight,
                ),
                // Clip the content when collapsed
                child: ClipRect(
                  child: Html(
                    data: widget.htmlData,
                    style: _htmlStyles,
                    onLinkTap: (String? url, _, __) async {
                      if (url != null && url.isNotEmpty) {
                        await _launchURL(url);
                      }
                    },
                  ),
                ),
              ),
            ),

            // This is the *measurement* widget.
            // It's offstage, so not visible.
            // It renders the *full* content to get its height.
            if (_isCalculating)
              Offstage(
                offstage: true,
                child: Builder(
                  builder: (context) {
                    // We need to run this *after* the build phase
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      final renderBox = context.findRenderObject() as RenderBox?;
                      if (renderBox != null) {
                        final fullHeight = renderBox.size.height;
                        // If full height is greater than collapsed height (with a buffer),
                        // then we are overflowing and need the button.
                        final bool overflows =
                            fullHeight > (_collapsedHeight + _estimatedLineHeight);

                        if (mounted) {
                          setState(() {
                            _isCalculating = false;
                            _isOverflowing = overflows;
                          });
                        }
                      } else {
                        // Failsafe in case renderBox is null
                        if (mounted) {
                          setState(() {
                            _isCalculating = false;
                            // Fallback to old heuristic
                            _isOverflowing = widget.htmlData.length > 300;
                          });
                        }
                      }
                    });

                    // Render the full widget for measurement
                    return Html(
                      data: widget.htmlData,
                      style: _htmlStyles,
                    );
                  },
                ),
              ),
          ],
        ),

        // Show the button only if we're not calculating and it *is* overflowing
        if (!_isCalculating && _isOverflowing)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isExpanded ? "Read Less" : "Read More",
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _launchURL(String url) async {
    try {
      // Make sure URL has a scheme
      String processedUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        processedUrl = 'https://$url';
      }

      final Uri uri = Uri.parse(processedUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        debugPrint('Could not launch $processedUrl');
        _showUrlError('Could not open link: $url');
      }
    } catch (e) {
      debugPrint('Error parsing or launching URL: $e');
      _showUrlError('Error opening link: Invalid URL format');
    }
  }

  void _showUrlError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}