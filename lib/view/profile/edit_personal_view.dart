import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_wise/viewModel/profile_view_model.dart';
import '../../utils/app_color.dart';

class EditPersonalInfoScreen extends StatefulWidget {
  const EditPersonalInfoScreen({super.key});

  @override
  State<EditPersonalInfoScreen> createState() => _EditPersonalInfoScreenState();
}

class _EditPersonalInfoScreenState extends State<EditPersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Updated controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController(); // Read-only
  final _phoneCtrl = TextEditingController();
  final _addressLine1Ctrl = TextEditingController();
  final _addressLine2Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _zipCodeCtrl = TextEditingController();

  DateTime? _dob; // Read-only

  // Define KYYAP Style Colors locally to ensure standalone functionality
  final Color _primaryColor = const Color(0xFF6C63FF);
  final Color _textColor = const Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    final vm = context.read<ProfileViewModel>();
    final p = vm.profile;
    if (p != null) {
      _firstNameCtrl.text = p.firstName ?? '';
      _lastNameCtrl.text = p.lastName ?? '';
      _emailCtrl.text = p.email ?? '';
      _phoneCtrl.text = p.phone ?? '';
      _addressLine1Ctrl.text = p.addressLine1 ?? '';
      _addressLine2Ctrl.text = p.addressLine2 ?? '';
      _cityCtrl.text = p.city ?? '';
      _stateCtrl.text = p.state ?? '';
      _countryCtrl.text = p.country ?? '';
      _zipCodeCtrl.text = p.zipCode ?? '';
      _dob = p.dob?.toDate();
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressLine1Ctrl.dispose();
    _addressLine2Ctrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _countryCtrl.dispose();
    _zipCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto(ProfileViewModel vm) async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.photos,
      ].request();
    }

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 90
      );

      if (picked == null) return;

      final file = File(picked.path);

      if (!await file.exists()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Image file not found')),
        );
        return;
      }

      final ext = picked.path.split('.').last.toLowerCase();
      final allowed = ['jpg', 'jpeg', 'png', 'gif'];

      if (!allowed.contains(ext)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please choose JPG/PNG/GIF image')),
        );
        return;
      }

      final url = await vm.uploadProfilePicture(file, fileExt: ext == 'jpeg' ? 'jpg' : ext);

      if (!mounted) return;

      if (url != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded successfully')),
        );
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.error ?? 'Unknown error occurred'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, vm, _) {
        final p = vm.profile;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(
                  Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Personal Information',
              style: TextStyle(
                color: _textColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // ===== Profile Picture Section =====
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[200]!, width: 4),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[100],
                            backgroundImage: (p?.profilePictureUrl != null &&
                                (p!.profilePictureUrl!.isNotEmpty))
                                ? NetworkImage(p.profilePictureUrl!)
                                : null,
                            child: (p?.profilePictureUrl == null ||
                                (p!.profilePictureUrl!.isEmpty))
                                ? Text(
                              (p != null && p.firstName != null && p.firstName!.isNotEmpty)
                                  ? p.firstName!.trim().characters.first.toUpperCase()
                                  : 'A',
                              style: TextStyle(
                                fontSize: 32,
                                color: _primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () => _pickAndUploadPhoto(vm),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: vm.savingRoot
                                  ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ===== Basic Information =====
                  _SectionTitle('Basic Information', color: _textColor),
                  const SizedBox(height: 16),

                  // First Name & Last Name (Editable, Required)
                  Row(
                    children: [
                      Expanded(
                        child: _StyledField(
                          label: 'First Name',
                          controller: _firstNameCtrl,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          primaryColor: _primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StyledField(
                          label: 'Last Name',
                          controller: _lastNameCtrl,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          primaryColor: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Email (Read-only)
                  _StyledField(
                    label: 'Email Address',
                    controller: _emailCtrl,
                    enabled: false,
                    primaryColor: _primaryColor,
                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // Phone Number (Editable, Required)
                  _StyledField(
                    label: 'Phone Number',
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    primaryColor: _primaryColor,
                    prefixIcon: const Icon(Icons.phone_outlined, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // Date of Birth (Read-only)
                  _StyledDateField(
                    label: 'Date of Birth',
                    value: _dob,
                    onPick: null, // Read-only
                    primaryColor: _primaryColor,
                    enabled: false,
                  ),

                  const SizedBox(height: 32),

                  // ===== Address Information =====
                  _SectionTitle('Address Information', color: _textColor),
                  const SizedBox(height: 16),

                  // Address Line 1 (Required)
                  _StyledField(
                    label: 'Address Line 1',
                    controller: _addressLine1Ctrl,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    primaryColor: _primaryColor,
                    prefixIcon: const Icon(Icons.home_outlined, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // Address Line 2 (Optional)
                  _StyledField(
                    label: 'Address Line 2 (Optional)',
                    controller: _addressLine2Ctrl,
                    primaryColor: _primaryColor,
                    prefixIcon: const Icon(Icons.home_outlined, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // City (Required)
                  _StyledField(
                    label: 'City',
                    controller: _cityCtrl,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    primaryColor: _primaryColor,
                    prefixIcon: const Icon(Icons.location_city_outlined, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // State & Zip Code Row
                  Row(
                    children: [
                      Expanded(
                        child: _StyledField(
                          label: 'State/Province',
                          controller: _stateCtrl,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          primaryColor: _primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StyledField(
                          label: 'Zip Code',
                          controller: _zipCodeCtrl,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          primaryColor: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Country (Required)
                  _StyledField(
                    label: 'Country',
                    controller: _countryCtrl,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    primaryColor: _primaryColor,
                    prefixIcon: const Icon(Icons.flag_outlined, color: Colors.grey),
                  ),

                  const SizedBox(height: 40),

                  // ===== Save Button =====
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: vm.savingRoot
                          ? null
                          : () async {
                        if (!_formKey.currentState!.validate()) return;

                        final ok = await vm.updatePersonalInfo(
                          name: '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
                          phone: _phoneCtrl.text.trim(),
                          dob: _dob != null ? Timestamp.fromDate(_dob!) : null,
                          city: _cityCtrl.text.trim(),
                          state: _stateCtrl.text.trim(),
                          country: _countryCtrl.text.trim(),
                        );

                        if (!mounted) return;
                        if (ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Personal information saved'),
                              backgroundColor: Color(0xFF00B894),
                            ),
                          );
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(vm.error ?? 'Failed to save'),
                              backgroundColor: const Color(0xFFD63031),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: vm.savingRoot
                          ? const SizedBox(
                          height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ===== Reusable Components =====

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {required this.color});
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: color,
        ),
      ),
    );
  }
}

class _StyledField extends StatelessWidget {
  const _StyledField({
    required this.label,
    required this.controller,
    required this.primaryColor,
    this.keyboardType,
    this.validator,
    this.enabled = true,
    this.prefixIcon,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool enabled;
  final Color primaryColor;
  final Widget? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          enabled: enabled,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 16,
            color: enabled ? const Color(0xFF1A1A1A) : Colors.grey[600],
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
            prefixIcon: prefixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _StyledDateField extends StatelessWidget {
  const _StyledDateField({
    required this.label,
    required this.value,
    required this.onPick,
    required this.primaryColor,
    this.enabled = true,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime>? onPick;
  final Color primaryColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController(
      text: value == null ? '' : DateFormat('dd/MM/yyyy').format(value!),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: enabled && onPick != null
              ? () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime(now.year - 20),
              firstDate: DateTime(1950),
              lastDate: now,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(primary: primaryColor),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) onPick!(picked);
          }
              : null,
          borderRadius: BorderRadius.circular(12),
          child: IgnorePointer(
            child: TextFormField(
              controller: ctrl,
              enabled: enabled,
              style: TextStyle(
                fontSize: 16,
                color: enabled ? const Color(0xFF1A1A1A) : Colors.grey[600],
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
                prefixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}