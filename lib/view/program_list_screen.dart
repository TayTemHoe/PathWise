import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_wise/view/program_detail_screen.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../model/program.dart';
import '../model/branch.dart';
import '../model/university.dart';
import '../repository/program_filter_repository.dart';
import '../repository/program_repository.dart';
import '../services/firebase_service.dart';
import '../utils/app_color.dart';
import '../utils/currency_utils.dart';
import '../viewModel/program_list_view_model.dart';
import '../viewModel/program_filter_view_model.dart';
import '../widgets/app_loading_screen.dart';
import '../widgets/program_card.dart';
import '../widgets/program_filter_bottom_sheet.dart';

class ProgramListScreen extends StatefulWidget {
  const ProgramListScreen({Key? key}) : super(key: key);

  @override
  State<ProgramListScreen> createState() => _ProgramListScreenState();
}

class _ProgramListScreenState extends State<ProgramListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _showSuggestions = false;
  bool _isLoadingMore = false;

  // Cache for program details (university + branch)
  final Map<String, UniversityModel> _universityCache = {};
  final Map<String, BranchModel> _branchCache = {};
  final Set<String> _loadingDetails = {};
  final Set<String> _loadingStudyArea = {};

  Timer? _searchDebounceTimer;
  static const Duration _searchDebounceDuration = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchFocusNode.addListener(_onSearchFocusChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<ProgramListViewModel>();
      final filterVM = context.read<ProgramFilterViewModel>();

      // Load filter options in background
      filterVM.loadFilterOptions();

      // Load initial programs
      if (viewModel.programs.isEmpty && !viewModel.isLoading) {
        viewModel.loadPrograms();
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final currentScroll = _scrollController.position.pixels;
    final maxScroll = _scrollController.position.maxScrollExtent;

    if (currentScroll >= maxScroll * 0.7 && !_isLoadingMore) {
      _loadMorePrograms();
    }
  }

  Future<void> _loadMorePrograms() async {
    final viewModel = context.read<ProgramListViewModel>();

    if (viewModel.isLoading || !viewModel.hasMore) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    await viewModel.loadPrograms();

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
    _searchDebounceTimer?.cancel();

    final viewModel = context.read<ProgramListViewModel>();

    if (query.isEmpty) {
      setState(() {
        _showSuggestions = false;
      });
      viewModel.fetchSearchSuggestions('');
      return;
    }

    setState(() {
      _showSuggestions = true;
    });

    _searchDebounceTimer = Timer(_searchDebounceDuration, () async {
      if (!mounted) return;
      await viewModel.fetchSearchSuggestions(query);
    });
  }

  void _performSearch() {
    if (_searchController.text.isEmpty) return;

    final viewModel = context.read<ProgramListViewModel>();
    viewModel.applySearch(_searchController.text);

    setState(() {
      _showSuggestions = false;
    });
    _searchFocusNode.unfocus();
  }

  /// Load program details (university + branch)
  Future<void> _loadProgramDetails(ProgramModel program) async {
    if (_loadingDetails.contains(program.programId)) return;
    if (_universityCache.containsKey(program.universityId) &&
        _branchCache.containsKey(program.branchId)) {
      return;
    }

    _loadingDetails.add(program.programId);

    try {
      // Load university
      if (!_universityCache.containsKey(program.universityId)) {
        final uni = await FirebaseService()
            .getUniversity(program.universityId);
        if (uni != null) {
          _universityCache[program.universityId] = uni;
        }
      }

      // Load branch
      if (!_branchCache.containsKey(program.branchId)) {
        final branches = await FirebaseService()
            .getBranchesByUniversity(program.universityId);
        for (var branch in branches) {
          _branchCache[branch.branchId] = branch;
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading program details: $e');
    } finally {
      _loadingDetails.remove(program.programId);
    }
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
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Programs',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.cleaning_services, color: Colors.orange),
              tooltip: 'Clear Cache',
              onPressed: () async {
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

                if (confirmed == true && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Clearing cache...'),
                        ],
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );

                  ProgramFilterRepository.clearCache();
                  ProgramRepository.clearCaches();
                  FirebaseService.clearAllCaches();
                  CurrencyUtils.clearCache();

                  final viewModel = context.read<ProgramListViewModel>();
                  final filterVM = context.read<ProgramFilterViewModel>();

                  await filterVM.loadFilterOptions();
                  await viewModel.forceRefresh();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Cache cleared successfully!'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: SafeArea(
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
                        Expanded(child: _buildProgramList()),
                      ],
                    ),
                  ),
                  if (_showSuggestions) _buildSuggestions(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildCompareFAB(),
    );
  }

  Widget _buildResultCountInfo(ProgramListViewModel viewModel) {
    if (viewModel.programs.isEmpty ||
        (viewModel.isLoading && viewModel.programs.isEmpty)) {
      return const SizedBox.shrink();
    }

    final count = viewModel.programs.length;
    final hasMore = viewModel.hasMore;
    final hasFilters = viewModel.filter.hasActiveFilters;

    String countString = '$count';
    if (hasMore) {
      countString += '+';
    }
    String resultText =
        'Showing $countString ${count == 1 ? "program" : "programs"}';

    const countStyle = TextStyle(
      color: AppColors.textPrimary,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

    Widget filterChip = const SizedBox.shrink();
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

    return Container(
      color: AppColors.background,
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
                  hintText: 'Search programs...',
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
                      context.read<ProgramListViewModel>().clearSearch();
                      setState(() {
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
          Consumer<ProgramListViewModel>(
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
    return Consumer<ProgramListViewModel>(
      builder: (context, viewModel, _) {
        final bool isSearching = viewModel.isSuggestionLoading;
        final List<String> suggestions = viewModel.suggestions;
        final bool hasText = _searchController.text.isNotEmpty;

        return Container(
          color: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 150),
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
              itemCount: (isSearching || (suggestions.isEmpty && hasText))
                  ? 1
                  : suggestions.length,
              itemBuilder: (context, index) {
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

                if (suggestions.isEmpty) return const SizedBox.shrink();

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
    return Consumer<ProgramListViewModel>(
      builder: (context, viewModel, _) {
        final bool isSearchActive = viewModel.filter.searchQuery?.isNotEmpty ?? false;

        if (!viewModel.filter.hasActiveFilters) {
          return const SizedBox.shrink();
        }

        final List<Widget> filterChips = [];

        if (viewModel.filter.universityName != null) {
          filterChips.add(_buildFilterChip(
            'Uni: ${viewModel.filter.universityName!}',
                () {
              viewModel.removeUniversityFilter();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {});
              });
            },
          ));
        }

        if (viewModel.filter.universityIds.isNotEmpty) {
          filterChips.add(_buildFilterChip(
            viewModel.filter.universityIds.length == 1
                ? '1 university'
                : '${viewModel.filter.universityIds.length} universities',
                () {
              viewModel.removeUniversityFilter();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {});
              });
            },
          ));
        }

        // Search filter
        if (isSearchActive) {
          filterChips.add(_buildFilterChip(
            viewModel.filter.searchQuery!,
                () {
              viewModel.removeSearchFilter();
              _searchController.clear();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {});
              });
            },
          ));
        }

        // Subject area filter
        if (viewModel.filter.subjectArea != null) {
          filterChips.add(_buildFilterChip(
            viewModel.filter.subjectArea!,
                () {
              viewModel.removeSubjectAreaFilter();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {});
              });
            },
          ));
        }

        // Study modes filter
        if (viewModel.filter.studyModes.isNotEmpty) {
          filterChips.add(_buildFilterChip(
            viewModel.filter.studyModes.length == 1
                ? viewModel.filter.studyModes.first
                : '${viewModel.filter.studyModes.length} modes',
                () {
              viewModel.removeStudyModesFilter();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {});
              });
            },
          ));
        }

        // Study levels filter
        if (viewModel.filter.studyLevels.isNotEmpty) {
          filterChips.add(_buildFilterChip(
            viewModel.filter.studyLevels.length == 1
                ? viewModel.filter.studyLevels.first
                : '${viewModel.filter.studyLevels.length} levels',
                () {
              viewModel.removeStudyLevelsFilter();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {});
              });
            },
          ));
        }

        // Intake months filter
        if (viewModel.filter.intakeMonths.isNotEmpty) {
          filterChips.add(_buildFilterChip(
            viewModel.filter.intakeMonths.length == 1
                ? viewModel.filter.intakeMonths.first
                : '${viewModel.filter.intakeMonths.length} months',
                () {
              viewModel.removeIntakeMonthsFilter();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {});
              });
            },
          ));
        }

        // Ranking range filter
        if (viewModel.filter.minSubjectRanking != null ||
            viewModel.filter.maxSubjectRanking != null) {
          final minRank = viewModel.filter.minSubjectRanking?.toInt() ?? 1;
          final maxRank = viewModel.filter.maxSubjectRanking?.toInt() ?? 500;
          filterChips.add(_buildFilterChip(
            'Rank #$minRank - #$maxRank',
                () {
              viewModel.removeRankingFilter();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {});
              });
            },
          ));
        }

        // Ranking sort filter
        if (viewModel.filter.rankingSortOrder != null) {
          final sortLabel = viewModel.filter.rankingSortOrder == 'asc'
              ? 'Rank: ↑'
              : 'Rank: ↓';
          filterChips.add(_buildFilterChip(
            sortLabel,
                () {
              viewModel.removeRankingSortFilter();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {});
              });
            },
          ));
        }

        // Duration filter
        if (viewModel.filter.minDurationYears != null ||
            viewModel.filter.maxDurationYears != null) {
          final minDuration = viewModel.filter.minDurationYears ?? 1.0;
          final maxDuration = viewModel.filter.maxDurationYears ?? 6.0;
          filterChips.add(_buildFilterChip(
            '${minDuration.toStringAsFixed(1)} - ${maxDuration.toStringAsFixed(1)} years',
                () {
              viewModel.removeDurationFilter();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {});
              });
            },
          ));
        }

        // Tuition filter
        if (viewModel.filter.minTuitionFeeMYR != null ||
            viewModel.filter.maxTuitionFeeMYR != null) {
          final minFee = viewModel.filter.minTuitionFeeMYR ?? 0;
          final maxFee = viewModel.filter.maxTuitionFeeMYR ?? 500000;
          filterChips.add(_buildFilterChip(
            '${CurrencyUtils.formatMYR(minFee)} - ${CurrencyUtils.formatMYR(maxFee)}',
                () {
              viewModel.removeTuitionFilter();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {});
              });
            },
          ));
        }

        return Container(
          color: AppColors.background,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: filterChips,
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 30, color: Colors.grey[300]),
              TextButton.icon(
                onPressed: () {
                  viewModel.clearFilter();
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
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
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
    return Consumer<ProgramListViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.compareList.isEmpty) {
          return const SizedBox.shrink();
        }

        return FloatingActionButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Navigate to Compare Screen (Placeholder)...'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          backgroundColor: AppColors.primary.withOpacity(0.7),
          elevation: 4.0,
          child: Badge(
            label: Text('${viewModel.compareList.length}'),
            isLabelVisible: viewModel.compareList.isNotEmpty,
            child: const Icon(Icons.compare_arrows, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildLoaderOrEndIndicator(ProgramListViewModel programVM) {
    if (programVM.isLoading) {
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
                'Loading page ${programVM.currentPage + 1}...',
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

    if (!programVM.hasMore) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline, size: 40, color: Colors.grey[400]),
            Text(
              'All ${programVM.programs.length} programs loaded',
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

  Widget _buildProgramList() {
    return Consumer<ProgramListViewModel>(
      builder: (context, programVM, _) {
        // Initial Loading State
        if (programVM.programs.isEmpty && programVM.isLoading) {
          return AppLoadingContent(
            statusText: programVM.getLoadingStatus(),
          );
        }

        // Empty State
        if (programVM.programs.isEmpty) {
          return SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text(
                  'No programs found',
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
                  onPressed: programVM.clearFilter,
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
          onRefresh: () => programVM.forceRefresh(),
          color: AppColors.primary,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildResultCountInfo(programVM)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final program = programVM.programs[index];

                    // Load program details if not cached
                    if (!_universityCache.containsKey(program.universityId) ||
                        !_branchCache.containsKey(program.branchId)) {
                      _loadProgramDetails(program);
                    }

                    final university = _universityCache[program.universityId];
                    final branch = _branchCache[program.branchId];
                    final isLoadingDetails = _loadingDetails.contains(program.programId);

                    return ProgramCard(
                      program: program,
                      university: university,
                      branch: branch,
                      isLoadingDetails: isLoadingDetails,
                      onTap: () => _navigateToDetails(program),
                      onCompare: () {
                        if (!programVM.canCompare &&
                            !programVM.isInCompareList(program.programId)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Maximum 3 programs can be compared at once',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              backgroundColor: AppColors.accent,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              action: SnackBarAction(
                                label: 'Clear',
                                textColor: Colors.white,
                                onPressed: programVM.clearCompare,
                              ),
                            ),
                          );
                        } else {
                          programVM.toggleCompare(program);
                        }
                      },
                      isInCompareList: programVM.isInCompareList(program.programId),
                      canCompare: programVM.canCompare,
                    );
                  },
                  childCount: programVM.programs.length,
                ),
              ),
              SliverToBoxAdapter(
                child: _buildLoaderOrEndIndicator(programVM),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToDetails(ProgramModel program) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProgramDetailScreen(
          programId: program.programId,
        ),
      ),
    );
  }

  void _showFilterSheet(ProgramListViewModel viewModel) {
    final filterVM = context.read<ProgramFilterViewModel>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProgramFilterBottomSheet(
        initialFilter: viewModel.filter,
        filterViewModel: filterVM,
        onApply: (filter) {
          viewModel.applyFilter(filter);
        },
      ),
    );
  }
}