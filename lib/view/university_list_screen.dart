import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_wise/utils/formatters.dart';
import 'package:path_wise/view/program_list_screen.dart';
import 'package:path_wise/view/university_details_screen.dart';
import 'package:path_wise/viewModel/university_list_view_model.dart';
import 'package:path_wise/widgets/university_card.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../model/comparison.dart';
import '../model/university.dart';
import '../model/university_filter.dart';
import '../repository/comparison_repository.dart';
import '../services/app_initialization_service.dart';
import '../services/firebase_service.dart';
import '../utils/app_color.dart';
import '../utils/currency_utils.dart';
import '../viewModel/auth_view_model.dart';
import '../viewModel/branch_view_model.dart';
import '../viewModel/university_filter_view_model.dart';
import '../viewModel/program_list_view_model.dart';
import '../viewModel/university_detail_view_model.dart';
import '../widgets/app_loading_screen.dart';
import '../widgets/filter_bottom_sheet.dart';
import 'ai_match_screen.dart';
import 'comparison_screen.dart';

class UniversityListScreen extends StatefulWidget {
  const UniversityListScreen({Key? key}) : super(key: key);

  @override
  State<UniversityListScreen> createState() => _UniversityListScreenState();
}

class _UniversityListScreenState extends State<UniversityListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _showSuggestions = false;
  List<String> _suggestions = [];
  bool _isLoadingMore = false;

  // ENHANCED: Debounce timer for search
  Timer? _searchDebounceTimer;
  static const Duration _searchDebounceDuration = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchFocusNode.addListener(_onSearchFocusChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<UniversityListViewModel>();
      final filterVM = context.read<FilterViewModel>();

      // Load filter options in background
      filterVM.loadFilterOptions();

      // CRITICAL: Ensure Malaysian default is set
      if (viewModel.filter.shouldDefaultToMalaysia == false &&
          viewModel.filter.country == null) {
        // Reset to Malaysian default
        viewModel.applyFilter(
          const UniversityFilterModel(shouldDefaultToMalaysia: true),
        );
      }

      // Load initial Malaysian universities if not loaded
      if (viewModel.universities.isEmpty && !viewModel.isLoading) {
        viewModel.loadUniversities();
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final currentScroll = _scrollController.position.pixels;
    final maxScroll = _scrollController.position.maxScrollExtent;

    // Trigger loading at 70% scroll position
    if (currentScroll >= maxScroll * 0.7 && !_isLoadingMore) {
      _loadMoreUniversities();
    }
  }

  Future<void> _loadMoreUniversities() async {
    final viewModel = context.read<UniversityListViewModel>();

    if (viewModel.isLoading || !viewModel.hasMore) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    await viewModel.loadUniversities();

    setState(() {
      _isLoadingMore = false;
    });
  }

  void _onSearchFocusChange() {
    setState(() {
      _showSuggestions =
          _searchFocusNode.hasFocus && _searchController.text.isNotEmpty;
    });
  }

  Future<void> _onSearchChanged(String query) async {
    // Cancel previous timer
    _searchDebounceTimer?.cancel();

    // Get the view model
    final viewModel = context.read<UniversityListViewModel>();

    if (query.isEmpty) {
      setState(() {
        _showSuggestions = false;
      });
      // Tell the VM to clear its suggestions
      viewModel.fetchSearchSuggestions('');
      return;
    }

    // Show the suggestion box immediately (it will show a loader)
    setState(() {
      _showSuggestions = true;
    });

    // Set new timer
    _searchDebounceTimer = Timer(_searchDebounceDuration, () async {
      if (!mounted) return;
      await viewModel.fetchSearchSuggestions(query);
    });
  }

  void _performSearch() {
    if (_searchController.text.isEmpty) return;

    final viewModel = context.read<UniversityListViewModel>();
    viewModel.applySearch(_searchController.text);

    setState(() {
      _showSuggestions = false;
    });
    _searchFocusNode.unfocus();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
              Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'University',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          if (kDebugMode) // Only show in debug mode
            IconButton(
              padding: EdgeInsets.symmetric(horizontal: 16),
              icon: const Icon(Icons.cleaning_services, color: Colors.orange),
              tooltip: 'Clear Cache',
              onPressed: () async {
                // Show confirmation dialog
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear All Cache?'),
                    content: const Text(
                      'This will clear all cached data and reload from server. Continue?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text('Clear Cache'),
                      ),
                    ],
                  ),
                );

                final viewModel = context.read<UniversityListViewModel>();

                if (confirmed == true && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Clearing local database...')),
                  );

                  try {
                    // Reset database and resync
                    await AppInitializationService.instance.resetAppData();
                    await viewModel.performInitialSync();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Cache cleared and resynced!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
            ),
        ],
      ),
      body: Consumer<UniversityListViewModel>(
        builder: (context, viewModel, _) {
          // Show sync progress if syncing
          if (viewModel.isSyncing) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(value: viewModel.syncProgress),
                  const SizedBox(height: 16),
                  Text(
                    'Syncing data: ${(viewModel.syncProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    viewModel.currentTable.isNotEmpty
                        ? 'Syncing ${viewModel.currentTable}...'
                        : 'Please wait...',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(),

                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Column(
                          children: [
                            _buildFilterChips(),
                            // This Expanded now has a valid height to fill
                            Expanded(child: _buildUniversityList()),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: _buildCompareFAB(),
                      ),

                      if (_showSuggestions) _buildSuggestions(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultCountInfo(UniversityListViewModel viewModel) {
    if (viewModel.universities.isEmpty ||
        (viewModel.isLoading && viewModel.universities.isEmpty)) {
      return const SizedBox.shrink();
    }

    final count = viewModel.universities.length;
    final hasMore = viewModel.hasMore;
    final hasFilters = viewModel.filter.hasActiveFilters;

    // --- 1. Professional Wording ---
    String countString = '$count';
    if (hasMore) {
      countString += '+'; // e.g., "120+"
    }
    String resultText =
        'Showing $countString ${count == 1 ? "university" : "universities"}';

    const countStyle = TextStyle(
      color: AppColors.textPrimary,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

    // --- 2. Separate "Filtered" Chip ---
    Widget filterChip = const SizedBox.shrink(); // Empty by default
    if (hasFilters) {
      filterChip = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list_alt, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              'Filtered',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // --- 3. Arrange them in a Row ---
    return Container(
      color: AppColors.background, // Match the screen background
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(resultText, style: countStyle),
          filterChip,
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: _searchFocusNode.hasFocus
                      ? AppColors.primary
                      : Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search universities...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.primary,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            context
                                .read<UniversityListViewModel>()
                                .clearSearch();
                            setState(() {
                              _suggestions = [];
                              _showSuggestions = false;
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: _onSearchChanged,
                onSubmitted: (_) => _performSearch(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Consumer<UniversityListViewModel>(
            builder: (context, viewModel, _) {
              return Container(
                height: 45,
                width: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                      onPressed: () => _showFilterSheet(viewModel),
                    ),
                    if (viewModel.filter.hasActiveFilters)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${viewModel.filter.activeFilterCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    // Consume the VM to get suggestions and loading state
    return Consumer<UniversityListViewModel>(
      builder: (context, viewModel, _) {
        // Get the states from the view model
        final bool isSearching = viewModel.isSuggestionLoading;
        final List<String> suggestions = viewModel.suggestions;

        // Use the text controller to check for empty state
        final bool hasText = _searchController.text.isNotEmpty;

        return Container(
          color: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 150),
            // From our previous discussion
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              // Calculate item count: 1 for info states, or list length
              itemCount: (isSearching || (suggestions.isEmpty && hasText))
                  ? 1
                  : suggestions.length,
              itemBuilder: (context, index) {
                // --- Loading State ---
                if (isSearching) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Searching...',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // --- Empty State ---
                if (suggestions.isEmpty && hasText) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No suggestions found',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                // This should not happen if logic is correct, but good failsafe
                if (suggestions.isEmpty) return const SizedBox.shrink();

                // --- Suggestion Item State ---
                final suggestion = suggestions[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _searchController.text = suggestion;
                      _performSearch();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              suggestion,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.north_west,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChips() {
    return Consumer<UniversityListViewModel>(
      builder: (context, viewModel, _) {
        final bool isSearchActive =
            viewModel.filter.searchQuery?.isNotEmpty ?? false;
        final bool isNotMalaysianDefault =
            !viewModel.filter.shouldDefaultToMalaysia ||
                viewModel.filter.country != null;

        // Check if we have any active filters besides Malaysian default
        if (!viewModel.filter.hasActiveFilters && !isNotMalaysianDefault) {
          return const SizedBox.shrink();
        }

        final List<Widget> filterChips = [];

        // Search filter
        if (isSearchActive) {
          filterChips.add(
            _buildFilterChip('Search: "${viewModel.filter.searchQuery}"', () {
              viewModel.removeSearchFilter();
              _searchController.clear();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {});
              });
            }),
          );
        }

        // Country filter
        if (viewModel.filter.country != null) {
          filterChips.add(
            _buildFilterChip(viewModel.filter.country!, () {
              viewModel.removeCountryFilter();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {});
              });
            }),
          );
        }

        // City filter
        if (viewModel.filter.city != null) {
          filterChips.add(
            _buildFilterChip(viewModel.filter.city!, () {
              viewModel.removeCityFilter();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {});
              });
            }),
          );
        }

        // Top N filter
        if (viewModel.filter.topN != null) {
          final topNLabel = viewModel.filter.country != null
              ? 'Top ${viewModel.filter.topN} in ${viewModel.filter.country}'
              : 'Top ${viewModel.filter.topN} Global';
          filterChips.add(
            _buildFilterChip(topNLabel, () {
              viewModel.removeTopNFilter();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {});
              });
            }),
          );
        }

        // Ranking sort filter (independent of Top N)
        if (viewModel.filter.rankingSortOrder != null) {
          final sortLabel = viewModel.filter.rankingSortOrder == 'asc'
              ? 'Best Ranked First'
              : 'Worst Ranked First';
          filterChips.add(
            _buildFilterChip(sortLabel, () {
              viewModel.removeRankingSortFilter();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {});
              });
            }),
          );
        }

        // Students filter
        if (viewModel.filter.minStudents != null ||
            viewModel.filter.maxStudents != null) {
          final minStudents = viewModel.filter.minStudents ?? 0;
          final maxStudents = viewModel.filter.maxStudents ?? 1000000;
          filterChips.add(
            _buildFilterChip(
              '${Formatters.formatNumber(minStudents)} - ${Formatters.formatNumber(maxStudents)} students',
                  () {
                viewModel.removeStudentFilter();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() {});
                });
              },
            ),
          );
        }

        // Tuition filter
        if (viewModel.filter.minTuitionFeeMYR != null ||
            viewModel.filter.maxTuitionFeeMYR != null) {
          final minFee = viewModel.filter.minTuitionFeeMYR ?? 0;
          final maxFee = viewModel.filter.maxTuitionFeeMYR ?? 500000;
          filterChips.add(
            _buildFilterChip(
              '${CurrencyUtils.formatMYR(minFee)} - ${CurrencyUtils.formatMYR(maxFee)}',
                  () {
                viewModel.removeFeesFilter();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() {});
                });
              },
            ),
          );
        }

        // Institution type filter
        if (viewModel.filter.institutionType != null) {
          filterChips.add(
            _buildFilterChip(viewModel.filter.institutionType!, () {
              viewModel.removeInstitutionTypeFilter();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {});
              });
            }),
          );
        }

        // If no chips to show, return empty
        if (filterChips.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          color: AppColors.background,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: filterChips),
                ),
              ),
              Container(width: 1, height: 30, color: Colors.grey[300]),
              TextButton.icon(
                onPressed: () {
                  viewModel.clearFilter();
                  _searchController.clear();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() {});
                  });
                },
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Clear All'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  padding: const EdgeInsets.only(left: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 16, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildCompareFAB() {
    return Consumer<UniversityListViewModel>(
      builder: (context, viewModel, _) {
        final compareCount = viewModel.compareCount;

        if (compareCount == 0) {
          return const SizedBox.shrink();
        }

        return FloatingActionButton.extended(
          onPressed: () async {
            final comparisonItems = await _getComparisonItemsFromRepo(viewModel);

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ComparisonScreen(
                  initialItems: comparisonItems,
                  fromUniversityList: true,
                ),
              ),
            );

            // Reload comparison state when returning
            if (mounted) {
              await viewModel.loadComparisonState();
              setState(() {});
            }
          },
          backgroundColor: AppColors.primary,
          elevation: 4.0,
          icon: Badge(
            label: Text('$compareCount'), // Shows actual count
            child: const Icon(Icons.compare_arrows, color: Colors.white),
          ),
          label: const Text(
            'Compare',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }

  Future<List<ComparisonItem>> _getComparisonItemsFromRepo(
      UniversityListViewModel viewModel
      ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final repo = ComparisonRepository.instance;
    return await repo.getComparisonItems(
      userId: user.uid,
      type: ComparisonType.universities,
    );
  }

  Widget _buildLoaderOrEndIndicator(UniversityListViewModel universityVM) {
    // This is the logic from the end of your old ListView.builder
    if (universityVM.isLoading) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
              const SizedBox(height: 12),
              Text(
                'Loading page ${universityVM.currentPage + 1}...',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!universityVM.hasMore) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline, size: 40, color: Colors.grey[400]),
            Text(
              'All ${universityVM.universities.length} universities loaded',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildUniversityList() {
    return Consumer2<UniversityListViewModel, BranchViewModel>(
      builder: (context, universityVM, branchVM, _) {
        // --- 1. Initial Loading State ---
        if (universityVM.universities.isEmpty && universityVM.isLoading) {
          return AppLoadingContent(statusText: universityVM.getLoadingStatus());
        }

        if (universityVM.universities.isEmpty) {
          return SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text(
                  'No universities found',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Try adjusting your filters',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: universityVM.clearFilter,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Clear Filters'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await universityVM.performIncrementalSync();
          },
          color: AppColors.primary,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildResultCountInfo(universityVM)),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  // ... (your existing list builder logic)
                  final university = universityVM.universities[index];
                  final branches = branchVM.getBranches(
                    university.universityId,
                  );
                  final bool isLoadingBranches = branchVM.isLoadingBranches(
                    university.universityId,
                  );
                  final bool hasRequestedBranches = branchVM
                      .hasRequestedBranches(university.universityId);

                  if (branches.isEmpty &&
                      !isLoadingBranches &&
                      !hasRequestedBranches) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        branchVM.loadBranches(university.universityId);
                      }
                    });
                  }

                  return UniversityCard(
                    university: university,
                    onTap: () => _navigateToDetails(university),
                    onCompare: () async {
                      // Check if limit is reached AND item is not already added
                      if (!universityVM.canCompare &&
                          !universityVM.isInCompareList(university.universityId)) {

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Maximum 3 universities can be compared at once',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            backgroundColor: AppColors.accent,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(16),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            action: SnackBarAction(
                              label: 'View',
                              textColor: Colors.white,
                              onPressed: () {
                                final comparisonItems = universityVM.getComparisonItems();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ComparisonScreen(
                                      initialItems: comparisonItems,
                                    ),
                                  ),
                                );
                              },
                            ),
                            // action: SnackBarAction(
                            //   label: 'Clear',
                            //   textColor: Colors.white,
                            //   onPressed: universityVM.clearCompare,
                            // ),
                          ),
                        );
                      } else {
                        await universityVM.toggleCompare(university);
                      }
                    },
                    onViewPrograms: () {
                      _navigateToPrograms(university);
                    },
                    isInCompareList: universityVM.isInCompareList(
                      university.universityId,
                    ),
                    canCompare: universityVM.canCompare,
                    branches: branches,
                    isLoadingBranches: isLoadingBranches,
                    programCount: universityVM.getProgramCount(
                      university.universityId,
                    ),
                    countryRank: university.countryRank,
                  );
                }, childCount: universityVM.universities.length),
              ),
              SliverToBoxAdapter(
                child: _buildLoaderOrEndIndicator(universityVM),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToDetails(UniversityModel university) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => UniversityDetailViewModel(),
          child: UniversityDetailScreen(universityId: university.universityId),
        ),
      ),
    );
  }

  void _navigateToPrograms(UniversityModel university) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => ProgramListViewModel()
            ..applyUniversityFilter(
              universityId: university.universityId,
              universityName: university.universityName,
            ),
          child: const ProgramListScreen(),
        ),
      ),
    );
  }

  void _showFilterSheet(UniversityListViewModel viewModel) {
    final filterVM = context.read<FilterViewModel>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        initialFilter: viewModel.filter,
        filterViewModel: filterVM, // Pass existing instance
        onApply: (filter) {
          viewModel.applyFilter(filter);
        },
      ),
    );
  }
}
