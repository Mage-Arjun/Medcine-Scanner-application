import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medcam_app/models/history_entry.dart';
import 'package:medcam_app/theme/app_theme.dart';
import 'package:medcam_app/widgets/status_badge.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryRow extends StatelessWidget {
  final HistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const HistoryRow({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy · HH:mm').format(entry.scannedAt);

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => true,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.danger,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.amberDim, width: 1),
                  color: AppColors.bgRaised,
                ),
                child: entry.imageUrl != null && entry.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Image.network(
                          entry.imageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.medication, color: AppColors.inkFaint, size: 20),
                        ),
                      )
                    : const Icon(Icons.medication, color: AppColors.inkFaint, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.medicine,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 14,
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (entry.genericName != null)
                      Text(
                        entry.genericName!,
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 11,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 10,
                        color: AppColors.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: entry.source,
                color: entry.source == 'scan' ? AppColors.success : AppColors.amberDim,
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.inkFaint, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
