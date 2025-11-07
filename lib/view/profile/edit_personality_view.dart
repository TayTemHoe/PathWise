import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_wise/ViewModel/profile_view_model.dart';

class EditPersonalityScreen extends StatefulWidget {
  const EditPersonalityScreen({super.key});

  @override
  EditPersonalityScreenState createState() => EditPersonalityScreenState();
}

// made public to avoid: "Invalid use of a private type in a public API"
class EditPersonalityScreenState extends State<EditPersonalityScreen> {
  late TextEditingController _mbtiController;
  late TextEditingController _riasecController;

  @override
  void initState() {
    super.initState();
    final vm = context.read<ProfileViewModel>();
    _mbtiController = TextEditingController(text: vm.profile?.mbti ?? '');
    _riasecController = TextEditingController(text: vm.profile?.riasec ?? '');
  }

  @override
  void dispose() {
    _mbtiController.dispose();
    _riasecController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final currentMbti = vm.profile?.mbti ?? '';
    final currentRiasec = vm.profile?.riasec ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7C4DFF), Color(0xFF6EA8FF)], // same as edit_skills_screen
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Personality Tests',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'MBTI (16 Personalities)',
            currentValue: currentMbti.isEmpty ? 'Not set' : currentMbti,
            controller: _mbtiController,
            placeholder: 'e.g., INTP, ENFJ...',
            onUpdate: () async {
              final ok = await context.read<ProfileViewModel>().updatePersonality(
                mbti: _mbtiController.text.trim(),
                riasec: currentRiasec, // keep riasec
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ok ? 'MBTI updated' : 'Failed to update MBTI')),
              );
            },
            // trusted, free MBTI-like test
            linkLabel: 'Take the MBTI test (16personalities)',
            linkUrl: Uri.parse('https://www.16personalities.com/free-personality-test'),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'RIASEC (Holland Code)',
            currentValue: currentRiasec.isEmpty ? 'Not set' : currentRiasec,
            controller: _riasecController,
            placeholder: 'e.g., RIA, SEC...',
            onUpdate: () async {
              final ok = await context.read<ProfileViewModel>().updatePersonality(
                mbti: currentMbti, // keep mbti
                riasec: _riasecController.text.trim(),
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ok ? 'RIASEC updated' : 'Failed to update RIASEC')),
              );
            },
            // trusted, free RIASEC test
            linkLabel: 'Take the RIASEC test (Truity)',
            linkUrl: Uri.parse('https://www.truity.com/test/holland-code-career-test'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.currentValue,
    required this.controller,
    required this.onUpdate,
    required this.linkLabel,
    required this.linkUrl,
    this.placeholder,
  });

  final String title;
  final String currentValue;
  final TextEditingController controller;
  final VoidCallback onUpdate;
  final String linkLabel;
  final Uri linkUrl;
  final String? placeholder;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                const Icon(Icons.psychology_alt_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Current value
            Text(
              'Current: $currentValue',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
            const SizedBox(height: 10),

            // Input
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: placeholder ?? 'Enter your result',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFAE5E7EB)),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            // Buttons (prevent overflow on small screens)
            LayoutBuilder(
              builder: (context, c) {
                final narrow = c.maxWidth < 380;
                final saveBtn = ElevatedButton(
                  onPressed: onUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C4DFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Update Result'),
                );

                final linkBtn = TextButton.icon(
                  onPressed: () async {
                    final ok = await _openExternal(linkUrl);
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not open the link.'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: Text(linkLabel),
                );

                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      saveBtn,
                      const SizedBox(height: 8),
                      linkBtn,
                    ],
                  );
                }
                return Row(
                  children: [
                    saveBtn,
                    const SizedBox(width: 12),
                    Flexible(child: Align(alignment: Alignment.centerLeft, child: linkBtn)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Uses the modern url_launcher API (no deprecations).
Future<bool> _openExternal(Uri uri) async {
  try {
    // Prefer launching into an external browser/app
    final can = await canLaunchUrl(uri);
    if (!can) return false;
    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication
    );
    return ok;
  } catch (_) {
    return false;
  }
}
