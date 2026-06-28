import 'package:flutter/material.dart';
import 'package:medcam_app/models/medicine.dart';
import 'package:medcam_app/theme/app_theme.dart';
import 'package:medcam_app/widgets/glass_card.dart';
import 'package:google_fonts/google_fonts.dart';

class DrugCard extends StatefulWidget {
  final SearchResult result;
  final VoidCallback onTap;

  const DrugCard({super.key, required this.result, required this.onTap});

  @override
  State<DrugCard> createState() => _DrugCardState();
}

class _DrugCardState extends State<DrugCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: GlassCard(
          padding: EdgeInsets.zero,
          blur: 12,
          borderRadius: AppRadius.xl,
          color: AppColors.glass(brightness),
          borderColor: AppColors.glassBorderColor(brightness),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl),
                ),
                child: SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: _buildImage(brightness),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.result.medicine,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.text(brightness),
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.result.genericName != null &&
                        widget.result.genericName!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          widget.result.genericName!,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: AppColors.primary(brightness),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (widget.result.uses != null &&
                        widget.result.uses!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          widget.result.uses!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textFaint(brightness),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
  }

  Widget _buildImage(Brightness brightness) {
    if (widget.result.imageUrl != null && widget.result.imageUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            widget.result.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _placeholderImage(brightness),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 30,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.glass(brightness),
                  ],
                ),
              ),
            ),
          ),
          if (widget.result.score > 0)
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: _confidenceBadge(),
            ),
        ],
      );
    }
    return _placeholderImage(brightness);
  }

  Widget _confidenceBadge() {
    final score = widget.result.score;
    Color color;
    if (score >= 0.8) {
      color = AppColors.safeGreen;
    } else if (score >= 0.5) {
      color = AppColors.warningAmber;
    } else {
      color = AppColors.coralDanger;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm - 1,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        '${(score * 100).round()}%',
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _placeholderImage(Brightness brightness) {
    return Container(
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
          size: 36,
        ),
      ),
    );
  }
}
