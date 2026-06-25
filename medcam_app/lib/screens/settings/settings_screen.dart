import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medcam_app/providers/shared_providers.dart';
import 'package:medcam_app/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _urlController = TextEditingController();
  bool _isTesting = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    final url = await ref.read(settingsServiceProvider).apiBaseUrl;
    _urlController.text = url;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(settingsServiceProvider).setApiBaseUrl(_urlController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API URL saved')),
      );
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });
    try {
      final api = ref.read(apiServiceProvider);
      final health = await api.health();
      setState(() {
        _testResult = 'Connected — ${health['records']} records loaded';
        _isTesting = false;
      });
    } catch (e) {
      setState(() {
        _testResult = 'Failed: $e';
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'API CONNECTION',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 10,
                color: AppColors.inkFaint,
                letterSpacing: 0.15,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                hintText: 'http://127.0.0.1:8000',
                labelStyle: TextStyle(color: AppColors.inkMuted),
              ),
              style: GoogleFonts.ibmPlexMono(
                fontSize: 13,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('SAVE'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isTesting ? null : _testConnection,
                    child: _isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('TEST'),
                  ),
                ),
              ],
            ),
            if (_testResult != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _testResult!.startsWith('Connected')
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _testResult!.startsWith('Connected')
                        ? AppColors.success.withValues(alpha: 0.3)
                        : AppColors.danger.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _testResult!,
                  style: GoogleFonts.ibmPlexMono(fontSize: 11, color: AppColors.inkMuted),
                ),
              ),
            ],
            const Spacer(),
            Center(
              child: Text(
                'MedCam v1.0.0',
                style: GoogleFonts.ibmPlexMono(fontSize: 11, color: AppColors.inkFaint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
