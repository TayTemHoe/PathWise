// lib/view/job_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/ViewModel/job_view_model.dart';
import 'package:path_wise/ViewModel/profile_view_model.dart';
import 'package:path_wise/model/job_models.dart';
import 'package:path_wise/view/career/job_details_view.dart';
import 'package:path_wise/service/job_service.dart';

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
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showFilters = false;

  // Country selection
  String _selectedCountry = 'my'; // Default Malaysia
  final Map<String, String> _supportedCountries = JobService.getSupportedCountries();

  // Pagination
  int _currentDisplayPage = 1;
  static const int _jobsPerPage = 10;

  // Cache flag
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

      // Wait for profile to load if not already loaded
      if (profileVM.profile == null && !profileVM.isLoading) {
        debugPrint('⏳ Waiting for profile to load...');
        await profileVM.loadAll();
      }

      // Get country from user profile
      _setCountryFromProfile(profileVM);

      if (widget.prefilledQuery != null) {
        jobVM.searchJobs(
          query: widget.prefilledQuery!,
          country: _selectedCountry,
        );
        _hasLoadedInitialJobs = true;
      } else if (!_hasLoadedInitialJobs && !jobVM.hasSearchResults) {
        _loadDefaultJobs();
        _hasLoadedInitialJobs = true;
      }
    });

    _scrollController.addListener(_onScroll);
  }

  /// Set country from user profile or default to Malaysia
  void _setCountryFromProfile(ProfileViewModel profileVM) {
    // Get country from profile (personalInfo.location.country in Firestore)
    final userCountry = profileVM.profile?.country;

    debugPrint('🌍 Checking user profile country: $userCountry');

    if (userCountry != null && userCountry.isNotEmpty) {
      // First, check if it's already a valid country code (e.g., "my", "us", "sg")
      if (_supportedCountries.containsKey(userCountry.toLowerCase())) {
        setState(() {
          _selectedCountry = userCountry.toLowerCase();
        });
        debugPrint('✅ Set country code from profile: ${userCountry.toLowerCase()} (${_supportedCountries[userCountry.toLowerCase()]})');
        return;
      }

      // If not a code, try to convert country name to code (e.g., "Malaysia" -> "my")
      final countryCode = JobService.getCountryCode(userCountry);
      if (countryCode != null) {
        setState(() {
          _selectedCountry = countryCode;
        });
        debugPrint('✅ Converted country name to code: $userCountry -> $countryCode (${_supportedCountries[countryCode]})');
        return;
      }

      // If conversion failed, log warning and use default
      debugPrint('⚠️ Unknown country from profile: "$userCountry", using default Malaysia (my)');
      setState(() {
        _selectedCountry = 'my';
      });
    } else {
      // No country in profile, use default
      debugPrint('ℹ️ No country in profile, using default: Malaysia (my)');
      setState(() {
        _selectedCountry = 'my';
      });
    }
  }

  void _onScroll() {
    // Reserved for future use
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultJobs() async {
    final jobVM = context.read<JobViewModel>();
    await jobVM.searchJobs(
      query: 'Software Developer OR Data Analyst OR Marketing Manager',
      country: _selectedCountry,
    );
    setState(() {
      _currentDisplayPage = 1;
    });
  }

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

  int _getTotalPages(JobViewModel jobVM) {
    return (jobVM.searchResults.length / _jobsPerPage).ceil();
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
        MediaQuery.of(context).padding.top + 8, // Reduced from 16 to 8
        16,
        12, // Reduced from 16 to 12
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

          // Country selector
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedCountry,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.public, color: Colors.grey[600]),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              hint: Text('Select Country'),
              items: _supportedCountries.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCountry = value;
                  });
                }
              },
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
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                  _buildQuickFilters(jobVM),
                  SizedBox(height: 16),
                  _buildAdvancedFilters(jobVM),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickFilters(JobViewModel jobVM) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Filters',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        SizedBox(height: 8),

        // Work Mode
        Wrap(
          spacing: 8,
          children: ['Remote', 'Hybrid', 'On-site'].map((mode) {
            final isSelected = jobVM.currentFilters.remote == mode;
            return FilterChip(
              label: Text(mode),
              selected: isSelected,
              onSelected: (selected) {
                final newFilters = jobVM.currentFilters.copyWith(
                  remote: selected ? mode : null,
                );
                jobVM.applyFilters(newFilters);
              },
              selectedColor: Color(0xFF7C3AED).withOpacity(0.2),
              checkmarkColor: Color(0xFF7C3AED),
            );
          }).toList(),
        ),

        SizedBox(height: 12),

        // Employment Type
        Text(
          'Employment Type',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['FULLTIME', 'PARTTIME', 'INTERN'].map((type) {
            final isSelected = jobVM.currentFilters.employmentTypes?.contains(type) ?? false;
            return FilterChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (selected) {
                final currentTypes = List<String>.from(jobVM.currentFilters.employmentTypes ?? []);
                if (selected) {
                  currentTypes.add(type);
                } else {
                  currentTypes.remove(type);
                }
                final newFilters = jobVM.currentFilters.copyWith(
                  employmentTypes: currentTypes.isEmpty ? null : currentTypes,
                );
                jobVM.applyFilters(newFilters);
              },
              selectedColor: Color(0xFF7C3AED).withOpacity(0.2),
              checkmarkColor: Color(0xFF7C3AED),
            );
          }).toList(),
        ),

        SizedBox(height: 12),

        // Date Posted
        Text(
          'Date Posted',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
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
            final isSelected = jobVM.currentFilters.dateRange == item['value'];
            return FilterChip(
              label: Text(item['label']!),
              selected: isSelected,
              onSelected: (selected) async {
                final newFilters = jobVM.currentFilters.copyWith(
                  dateRange: selected ? item['value'] : 'all',
                );
                // Need to re-search because date is API parameter
                await jobVM.searchJobs(
                  query: _searchController.text.trim().isEmpty ? 'jobs' : _searchController.text.trim(),
                  country: _selectedCountry,
                  datePosted: newFilters.dateRange,
                );
                await jobVM.applyFilters(newFilters);
              },
              selectedColor: Color(0xFF7C3AED).withOpacity(0.2),
              checkmarkColor: Color(0xFF7C3AED),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAdvancedFilters(JobViewModel jobVM) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(),
        SizedBox(height: 8),
        Text(
          'Advanced Filters',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        SizedBox(height: 12),
        _buildLocationFilter(jobVM),
        SizedBox(height: 12),
        _buildSalaryRangeFilter(jobVM),
      ],
    );
  }

  Widget _buildLocationFilter(JobViewModel jobVM) {
    final locationController = TextEditingController(
      text: jobVM.currentFilters.location ?? '',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Location (City)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        SizedBox(height: 8),
        TextField(
          controller: locationController,
          decoration: InputDecoration(
            hintText: 'e.g., Kuala Lumpur',
            isDense: true,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onChanged: (value) {
            final newFilters = jobVM.currentFilters.copyWith(
              location: value.isEmpty ? null : value,
            );
            jobVM.applyFilters(newFilters);
          },
        ),
      ],
    );
  }

  Widget _buildSalaryRangeFilter(JobViewModel jobVM) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Salary Range (Optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Min',
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final minSalary = int.tryParse(value);
                  final newFilters = jobVM.currentFilters.copyWith(
                    minSalary: minSalary,
                  );
                  jobVM.applyFilters(newFilters);
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('-'),
            ),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Max',
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final maxSalary = int.tryParse(value);
                  final newFilters = jobVM.currentFilters.copyWith(
                    maxSalary: maxSalary,
                  );
                  jobVM.applyFilters(newFilters);
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          'Jobs without salary info will also be shown',
          style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
        ),
      ],
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
              // Results summary
              Container(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${jobVM.totalSearchResults} Jobs Found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          if (jobVM.totalAllResults != jobVM.totalSearchResults)
                            Text(
                              'Filtered from ${jobVM.totalAllResults} total results',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                        ],
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

              // Pagination
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
                    color: _currentDisplayPage == pageNum ? Color(0xFF7C3AED) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _currentDisplayPage == pageNum ? Color(0xFF7C3AED) : Colors.grey[300]!,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$pageNum',
                      style: TextStyle(
                        color: _currentDisplayPage == pageNum ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(width: 16),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
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
                        mainAxisSize: MainAxisSize.min,
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
                Flexible(
                  fit: FlexFit.loose,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (job.isRemote) _buildTag('Remote', Colors.green),
                      _buildTag(job.requiredExperience.experienceLevel ?? 'Entry level', Colors.blue),
                      if (job.jobEmploymentTypes.isNotEmpty)
                        _buildTag(job.jobEmploymentTypes.first, Colors.orange),
                    ],
                  ),
                ),
                SizedBox(height: 12),
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
                    Flexible(
                      child: Text(
                        job.getTimeSincePosted(),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
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
                      padding: EdgeInsets.symmetric(vertical: 12),
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

    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a search term')),
      );
      return;
    }

    final jobVM = context.read<JobViewModel>();

    setState(() {
      _currentDisplayPage = 1; // Reset to first page
    });

    await jobVM.searchJobs(
      query: query,
      country: _selectedCountry,
    );
  }
}