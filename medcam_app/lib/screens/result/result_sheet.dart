import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:medcam_app/models/medicine.dart';
import 'package:medcam_app/theme/app_theme.dart';
import 'package:medcam_app/widgets/confidence_indicator.dart';
import 'package:medcam_app/widgets/status_badge.dart';
import 'package:google_fonts/google_fonts.dart';

class ResultSheet extends StatelessWidget {
  final SearchResult result;

  const ResultSheet({super.key, required this.result});

  List<String> _parseChips(String? text) {
    if (text == null || text.isEmpty) return [];
    final cleaned = text
        .replaceAll(RegExp(r'\.\s*'), ',')
        .replaceAll(RegExp(r';\s*'), ',')
        .replaceAll(RegExp(r'\n'), ',');
    return cleaned
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final useChips = _parseChips(result.uses);
    final sideEffectChips = _parseChips(result.sideEffects);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.glass(brightness),
                border: Border(
                  top: BorderSide(
                    color: AppColors.glassBorderColor(brightness),
                  ),
                ),
              ),
              child: Column(
                children: [
                  // ── Handle ───────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderColor(brightness),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),

                  // ── Scrollable Content ───────────────────────────────────
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xxl,
                        AppSpacing.lg,
                        AppSpacing.xxl,
                        AppSpacing.xxxl,
                      ),
                      children: [
                        // ── Hero Image ─────────────────────────────────────
                        if (result.imageUrl != null &&
                            result.imageUrl!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            child: Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.raised(brightness),
                              ),
                              child: Image.network(
                                result.imageUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => _heroPlaceholder(brightness),
                              ),
                            ),
                          )
                        else
                          _heroPlaceholder(brightness),

                        const SizedBox(height: AppSpacing.xxl),

                        // ── Medicine Name ──────────────────────────────────
                        Text(
                          result.medicine,
                          style: Theme.of(context).textTheme.displayMedium,
                        ),

                        // ── Generic Name Chip ──────────────────────────────
                        if (result.genericName != null &&
                            result.genericName!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: StatusBadge(
                              label: result.genericName!,
                              type: BadgeType.info,
                              fontSize: 12,
                            ),
                          ),

                        const SizedBox(height: AppSpacing.lg),

                        // ── Match Info Row ─────────────────────────────────
                        Row(
                          children: [
                            StatusBadge(
                              label: result.matchType,
                              type: BadgeType.info,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              'Confidence',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // ── Confidence Ring ────────────────────────────────
                        Center(
                          child: ConfidenceIndicator(
                            score: result.score,
                            size: 80,
                            strokeWidth: 6,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xxxl),
                        Divider(color: AppColors.borderColor(brightness)),
                        const SizedBox(height: AppSpacing.lg),

                        // ── Uses Section ───────────────────────────────────
                        _buildSection(
                          context,
                          title: 'Uses',
                          icon: Icons.healing_rounded,
                          child: useChips.isNotEmpty
                              ? Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  children: useChips
                                      .map((chip) => _buildChip(chip, AppColors.primary(brightness), brightness))
                                      .toList(),
                                )
                              : _emptyState(brightness, 'No uses information available'),
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        // ── Side Effects Section ───────────────────────────
                        _buildSection(
                          context,
                          title: 'Side Effects',
                          icon: Icons.warning_amber_rounded,
                          child: sideEffectChips.isNotEmpty
                              ? Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  children: sideEffectChips
                                      .map((chip) => _buildChip(
                                          chip, AppColors.secondary(brightness), brightness))
                                      .toList(),
                                )
                              : _emptyState(brightness, 'No side effects information available'),
                        ),

                        const SizedBox(height: AppSpacing.xxxl),

                        // ── View Details Button ────────────────────────────
                        if (result.imageUrl != null &&
                            result.imageUrl!.isNotEmpty)
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: () => _launchUrl(result.imageUrl!),
                              icon: const Icon(Icons.open_in_new_rounded, size: 18),
                              label: const Text('VIEW DETAILS'),
                            ),
                          ),
                      ],
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

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary(Theme.of(context).brightness)),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }

  Widget _buildChip(String label, Color color, Brightness brightness) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _emptyState(Brightness brightness, String message) {
    return Text(
      message,
      style: GoogleFonts.inter(
        fontSize: 13,
        color: AppColors.textFaint(brightness),
      ),
    );
  }

  Widget _heroPlaceholder(Brightness brightness) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryFaint(brightness),
            AppColors.raised(brightness),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.medication_rounded,
          color: AppColors.primaryDim(brightness),
          size: 48,
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
