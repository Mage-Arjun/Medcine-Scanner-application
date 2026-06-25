import 'package:flutter/material.dart';
import 'package:medcam_app/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({
    super.key,
    required this.label,
    this.color = AppColors.amberGlow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.ibmPlexMono(
          fontSize: 10,
          color: color,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
