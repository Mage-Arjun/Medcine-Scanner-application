import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medcam_app/providers/shared_providers.dart';
import 'package:medcam_app/theme/app_theme.dart';
import 'package:medcam_app/widgets/glass_card.dart';
import 'package:medcam_app/widgets/aurora_background.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _urlController = TextEditingController();
  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;
  String _version = '';
  String _buildMode = '';

  @override
  void initState() {
    super.initState();
    _loadUrl();
    _loadVersion();
  }

  Future<void> _loadUrl() async {
    final url = await ref.read(settingsServiceProvider).apiBaseUrl;
    _urlController.text = url;
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
        _buildMode = const bool.fromEnvironment('dart.vm.product')
            ? 'Release'
            : 'Debug';
      });
    }
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
        _testSuccess = true;
        _isTesting = false;
      });
    } catch (e) {
      setState(() {
        _testResult = 'Failed: $e';
        _testSuccess = false;
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: AuroraBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBrandingCard(brightness),
              const SizedBox(height: AppSpacing.xxxl),

              _buildSectionHeader('API Connection', Icons.cloud_rounded),
              const SizedBox(height: AppSpacing.md),
              _buildApiCard(brightness),
              const SizedBox(height: AppSpacing.xxxl),

              _buildSectionHeader('About', Icons.info_outline_rounded),
              const SizedBox(height: AppSpacing.md),
              _buildAboutCard(brightness),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandingCard(Brightness brightness) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      blur: 16,
      borderRadius: AppRadius.xl,
      color: AppColors.primary(brightness).withValues(alpha: 0.12),
      borderColor: AppColors.primary(brightness).withValues(alpha: 0.2),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary(brightness).withValues(alpha: 0.12),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary(brightness).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medical_services_rounded,
              color: AppColors.primary(brightness),
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'MediCam',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.text(brightness),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Medicine Scanner & Search',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textMuted(brightness),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary(brightness).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              _version.isNotEmpty ? 'v$_version' : 'v...',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: AppColors.primary(brightness),
              ),
            ),
          ),
          ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary(Theme.of(context).brightness)),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    );
  }

  Widget _buildApiCard(Brightness brightness) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      blur: 12,
      borderRadius: AppRadius.xl,
      color: AppColors.glass(brightness),
      borderColor: AppColors.glassBorderColor(brightness),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SERVER URL',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color: AppColors.textFaint(brightness),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _urlController,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              color: AppColors.text(brightness),
            ),
            decoration: const InputDecoration(
              hintText: 'http://127.0.0.1:8000',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('SAVE'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
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
            const SizedBox(height: AppSpacing.lg),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: _testSuccess
                    ? AppColors.safeGreen.withValues(alpha: 0.1)
                    : AppColors.coralDanger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: _testSuccess
                      ? AppColors.safeGreen.withValues(alpha: 0.3)
                      : AppColors.coralDanger.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _testSuccess
                        ? Icons.check_circle_rounded
                        : Icons.error_rounded,
                    size: 16,
                    color: _testSuccess ? AppColors.safeGreen : AppColors.coralDanger,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _testResult!,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: AppColors.textMuted(brightness),
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

  Widget _buildAboutCard(Brightness brightness) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      blur: 12,
      borderRadius: AppRadius.xl,
      color: AppColors.glass(brightness),
      borderColor: AppColors.glassBorderColor(brightness),
      child: Column(
        children: [
          _aboutRow(brightness, 'Version', _version.isNotEmpty ? _version : '...'),
          Divider(height: AppSpacing.xxl, color: AppColors.borderColor(brightness)),
          _aboutRow(brightness, 'Build', _buildMode.isNotEmpty ? _buildMode : '...'),
          Divider(height: AppSpacing.xxl, color: AppColors.borderColor(brightness)),
          _aboutRow(brightness, 'Platform', Theme.of(context).platform.name),
        ],
      ),
    );
  }

  Widget _aboutRow(Brightness brightness, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textMuted(brightness),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 13,
            color: AppColors.text(brightness),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
