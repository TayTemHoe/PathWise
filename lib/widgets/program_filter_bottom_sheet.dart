import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../model/program_filter.dart';
import '../utils/app_color.dart';
import '../utils/currency_utils.dart';
import '../viewModel/program_filter_view_model.dart';
import 'form_components.dart';
import 'multi_select_dropdown.dart';

class ProgramFilterBottomSheet extends StatefulWidget {
  final ProgramFilterModel initialFilter;
  final ProgramFilterViewModel filterViewModel;
  final Function(ProgramFilterModel) onApply;

  const ProgramFilterBottomSheet({
    Key? key,
    required this.initialFilter,
    required this.filterViewModel,
    required this.onApply,
  }) : super(key: key);

  @override
  State<ProgramFilterBottomSheet> createState() => _ProgramFilterBottomSheetState();
}

class _ProgramFilterBottomSheetState extends State<ProgramFilterBottomSheet> {
  // Text Controllers
  final TextEditingController _topNController = TextEditingController();
  final TextEditingController _minDurationController = TextEditingController();
  final TextEditingController _maxDurationController = TextEditingController();
  final TextEditingController _minTuitionController = TextEditingController();
  final TextEditingController _maxTuitionController = TextEditingController();
  final TextEditingController _universitySearchController = TextEditingController();

  String? _rankingSortOrder;
  List<String> _selectedSubjectArea = [];
  List<String> _selectedStudyModes = [];
  List<String> _selectedStudyLevels = [];
  List<String> _selectedIntakeMonths = [];
  List<String> _selectedUniversityIds = [];
  List<String> _selectedCountries = [];
  List<Map<String, String>> _filteredUniversities = [];

  // Validation error messages
  String? _topNError;
  String? _durationError;
  String? _tuitionError;

  bool _showUniversityDropdown = false;
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

    // Initialize ranking fields
    if (widget.initialFilter.topN != null) {
      _topNController.text = widget.initialFilter.topN!.toString();
    }
    _rankingSortOrder = widget.initialFilter.rankingSortOrder;

    // Initialize duration fields
    if (widget.initialFilter.minDurationYears != null) {
      _minDurationController.text = widget.initialFilter.minDurationYears!.toStringAsFixed(1);
    }
    if (widget.initialFilter.maxDurationYears != null) {
      _maxDurationController.text = widget.initialFilter.maxDurationYears!.toStringAsFixed(1);
    }

    // Initialize tuition fields
    if (widget.initialFilter.minTuitionFeeMYR != null) {
      _minTuitionController.text = widget.initialFilter.minTuitionFeeMYR!.toInt().toString();
    }
    if (widget.initialFilter.maxTuitionFeeMYR != null) {
      _maxTuitionController.text = widget.initialFilter.maxTuitionFeeMYR!.toInt().toString();
    }

    // Initialize selections
    _selectedSubjectArea = List.from(widget.initialFilter.subjectArea);
    _selectedStudyModes = List.from(widget.initialFilter.studyModes);
    _selectedStudyLevels = List.from(widget.initialFilter.studyLevels);
    _selectedIntakeMonths = List.from(widget.initialFilter.intakeMonths);
    _selectedCountries = List.from(widget.initialFilter.countries);
    _selectedUniversityIds = List.from(widget.initialFilter.universityIds);
    if (widget.initialFilter.universityName != null) {
      _universitySearchController.text = widget.initialFilter.universityName!;
    }

    if (mounted && !_isDisposed) {
      setState(() {});
    }
  }

  bool _validateInputs() {
    bool isValid = true;

    // Validate ranking
    if (_topNController.text.isNotEmpty) {
      final topN = int.tryParse(_topNController.text);

      if (topN == null) {
        setState(() => _topNError = 'Invalid number');
        isValid = false;
      } else if (topN < 1) {
        setState(() => _topNError = 'Must be at least 1');
        isValid = false;
      } else if (topN > 500) {
        setState(() => _topNError = 'Cannot exceed 500');
        isValid = false;
      } else {
        setState(() => _topNError = null);
      }
    } else {
      setState(() => _topNError = null);
    }

    // Validate duration
    if (_minDurationController.text.isNotEmpty || _maxDurationController.text.isNotEmpty) {
      final minDuration = double.tryParse(_minDurationController.text);
      final maxDuration = double.tryParse(_maxDurationController.text);

      if (_minDurationController.text.isNotEmpty && minDuration == null) {
        setState(() => _durationError = 'Invalid minimum duration');
        isValid = false;
      } else if (_maxDurationController.text.isNotEmpty && maxDuration == null) {
        setState(() => _durationError = 'Invalid maximum duration');
        isValid = false;
      } else if (minDuration != null && maxDuration != null && minDuration > maxDuration) {
        setState(() => _durationError = 'Min duration cannot exceed max duration');
        isValid = false;
      } else if (minDuration != null && minDuration < 0) {
        setState(() => _durationError = 'Duration cannot be negative');
        isValid = false;
      } else {
        setState(() => _durationError = null);
      }
    } else {
      setState(() => _durationError = null);
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

  void _filterUniversities(String query) {
    final filterVM = widget.filterViewModel;
    if (query.isEmpty) {
      _filteredUniversities = filterVM.availableUniversities;
    } else {
      _filteredUniversities = filterVM.availableUniversities
          .where((uni) => uni['name']!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _isDisposed = true;
    _topNController.dispose();
    _minDurationController.dispose();
    _maxDurationController.dispose();
    _minTuitionController.dispose();
    _maxTuitionController.dispose();
    _universitySearchController.dispose();
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
                  _buildUniversityFilter(filterVM),
                  const SizedBox(height: 24),
                  _buildCountryFilter(filterVM), // ✅ Move this BEFORE Top N
                  const SizedBox(height: 24),
                  _buildTopNFilter(filterVM), // ✅ NEW: Replaces _buildSubjectRankingFilter
                  const SizedBox(height: 24),
                  _buildSubjectAreaFilter(filterVM),
                  const SizedBox(height: 24),
                  _buildDurationFilter(filterVM),
                  const SizedBox(height: 24),
                  _buildTuitionFilter(filterVM),
                  const SizedBox(height: 24),
                  _buildStudyModeFilter(filterVM),
                  const SizedBox(height: 24),
                  _buildStudyLevelFilter(filterVM),
                  const SizedBox(height: 24),
                  _buildIntakeMonthFilter(filterVM),
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
                'Filter Programs',
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

  Widget _buildUniversityFilter(ProgramFilterViewModel filterVM) {
    return _buildFilterSection(
      title: 'University',
      icon: Icons.account_balance,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search input
          TextField(
            controller: _universitySearchController,
            decoration: InputDecoration(
              hintText: 'Search university name...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: _universitySearchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  _universitySearchController.clear();
                  _filteredUniversities.clear();
                  _showUniversityDropdown = false;
                  setState(() {});
                },
              )
                  : null,
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
            onChanged: (value) {
              _filterUniversities(value);
              _showUniversityDropdown = value.isNotEmpty;
              setState(() {});
            },
            onTap: () {
              if (_universitySearchController.text.isEmpty) {
                _filteredUniversities = filterVM.availableUniversities;
              }
              _showUniversityDropdown = true;
              setState(() {});
            },
          ),

          // Dropdown suggestions
          if (_showUniversityDropdown && _filteredUniversities.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredUniversities.length,
                itemBuilder: (context, index) {
                  final uni = _filteredUniversities[index];
                  final isSelected = _selectedUniversityIds.contains(uni['id']);

                  return ListTile(
                    dense: true,
                    title: Text(
                      uni['name']!,
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                        : null,
                    tileColor: isSelected ? AppColors.primary.withOpacity(0.1) : null,
                    onTap: () {
                      if (isSelected) {
                        _selectedUniversityIds.remove(uni['id']);
                      } else {
                        _selectedUniversityIds.add(uni['id']!);
                      }
                      setState(() {});
                    },
                  );
                },
              ),
            ),
          ],

          // Selected universities chips
          if (_selectedUniversityIds.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_selectedUniversityIds).map((id) {
                final uni = filterVM.availableUniversities.firstWhere(
                      (u) => u['id'] == id,
                  orElse: () => {'id': id, 'name': 'Unknown'},
                );
                return _buildChipOption(
                  uni['name']!,
                  true,
                      () {
                    _selectedUniversityIds.remove(id);
                    setState(() {});
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCountryFilter(ProgramFilterViewModel filterVM) {
    return _buildFilterSection(
      title: 'Country/Location',
      icon: Icons.public,
      child: MultiSelectField(
        icon: Icons.public,
        items: filterVM.availableCountries,
        selectedItems: _selectedCountries,
        hint: 'Select one or more countries',
        isSearchable: true, // Enable search for countries
        onChanged: (selected) {
          setState(() {
            _selectedCountries.clear();
            _selectedCountries.addAll(selected);
          });
        },
      ),
    );
  }

  Widget _buildTopNFilter(ProgramFilterViewModel filterVM) {
    return _buildFilterSection(
      title: 'Top Programs by Subject Ranking',
      icon: Icons.emoji_events,
      error: _topNError,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.filterViewModel.availableCountries.isNotEmpty &&
                      _selectedCountries.isNotEmpty
                      ? 'View top ranked programs in ${_selectedCountries.join(", ")}'
                      : 'View top ranked programs globally',
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
          NumberStepperField(
            controller: _topNController,
            label: 'Top N Programs',
            hint: 'Enter a number (e.g., 50)',
            min: 1,
            max: 500,
            step: 1,
            onChanged: (_) => _validateInputs(),
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
                  'Best First',
                  'asc',
                  Icons.arrow_upward,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSortOption(
                  'Worst First',
                  'desc',
                  Icons.arrow_downward,
                ),
              ),
            ],
          ),
          if (_topNController.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedCountries.isNotEmpty
                          ? 'Showing top ${_topNController.text} programs in ${_selectedCountries.join(", ")}'
                          : 'Showing top ${_topNController.text} programs globally',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubjectAreaFilter(ProgramFilterViewModel filterVM) {
    return _buildFilterSection(
      title: 'Subject Area',
      icon: Icons.book,
      child: MultiSelectField(
        icon: Icons.book,
        items: filterVM.availableSubjectAreas,
        selectedItems: _selectedSubjectArea,
        hint: 'Select one or more Subject Area',
        onChanged: (selected) {
          setState(() {
            _selectedSubjectArea.clear();
            _selectedSubjectArea.addAll(selected);
          });
        },
      ),
    );
  }

  Widget _buildStudyModeFilter(ProgramFilterViewModel filterVM) {
    return _buildFilterSection(
      title: 'Study Mode',
      icon: Icons.school,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: (filterVM.availableStudyModes ?? []).map((mode) {
          final isSelected = _selectedStudyModes.contains(mode);
          return _buildChipOption(mode, isSelected, () {
            if (_isDisposed) return;
            setState(() {
              if (isSelected) {
                _selectedStudyModes.remove(mode);
              } else {
                _selectedStudyModes.add(mode);
              }
            });
          });
        }).toList(),
      ),
    );
  }

  Widget _buildStudyLevelFilter(ProgramFilterViewModel filterVM) {
    return _buildFilterSection(
      title: 'Study Level',
      icon: Icons.stairs,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: (filterVM.availableStudyLevels ?? []).map((level) {
          final isSelected = _selectedStudyLevels.contains(level);
          return _buildChipOption(level, isSelected, () {
            if (_isDisposed) return;
            setState(() {
              if (isSelected) {
                _selectedStudyLevels.remove(level);
              } else {
                _selectedStudyLevels.add(level);
              }
            });
          });
        }).toList(),
      ),
    );
  }

  Widget _buildDurationFilter(ProgramFilterViewModel filterVM) {
    return _buildFilterSection(
      title: 'Duration (Years)',
      icon: Icons.schedule,
      error: _durationError,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter duration range in years',
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
                  controller: _minDurationController,
                  label: 'Min Duration',
                  hint: '1.0',
                  isDecimal: true,
                  onChanged: (_) => _validateInputs(),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 10, left: 12, right: 12),
                child: Text('to', style: TextStyle(fontSize: 15)),
              ),
              Expanded(
                child: _buildNumberTextField(
                  controller: _maxDurationController,
                  label: 'Max Duration',
                  hint: '6.0',
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

  Widget _buildIntakeMonthFilter(ProgramFilterViewModel filterVM) {
    return _buildFilterSection(
      title: 'Intake Period',
      icon: Icons.calendar_month,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: (filterVM.availableIntakeMonths ?? []).map((month) {
          final isSelected = _selectedIntakeMonths.contains(month);
          return _buildChipOption(month, isSelected, () {
            if (_isDisposed) return;
            setState(() {
              if (isSelected) {
                _selectedIntakeMonths.remove(month);
              } else {
                _selectedIntakeMonths.add(month);
              }
            });
          });
        }).toList(),
      ),
    );
  }

  Widget _buildTuitionFilter(ProgramFilterViewModel filterVM) {
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
                child: Text('to', style: TextStyle(fontSize: 15)),
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

  // Helper Widgets

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

  Widget _buildDropdown<T>({
    required String label,
    required List<String> items,
    required String hint,
    bool enabled = true,
    bool isMultiSelect = false,
    T? value, // supports String? or List<String>
    required ValueChanged<T> onChanged, // ✅ strong typed callback
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: isMultiSelect
              ? Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              final selectedValues = value as List<String>? ?? [];
              final isSelected = selectedValues.contains(item);

              // --- START OF CHANGE ---
              // Replaced FilterChip with _buildChipOption for consistency
              return _buildChipOption(
                item,
                isSelected,
                enabled
                    ? () {
                  if (_isDisposed) return;
                  final updated = List<String>.from(selectedValues);
                  if (isSelected) {
                    updated.remove(item);
                  } else {
                    updated.add(item);
                  }
                  onChanged(updated as T);
                }
                    : () {}, // Pass empty function if disabled
              );
              // --- END OF CHANGE ---

            }).toList(),
          )
              : DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value as String?,
              isExpanded: true,
              hint: Text(hint),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: enabled ? (val) => onChanged(val as T) : null,
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

  Widget _buildChipOption(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
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
              label,
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
      _topNController.clear();
      _selectedCountries.clear();
      _rankingSortOrder = null;
      _minDurationController.clear();
      _maxDurationController.clear();
      _selectedSubjectArea.clear();
      _selectedStudyModes.clear();
      _selectedStudyLevels.clear();
      _selectedIntakeMonths.clear();
      _minTuitionController.clear();
      _maxTuitionController.clear();
      _universitySearchController.clear();
      _selectedUniversityIds.clear();
      _filteredUniversities.clear();
      _showUniversityDropdown = false;
      _topNError = null;
      _durationError = null;
      _tuitionError = null;
    });
  }

  void _applyFilters() {
    if (_isDisposed) return;

    if (!_validateInputs()) {
      return;
    }

    final filter = ProgramFilterModel(
      universityName: _universitySearchController.text.isNotEmpty
          ? _universitySearchController.text
          : null,
      universityIds: _selectedUniversityIds,
      topN: _topNController.text.isNotEmpty
          ? int.tryParse(_topNController.text)
          : null,
      rankingSortOrder: _rankingSortOrder,
      minDurationYears: _minDurationController.text.isNotEmpty
          ? double.tryParse(_minDurationController.text)
          : null,
      maxDurationYears: _maxDurationController.text.isNotEmpty
          ? double.tryParse(_maxDurationController.text)
          : null,
      subjectArea: _selectedSubjectArea,
      studyModes: _selectedStudyModes,
      studyLevels: _selectedStudyLevels,
      intakeMonths: _selectedIntakeMonths,
      minTuitionFeeMYR: _minTuitionController.text.isNotEmpty
          ? double.tryParse(_minTuitionController.text)
          : null,
      maxTuitionFeeMYR: _maxTuitionController.text.isNotEmpty
          ? double.tryParse(_maxTuitionController.text)
          : null,
      countries: _selectedCountries,
    );

    widget.onApply(filter);
    Navigator.pop(context);
  }
}