// lib/view/career/job_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/viewModel/job_view_model.dart';
import 'package:path_wise/viewModel/profile_view_model.dart';
import 'package:path_wise/model/job_models.dart';
import 'package:path_wise/view/career/job_details_view.dart';
import 'package:path_wise/services/job_service.dart';

class JobView extends StatefulWidget {
  final String? prefilledQuery;

  const JobView({
    Key? key,
    this.prefilledQuery,
  }) : super(key: key);

  @override
  State<JobView> createState() => _JobViewState();
}

class _JobViewState extends State<JobView> with AutomaticKeepAliveClientMixin {
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Persistent controllers for filters (Fixes the "ualaK" typing bug)
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _minSalaryController = TextEditingController();
  final TextEditingController _maxSalaryController = TextEditingController();

  bool _showFilters = false;

  // Local state for filters (prevents auto-fetching on every click)
  JobFilters _tempFilters = JobFilters.empty();

  // Country selection
  String _selectedCountry = 'my';
  final Map<String, String> _supportedCountries = JobService.getSupportedCountries();

  // Pagination
  int _currentDisplayPage = 1;
  static const int _jobsPerPage = 10;
  static bool _hasLoadedInitialJobs = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

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

  /// The MAIN search action.
  /// Applies both the search text AND the filters currently set in the panel.
  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a search term')),
      );
      return;
    }

    // Update the temp filters with the main query and country
    setState(() {
      _tempFilters = _tempFilters.copyWith(
        query: query,
        country: _selectedCountry,
      );
      _currentDisplayPage = 1;
      _showFilters = false; // Close panel on search
    });

    // Apply to VM (VM handles whether to fetch API or filter locally)
    await context.read<JobViewModel>().applyFilters(_tempFilters);
  }

  /// Apply filters from the "Apply Filters" button
  void _applyFiltersOnly() async {
    setState(() {
      _currentDisplayPage = 1;
      _showFilters = false;
    });
    // Ensure the current search query is kept
    final currentQuery = _searchController.text.trim();
    final filtersToApply = _tempFilters.copyWith(
      query: currentQuery.isNotEmpty ? currentQuery : null,
      country: _selectedCountry,
    );

    await context.read<JobViewModel>().applyFilters(filtersToApply);
  }

  void _clearFilters() {
    setState(() {
      _tempFilters = JobFilters.empty();
      _locationController.clear();
      _minSalaryController.clear();
      _maxSalaryController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildSearchHeader(),
          if (_showFilters) Flexible(child: _buildFilterPanel()),
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
        MediaQuery.of(context).padding.top + 8,
        16,
        12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
              ),
              SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showFilters = !_showFilters;
                    // Sync local state with VM state when opening
                    if (_showFilters) {
                      _tempFilters = context.read<JobViewModel>().currentFilters;
                      _updateFilterControllers();
                    }
                  });
                },
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: _showFilters || _tempFilters.hasActiveFilters ? Color(0xFF7C3AED) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.tune,
                    color: _showFilters || _tempFilters.hasActiveFilters ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // Country Selector
          Container(
            height: 48,
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCountry,
                isExpanded: true,
                items: _supportedCountries.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value, style: TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedCountry = value);
                },
              ),
            ),
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _performSearch,
              icon: Icon(Icons.search, size: 20),
              label: Text('Search Jobs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: _clearFilters,
                        child: Text('Clear All'),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Employment Type Filter
                  Text('Employment Type', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['FULLTIME', 'PARTTIME', 'INTERN'].map((type) {
                      final isSelected = _tempFilters.employmentTypes?.contains(type) ?? false;
                      return FilterChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            final types = List<String>.from(_tempFilters.employmentTypes ?? []);
                            if (selected) {
                              types.add(type);
                            } else {
                              types.remove(type);
                            }
                            _tempFilters = _tempFilters.copyWith(
                                employmentTypes: types.isEmpty ? null : types
                            );
                          });
                        },
                        selectedColor: Color(0xFF7C3AED).withOpacity(0.2),
                        checkmarkColor: Color(0xFF7C3AED),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16),

                  // Date Posted Filter
                  Text('Date Posted', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      {'label': 'All Time', 'value': 'all'},
                      {'label': 'Today', 'value': 'today'},
                      {'label': '3 Days', 'value': '3days'},
                      {'label': 'Week', 'value': 'week'},
                      {'label': 'Month', 'value': 'month'},
                    ].map((item) {
                      final isSelected = _tempFilters.dateRange == item['value'];
                      return FilterChip(
                        label: Text(item['label']!),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            // If clicking same chip, don't unselect (must have one date range), or default to 'all'
                            _tempFilters = _tempFilters.copyWith(
                                dateRange: selected ? item['value'] : 'all'
                            );
                          });
                        },
                        selectedColor: Color(0xFF7C3AED).withOpacity(0.2),
                        checkmarkColor: Color(0xFF7C3AED),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16),

                  // Location Filter (Fixed bug using persistent controller)
                  Text('Location', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: 'City (e.g., Kuala Lumpur)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (value) {
                      _tempFilters = _tempFilters.copyWith(location: value.trim().isEmpty ? null : value.trim());
                    },
                  ),
                  SizedBox(height: 16),

                  // Salary Filter (Fixed bug using persistent controller)
                  Text('Salary Range (Optional)', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minSalaryController,
                          decoration: InputDecoration(labelText: 'Min', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            _tempFilters = _tempFilters.copyWith(minSalary: int.tryParse(val));
                          },
                        ),
                      ),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('-')),
                      Expanded(
                        child: TextField(
                          controller: _maxSalaryController,
                          decoration: InputDecoration(labelText: 'Max', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            _tempFilters = _tempFilters.copyWith(maxSalary: int.tryParse(val));
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Apply Button Area
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _applyFiltersOnly,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Apply Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
          return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED))));
        }

        if (jobVM.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                SizedBox(height: 16),
                Text('Oops! Something went wrong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(jobVM.errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                SizedBox(height: 24),
                ElevatedButton(onPressed: _performSearch, child: Text('Try Again')),
              ],
            ),
          );
        }

        if (!jobVM.hasSearchResults && !jobVM.isSearching) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.work_off, size: 80, color: Colors.grey[300]),
                SizedBox(height: 20),
                Text('No Jobs Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Try adjusting your search or filters', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        }

        final currentPageJobs = _getCurrentPageJobs(jobVM);
        final totalPages = _getTotalPages(jobVM);

        return RefreshIndicator(
          onRefresh: _performSearch,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey[50],
                child: Row(
                  children: [
                    Text('${jobVM.totalSearchResults} Jobs Found', style: TextStyle(fontWeight: FontWeight.w600)),
                    Spacer(),
                    if (_tempFilters.hasActiveFilters)
                      Text('${_tempFilters.activeFilterCount} Active Filters', style: TextStyle(fontSize: 12, color: Color(0xFF7C3AED))),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: currentPageJobs.length,
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

  // --- Helpers for Pagination & Cards (Same as before) ---

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
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentDisplayPage > 1 ? () => setState(() => _currentDisplayPage--) : null,
            icon: Icon(Icons.chevron_left),
          ),
          Text('Page $_currentDisplayPage of $totalPages'),
          IconButton(
            onPressed: _currentDisplayPage < totalPages ? () => setState(() => _currentDisplayPage++) : null,
            icon: Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(JobModel job, JobViewModel jobVM) {
    final isSaved = jobVM.isJobSaved(job.jobId);
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailsView(job: job))),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                    child: job.employerLogo != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(job.employerLogo!, fit: BoxFit.cover, errorBuilder: (_,__,___) => Icon(Icons.business)))
                        : Icon(Icons.business, color: Colors.grey),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.companyName, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700])),
                        Text('${job.jobLocation.city}, ${job.jobLocation.state}', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: isSaved ? Color(0xFF7C3AED) : Colors.grey),
                    onPressed: () => jobVM.toggleJobSave(context.read<ProfileViewModel>().uid, job),
                  )
                ],
              ),
              SizedBox(height: 12),
              Text(job.jobTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                if (job.isRemote) _buildTag('Remote', Colors.green),
                _buildTag(job.requiredExperience.experienceLevel ?? 'Entry', Colors.blue),
                if (job.jobEmploymentTypes.isNotEmpty) _buildTag(job.jobEmploymentTypes.first, Colors.orange),
              ]),
              SizedBox(height: 12),
              Text(job.getFormattedSalary(), style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}