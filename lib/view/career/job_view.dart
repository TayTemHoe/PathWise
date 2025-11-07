// lib/view/job_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/ViewModel/job_view_model.dart';
import 'package:path_wise/ViewModel/profile_view_model.dart';
import 'package:path_wise/model/job_models.dart';
import 'package:path_wise/view/career/job_details_view.dart';

class JobView extends StatefulWidget {
  final String? prefilledQuery; // For career suggestion navigation
  final String? prefilledLocation;

  const JobView({
    Key? key,
    this.prefilledQuery,
    this.prefilledLocation,
  }) : super(key: key);

  @override
  State<JobView> createState() => _JobViewState();
}

class _JobViewState extends State<JobView> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showFilters = false;

  // Pagination
  int _currentDisplayPage = 1;
  static const int _jobsPerPage = 10;

  // Cache flag to prevent reloading
  static bool _hasLoadedInitialJobs = false;

  @override
  bool get wantKeepAlive => true; // Keep state alive when switching tabs

  @override
  void initState() {
    super.initState();

    // Set prefilled values if provided
    if (widget.prefilledQuery != null) {
      _searchController.text = widget.prefilledQuery!;
    }
    if (widget.prefilledLocation != null) {
      _locationController.text = widget.prefilledLocation!;
    }

    // Auto-load jobs only once (first time ever visiting)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final jobVM = context.read<JobViewModel>();

      if (widget.prefilledQuery != null) {
        // If there's a prefilled query (from career suggestions), always load it
        jobVM.searchJobs(
          query: widget.prefilledQuery!,
          location: widget.prefilledLocation ?? 'Malaysia',
        );
        _hasLoadedInitialJobs = true;
      } else if (!_hasLoadedInitialJobs && !jobVM.hasSearchResults) {
        // Load default jobs only on FIRST visit ever
        _loadDefaultJobs();
        _hasLoadedInitialJobs = true;
      }
      // If jobs already loaded, do nothing (preserve cache)
    });

    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Infinite scroll is removed, pagination is manual now
    // This listener is kept for future enhancements
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Don't dispose controllers to keep state
    super.dispose();
  }

  /// Load default jobs when user first visits the page (ONLY ONCE)
  Future<void> _loadDefaultJobs() async {
    final jobVM = context.read<JobViewModel>();
    await jobVM.searchJobs(
      query: 'Software Developer OR Data Analyst OR Marketing Manager OR Designer OR Accountant',
      location: 'Malaysia',
    );
    setState(() {
      _currentDisplayPage = 1;
    });
  }

  /// Get jobs for current page
  List<JobModel> _getCurrentPageJobs(JobViewModel jobVM) {
    final startIndex = (_currentDisplayPage - 1) * _jobsPerPage;
    final endIndex = startIndex + _jobsPerPage;

    if (startIndex >= jobVM.searchResults.length) {
      return [];
    }

    return jobVM.searchResults.sublist(
      startIndex,
      endIndex > jobVM.searchResults.length ? jobVM.searchResults.length : endIndex,
    );
  }

  /// Get total number of pages
  int _getTotalPages(JobViewModel jobVM) {
    return (jobVM.searchResults.length / _jobsPerPage).ceil();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildSearchHeader(),
          if (_showFilters) _buildFilterPanel(),
          Expanded(child: _buildJobListings()),
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
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 16,
        16,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Job title, keywords...',
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: (value) => setState(() {}),
                    onSubmitted: (value) => _performSearch(),
                  ),
                ),
              ),
              SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
                child: Consumer<JobViewModel>(
                  builder: (context, jobVM, _) {
                    final hasActiveFilters = jobVM.currentFilters.hasActiveFilters;
                    return Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: hasActiveFilters ? Color(0xFF7C3AED) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.tune,
                            color: hasActiveFilters ? Colors.white : Colors.grey[700],
                          ),
                          if (hasActiveFilters)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // Location search
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'Location (e.g., Kuala Lumpur)',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                prefixIcon: Icon(Icons.location_on_outlined, color: Colors.grey[600]),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          SizedBox(height: 12),
          // Search button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _performSearch,
              icon: Icon(Icons.search, size: 20),
              label: Text(
                'Search Jobs',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Consumer<JobViewModel>(
      builder: (context, jobVM, _) {
        return Container(
          color: Colors.white,
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      jobVM.clearFilters();
                    },
                    child: Text('Clear All'),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildFilterChips(jobVM),
              SizedBox(height: 12),
              _buildAdvancedFilters(jobVM),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChips(JobViewModel jobVM) {
    final filters = jobVM.currentFilters;
    List<Widget> chips = [];

    // Work Mode chips
    for (var mode in ['Remote', 'Hybrid', 'On-site']) {
      chips.add(
        Padding(
          padding: EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(mode),
            selected: filters.remote == mode,
            onSelected: (selected) {
              final newFilters = filters.copyWith(
                remote: selected ? mode : null,
              );
              jobVM.applyFilters(newFilters);
            },
            selectedColor: Color(0xFF7C3AED).withOpacity(0.2),
            checkmarkColor: Color(0xFF7C3AED),
          ),
        ),
      );
    }

    return Wrap(
      children: chips,
    );
  }

  Widget _buildAdvancedFilters(JobViewModel jobVM) {
    return ExpansionTile(
      title: Text('Advanced Filters', style: TextStyle(fontWeight: FontWeight.w600)),
      children: [
        _buildSalaryRangeFilter(jobVM),
        _buildExperienceLevelFilter(jobVM),
        _buildIndustryFilter(jobVM),
      ],
    );
  }

  Widget _buildSalaryRangeFilter(JobViewModel jobVM) {
    return ListTile(
      title: Text('Salary Range', style: TextStyle(fontSize: 14)),
      subtitle: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Min (RM)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final minSalary = int.tryParse(value);
                if (minSalary != null) {
                  final newFilters = jobVM.currentFilters.copyWith(
                    minSalary: minSalary,
                  );
                  jobVM.applyFilters(newFilters);
                }
              },
            ),
          ),
          SizedBox(width: 8),
          Text('-'),
          SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Max (RM)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final maxSalary = int.tryParse(value);
                if (maxSalary != null) {
                  final newFilters = jobVM.currentFilters.copyWith(
                    maxSalary: maxSalary,
                  );
                  jobVM.applyFilters(newFilters);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceLevelFilter(JobViewModel jobVM) {
    final levels = ['Internship', 'Entry level', 'Mid-Senior level', 'Director'];
    return ListTile(
      title: Text('Experience Level', style: TextStyle(fontSize: 14)),
      subtitle: Wrap(
        spacing: 8,
        children: levels.map((level) {
          final isSelected = jobVM.currentFilters.experienceLevel == level;
          return ChoiceChip(
            label: Text(level, style: TextStyle(fontSize: 12)),
            selected: isSelected,
            onSelected: (selected) {
              final newFilters = jobVM.currentFilters.copyWith(
                experienceLevel: selected ? level : null,
              );
              jobVM.applyFilters(newFilters);
            },
            selectedColor: Color(0xFF7C3AED).withOpacity(0.2),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIndustryFilter(JobViewModel jobVM) {
    final industries = ['Technology', 'Finance', 'Healthcare', 'Education', 'Marketing'];
    return ListTile(
      title: Text('Industry', style: TextStyle(fontSize: 14)),
      subtitle: Wrap(
        spacing: 8,
        children: industries.map((industry) {
          final isSelected = jobVM.currentFilters.industries?.contains(industry) ?? false;
          return FilterChip(
            label: Text(industry, style: TextStyle(fontSize: 12)),
            selected: isSelected,
            onSelected: (selected) {
              final currentIndustries = List<String>.from(jobVM.currentFilters.industries ?? []);
              if (selected) {
                currentIndustries.add(industry);
              } else {
                currentIndustries.remove(industry);
              }
              final newFilters = jobVM.currentFilters.copyWith(
                industries: currentIndustries.isEmpty ? null : currentIndustries,
              );
              jobVM.applyFilters(newFilters);
            },
            selectedColor: Color(0xFF7C3AED).withOpacity(0.2),
            checkmarkColor: Color(0xFF7C3AED),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildJobListings() {
    return Consumer<JobViewModel>(
      builder: (context, jobVM, _) {
        if (jobVM.isSearching && jobVM.searchResults.isEmpty) {
          return _buildLoadingState();
        }

        if (jobVM.hasError) {
          return _buildErrorState(jobVM.errorMessage!);
        }

        if (!jobVM.hasSearchResults && !jobVM.isSearching) {
          return _buildEmptyState(hasSearched: _hasLoadedInitialJobs);
        }

        // Get jobs for current page
        final currentPageJobs = _getCurrentPageJobs(jobVM);
        final totalPages = _getTotalPages(jobVM);

        return RefreshIndicator(
          onRefresh: () async {
            if (_searchController.text.trim().isNotEmpty) {
              await _performSearch();
            } else {
              await _loadDefaultJobs();
            }
          },
          child: Column(
            children: [
              // Results count and filter summary
              Container(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${jobVM.totalSearchResults} Jobs Available',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (jobVM.currentFilters.hasActiveFilters)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFF7C3AED).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${jobVM.currentFilters.activeFilterCount} filters',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7C3AED),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Job listings
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: currentPageJobs.length,
                  itemBuilder: (context, index) {
                    final job = currentPageJobs[index];
                    return _buildJobCard(job, jobVM);
                  },
                ),
              ),

              // Pagination controls
              if (totalPages > 1) _buildPaginationControls(totalPages),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          IconButton(
            onPressed: _currentDisplayPage > 1
                ? () {
              setState(() {
                _currentDisplayPage--;
              });
              _scrollController.jumpTo(0);
            }
                : null,
            icon: Icon(Icons.chevron_left),
            color: Color(0xFF7C3AED),
            disabledColor: Colors.grey[300],
          ),

          SizedBox(width: 16),

          // Page numbers
          ...List.generate(
            totalPages > 5 ? 5 : totalPages,
                (index) {
              int pageNum;
              if (totalPages <= 5) {
                pageNum = index + 1;
              } else if (_currentDisplayPage <= 3) {
                pageNum = index + 1;
              } else if (_currentDisplayPage >= totalPages - 2) {
                pageNum = totalPages - 4 + index;
              } else {
                pageNum = _currentDisplayPage - 2 + index;
              }

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _currentDisplayPage = pageNum;
                  });
                  _scrollController.jumpTo(0);
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _currentDisplayPage == pageNum
                        ? Color(0xFF7C3AED)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _currentDisplayPage == pageNum
                          ? Color(0xFF7C3AED)
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$pageNum',
                      style: TextStyle(
                        color: _currentDisplayPage == pageNum
                            ? Colors.white
                            : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          SizedBox(width: 16),

          // Next button
          IconButton(
            onPressed: _currentDisplayPage < totalPages
                ? () {
              setState(() {
                _currentDisplayPage++;
              });
              _scrollController.jumpTo(0);
            }
                : null,
            icon: Icon(Icons.chevron_right),
            color: Color(0xFF7C3AED),
            disabledColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(JobModel job, JobViewModel jobVM) {
    final isSaved = jobVM.isJobSaved(job.jobId);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => JobDetailsView(job: job),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with company logo and save button
                Row(
                  children: [
                    // Company Logo
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: job.employerLogo != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          job.employerLogo!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.business, color: Colors.grey[400]);
                          },
                        ),
                      )
                          : Icon(Icons.business, color: Colors.grey[400]),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.companyName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${job.jobLocation.city}, ${job.jobLocation.state}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: isSaved ? Color(0xFF7C3AED) : Colors.grey[400],
                      ),
                      onPressed: () async {
                        final profileVM = context.read<ProfileViewModel>();
                        await jobVM.toggleJobSave(profileVM.uid, job);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isSaved ? 'Job removed from saved' : 'Job saved successfully!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Job Title
                Text(
                  job.jobTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                // Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (job.isRemote)
                      _buildTag('Remote', Colors.green),
                    _buildTag(job.requiredExperience.experienceLevel ?? 'Entry level', Colors.blue),
                    if (job.jobEmploymentTypes.isNotEmpty)
                      _buildTag(job.jobEmploymentTypes.first, Colors.orange),
                  ],
                ),
                SizedBox(height: 12),
                // Salary and Posted Date
                Row(
                  children: [
                    Icon(Icons.payments_outlined, size: 16, color: Color(0xFF10B981)),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        job.getFormattedSalary(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                    SizedBox(width: 4),
                    Text(
                      job.getTimeSincePosted(),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // View Details Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JobDetailsView(job: job),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF7C3AED),
                      side: BorderSide(color: Color(0xFF7C3AED)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('View Details'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
          ),
          SizedBox(height: 16),
          Text(
            'Searching for jobs...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (_searchController.text.trim().isNotEmpty) {
                  _performSearch();
                } else {
                  _loadDefaultJobs();
                }
              },
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF7C3AED),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({bool hasSearched = false}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSearched ? Icons.search_off : Icons.work_outline,
              size: 80,
              color: Colors.grey[300],
            ),
            SizedBox(height: 20),
            Text(
              hasSearched ? 'No Jobs Found' : 'Explore Job Opportunities',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              hasSearched
                  ? 'Try adjusting your search terms or filters\nto find more opportunities'
                  : 'Search for jobs by title, keywords,\nor browse our featured listings',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (hasSearched) ...[
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  _locationController.clear();
                  final jobVM = context.read<JobViewModel>();
                  jobVM.clearFilters();
                  _loadDefaultJobs();
                },
                icon: Icon(Icons.refresh),
                label: Text('View All Jobs'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    final location = _locationController.text.trim();

    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a search term')),
      );
      return;
    }

    final jobVM = context.read<JobViewModel>();
    await jobVM.searchJobs(
      query: query,
      location: location.isEmpty ? 'Malaysia' : location,
    );
  }
}
