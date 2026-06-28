import 'package:flutter/material.dart';
import 'package:medcam_app/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

enum BadgeType { info, success, warning, danger }

class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final BadgeType? type;
  final IconData? icon;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.label,
    this.color,
    this.type,
    this.icon,
    this.fontSize = 10,
  });

  Color get _resolvedColor {
    if (color != null) return color!;
    switch (type) {
      case BadgeType.success:
        return AppColors.safeGreen;
      case BadgeType.warning:
        return AppColors.warningAmber;
      case BadgeType.danger:
        return AppColors.coralDanger;
      case BadgeType.info:
      case null:
        return AppColors.metadataLavender;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedColor = _resolvedColor;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: resolvedColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: resolvedColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: resolvedColor),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              fontSize: fontSize,
              color: resolvedColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
