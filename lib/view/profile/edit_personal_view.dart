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

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();

  DateTime? _dob;

  // Define KYYAP Style Colors locally to ensure standalone functionality
  final Color _primaryColor = const Color(0xFF6C63FF);
  final Color _textColor = const Color(0xFF1A1A1A);


  @override
  void initState() {
    super.initState();
    final vm = context.read<ProfileViewModel>();
    final p = vm.profile;
    if (p != null) {
      _nameCtrl.text = p.name ?? '';
      _emailCtrl.text = p.email ?? '';
      _phoneCtrl.text = p.phone ?? '';
      _cityCtrl.text = p.city ?? '';
      _stateCtrl.text = p.state ?? '';
      _countryCtrl.text = p.country ?? '';
      _dob = p.dob?.toDate();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _countryCtrl.dispose();
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
          // KYYAP Style: White background
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
                              (p != null && p.name != null && p.name!.isNotEmpty)
                                  ? p.name!.trim().characters.first.toUpperCase()
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
                  _StyledField(
                    label: 'Full Name',
                    controller: _nameCtrl,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    primaryColor: _primaryColor,
                  ),
                  const SizedBox(height: 20),
                  _StyledField(
                    label: 'Email Address',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    primaryColor: _primaryColor,
                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  _StyledField(
                    label: 'Phone Number',
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    primaryColor: _primaryColor,
                    prefixIcon: const Icon(Icons.phone_outlined, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  _StyledDateField(
                    label: 'Date of Birth',
                    value: _dob,
                    onPick: (d) => setState(() => _dob = d),
                    primaryColor: _primaryColor,
                  ),

                  const SizedBox(height: 32),

                  // ===== Location Information =====
                  _SectionTitle('Location Information', color: _textColor),
                  const SizedBox(height: 16),
                  _StyledField(
                    label: 'Current City',
                    controller: _cityCtrl,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    primaryColor: _primaryColor,
                    prefixIcon: const Icon(Icons.location_city_outlined, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _StyledField(
                          label: 'Country',
                          controller: _countryCtrl,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          primaryColor: _primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StyledField(
                          label: 'State/Province',
                          controller: _stateCtrl,
                          primaryColor: _primaryColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // ===== Actions =====
                  // Save Button styled like KYYAP CustomButton
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: vm.savingRoot
                          ? null
                          : () async {
                        if (!_formKey.currentState!.validate()) return;

                        final ok = await vm.updatePersonalInfo(
                          name: _nameCtrl.text.trim(),
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
                              backgroundColor: Color(0xFF00B894), // Success green
                            ),
                          );
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(vm.error ?? 'Failed to save'),
                              backgroundColor: const Color(0xFFD63031), // Error red
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

// ===== Reusable Components Styled to Match KYYAP =====

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

// Modified to match KYYAP's "CustomTextField" look
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
          style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A1A)),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
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
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController(
      text: value == null ? '' : DateFormat('dd/MM/yyyy').format(value!),
    );

    return _StyledField(
      label: label,
      controller: ctrl,
      primaryColor: primaryColor,
      prefixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
    ).copyWithTap(
      onTap: () async {
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
        if (picked != null) onPick(picked);
      },
    );
  }
}

extension on _StyledField {
  Widget copyWithTap({required VoidCallback onTap}) {
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: IgnorePointer(
            child: TextFormField(
              controller: controller,
              style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A1A)),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[50],
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
                disabledBorder: OutlineInputBorder( // Ensure styled even when disabled/ignored
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