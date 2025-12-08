// lib/view/comparison_screen.dart

import 'package:flutter/material.dart';
import 'package:path_wise/view/program_list_screen.dart';
import 'package:path_wise/view/university_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../model/comparison.dart';
import '../viewModel/comparison_view_model.dart';
import '../utils/app_color.dart';
import '../widgets/app_loading_screen.dart';

class ComparisonScreen extends StatefulWidget {
  final List<ComparisonItem> initialItems;
  final bool fromProgramList;
  final bool fromUniversityList;

  const ComparisonScreen({
    Key? key,
    required this.initialItems,
    this.fromProgramList = false,
    this.fromUniversityList = false,
  }) : super(key: key);

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  late PageController _pageController;
  int _currentTabIndex = 0;
  bool _isInitializing = true; // ✅ NEW: Track initialization state

  @override
  void initState() {
    super.initState();

    // Determine initial tab from initialItems if provided
    int initialTab = 0;
    if (widget.initialItems.isNotEmpty) {
      final hasPrograms = widget.initialItems
          .any((item) => item.type == ComparisonType.programs);
      final hasUniversities = widget.initialItems
          .any((item) => item.type == ComparisonType.universities);

      if (hasUniversities && !hasPrograms) {
        initialTab = 1;
      }
    }

    _currentTabIndex = initialTab;
    _pageController = PageController(initialPage: initialTab);

    // ✅ FIXED: Initialize in the next frame to ensure ViewModel is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeViewModel();
    });
  }

  // ✅ FIXED: Proper initialization with error handling
  Future<void> _initializeViewModel() async {
    if (!mounted) return;

    try {
      final viewModel = context.read<ComparisonViewModel>();

      debugPrint('🔧 Initializing ComparisonScreen with ${widget.initialItems.length} initial items');

      // Initialize the ViewModel
      await viewModel.initialize(
        widget.initialItems.isNotEmpty ? widget.initialItems : null,
      );

      // Update tab if needed
      if (mounted) {
        _updateTabIfNeeded();
      }
    } catch (e) {
      debugPrint('❌ Error initializing ComparisonScreen: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  void _updateTabIfNeeded() {
    final viewModel = context.read<ComparisonViewModel>();

    if (viewModel.comparisonItems.isEmpty) return;

    final hasPrograms = viewModel.comparisonItems
        .any((item) => item.type == ComparisonType.programs);
    final hasUniversities = viewModel.comparisonItems
        .any((item) => item.type == ComparisonType.universities);

    int correctTabIndex = 0;

    // If ONLY universities exist, switch to Universities tab
    if (hasUniversities && !hasPrograms) {
      correctTabIndex = 1;
    }

    if (_currentTabIndex != correctTabIndex && _pageController.hasClients) {
      setState(() {
        _currentTabIndex = correctTabIndex;
      });
      _pageController.jumpToPage(correctTabIndex);
      debugPrint('📍 Switched to ${correctTabIndex == 0 ? "Programs" : "Universities"} tab');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    // ✅ REMOVED: Don't dispose the ViewModel here - it's managed by Provider
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (!_pageController.hasClients) return;

    setState(() {
      _currentTabIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    debugPrint('👆 User switched to ${index == 0 ? "Programs" : "Universities"} tab');
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentTabIndex = index;
    });
    debugPrint('📄 Page changed to ${index == 0 ? "Programs" : "Universities"}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Consumer<ComparisonViewModel>(
        builder: (context, viewModel, _) {
          // ✅ FIXED: Show loading during initialization
          if (_isInitializing || viewModel.isLoading) {
            return const AppLoadingContent(
              statusText: 'Loading comparison data...',
            );
          }

          // Build the comparison view with tabs
          return Column(
            children: [
              _buildCustomTabBar(viewModel),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: [
                    _buildPageForType(viewModel, ComparisonType.programs),
                    _buildPageForType(viewModel, ComparisonType.universities),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // --- NEW HELPER METHOD ---
  Widget _buildPageForType(ComparisonViewModel viewModel, ComparisonType type) {
    final itemsOfType = viewModel.comparisonItems
        .where((item) => item.type == type)
        .toList();

    debugPrint('🔍 ${type == ComparisonType.programs ? "Programs" : "Universities"} Tab: ${itemsOfType.length} items');

    if (itemsOfType.isNotEmpty) {
      return _buildComparisonContent(viewModel, type);
    } else {
      return _buildInPageEmptyState(type);
    }
  }

  // --- NEW WIDGET ---
  Widget _buildInPageEmptyState(ComparisonType type) {
    bool isProgram = type == ComparisonType.programs;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isProgram ? Icons.school_rounded : Icons.business_rounded,
                size: 50,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No ${isProgram ? "Programs" : "Universities"} Added',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Tap the button below to browse and add ${isProgram ? "programs" : "universities"} for comparison.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                if (isProgram) {
                  await Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProgramListScreen(
                        showOnlyRecommended: false,
                        fromComparisonScreen: true,
                      ),
                    ),
                  );
                } else {
                  await Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UniversityListScreen(
                        fromComparisonScreen: true,
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text('Browse ${isProgram ? "Programs" : "Universities"}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Compare',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        Consumer<ComparisonViewModel>(
          builder: (context, viewModel, _) {
            if (!viewModel.hasItems) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                onPressed: () => _showClearConfirmation(viewModel),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCustomTabBar(ComparisonViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 52,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFE8EAED),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: _currentTabIndex == 0
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(23),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4285F4), Color(0xFF6C63FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4285F4).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _onTabChanged(0),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(23),
                      color: Colors.transparent,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school_rounded,
                            size: 18,
                            color: _currentTabIndex == 0
                                ? Colors.white
                                : const Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Programs',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: _currentTabIndex == 0
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: _currentTabIndex == 0
                                  ? Colors.white
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _onTabChanged(1),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(23),
                      color: Colors.transparent,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.business_rounded,
                            size: 18,
                            color: _currentTabIndex == 1
                                ? Colors.white
                                : const Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Universities',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: _currentTabIndex == 1
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: _currentTabIndex == 1
                                  ? Colors.white
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildComparisonContent(ComparisonViewModel viewModel, ComparisonType filterType) {
    final items = viewModel.comparisonItems
        .where((item) => item.type == filterType)
        .toList();

    if (items.isEmpty) {
      return _buildInPageEmptyState(filterType);
    }

    final attributes = filterType == ComparisonType.programs
        ? viewModel.getProgramAttributes()
        : viewModel.getUniversityAttributes();

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildItemHeaders(items, viewModel),
          const SizedBox(height: 16),
          if (filterType == ComparisonType.universities)
            _buildMetricsSection(items, viewModel),
          _buildAttributesTable(attributes, items.length),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildItemHeaders(List<ComparisonItem> items,
      ComparisonViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .asMap()
            .entries
            .map((entry) {
          final index = entry.key;
          final item = entry.value;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : 8,
                right: index == items.length - 1 ? 0 : 8,
              ),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(17),
                            child: item.logoUrl != null &&
                                item.logoUrl!.isNotEmpty
                                ? CachedNetworkImage(
                              imageUrl: item.logoUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                              errorWidget: (context, url, error) =>
                                  Icon(
                                    item.type == ComparisonType.programs
                                        ? Icons.school_rounded
                                        : Icons.business_rounded,
                                    color: AppColors.primary,
                                    size: 36,
                                  ),
                            )
                                : Icon(
                              item.type == ComparisonType.programs
                                  ? Icons.school_rounded
                                  : Icons.business_rounded,
                              color: AppColors.primary,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => viewModel.removeItem(item.id),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricsSection(List<ComparisonItem> items,
      ComparisonViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER (Unchanged) ---
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Key Metrics',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // --- METRICS ROW (Unchanged) ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items
                .asMap()
                .entries
                .map((entry) {
              final index = entry.key;
              final item = entry.value;
              final metrics = viewModel.getUniversityMetrics(item.id);

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : 8,
                    right: index == items.length - 1 ? 0 : 8,
                  ),
                  child: Column(
                    children: metrics.isEmpty
                    // --- [UI CHANGE] "NO METRICS" STATE ---
                        ? [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1.5,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'No metrics available',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ]
                    // --- [UI CHANGE] METRIC CARD DESIGN ---
                        : metrics.map((metric) {
                      final metricColor = metric.color ?? AppColors.primary;
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              metricColor.withOpacity(0.08),
                              metricColor.withOpacity(0.02),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: metricColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // LABEL
                            Text(
                              metric.label,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // VALUE
                            Text(
                              metric.value ?? 'N/A',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: metric.value != null
                                    ? metricColor
                                    : Colors.grey,
                                letterSpacing: -0.5,
                              ),
                            ),
                            // CATEGORY CHIP
                            if (metric.category != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: metricColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  metric.category!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: metricColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributesTable(List<ComparisonAttribute> attributes,
      int itemCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // --- UI CHANGE ---
      // We now use Column and manually add Dividers for a cleaner look.
      // The 'expand' trick is used to flatten the list created by map.
      child: Column(
        children: attributes
            .asMap()
            .entries
            .map((entry) {
          final index = entry.key;
          final attribute = entry.value;

          // Return a List containing the Row and an optional Divider
          return [
            _buildAttributeRow(attribute, itemCount),
            // 'isLast' is no longer needed
            // Add a Divider if it's NOT the last item
            if (index != attributes.length - 1)
              Divider(
                color: Colors.grey[100],
                height: 1,
                thickness: 1,
                indent: 20,
                endIndent: 20,
              ),
          ];
        })
            .expand((widgets) => widgets)
            .toList(), // Flattens the List<List<Widget>>
      ),
    );
  }

  Widget _buildAttributeRow(ComparisonAttribute attribute, int itemCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- HEADER (Unchanged) ---
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  attribute.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              InkWell(
                onTap: () => _showTooltip(attribute.tooltip),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        // --- VALUES ROW (UI Changed) ---
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: attribute.values
                .asMap()
                .entries
                .map((entry) {
              final index = entry.key;
              final value = entry.value ?? '—';

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : 8,
                    right: index == itemCount - 1 ? 0 : 8,
                  ),
                  // --- VALUE BOX UI CHANGE ---
                  child: Container(
                    width: double.infinity, // Ensures consistent height
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      // Lighter, branded background with no border
                      color: AppColors.primary.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 13,
                        color: value == '—' || value == 'N/A'
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        fontStyle: value == '—' || value == 'N/A'
                            ? FontStyle.italic
                            : FontStyle.normal,
                        height: 1.4,
                      ),
                      // Start-aligned text is easier to read
                      textAlign: TextAlign.start,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingBar() {
    return Consumer<ComparisonViewModel>(
      builder: (context, viewModel, _) {
        if (!viewModel.hasItems) return const SizedBox.shrink();

        final ComparisonType currentType = (_currentTabIndex == 0)
            ? ComparisonType.programs
            : ComparisonType.universities;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.85)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${viewModel.getItemCountByType(currentType)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '/ 3 selected',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (viewModel.canAddMore(currentType)) ...[
                const Spacer(),
                InkWell(
                  onTap: () async {
                    if (currentType == ComparisonType.programs) {
                      await Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProgramListScreen(
                            showOnlyRecommended: false,
                            fromComparisonScreen: true,
                          ),
                        ),
                      );
                    } else {
                      await Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UniversityListScreen(
                            fromComparisonScreen: true,
                          ),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    children: [
                      Container(
                        height: 28,
                        width: 1.5,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(width: 20),
                      const Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Add more',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showTooltip(String message) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            contentPadding: const EdgeInsets.all(24),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                      Icons.info_outline, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Got it'),
              ),
            ],
          ),
    );
  }

  void _showClearConfirmation(ComparisonViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Clear All Items?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'This will remove all items from the comparison. Are you sure?',
          style: TextStyle(fontSize: 15, height: 1.5, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await viewModel.clearAll();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}