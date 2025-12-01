// lib/widgets/common/form_components.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_color.dart';

/// Modern custom text field with consistent styling
class CustomTextField extends StatefulWidget {
  final String? label;
  final TextEditingController controller;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool isRequired;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  // ADDED: textCapitalization property
  final TextCapitalization textCapitalization;

  const CustomTextField({
    Key? key,
    this.label,
    required this.controller,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.isRequired = false,
    this.validator,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    // ADDED: Default to none
    this.textCapitalization = TextCapitalization.none,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = false;
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          FieldLabel(
            label: widget.label!,
            isRequired: widget.isRequired,
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          maxLines: widget.maxLines,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          validator: widget.validator,
          onChanged: widget.onChanged,
          obscureText: _obscureText,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          // ADDED: Pass the property to TextFormField
          textCapitalization: widget.textCapitalization,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(
              widget.prefixIcon,
              size: 20,
              color: _isFocused ? AppColors.primary : Colors.grey[600],
            )
                : null,
            suffixIcon: widget.obscureText
                ? IconButton(
              icon: Icon(
                _obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.grey[600],
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            )
                : widget.suffixIcon,
            filled: true,
            fillColor: widget.enabled ? Colors.grey[50] : Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              const BorderSide(color: Color(0xFFE53935), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              const BorderSide(color: Color(0xFFE53935), width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
            ),
            errorStyle: const TextStyle(
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Modern custom dropdown field with menu popup
class CustomDropdownField<T> extends StatefulWidget {
  final String? label;
  final T? value;
  final List<T> items;
  final Function(T?) onChanged;
  final bool isRequired;
  final String Function(T)? itemLabel;
  final String? hint;
  final IconData? prefixIcon;
  final bool enabled;

  const CustomDropdownField({
    Key? key,
    this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isRequired = false,
    this.itemLabel,
    this.hint,
    this.prefixIcon,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<CustomDropdownField<T>> createState() => _CustomDropdownFieldState<T>();
}

class _CustomDropdownFieldState<T> extends State<CustomDropdownField<T>> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          FieldLabel(
            label: widget.label!,
            isRequired: widget.isRequired,
          ),
          const SizedBox(height: 8),
        ],
        Focus(
          onFocusChange: (focused) {
            setState(() {
              _isFocused = focused;
            });
          },
          child: DropdownButtonFormField<T>(
            value: widget.value,
            isExpanded: true,
            isDense: false,
            menuMaxHeight: 200,
            validator: (value) => widget.isRequired && value == null
                ? 'Please select ${widget.label ?? 'an option'}'
                : null,
            decoration: InputDecoration(
              filled: true,
              fillColor: widget.enabled ? Colors.grey[50] : Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                widget.prefixIcon,
                size: 20,
                color: _isFocused ? AppColors.primary : Colors.grey[600],
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
              ),
              errorStyle: const TextStyle(
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
            hint: Text(
              widget.hint ?? 'Select ${widget.label ?? 'an option'}',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _isFocused ? AppColors.primary : Colors.grey[600],
              size: 24,
            ),
            items: widget.items.map((item) {
              final displayText = widget.itemLabel?.call(item) ?? item.toString();
              return DropdownMenuItem(
                value: item,
                child: Text(
                  displayText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: widget.enabled ? widget.onChanged : null,
            dropdownColor: Colors.white,
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }
}

/// Modern searchable dropdown field
class CustomSearchableDropdown<T> extends StatefulWidget {
  final String? label;
  final T? value;
  final List<T> items;
  final Function(T?) onChanged;
  final bool isRequired;
  final String Function(T) itemLabel;
  final String? hint;
  final IconData? prefixIcon;
  final bool enabled;

  const CustomSearchableDropdown({
    Key? key,
    this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemLabel,
    this.isRequired = false,
    this.hint,
    this.prefixIcon,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<CustomSearchableDropdown<T>> createState() => _CustomSearchableDropdownState<T>();
}

class _CustomSearchableDropdownState<T> extends State<CustomSearchableDropdown<T>> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<T> _filteredItems = [];
  bool _isOpen = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOpen = false;
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: () => _removeOverlay(),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              width: size.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, size.height + 4),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[200]!),
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey[600]),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                icon: Icon(Icons.clear, size: 20, color: Colors.grey[600]),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _filteredItems = widget.items;
                                  });
                                  _overlayEntry?.markNeedsBuild();
                                },
                              )
                                  : null,
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _filteredItems = widget.items
                                    .where((item) => widget
                                    .itemLabel(item)
                                    .toLowerCase()
                                    .contains(value.toLowerCase()))
                                    .toList();
                              });
                              _overlayEntry?.markNeedsBuild();
                            },
                          ),
                        ),
                        Flexible(
                          child: _filteredItems.isEmpty
                              ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text(
                                  'No results found',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                              : ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: _filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = _filteredItems[index];
                              final isSelected = item == widget.value;
                              return InkWell(
                                onTap: () {
                                  widget.onChanged(item);
                                  _removeOverlay();
                                  setState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary.withOpacity(0.1)
                                        : Colors.transparent,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          widget.itemLabel(item),
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                            color: isSelected ? AppColors.primary : const Color(0xFF1A1A1A),
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          FieldLabel(
            label: widget.label!,
            isRequired: widget.isRequired,
          ),
          const SizedBox(height: 8),
        ],
        CompositedTransformTarget(
          link: _layerLink,
          child: InkWell(
            onTap: widget.enabled ? _toggleDropdown : null,
            focusNode: _focusNode,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: widget.enabled ? Colors.grey[50] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isOpen
                      ? AppColors.primary
                      : _focusNode.hasFocus
                      ? AppColors.primary
                      : Colors.grey[300]!,
                  width: _isOpen || _focusNode.hasFocus ? 2 : 1.5,
                ),
              ),
              child: Row(
                children: [
                  if (widget.prefixIcon != null) ...[
                    Icon(
                      widget.prefixIcon,
                      size: 20,
                      color: _isOpen || _focusNode.hasFocus ? AppColors.primary : Colors.grey[600],
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      widget.value != null
                          ? widget.itemLabel(widget.value!)
                          : widget.hint ?? 'Select ${widget.label ?? 'an option'}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: widget.value != null ? FontWeight.w500 : FontWeight.w400,
                        color: widget.value != null ? const Color(0xFF1A1A1A) : Colors.grey[400],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    _isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: _isOpen || _focusNode.hasFocus ? AppColors.primary : Colors.grey[600],
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CustomYearPicker extends StatefulWidget {
  final String? label;
  final int? selectedYear;
  final Function(int?) onYearSelected;
  final bool isRequired;
  final String? Function(int?)? validator; // <-- ADDED
  final int? firstYear;
  final int? lastYear;
  final IconData? prefixIcon;
  final bool enabled;

  const CustomYearPicker({
    Key? key,
    this.label,
    required this.selectedYear,
    required this.onYearSelected,
    this.isRequired = false,
    this.validator, // <-- ADDED
    this.firstYear,
    this.lastYear,
    this.prefixIcon,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<CustomYearPicker> createState() => _CustomYearPickerState();
}

class _CustomYearPickerState extends State<CustomYearPicker> {
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<int>(
      // Use a key to ensure the FormField rebuilds if the selectedYear changes externally
      key: ValueKey(widget.selectedYear),
      initialValue: widget.selectedYear,
      validator: widget.validator,
      enabled: widget.enabled,
      builder: (FormFieldState<int> state) {
        final bool hasError = state.hasError;
        final bool isCurrentlyFocused = _focusNode.hasFocus;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.label != null) ...[
              FieldLabel(
                label: widget.label!,
                isRequired: widget.isRequired,
              ),
              const SizedBox(height: 8),
            ],
            Focus(
              focusNode: _focusNode,
              child: InkWell(
                onTap: widget.enabled
                    ? () async {
                  _focusNode.requestFocus(); // Manually request focus on tap
                  final year = await showDialog<int>(
                    context: context,
                    builder: (context) => Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Select Year',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () => Navigator.pop(context),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: 300,
                                height: 350,
                                child: YearPicker(
                                  firstDate:
                                  DateTime(widget.firstYear ?? 1950),
                                  lastDate:
                                  DateTime(widget.lastYear ?? 2035),
                                  selectedDate: DateTime(
                                    state.value ?? DateTime.now().year,
                                  ),
                                  onChanged: (date) {
                                    // Update the FormField state
                                    state.didChange(date.year);
                                    // Call the user's callback
                                    widget.onYearSelected(date.year);
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                  // If the dialog is dismissed without selection,
                  // we don't need to do anything, but we keep the focus.
                  // Or you could unfocus: _focusNode.unfocus();
                }
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: widget.enabled ? Colors.grey[50] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      // Logic to determine border color
                      color: hasError
                          ? const Color(0xFFE53935)
                          : isCurrentlyFocused
                          ? AppColors.primary
                          : Colors.grey[300]!,
                      // Logic to determine border width
                      width: hasError
                          ? 1.5
                          : isCurrentlyFocused
                          ? 2.0
                          : 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (widget.prefixIcon != null) ...[
                        Icon(
                          widget.prefixIcon,
                          size: 20,
                          color: hasError
                              ? const Color(0xFFE53935)
                              : isCurrentlyFocused
                              ? AppColors.primary
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          state.value?.toString() ?? 'Select year', // Use state's value
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: state.value != null
                                ? FontWeight.w500
                                : FontWeight.w400,
                            color: state.value != null
                                ? const Color(0xFF1A1A1A)
                                : Colors.grey[400],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: hasError
                            ? const Color(0xFFE53935)
                            : isCurrentlyFocused
                            ? AppColors.primary
                            : Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Show error text from the validator, just like TextFormField
            if (hasError) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(
                    color: Color(0xFFE53935),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Modern custom slider
class CustomSlider extends StatelessWidget {
  final String? label;
  final double value; // This now acts as the initialValue
  final double min;
  final double max;
  final Function(double) onChanged;
  final bool isRequired;
  final String? Function(double?)? validator; // <-- ADDED
  final int? divisions;
  final String? valuePrefix;
  final String? valueSuffix;
  final int decimalPlaces;
  final bool enabled;

  const CustomSlider({
    Key? key,
    this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.isRequired = false,
    this.validator, // <-- ADDED
    this.divisions,
    this.valuePrefix,
    this.valueSuffix,
    this.decimalPlaces = 2,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FormField<double>(
      initialValue: value,
      validator: validator,
      enabled: enabled,
      builder: (FormFieldState<double> state) {
        // The state's value is the source of truth
        final currentValue = state.value ?? min;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Flexible(
                    child: FieldLabel(
                      label: label!,
                      isRequired: isRequired,
                    ),
                  ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  constraints: const BoxConstraints(maxWidth: 120),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    // Use the state's value
                    '${valuePrefix ?? ''}${currentValue.toStringAsFixed(decimalPlaces)}${valueSuffix ?? ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: Colors.grey[300],
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withOpacity(0.2),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                trackHeight: 4,
                valueIndicatorColor: AppColors.primary,
                valueIndicatorTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                // Handle disabled state
                disabledActiveTrackColor: Colors.grey[300],
                disabledInactiveTrackColor: Colors.grey[200],
                disabledThumbColor: Colors.grey[400],
              ),
              child: Slider(
                value: currentValue,
                min: min,
                max: max,
                divisions: divisions ?? ((max - min) * 100).round(),
                onChanged: enabled
                    ? (newValue) {
                  // Update the FormField state
                  state.didChange(newValue);
                  // Call the user's callback
                  onChanged(newValue);
                }
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${valuePrefix ?? ''}${min.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${valuePrefix ?? ''}${max.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Show error text from the validator
            if (state.hasError) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(
                    color: Color(0xFFE53935),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Modern section header
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? iconColor;

  const SectionHeader({
    Key? key,
    required this.title,
    this.icon,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (iconColor ?? AppColors.primary).withOpacity(0.12),
            (iconColor ?? AppColors.primary).withOpacity(0.06),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (iconColor ?? AppColors.primary).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: iconColor ?? AppColors.primary,
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: iconColor ?? AppColors.primary,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Modern info card
class InfoCard extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  const InfoCard({
    Key? key,
    required this.title,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.color = const Color(0xFF4285F4),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: color.withOpacity(0.85),
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Modern dialog header
class DialogHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onClose;
  final Color? backgroundColor;

  const DialogHeader({
    Key? key,
    required this.title,
    required this.icon,
    required this.onClose,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor ?? AppColors.primary,
            (backgroundColor ?? AppColors.primary).withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
            onPressed: onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}

/// Modern dialog footer
class DialogFooter extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final String saveLabel;
  final IconData saveIcon;
  final bool isLoading;

  const DialogFooter({
    Key? key,
    required this.onCancel,
    required this.onSave,
    this.saveLabel = 'Save',
    this.saveIcon = Icons.check_circle_rounded,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: isLoading ? null : onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A1A1A),
                side: BorderSide(color: Colors.grey[400]!, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onSave,
              icon: isLoading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : Icon(saveIcon, size: 20),
              label: Text(
                isLoading ? 'Saving...' : saveLabel,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String label;
  final bool isRequired;
  final IconData? icon;
  final String? tooltip;

  const FieldLabel({
    Key? key,
    required this.label,
    this.isRequired = false,
    this.icon,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget labelWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 16,
            color: AppColors.textPrimary.withOpacity(0.7),
          ),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: 0.1,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isRequired ? Colors.red[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isRequired ? Colors.red[300]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Text(
            isRequired ? 'REQUIRED' : 'OPTIONAL',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: isRequired ? Colors.red[700] : Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: labelWidget,
      );
    }

    return labelWidget;
  }
}

class NumberStepperField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int min;
  final int? max;
  final int step;
  final Function(String)? onChanged;

  const NumberStepperField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.min = 0,
    this.max,
    this.step = 1,
    this.onChanged,
  });

  void _updateValue(int delta) {
    // If empty, start from min when incrementing or set to empty when decrementing
    if (controller.text.isEmpty) {
      if (delta > 0) {
        controller.text = min.toString();
        if (onChanged != null) onChanged!(controller.text);
      }
      return;
    }

    int current = int.tryParse(controller.text) ?? min;
    int newValue = current + delta;

    // If decrementing below min, clear the field instead
    if (newValue < min) {
      controller.clear();
      if (onChanged != null) onChanged!('');
      return;
    }

    if (max != null && newValue > max!) newValue = max!;

    controller.text = newValue.toString();
    if (onChanged != null) onChanged!(controller.text);
  }

  bool _canDecrement() {
    if (controller.text.isEmpty) return false;
    int current = int.tryParse(controller.text) ?? min;
    return current >= min;
  }

  bool _canIncrement() {
    if (controller.text.isEmpty) return true;
    int current = int.tryParse(controller.text) ?? min;
    return max == null || current < max!;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            // ───── MINUS BUTTON ─────
            Material(
              color: _canDecrement() ? const Color(0xFF3B82F6) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: _canDecrement() ? () => _updateValue(-step) : null,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.remove_rounded,
                    color: _canDecrement() ? Colors.white : Colors.grey.shade500,
                    size: 18,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // ───── INPUT FIELD ─────
            Expanded(
              child: TextField(
                controller: controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.normal,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                  ),
                ),
                onChanged: (value) {
                  // Allow empty value (cleared state)
                  if (value.isEmpty) {
                    if (onChanged != null) onChanged!('');
                    return;
                  }

                  // Validate and constrain the value
                  int? parsed = int.tryParse(value);
                  if (parsed != null) {
                    if (parsed < min) {
                      controller.text = min.toString();
                      controller.selection = TextSelection.collapsed(
                        offset: controller.text.length,
                      );
                    } else if (max != null && parsed > max!) {
                      controller.text = max.toString();
                      controller.selection = TextSelection.collapsed(
                        offset: controller.text.length,
                      );
                    }
                  }
                  if (onChanged != null) onChanged!(controller.text);
                },
              ),
            ),

            const SizedBox(width: 12),

            // ───── PLUS BUTTON ─────
            Material(
              color: _canIncrement() ? const Color(0xFF3B82F6) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: _canIncrement() ? () => _updateValue(step) : null,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: _canIncrement() ? Colors.white : Colors.grey.shade500,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
