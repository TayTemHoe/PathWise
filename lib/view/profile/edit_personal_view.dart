import 'dart:io';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/ViewModel/profile_view_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

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
    try {
      // Request permissions
      PermissionStatus status;

      if (Platform.isAndroid) {
        // For Android 13+, request READ_MEDIA_IMAGES
        // For Android 12 and below, request READ_EXTERNAL_STORAGE
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          // Android 13+
          status = await Permission.photos.request();
        } else {
          // Android 12 and below
          status = await Permission.storage.request();
        }
      } else {
        // iOS
        status = await Permission.photos.request();
      }

      // Handle permission result
      if (status.isDenied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo permission is required'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      if (status.isPermanentlyDenied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo permission is permanently denied. Open app settings.'),
            duration: Duration(seconds: 3),
          ),
        );
        openAppSettings();
        return;
      }

      // Pick image
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (picked == null) {
        // User cancelled
        return;
      }

      final file = File(picked.path);
      final ext = picked.path.split('.').last.toLowerCase();
      const allowed = ['jpg', 'jpeg', 'png', 'gif'];

      if (!allowed.contains(ext)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please choose a JPG, PNG, or GIF image'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Show uploading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uploading photo...'),
          duration: Duration(seconds: 5),
        ),
      );

      // Upload
      final url = await vm.uploadProfilePicture(
        file,
        fileExt: ext == 'jpeg' ? 'jpg' : ext,
      );

      if (!mounted) return;
      if (url != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo uploaded successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {}); // Refresh avatar
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.error ?? 'Failed to upload photo'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, vm, _) {
        final p = vm.profile;

        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FC),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF6EA8FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            title: const Text(
              'Personal Information',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // ===== Profile Picture card =====
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: const Color(0xFFE5E7EB),
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
                              style: const TextStyle(
                                fontSize: 22,
                                color: Color(0xFF111827),
                                fontWeight: FontWeight.bold,
                              ),
                            )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _pickAndUploadPhoto(vm),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEEF2FF),
                                    foregroundColor: const Color(0xFF4338CA),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                                  label: const Text('Upload Photo'),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Upload a clear photo. Max 5MB (JPG, PNG, GIF)',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ===== Basic Information card =====
                  _SectionTitle('Basic Information'),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _Field(
                            label: 'Full Name *',
                            controller: _nameCtrl,
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                          _Field(
                            label: 'Email Address *',
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            // If you keep email non-editable, uncomment:
                            // enabled: false,
                          ),
                          _Field(
                            label: 'Phone Number *',
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            helper:
                            'Include country code for better verification',
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                          _DateField(
                            label: 'Date of Birth',
                            value: _dob,
                            onPick: (d) => setState(() => _dob = d),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ===== Location Information card =====
                  _SectionTitle('Location Information'),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _Field(
                            label: 'Current City *',
                            controller: _cityCtrl,
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                          _Field(
                            label: 'Country *',
                            controller: _countryCtrl,
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                          _Field(
                            label: 'State/Province',
                            controller: _stateCtrl,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ===== Actions =====
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: vm.savingRoot
                          ? null
                          : () async {
                        if (!_formKey.currentState!.validate()) return;

                        // If you keep email editable, ensure ViewModel supports it (see note below).
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
                            const SnackBar(content: Text('Personal information saved')),
                          );
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(vm.error ?? 'Failed to save')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C4DFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: vm.savingRoot
                          ? const SizedBox(
                          height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Save Personal Information'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
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

// ===== Helpers =====

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF111827),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.helper,
    this.keyboardType,
    this.validator,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final String? helper;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            validator: validator,
            enabled: enabled,
            keyboardType: keyboardType,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          if (helper != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(helper!, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onPick});
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController(
      text: value == null ? '' : DateFormat('dd/MM/yyyy').format(value!),
    );

    return _Field(
      label: label,
      controller: ctrl,
      keyboardType: TextInputType.none,
    ).copyWith(
      child: InkWell(
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime(now.year - 20),
            firstDate: DateTime(1950),
            lastDate: now,
          );
          if (picked != null) onPick(picked);
        },
        child: IgnorePointer(
          child: TextFormField(
            controller: ctrl,
            decoration: const InputDecoration(
              suffixIcon: Icon(Icons.calendar_today_outlined, size: 20),
              filled: true,
              fillColor: Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
      ),
    );
  }
}

// Small extension to reuse _Field decoration for _DateField
extension on _Field {
  Widget copyWith({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
