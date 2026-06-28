import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medcam_app/core/constants.dart';
import 'package:medcam_app/models/history_entry.dart';
import 'package:medcam_app/providers/history_provider.dart';
import 'package:medcam_app/providers/tab_provider.dart';
import 'package:medcam_app/screens/result/result_sheet.dart';
import 'package:medcam_app/theme/app_theme.dart';
import 'package:medcam_app/widgets/history_row.dart';
import 'package:medcam_app/models/medicine.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    Future.microtask(() => ref.read(historyProvider.notifier).load());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _showResult(HistoryEntry entry) {
    HapticFeedback.mediumImpact();
    final result = SearchResult(
      medicine: entry.medicine,
      genericName: entry.genericName,
      score: 1.0,
      matchType: 'history',
      imageUrl: entry.imageUrl,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ResultSheet(result: result),
    );
  }

  Map<String, List<HistoryEntry>> _groupByDate(List<HistoryEntry> entries) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final grouped = <String, List<HistoryEntry>>{
      'Today': [],
      'Yesterday': [],
      'Earlier': [],
    };

    for (final entry in entries) {
      final entryDate = DateTime(
        entry.scannedAt.year,
        entry.scannedAt.month,
        entry.scannedAt.day,
      );

      if (entryDate.isAtSameMomentAs(today)) {
        grouped['Today']!.add(entry);
      } else if (entryDate.isAtSameMomentAs(yesterday)) {
        grouped['Yesterday']!.add(entry);
      } else {
        grouped['Earlier']!.add(entry);
      }
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final history = ref.watch(historyProvider);

    if (history.isEmpty) {
      return _buildEmptyState();
    }

    final grouped = _groupByDate(history);

    return Column(
      children: [
        // Header with clear button
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(Icons.history_rounded, color: AppColors.primary(brightness), size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Scan History',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              if (history.isNotEmpty)
                TextButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear History'),
                        content: const Text(
                            'Remove all scan history? This cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.danger,
                            ),
                            child: const Text('Clear All'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      ref.read(historyProvider.notifier).clear();
                    }
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Grouped list
        Expanded(
          child: FadeTransition(
            opacity: _fadeController,
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              itemCount: _buildGroupedList(grouped).length,
              itemBuilder: (context, index) =>
                  _buildGroupedList(grouped)[index],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildGroupedList(Map<String, List<HistoryEntry>> grouped) {
    final widgets = <Widget>[];

    for (final entry in grouped.entries) {
      if (entry.value.isNotEmpty) {
        // Section header
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.lg,
              AppSpacing.xxl,
              AppSpacing.sm,
            ),
            child: Text(
              entry.key.toUpperCase(),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.inkFaint,
                letterSpacing: 1.0,
              ),
            ),
          ),
        );

        // Entries
        for (final item in entry.value) {
          widgets.add(
            HistoryRow(
              entry: item,
              onTap: () => _showResult(item),
              onDelete: () =>
                  ref.read(historyProvider.notifier).delete(item.id),
            ),
          );
        }
      }
    }

    return widgets;
  }

  Widget _buildEmptyState() {
    final brightness = Theme.of(context).brightness;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryFaint(brightness),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.document_scanner_rounded,
                color: AppColors.primary(brightness),
                size: 48,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            Text(
              'No Scans Yet',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Point the scanner at any medicine\nto start building your history',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxxl),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(tabProvider.notifier).goTo(AppTabs.scanner);
              },
              icon: const Icon(Icons.camera_alt_rounded, size: 20),
              label: const Text('START SCANNING'),
            ),
          ],
        ),
      ),
    );
  }
}
