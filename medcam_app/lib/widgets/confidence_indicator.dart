import 'package:flutter/material.dart';
import 'package:medcam_app/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

enum ConfidenceLevel { high, medium, low }

class ConfidenceIndicator extends StatelessWidget {
  final double score;
  final double size;
  final double strokeWidth;
  final bool showLabel;
  final bool animate;

  const ConfidenceIndicator({
    super.key,
    required this.score,
    this.size = 64,
    this.strokeWidth = 5,
    this.showLabel = true,
    this.animate = true,
  });

  ConfidenceLevel get _level {
    if (score >= 0.8) return ConfidenceLevel.high;
    if (score >= 0.5) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }

  Color get _color {
    switch (_level) {
      case ConfidenceLevel.high:
        return AppColors.safeGreen;
      case ConfidenceLevel.medium:
        return AppColors.warningAmber;
      case ConfidenceLevel.low:
        return AppColors.coralDanger;
    }
  }

  Color get _trackColor {
    switch (_level) {
      case ConfidenceLevel.high:
        return AppColors.safeGreen.withValues(alpha: 0.15);
      case ConfidenceLevel.medium:
        return AppColors.warningAmber.withValues(alpha: 0.15);
      case ConfidenceLevel.low:
        return AppColors.coralDanger.withValues(alpha: 0.15);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              color: _trackColor,
              strokeCap: StrokeCap.round,
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: score),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (_, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: strokeWidth,
                color: _color,
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
          if (showLabel)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(score * 100).round()}',
                  style: GoogleFonts.inter(
                    fontSize: size * 0.24,
                    fontWeight: FontWeight.w700,
                    color: _color,
                  ),
                ),
                Text(
                  '%',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: size * 0.13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkFaint,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class MiniConfidenceBadge extends StatelessWidget {
  final double score;
  final double size;

  const MiniConfidenceBadge({
    super.key,
    required this.score,
    this.size = 32,
  });

  Color get _color {
    if (score >= 0.8) return AppColors.safeGreen;
    if (score >= 0.5) return AppColors.warningAmber;
    return AppColors.coralDanger;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _color.withValues(alpha: 0.15),
        border: Border.all(color: _color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Center(
        child: Text(
          '${(score * 100).round()}',
          style: GoogleFonts.inter(
            fontSize: size * 0.3,
            fontWeight: FontWeight.w700,
            color: _color,
          ),
        ),
      ),
    );
  }
}
