import 'package:flutter/material.dart';
import 'package:medcam_app/models/history_entry.dart';
import 'package:medcam_app/theme/app_theme.dart';
import 'package:medcam_app/widgets/status_badge.dart';
import 'package:medcam_app/widgets/glass_card.dart';
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

  String _relativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final borderColor =
        entry.source == 'scan' ? AppColors.primaryDim(brightness) : AppColors.borderColor(brightness);

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Entry'),
            content: Text('Remove "${entry.medicine}" from history?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xxl),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.danger, size: 22),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          blur: 12,
          borderRadius: AppRadius.xl,
          color: AppColors.glass(brightness),
          borderColor: AppColors.glassBorderColor(brightness),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: borderColor,
                    width: 1.5,
                  ),
                  color: AppColors.raised(brightness),
                ),
                child: entry.imageUrl != null && entry.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md - 1),
                        child: Image.network(
                          entry.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _placeholderIcon(context),
                        ),
                      )
                    : _placeholderIcon(context),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.medicine,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.text(brightness),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (entry.genericName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          entry.genericName!,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: AppColors.primary(brightness),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _relativeTime(entry.scannedAt),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: AppColors.textFaint(brightness),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusBadge(
                label: entry.source,
                type: entry.source == 'scan'
                    ? BadgeType.success
                    : BadgeType.info,
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textFaint(brightness),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderIcon(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Center(
      child: Icon(
        Icons.medication_rounded,
        color: AppColors.primaryDim(brightness),
        size: 24,
      ),
    );
  }
}
