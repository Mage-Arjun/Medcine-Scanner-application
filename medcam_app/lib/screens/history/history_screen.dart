import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medcam_app/models/history_entry.dart';
import 'package:medcam_app/providers/history_provider.dart';
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

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(historyProvider.notifier).load());
  }

  void _showResult(HistoryEntry entry) {
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

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);

    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.biotech_outlined, color: AppColors.amberDim, size: 48),
              const SizedBox(height: 12),
              Text(
                'no scans yet',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 20,
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'point the scanner at any medicine to begin',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 11,
                  color: AppColors.inkFaint,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, index) {
        final entry = history[index];
        return HistoryRow(
          entry: entry,
          onTap: () => _showResult(entry),
          onDelete: () => ref.read(historyProvider.notifier).delete(entry.id),
        );
      },
    );
  }
}
