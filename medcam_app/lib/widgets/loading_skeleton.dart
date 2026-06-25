import 'package:flutter/material.dart';
import 'package:medcam_app/theme/app_theme.dart';

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
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (widget.type == SkeletonType.grid) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: widget.itemCount,
            itemBuilder: (_, __) => _skeletonCard(),
          );
        }
        return ListView.builder(
          itemCount: widget.itemCount,
          itemBuilder: (_, __) => _skeletonRow(),
        );
      },
    );
  }

  Widget _skeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerBlock(height: 80),
          const SizedBox(height: 8),
          _shimmerBlock(width: 100, height: 14),
          const SizedBox(height: 4),
          _shimmerBlock(width: 80, height: 11),
          const SizedBox(height: 6),
          _shimmerBlock(width: double.infinity, height: 10),
          const SizedBox(height: 2),
          _shimmerBlock(width: 60, height: 10),
        ],
      ),
    );
  }

  Widget _skeletonRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _shimmerBlock(width: 48, height: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBlock(width: 140, height: 14),
                const SizedBox(height: 4),
                _shimmerBlock(width: 100, height: 11),
                const SizedBox(height: 2),
                _shimmerBlock(width: 80, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBlock({double? width, required double height}) {
    final shimmerValue = (_controller.value * 2).clamp(0.0, 1.0);
    final shimmerOpacity = 0.3 + shimmerValue * 0.3;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.bgRaised.withValues(alpha: shimmerOpacity),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
