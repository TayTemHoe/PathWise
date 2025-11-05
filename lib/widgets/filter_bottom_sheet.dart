import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../model/university_filter.dart';
import '../utils/app_color.dart';
import '../utils/currency_utils.dart';
import '../viewModel/filter_view_model.dart';

class FilterBottomSheet extends StatefulWidget {
  final FilterModel initialFilter;
  final FilterViewModel filterViewModel; // Accept existing instance
  final Function(FilterModel) onApply;

  const FilterBottomSheet({
    Key? key,
    required this.initialFilter,
    required this.filterViewModel,
    required this.onApply,
  }) : super(key: key);

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  // Text Controllers for input fields
  final TextEditingController _minRankingController = TextEditingController();
  final TextEditingController _maxRankingController = TextEditingController();
  final TextEditingController _minStudentsController = TextEditingController();
  final TextEditingController _maxStudentsController = TextEditingController();
  final TextEditingController _minTuitionController = TextEditingController();
  final TextEditingController _maxTuitionController = TextEditingController();

  String? _rankingSortOrder;
  String? _selectedCountry;
  String? _selectedCity;
  String? _selectedType;

  // Validation error messages
  String? _rankingError;
  String? _studentError;
  String? _tuitionError;

  // Add listener subscription
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        _initializeValues();
      }
    });
  }

  void _initializeValues() {
    if (_isDisposed) return;

    final filterVM = widget.filterViewModel;

    // Initialize ranking fields
    if (widget.initialFilter.minRanking != null) {
      _minRankingController.text = widget.initialFilter.minRanking!.toInt().toString();
    }
    if (widget.initialFilter.maxRanking != null) {
      _maxRankingController.text = widget.initialFilter.maxRanking!.toInt().toString();
    }
    _rankingSortOrder = widget.initialFilter.rankingSortOrder;

    // Initialize student fields
    if (widget.initialFilter.minStudents != null) {
      _minStudentsController.text = widget.initialFilter.minStudents!.toString();
    }
    if (widget.initialFilter.maxStudents != null) {
      _maxStudentsController.text = widget.initialFilter.maxStudents!.toString();
    }

    // Initialize tuition fields
    if (widget.initialFilter.minTuitionFeeMYR != null) {
      _minTuitionController.text = widget.initialFilter.minTuitionFeeMYR!.toInt().toString();
    }
    if (widget.initialFilter.maxTuitionFeeMYR != null) {
      _maxTuitionController.text = widget.initialFilter.maxTuitionFeeMYR!.toInt().toString();
    }

    // Initialize location and type
    _selectedCountry = widget.initialFilter.country;
    _selectedCity = widget.initialFilter.city;
    _selectedType = widget.initialFilter.institutionType;

    // Load cities if country is selected
    if (_selectedCountry != null && !_isDisposed) {
      filterVM.loadCitiesForCountry(_selectedCountry!);
    }

    if (mounted && !_isDisposed) {
      setState(() {});
    }
  }

  bool _validateInputs() {
    bool isValid = true;

    // Validate ranking
    if (_minRankingController.text.isNotEmpty || _maxRankingController.text.isNotEmpty) {
      final minRank = int.tryParse(_minRankingController.text);
      final maxRank = int.tryParse(_maxRankingController.text);

      if (_minRankingController.text.isNotEmpty && minRank == null) {
        setState(() => _rankingError = 'Invalid minimum ranking');
        isValid = false;
      } else if (_maxRankingController.text.isNotEmpty && maxRank == null) {
        setState(() => _rankingError = 'Invalid maximum ranking');
        isValid = false;
      } else if (minRank != null && maxRank != null && minRank > maxRank) {
        setState(() => _rankingError = 'Min ranking cannot exceed max ranking');
        isValid = false;
      } else if (minRank != null && minRank < 1) {
        setState(() => _rankingError = 'Ranking must be at least 1');
        isValid = false;
      } else {
        setState(() => _rankingError = null);
      }
    } else {
      setState(() => _rankingError = null);
    }

    // Validate students
    if (_minStudentsController.text.isNotEmpty || _maxStudentsController.text.isNotEmpty) {
      final minStudents = int.tryParse(_minStudentsController.text);
      final maxStudents = int.tryParse(_maxStudentsController.text);

      if (_minStudentsController.text.isNotEmpty && minStudents == null) {
        setState(() => _studentError = 'Invalid minimum students');
        isValid = false;
      } else if (_maxStudentsController.text.isNotEmpty && maxStudents == null) {
        setState(() => _studentError = 'Invalid maximum students');
        isValid = false;
      } else if (minStudents != null && maxStudents != null && minStudents > maxStudents) {
        setState(() => _studentError = 'Min students cannot exceed max students');
        isValid = false;
      } else if (minStudents != null && minStudents < 0) {
        setState(() => _studentError = 'Students cannot be negative');
        isValid = false;
      } else {
        setState(() => _studentError = null);
      }
    } else {
      setState(() => _studentError = null);
    }

    // Validate tuition
    if (_minTuitionController.text.isNotEmpty || _maxTuitionController.text.isNotEmpty) {
      final minTuition = double.tryParse(_minTuitionController.text);
      final maxTuition = double.tryParse(_maxTuitionController.text);

      if (_minTuitionController.text.isNotEmpty && minTuition == null) {
        setState(() => _tuitionError = 'Invalid minimum tuition');
        isValid = false;
      } else if (_maxTuitionController.text.isNotEmpty && maxTuition == null) {
        setState(() => _tuitionError = 'Invalid maximum tuition');
        isValid = false;
      } else if (minTuition != null && maxTuition != null && minTuition > maxTuition) {
        setState(() => _tuitionError = 'Min tuition cannot exceed max tuition');
        isValid = false;
      } else if (minTuition != null && minTuition < 0) {
        setState(() => _tuitionError = 'Tuition cannot be negative');
        isValid = false;
      } else {
        setState(() => _tuitionError = null);
      }
    } else {
      setState(() => _tuitionError = null);
    }

    return isValid;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _minRankingController.dispose();
    _maxRankingController.dispose();
    _minStudentsController.dispose();
    _maxStudentsController.dispose();
    _minTuitionController.dispose();
    _maxTuitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filterVM = widget.filterViewModel;

    if (filterVM.isLoadingOptions) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRankingFilter(filterVM),
                  const SizedBox(height: 24),
                  _buildLocationFilter(filterVM),
                  const SizedBox(height: 24),
                  _buildStudentFilter(filterVM),
                  const SizedBox(height: 24),
                  _buildTuitionFilter(filterVM),
                  const SizedBox(height: 24),
                  _buildInstitutionTypeFilter(filterVM),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Universities',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reset All'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankingFilter(FilterViewModel filterVM) {
    return _buildFilterSection(
      title: 'University Ranking',
      icon: Icons.emoji_events,
      error: _rankingError,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Filter by ranking range, or just sort all universities by rank',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Ranking Range (Optional)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildNumberTextField(
                  controller: _minRankingController,
                  label: 'Min Ranking',
                  hint: '1',
                  onChanged: (_) => _validateInputs(),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 10, left: 12, right: 12),
                child: Text(
                  'to',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
                ),
              ),
              Expanded(
                child: _buildNumberTextField(
                  controller: _maxRankingController,
                  label: 'Max Ranking',
                  hint: '2000',
                  onChanged: (_) => _validateInputs(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Sort Order',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSortOption(
                  'Ascending',
                  'asc',
                  Icons.arrow_upward,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSortOption(
                  'Descending',
                  'desc',
                  Icons.arrow_downward,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationFilter(FilterViewModel filterVM) {
    return _buildFilterSection(
      title: 'Location',
      icon: Icons.location_on,
      child: Column(
        children: [
          _buildDropdown(
            label: 'Country',
            value: _selectedCountry,
            items: filterVM.availableCountries,
            onChanged: (value) {
              if (_isDisposed) return;

              setState(() {
                _selectedCountry = value;
                _selectedCity = null;
              });

              if (value != null && !_isDisposed) {
                filterVM.loadCitiesForCountry(value).then((_) {
                  // Force rebuild after cities are loaded
                  if (mounted && !_isDisposed) {
                    setState(() {});
                  }
                });
              } else if (!_isDisposed) {
                filterVM.clearCities();
              }
            },
            hint: 'Select Country',
          ),
          const SizedBox(height: 16),
          // Listen to filterVM to rebuild when cities change
          AnimatedBuilder(
            animation: filterVM,
            builder: (context, child) {
              return _buildDropdown(
                label: 'City',
                value: _selectedCity,
                items: filterVM.availableCities,
                onChanged: (value) {
                  if (_isDisposed) return;

                  setState(() {
                    _selectedCity = value;
                  });
                },
                hint: _selectedCountry == null
                    ? 'Select country first'
                    : filterVM.isLoadingCities
                    ? 'Loading cities...'
                    : 'Select City',
                enabled: _selectedCountry != null && !filterVM.isLoadingCities,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStudentFilter(FilterViewModel filterVM) {
    return _buildFilterSection(
      title: 'Total Students',
      icon: Icons.people,
      error: _studentError,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter student count range',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildNumberTextField(
                  controller: _minStudentsController,
                  label: 'Min Students',
                  hint: '0',
                  onChanged: (_) => _validateInputs(),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 10, left: 12, right: 12),
                child: Text(
                  'to',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
                ),
              ),
              Expanded(
                child: _buildNumberTextField(
                  controller: _maxStudentsController,
                  label: 'Max Students',
                  hint: '100000',
                  onChanged: (_) => _validateInputs(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTuitionFilter(FilterViewModel filterVM) {
    return _buildFilterSection(
      title: 'Tuition Fees (MYR)',
      icon: Icons.attach_money,
      error: _tuitionError,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter tuition fee range in MYR',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildNumberTextField(
                  controller: _minTuitionController,
                  label: 'Min Tuition (RM)',
                  hint: '0.00',
                  isDecimal: true,
                  onChanged: (_) => _validateInputs(),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 10, left: 12, right: 12),
                child: Text(
                  'to',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
                ),
              ),
              Expanded(
                child: _buildNumberTextField(
                  controller: _maxTuitionController,
                  label: 'Max Tuition (RM)',
                  hint: '200000.00',
                  isDecimal: true,
                  onChanged: (_) => _validateInputs(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstitutionTypeFilter(FilterViewModel filterVM) {
    return _buildFilterSection(
      title: 'Institution Type',
      icon: Icons.business,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: filterVM.institutionTypes.map((type) {
          final isSelected = _selectedType == type;
          return InkWell(
            onTap: () {
              if (_isDisposed) return;
              setState(() {
                _selectedType = isSelected ? null : type;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  Text(
                    type,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
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

  Widget _buildFilterSection({
    required String title,
    required IconData icon,
    required Widget child,
    String? error,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: error != null ? Colors.red[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: error != null ? Colors.red[300]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: Colors.red[700]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    error,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildNumberTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isDecimal = false,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
          inputFormatters: [
            if (isDecimal)
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            else
              FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required String hint,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(hint),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSortOption(String label, String value, IconData icon) {
    final isSelected = _rankingSortOrder == value;
    return InkWell(
      onTap: () {
        if (_isDisposed) return;
        setState(() {
          _rankingSortOrder = isSelected ? null : value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetFilters() {
    if (_isDisposed) return;

    setState(() {
      _minRankingController.clear();
      _maxRankingController.clear();
      _rankingSortOrder = null;
      _minStudentsController.clear();
      _maxStudentsController.clear();
      _selectedCountry = null;
      _selectedCity = null;
      _selectedType = null;
      _minTuitionController.clear();
      _maxTuitionController.clear();
      _rankingError = null;
      _studentError = null;
      _tuitionError = null;
    });

    if (!_isDisposed) {
      widget.filterViewModel.clearCities();
    }
  }

  void _applyFilters() {
    if (_isDisposed) return;

    if (!_validateInputs()) {
      return;
    }

    final filter = FilterModel(
      minRanking: _minRankingController.text.isNotEmpty
          ? int.tryParse(_minRankingController.text)
          : null,
      maxRanking: _maxRankingController.text.isNotEmpty
          ? int.tryParse(_maxRankingController.text)
          : null,
      rankingSortOrder: _rankingSortOrder,
      minStudents: _minStudentsController.text.isNotEmpty
          ? int.tryParse(_minStudentsController.text)
          : null,
      maxStudents: _maxStudentsController.text.isNotEmpty
          ? int.tryParse(_maxStudentsController.text)
          : null,
      country: _selectedCountry,
      city: _selectedCity,
      institutionType: _selectedType,
      minTuitionFeeMYR: _minTuitionController.text.isNotEmpty
          ? double.tryParse(_minTuitionController.text)
          : null,
      maxTuitionFeeMYR: _maxTuitionController.text.isNotEmpty
          ? double.tryParse(_maxTuitionController.text)
          : null,
    );

    widget.onApply(filter);
    Navigator.pop(context);
  }
}