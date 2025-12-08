import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_wise/view/program_detail_screen.dart';
import 'package:path_wise/viewModel/comparison_view_model.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../model/ai_match_model.dart';
import '../model/comparison.dart';
import '../model/program_filter.dart';
import '../repository/comparison_repository.dart';
import '../viewModel/ai_match_view_model.dart';
import '../viewModel/university_list_view_model.dart';
import '../model/program.dart';
import '../model/branch.dart';
import '../model/university.dart';
import '../services/app_initialization_service.dart';
import '../utils/app_color.dart';
import '../utils/currency_utils.dart';
import '../viewModel/program_list_view_model.dart';
import '../viewModel/program_filter_view_model.dart';
import '../widgets/ai_match_pages/ai_recommendation_widgets.dart';
import '../widgets/app_loading_screen.dart';
import '../widgets/program_card.dart';
import '../widgets/program_filter_bottom_sheet.dart';
import 'ai_match_screen.dart';
import 'ai_rationale_screen.dart';
import 'comparison_screen.dart';

class ProgramListScreen extends StatefulWidget {
  final List<RecommendedSubjectArea>? aiRecommendations;
  final List<String>? aiMatchedProgramIds;
  final UserPreferences? aiUserPreferences;
  final bool showOnlyRecommended;
  final bool fromComparisonScreen;

  const ProgramListScreen({
    super.key,
    this.aiRecommendations,
    this.aiMatchedProgramIds,
    this.aiUserPreferences,
    this.showOnlyRecommended = false,
    this.fromComparisonScreen = false,
  });

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

  Timer? _searchDebounceTimer;
  static const Duration _searchDebounceDuration = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchFocusNode.addListener(_onSearchFocusChange);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewModel = context.read<ProgramListViewModel>();
      final filterVM = context.read<ProgramFilterViewModel>();
      final aiViewModel = context.read<AIMatchViewModel>();

      if (widget.fromComparisonScreen) {
        debugPrint('🔄 Loading comparison state from ComparisonScreen');
        await viewModel.loadComparisonState();
      }

      filterVM.loadFilterOptions();

      if (widget.showOnlyRecommended) {
        // ✅ CRITICAL: Always reset state when showing AI recommendations
        debugPrint('🎯 Preparing to show AI-matched programs');

        // Load AI data if not already loaded
        if (aiViewModel.matchResponse == null) {
          await aiViewModel.loadProgress();
        }

        // ✅ FIX: Always reset and reload AI matched programs
        if (widget.aiMatchedProgramIds != null && widget.aiMatchedProgramIds!.isNotEmpty) {
          debugPrint('🔄 Resetting viewModel and loading ${widget.aiMatchedProgramIds!.length} AI-matched programs');

          // Clear existing state first
          viewModel.resetToAIMode();

          // Set and load AI matched programs
          viewModel.setAIMatchedPrograms(widget.aiMatchedProgramIds!);
        } else {
          debugPrint('⚠️ No AI matched program IDs available');
        }
      } else {
        // Normal mode: Load programs with Malaysia + ranking sort
        if (viewModel.programs.isEmpty && !viewModel.isLoading) {
          await viewModel.loadPrograms();
        }
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

    final viewModel = context.read<ProgramListViewModel>();

    try {
      // Load university
      if (!_universityCache.containsKey(program.universityId)) {
        final uni = await viewModel.getUniversityForProgram(
          program.universityId,
        );
        if (uni != null) {
          _universityCache[program.universityId] = uni;
        }
      }

      // Load branch (using the new VM method, NOT FirebaseService)
      if (!_branchCache.containsKey(program.branchId)) {
        final branch = await viewModel.getBranchForProgram(program.branchId);
        if (branch != null) {
          _branchCache[program.branchId] = branch;
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
          icon: const Icon(
              Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Programs',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (widget.showOnlyRecommended) ...[
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 20, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'AI',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (kDebugMode)
            IconButton(
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.showOnlyRecommended) ...[_buildSearchBar()],
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Column(
                      children: [
                        if (!widget.showOnlyRecommended) ...[
                          _buildFilterChips(),
                        ],
                        Expanded(child: _buildProgramList()),
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
      ),
    );
  }

  void _navigateToAIRationaleScreen() async {
    final aiViewModel = context.read<AIMatchViewModel>();

    // Load progress if not already loaded
    if (aiViewModel.matchResponse == null) {
      await aiViewModel.loadProgress();
    }

    // Safety check after loading
    if (aiViewModel.matchResponse == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI match data not available'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    // Navigate to full screen
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIRationaleScreen(
          viewModel: aiViewModel,
          programCount: widget.aiMatchedProgramIds?.length ?? 0,
        ),
      ),
    );
  }

  Widget _navigateAIScreen(ProgramListViewModel programVM) {
    if (programVM.filter.hasActiveFilters) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 5, 16, 5),
      child: InkWell(
        onTap: () async {
          final aiViewModel = context.read<AIMatchViewModel>();

          // ✅ CRITICAL FIX: Always reload from SharedPreferences to get latest data
          debugPrint('🔄 Force reloading AI data from SharedPreferences...');
          await aiViewModel.loadProgress(forceRefresh: true);

          // Check if AI matches exist after loading
          if (aiViewModel.hasAIMatches &&
              aiViewModel.matchResponse != null &&
              aiViewModel.matchedProgramIds != null &&
              aiViewModel.matchedProgramIds!.isNotEmpty) {

            debugPrint('✅ Loaded ${aiViewModel.matchedProgramIds!.length} matched programs');

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProgramListScreen(
                  aiRecommendations:
                  aiViewModel.matchResponse!.recommendedSubjectAreas,
                  aiMatchedProgramIds: aiViewModel.matchedProgramIds,
                  aiUserPreferences: aiViewModel.preferences,
                  showOnlyRecommended: true,
                ),
              ),
            );
          } else {
            // Open AI matching form
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AIMatchScreen()),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'AI Personalized Program Match',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
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
        final bool isSearchActive =
            viewModel.filter.searchQuery?.isNotEmpty ?? false;

        if (!viewModel.filter.hasActiveFilters) {
          return const SizedBox.shrink();
        }

        final List<Widget> filterChips = [];

        if (viewModel.filter.universityName != null) {
          filterChips.add(
            _buildFilterChip('Uni: ${viewModel.filter.universityName!}', () {
              viewModel.removeUniversityFilter();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {});
              });
            }),
          );
        }

        if (viewModel.filter.universityIds.isNotEmpty) {
          filterChips.add(
            _buildFilterChip(
              viewModel.filter.universityIds.length == 1
                  ? '1 university'
                  : '${viewModel.filter.universityIds.length} universities',
                  () {
                viewModel.removeUniversityFilter();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() {});
                });
              },
            ),
          );
        }

        // Countries Filter
        if (viewModel.filter.countries.isNotEmpty) {
          filterChips.add(
            _buildFilterChip(
              viewModel.filter.countries.length == 1
                  ? viewModel.filter.countries.first
                  : '${viewModel.filter.countries.length} Countries',
                  () {
                viewModel.removeCountriesFilter();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() {});
                });
              },
            ),
          );
        }

        // Search filter
        if (isSearchActive) {
          filterChips.add(
            _buildFilterChip(viewModel.filter.searchQuery!, () {
              viewModel.removeSearchFilter();
              _searchController.clear();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {});
              });
            }),
          );
        }

        // Subject area filter
        if (viewModel.filter.subjectArea.isNotEmpty) {
          filterChips.add(
            _buildFilterChip(
              viewModel.filter.subjectArea.length == 1
                  ? viewModel.filter.subjectArea.first
                  : '${viewModel.filter.subjectArea.length} Subject Area',
                  () {
                viewModel.removeSubjectAreaFilter();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() {});
                });
              },
            ),
          );
        }

        // Study modes filter
        if (viewModel.filter.studyModes.isNotEmpty) {
          filterChips.add(
            _buildFilterChip(
              viewModel.filter.studyModes.length == 1
                  ? viewModel.filter.studyModes.first
                  : '${viewModel.filter.studyModes.length} Modes',
                  () {
                viewModel.removeStudyModesFilter();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() {});
                });
              },
            ),
          );
        }

        // Study levels filter
        if (viewModel.filter.studyLevels.isNotEmpty) {
          filterChips.add(
            _buildFilterChip(
              viewModel.filter.studyLevels.length == 1
                  ? viewModel.filter.studyLevels.first
                  : '${viewModel.filter.studyLevels.length} levels',
                  () {
                viewModel.removeStudyLevelsFilter();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() {});
                });
              },
            ),
          );
        }

        // Intake months filter
        if (viewModel.filter.intakeMonths.isNotEmpty) {
          filterChips.add(
            _buildFilterChip(
              viewModel.filter.intakeMonths.length == 1
                  ? viewModel.filter.intakeMonths.first
                  : '${viewModel.filter.intakeMonths.length} months',
                  () {
                viewModel.removeIntakeMonthsFilter();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() {});
                });
              },
            ),
          );
        }

        // ✅ CHANGED: Top N filter (replaces min/max ranking)
        if (viewModel.filter.topN != null) {
          final topNLabel = viewModel.filter.countries.isNotEmpty
              ? 'Top ${viewModel.filter.topN} in ${viewModel.filter.countries.join(", ")}'
              : 'Top ${viewModel.filter.topN}';

          filterChips.add(
            _buildFilterChip(topNLabel, () {
              viewModel.removeTopNFilter();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {});
              });
            }),
          );
        }

        // ✅ NEW: Ranking sort filter (independent)
        if (viewModel.filter.rankingSortOrder != null) {
          final sortLabel = viewModel.filter.rankingSortOrder == 'asc'
              ? 'Rank: ↑'
              : 'Rank: ↓';
          filterChips.add(
            _buildFilterChip(sortLabel, () {
              viewModel.removeRankingSortFilter();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {});
              });
            }),
          );
        }

        // Duration filter
        if (viewModel.filter.minDurationYears != null ||
            viewModel.filter.maxDurationYears != null) {
          final minDuration = viewModel.filter.minDurationYears ?? 1.0;
          final maxDuration = viewModel.filter.maxDurationYears ?? 6.0;
          filterChips.add(
            _buildFilterChip(
              '${minDuration.toStringAsFixed(1)} - ${maxDuration.toStringAsFixed(1)} years',
                  () {
                viewModel.removeDurationFilter();
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
                viewModel.removeTuitionFilter();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() {});
                });
              },
            ),
          );
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
        final compareCount = viewModel.compareCount;

        if (compareCount == 0) {
          return const SizedBox.shrink();
        }

        return FloatingActionButton.extended(
          onPressed: () async {
            // Fetch from repo to get ALL compared items
            final comparisonItems = await _getComparisonItemsFromRepo(
              viewModel,
            );

            if (widget.fromComparisonScreen) {
              // Navigate back to comparison screen (replace current screen)
              await Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ComparisonScreen(
                    initialItems: comparisonItems,
                    fromProgramList: true,
                  ),
                ),
              );
            } else {
              // Fresh navigation - push new comparison screen
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ComparisonScreen(
                        initialItems: comparisonItems,
                        fromProgramList: true,
                      ),
                ),
              );

              if (mounted) {
                await viewModel.loadComparisonState();
                setState(() {});
              }
            }
          },
          backgroundColor: AppColors.primary,
          elevation: 4.0,
          icon: Badge(
            label: Text('$compareCount'),
            child: const Icon(Icons.compare_arrows, color: Colors.white),
          ),
          label: Text(
            widget.fromComparisonScreen ? 'Back to Compare' : 'Compare',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        );
      },
    );
  }

  Future<List<ComparisonItem>> _getComparisonItemsFromRepo(
    ProgramListViewModel viewModel,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final repo = ComparisonRepository.instance;
    return await repo.getComparisonItems(
      userId: user.uid,
      type: ComparisonType.programs,
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
    return Consumer2<ProgramListViewModel, ComparisonViewModel>(
      builder: (context, programVM, compareVM, _) {
        // Initial Loading State
        if (programVM.programs.isEmpty && programVM.isLoading) {
          return AppLoadingContent(statusText: programVM.getLoadingStatus());
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
              if (!widget.showOnlyRecommended) ...[
                SliverToBoxAdapter(child: _navigateAIScreen(programVM)),
                SliverToBoxAdapter(child: _buildResultCountInfo(programVM)),
              ],

              if (widget.showOnlyRecommended) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.90),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          // Use a lighter border for better contrast on the gradient
                          color: AppColors.textWhite.withOpacity(0.5),
                          // <-- CHANGED
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: Icon(
                              Icons.auto_awesome,
                              color: AppColors.textWhite, // <-- CHANGED
                              size: 28,
                            ),
                            title: Text(
                              'AI-Matched Programs',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textWhite, // <-- CHANGED
                              ),
                            ),
                            subtitle: Text(
                              'Showing ${programVM.programs.length} programs matched to your profile',
                              style: TextStyle(
                                fontSize: 14,
                                // Use white with slight transparency to maintain hierarchy
                                color: AppColors.textWhite.withOpacity(
                                  0.85,
                                ), // <-- CHANGED
                              ),
                            ),
                            dense: true,
                            visualDensity: VisualDensity.compact,
                          ),

                          // --- Actions ---
                          if (widget.showOnlyRecommended &&
                              widget.aiRecommendations != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    // Style the TextButton to use white
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          AppColors.textWhite, // <-- CHANGED
                                    ),
                                    child: const Text('VIEW RATIONALE'),
                                    onPressed: () =>
                                        _navigateToAIRationaleScreen(),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    icon: const Icon(
                                      Icons.refresh_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('MATCH AGAIN'),
                                    // Style the OutlinedButton to use white
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.textWhite,
                                      // <-- CHANGED
                                      side: BorderSide(
                                        color: AppColors.textWhite.withOpacity(
                                          0.8,
                                        ), // <-- CHANGED
                                      ),
                                    ),
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const AIMatchScreen(),
                                        ),
                                      );
                                      if (mounted) {
                                        final viewModel = context
                                            .read<ProgramListViewModel>();
                                        await viewModel.forceRefresh();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final program = programVM.programs[index];

                  // Load program details if not cached
                  if (!_universityCache.containsKey(program.universityId) ||
                      !_branchCache.containsKey(program.branchId)) {
                    _loadProgramDetails(program);
                  }

                  final university = _universityCache[program.universityId];
                  final branch = _branchCache[program.branchId];
                  final isLoadingDetails = _loadingDetails.contains(
                    program.programId,
                  );

                  return ProgramCard(
                    program: program,
                    university: university,
                    branch: branch,
                    isLoadingDetails: isLoadingDetails,
                    onTap: () => _navigateToDetails(program),
                    onCompare: () async {
                      // Check if limit is reached AND item is not already added
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
                            margin: const EdgeInsets.all(16),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            action: SnackBarAction(
                              label: 'View',
                              textColor: Colors.white,
                              onPressed: () {
                                final comparisonItems = programVM.getComparisonItems();
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
                          ),
                        );
                      } else {
                        await programVM.toggleCompare(program);
                      }
                    },
                    isInCompareList: programVM.isInCompareList(
                      program.programId,
                    ),
                    canCompare: programVM.canCompare,
                  );
                }, childCount: programVM.programs.length),
              ),
              SliverToBoxAdapter(child: _buildLoaderOrEndIndicator(programVM)),
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
        builder: (context) => ProgramDetailScreen(programId: program.programId),
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
