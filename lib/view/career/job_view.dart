// lib/view/career/job_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/viewModel/job_view_model.dart';
import 'package:path_wise/viewModel/profile_view_model.dart';
import 'package:path_wise/model/job_models.dart';
import 'package:path_wise/view/career/job_details_view.dart';
import 'package:path_wise/services/job_service.dart';

import '../../utils/app_color.dart';

// Defining KYYAP Design Colors locally
class _DesignColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color background = Color(0xFFF5F7FA);
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color cardBackground = Colors.white;
  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFFDCB6E);
  static const Color error = Color(0xFFFF0000);
  static Color shadow = Colors.black.withOpacity(0.08);
}

class JobView extends StatefulWidget {
  final String? prefilledQuery;

  const JobView({
    Key? key,
    this.prefilledQuery,
  }) : super(key: key);

  @override
  State<JobView> createState() => _JobViewState();
}

class _JobViewState extends State<JobView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Persistent controllers for filters
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _minSalaryController = TextEditingController();
  final TextEditingController _maxSalaryController = TextEditingController();

  JobFilters _tempFilters = JobFilters.empty();

  // Country selection
  String _selectedCountry = 'my';
  final Map<String, String> _supportedCountries = JobService.getSupportedCountries();

  // Pagination
  int _currentDisplayPage = 1;
  static const int _jobsPerPage = 10;
  static bool _hasLoadedInitialJobs = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    if (widget.prefilledQuery != null) {
      _searchController.text = widget.prefilledQuery!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final jobVM = context.read<JobViewModel>();
      final profileVM = context.read<ProfileViewModel>();

      // Initialize local filter state from VM
      _tempFilters = jobVM.currentFilters;
      _updateFilterControllers();

      // Wait for profile to load
      if (profileVM.profile == null && !profileVM.isLoading) {
        await profileVM.loadAll();
      }

      _setCountryFromProfile(profileVM);

      // Load saved jobs initially
      if (profileVM.uid != null) {
        await jobVM.fetchSavedJobs(profileVM.uid!);
      }

      if (widget.prefilledQuery != null) {
        _performSearch();
        _hasLoadedInitialJobs = true;
      } else if (!_hasLoadedInitialJobs && !jobVM.hasSearchResults) {
        _loadDefaultJobs();
        _hasLoadedInitialJobs = true;
      }
    });
  }

  void _updateFilterControllers() {
    if (_tempFilters.location != null) {
      _locationController.text = _tempFilters.location!;
    }
    if (_tempFilters.minSalary != null) {
      _minSalaryController.text = _tempFilters.minSalary.toString();
    }
    if (_tempFilters.maxSalary != null) {
      _maxSalaryController.text = _tempFilters.maxSalary.toString();
    }
  }

  void _setCountryFromProfile(ProfileViewModel profileVM) {
    final userCountry = profileVM.profile?.country;
    if (userCountry != null && userCountry.isNotEmpty) {
      if (_supportedCountries.containsKey(userCountry.toLowerCase())) {
        setState(() => _selectedCountry = userCountry.toLowerCase());
        return;
      }
      final countryCode = JobService.getCountryCode(userCountry);
      if (countryCode != null) {
        setState(() => _selectedCountry = countryCode);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _locationController.dispose();
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultJobs() async {
    final jobVM = context.read<JobViewModel>();
    // Reset filters for default load
    _tempFilters = JobFilters.empty();
    _updateFilterControllers();

    await jobVM.searchJobs(
      query: 'Software Developer', // Default query
      country: _selectedCountry,
    );
    setState(() => _currentDisplayPage = 1);
  }

  /// MODE 1: Search from API with filters
  /// This method searches from JSearch API with query and applies filters
  Future<void> _performSearchWithFilters() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a search term')),
      );
      return;
    }

    // Update temp filters with current values
    setState(() {
      _tempFilters = _tempFilters.copyWith(
        query: query,
        country: _selectedCountry,
      );
      _currentDisplayPage = 1;
    });

    // Close the filter sheet if open
    if (mounted) Navigator.of(context).pop();

    // Perform search with filters
    final jobVM = context.read<JobViewModel>();
    await jobVM.searchJobsWithFilters(
      query: query,
      country: _selectedCountry,
      filters: _tempFilters,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Found ${jobVM.totalSearchResults} jobs'),
          backgroundColor: _DesignColors.success,
        ),
      );
    }
  }

  /// Quick search from search bar (without opening filter sheet)
  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a search term')),
      );
      return;
    }

    setState(() {
      _tempFilters = _tempFilters.copyWith(
        query: query,
        country: _selectedCountry,
      );
      _currentDisplayPage = 1;
    });

    await context.read<JobViewModel>().searchJobsWithFilters(
      query: query,
      country: _selectedCountry,
      filters: _tempFilters,
    );
  }

  /// MODE 2: Filter existing results only (no API call)
  /// This method filters the already fetched results stored in JobViewModel
  void _applyFiltersOnly() async {
    final jobVM = context.read<JobViewModel>();

    // Check if there are existing results to filter
    if (jobVM.totalAllResults == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No existing results to filter. Please search first.'),
          backgroundColor: _DesignColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _currentDisplayPage = 1;
    });

    // Update temp filters with current country
    _tempFilters = _tempFilters.copyWith(country: _selectedCountry);

    // Apply filters to existing results (local filtering only)
    await jobVM.applyFiltersToExistingResults(_tempFilters);

    if (mounted) {
      Navigator.pop(context); // Close the sheet

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Filtered to ${jobVM.totalSearchResults} jobs'),
          backgroundColor: _DesignColors.primary,
        ),
      );
    }
  }

  void _clearFilters() {
    setState(() {
      // Keep only query, reset others
      final currentQuery = _searchController.text;
      _tempFilters = JobFilters.empty().copyWith(query: currentQuery, country: _selectedCountry);

      _locationController.clear();
      _minSalaryController.clear();
      _maxSalaryController.clear();
    });
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: _DesignColors.primary),
            SizedBox(width: 12),
            Text('Job Search Guide', style: TextStyle(color: _DesignColors.textPrimary)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HelpItem(icon: Icons.search, text: 'Use "Search" to fetch new jobs from API with filters.'),
            _HelpItem(icon: Icons.filter_alt, text: 'Use "Filter Results" to filter existing results without searching again.'),
            _HelpItem(icon: Icons.bookmark_border, text: 'Tap the bookmark icon to save jobs for later.'),
            _HelpItem(icon: Icons.public, text: 'Change country to search in different regions.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it', style: TextStyle(color: _DesignColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    // Sync temp filters with current VM state before opening
    setState(() {
      _tempFilters = context.read<JobViewModel>().currentFilters;
      // Ensure query in temp filters matches text field if user typed but didn't search yet
      if (_searchController.text.isNotEmpty) {
        _tempFilters = _tempFilters.copyWith(query: _searchController.text);
      }
      _updateFilterControllers();
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Sheet Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _DesignColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _clearFilters();
                          // Update UI inside sheet
                          setSheetState(() {});
                        },
                        child: const Text(
                          'Reset',
                          style: TextStyle(color: _DesignColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Keyword (Inside Sheet)
                        const Text('Search Keyword', style: TextStyle(fontWeight: FontWeight.w600, color: _DesignColors.textPrimary)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _searchController, // Sync with main controller
                          decoration: InputDecoration(
                            hintText: 'Job title, keywords...',
                            prefixIcon: const Icon(Icons.search, color: _DesignColors.textSecondary),
                            filled: true,
                            fillColor: _DesignColors.background,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          onChanged: (val) {
                            _tempFilters = _tempFilters.copyWith(query: val);
                          },
                        ),
                        const SizedBox(height: 20),

                        // Country Selection (Inside Sheet)
                        const Text('Country', style: TextStyle(fontWeight: FontWeight.w600, color: _DesignColors.textPrimary)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: _DesignColors.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCountry,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down, color: _DesignColors.textSecondary),
                              items: _supportedCountries.entries.map((entry) {
                                return DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(entry.value, style: const TextStyle(fontSize: 14, color: _DesignColors.textPrimary)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setSheetState(() {
                                    _selectedCountry = value;
                                    _tempFilters = _tempFilters.copyWith(country: value);
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Location
                        const Text('Location', style: TextStyle(fontWeight: FontWeight.w600, color: _DesignColors.textPrimary)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            hintText: 'City (e.g., Kuala Lumpur)',
                            filled: true,
                            fillColor: _DesignColors.background,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          onChanged: (val) {
                            _tempFilters = _tempFilters.copyWith(location: val.trim().isEmpty ? null : val.trim());
                          },
                        ),
                        const SizedBox(height: 20),

                        // Date Posted
                        const Text('Date Posted', style: TextStyle(fontWeight: FontWeight.w600, color: _DesignColors.textPrimary)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            {'label': 'Anytime', 'value': 'all'},
                            {'label': 'Today', 'value': 'today'},
                            {'label': 'Past 3 days', 'value': '3days'},
                            {'label': 'Past week', 'value': 'week'},
                            {'label': 'Past month', 'value': 'month'},
                          ].map((item) {
                            final isSelected = _tempFilters.dateRange == item['value'];
                            return FilterChip(
                              label: Text(item['label']!),
                              selected: isSelected,
                              onSelected: (selected) {
                                setSheetState(() {
                                  _tempFilters = _tempFilters.copyWith(dateRange: selected ? item['value'] : 'all');
                                });
                              },
                              selectedColor: _DesignColors.primary.withOpacity(0.2),
                              checkmarkColor: _DesignColors.primary,
                              backgroundColor: _DesignColors.background,
                              labelStyle: TextStyle(
                                color: isSelected ? _DesignColors.primary : _DesignColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: isSelected ? _DesignColors.primary : Colors.transparent),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // Work Mode (Remote)
                        const Text('Work Mode', style: TextStyle(fontWeight: FontWeight.w600, color: _DesignColors.textPrimary)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: ['Remote', 'Hybrid', 'On-site'].map((mode) {
                            final isSelected = _tempFilters.remote == mode;
                            return FilterChip(
                              label: Text(mode),
                              selected: isSelected,
                              onSelected: (selected) {
                                setSheetState(() {
                                  _tempFilters = _tempFilters.copyWith(remote: selected ? mode : null);
                                });
                              },
                              selectedColor: _DesignColors.primary.withOpacity(0.2),
                              checkmarkColor: _DesignColors.primary,
                              backgroundColor: _DesignColors.background,
                              labelStyle: TextStyle(
                                color: isSelected ? _DesignColors.primary : _DesignColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: isSelected ? _DesignColors.primary : Colors.transparent),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // Salary
                        const Text('Monthly Salary (MYR)', style: TextStyle(fontWeight: FontWeight.w600, color: _DesignColors.textPrimary)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _minSalaryController,
                                decoration: InputDecoration(
                                  hintText: 'Min',
                                  filled: true,
                                  fillColor: _DesignColors.background,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (val) {
                                  _tempFilters = _tempFilters.copyWith(minSalary: int.tryParse(val));
                                },
                              ),
                            ),
                            const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('-')),
                            Expanded(
                              child: TextField(
                                controller: _maxSalaryController,
                                decoration: InputDecoration(
                                  hintText: 'Max',
                                  filled: true,
                                  fillColor: _DesignColors.background,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (val) {
                                  _tempFilters = _tempFilters.copyWith(maxSalary: int.tryParse(val));
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40), // Bottom padding
                      ],
                    ),
                  ),
                ),

                // Action Buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Consumer<JobViewModel>(
                    builder: (context, jobVM, _) {
                      final hasExistingResults = jobVM.totalAllResults > 0;

                      return Column(
                        children: [
                          // Search Button (Primary action)
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _performSearchWithFilters,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _DesignColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.search),
                              label: const Text('Search', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),

                          // Filter Results Button (Secondary action - only show if there are existing results)
                          if (hasExistingResults) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: _applyFiltersOnly,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _DesignColors.primary,
                                  side: const BorderSide(color: _DesignColors.primary, width: 2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.filter_alt),
                                label: const Text('Filter Results', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).then((_) {
      // When sheet closes, force a rebuild to update active filter counts/UI if needed
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DesignColors.background,
      appBar: AppBar(
        backgroundColor: _DesignColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Job Search',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _DesignColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
              Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: _DesignColors.textSecondary),
            onPressed: _showHelpDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: _DesignColors.primary,
          unselectedLabelColor: _DesignColors.textSecondary,
          indicatorColor: _DesignColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Explore'),
            Tab(text: 'Saved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Explore Jobs
          Column(
            children: [
              _buildSearchHeader(),
              Expanded(child: _buildJobListings()),
            ],
          ),
          // Tab 2: Saved Jobs
          _buildSavedJobsList(),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: _DesignColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Job title, keywords...',
                  prefixIcon: Icon(Icons.search, color: _DesignColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onSubmitted: (_) => _performSearch(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _showFilterSheet,
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: _tempFilters.hasActiveFilters ? _DesignColors.primary : _DesignColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _tempFilters.hasActiveFilters ? _DesignColors.primary : Colors.grey[300]!),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.tune,
                    color: _tempFilters.hasActiveFilters ? Colors.white : _DesignColors.textSecondary,
                  ),
                  if (_tempFilters.hasActiveFilters)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: _DesignColors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobListings() {
    return Consumer<JobViewModel>(
      builder: (context, jobVM, _) {
        if (jobVM.isSearching && jobVM.searchResults.isEmpty) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_DesignColors.primary)));
        }

        if (jobVM.hasError) {
          return _buildErrorState(jobVM);
        }

        if (!jobVM.hasSearchResults && !jobVM.isSearching) {
          return _buildNoResultsState();
        }

        final currentPageJobs = _getCurrentPageJobs(jobVM);
        final totalPages = _getTotalPages(jobVM);

        return RefreshIndicator(
          onRefresh: _performSearch,
          color: _DesignColors.primary,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: _DesignColors.background,
                child: Row(
                  children: [
                    Text(
                      '${jobVM.totalSearchResults} Jobs Found',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: _DesignColors.textPrimary),
                    ),
                    const Spacer(),
                    if (_tempFilters.hasActiveFilters)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _DesignColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Filtered by ${_tempFilters.activeFilterCount} criteria',
                          style: const TextStyle(fontSize: 12, color: _DesignColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: currentPageJobs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _buildJobCard(currentPageJobs[index], jobVM),
                ),
              ),
              if (totalPages > 1) _buildPaginationControls(totalPages),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSavedJobsList() {
    return Consumer<JobViewModel>(
      builder: (context, jobVM, _) {
        final savedJobs = jobVM.savedJobs;

        if (savedJobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_outline, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text('No Saved Jobs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _DesignColors.textPrimary)),
                const Text('Jobs you bookmark will appear here.', style: TextStyle(color: _DesignColors.textSecondary)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: savedJobs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _buildJobCard(savedJobs[index], jobVM),
        );
      },
    );
  }

  // --- Helpers for Pagination & Cards ---

  List<JobModel> _getCurrentPageJobs(JobViewModel jobVM) {
    final startIndex = (_currentDisplayPage - 1) * _jobsPerPage;
    final endIndex = startIndex + _jobsPerPage;
    if (startIndex >= jobVM.searchResults.length) return [];
    return jobVM.searchResults.sublist(
      startIndex,
      endIndex > jobVM.searchResults.length ? jobVM.searchResults.length : endIndex,
    );
  }

  int _getTotalPages(JobViewModel jobVM) {
    return (jobVM.searchResults.length / _jobsPerPage).ceil();
  }

  Widget _buildPaginationControls(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentDisplayPage > 1 ? () => setState(() => _currentDisplayPage--) : null,
            icon: const Icon(Icons.chevron_left),
            color: _DesignColors.primary,
          ),
          Text(
            'Page $_currentDisplayPage of $totalPages',
            style: const TextStyle(fontWeight: FontWeight.w600, color: _DesignColors.textPrimary),
          ),
          IconButton(
            onPressed: _currentDisplayPage < totalPages ? () => setState(() => _currentDisplayPage++) : null,
            icon: const Icon(Icons.chevron_right),
            color: _DesignColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(JobModel job, JobViewModel jobVM) {
    final isSaved = jobVM.isJobSaved(job.jobId);

    return Container(
      decoration: BoxDecoration(
        color: _DesignColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _DesignColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailsView(job: job))),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _DesignColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: job.employerLogo != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          job.employerLogo!,
                          fit: BoxFit.cover,
                          errorBuilder: (_,__,___) => const Icon(Icons.business, color: Colors.grey),
                        ),
                      )
                          : const Icon(Icons.business, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.jobTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _DesignColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job.companyName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: _DesignColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: isSaved ? _DesignColors.primary : Colors.grey,
                      ),
                      onPressed: () {
                        final user = context.read<ProfileViewModel>().uid;
                        if (user != null) {
                          jobVM.toggleJobSave(user, job);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please log in to save jobs')),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (job.isRemote) _buildTag('Remote', _DesignColors.success),
                    if (job.jobEmploymentTypes.isNotEmpty) _buildTag(job.jobEmploymentTypes.first, _DesignColors.primary),
                    _buildTag('${job.jobLocation.city}, ${job.jobLocation.state}', _DesignColors.textSecondary),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  job.getFormattedSalary(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _DesignColors.success,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Posted ${job.postedAt.day}/${job.postedAt.month}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    // Determine background color based on text color for contrast
    Color bgColor = color.withOpacity(0.1);
    if (color == _DesignColors.textSecondary) bgColor = Colors.grey[100]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildErrorState(JobViewModel jobVM) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: _DesignColors.error),
            const SizedBox(height: 16),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _DesignColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              jobVM.errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _DesignColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _performSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: _DesignColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            const Text(
              'No Jobs Found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _DesignColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your search terms or filters to find more opportunities.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _DesignColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HelpItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: _DesignColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: _DesignColors.textPrimary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}