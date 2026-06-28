import 'package:flutter/material.dart';
import 'package:medcam_app/theme/app_theme.dart';
import 'package:medcam_app/widgets/glass_card.dart';

class LoadingSkeleton extends StatefulWidget {
  final int itemCount;
  final SkeletonType type;

  const LoadingSkeleton({
    super.key,
    this.itemCount = 6,
    this.type = SkeletonType.grid,
  });

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

enum SkeletonType { grid, list }

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return AnimatedBuilder(
      animation: _controller,
        builder: (context, _) {
        if (widget.type == SkeletonType.grid) {
          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.72,
            ),
            itemCount: widget.itemCount,
            itemBuilder: (_, _) => _skeletonCard(brightness),
          );
        }
        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.itemCount,
          itemBuilder: (_, _) => _skeletonRow(brightness),
        );
      },
    );
  }

  Widget _skeletonCard(Brightness brightness) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      blur: 8,
      borderRadius: AppRadius.xl,
      color: AppColors.glass(brightness),
      borderColor: AppColors.glassBorderColor(brightness),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerBlock(height: 80, radius: AppRadius.md, brightness: brightness),
          const SizedBox(height: AppSpacing.sm + 2),
          _shimmerBlock(width: 110, height: 14, radius: AppRadius.sm, brightness: brightness),
          const SizedBox(height: AppSpacing.xs + 2),
          _shimmerBlock(width: 80, height: 11, radius: AppRadius.sm, brightness: brightness),
          const SizedBox(height: AppSpacing.sm),
          _shimmerBlock(width: double.infinity, height: 10, radius: AppRadius.sm, brightness: brightness),
          const SizedBox(height: AppSpacing.xs),
          _shimmerBlock(width: 60, height: 10, radius: AppRadius.sm, brightness: brightness),
        ],
      ),
    );
  }

  Widget _skeletonRow(Brightness brightness) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      blur: 8,
      borderRadius: AppRadius.xl,
      color: AppColors.glass(brightness),
      borderColor: AppColors.glassBorderColor(brightness),
      child: Row(
        children: [
          _shimmerBlock(width: 52, height: 52, radius: AppRadius.md, brightness: brightness),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBlock(width: 140, height: 14, radius: AppRadius.sm, brightness: brightness),
                const SizedBox(height: AppSpacing.xs + 2),
                _shimmerBlock(width: 100, height: 11, radius: AppRadius.sm, brightness: brightness),
                const SizedBox(height: AppSpacing.xs),
                _shimmerBlock(width: 80, height: 10, radius: AppRadius.sm, brightness: brightness),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBlock({
    double? width,
    required double height,
    double radius = 4,
    Brightness? brightness,
  }) {
    final b = brightness ?? Brightness.dark;
    final shimmerPosition = (_controller.value * 2).clamp(0.0, 1.0);
    final baseOpacity = 0.15;
    final shimmerOpacity = baseOpacity + shimmerPosition * 0.25;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(-1.0 + shimmerPosition * 2, 0),
          end: Alignment(-0.5 + shimmerPosition * 2, 0),
          colors: [
            AppColors.bgRaised.withValues(alpha: shimmerOpacity),
            AppColors.primary(b).withValues(alpha: shimmerOpacity * 0.4),
            AppColors.bgRaised.withValues(alpha: shimmerOpacity),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}
