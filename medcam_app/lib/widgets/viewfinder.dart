import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:medcam_app/theme/app_theme.dart';

class Viewfinder extends StatefulWidget {
  final double size;

  const Viewfinder({super.key, this.size = 260});

  @override
  State<Viewfinder> createState() => _ViewfinderState();
}

class _ViewfinderState extends State<Viewfinder>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _scanController]),
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _ViewfinderPainter(
            pulseOpacity: _pulseAnimation.value,
            scanProgress: _scanController.value,
          ),
        );
      },
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  final double pulseOpacity;
  final double scanProgress;

  _ViewfinderPainter({
    required this.pulseOpacity,
    required this.scanProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Outer glow ring
      paint.color = AppColors.amberGlow.withValues(alpha: pulseOpacity * 0.3);
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, radius, paint);
    paint.maskFilter = null;

    // Main ring
    paint.color = AppColors.amberGlow.withValues(alpha: pulseOpacity);
    canvas.drawCircle(center, radius, paint);

    // Inner dark fill
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF0A0907);
    canvas.drawCircle(center, radius - 1.5, fillPaint);

    // Corner tick marks (arcs at NE/NW/SE/SW)
    final tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.amberGlow.withValues(alpha: 0.8);
    const tickLength = 16.0;
    const gap = 6.0;

    void drawCornerTick(double startAngle) {
      final path = Path();
      const segments = 12;
      for (int i = 0; i <= segments; i++) {
        final t = i / segments;
        final angle = startAngle + t * (math.pi / 6);
        final r = radius - gap - tickLength + t * tickLength;
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, tickPaint);
    }

    drawCornerTick(-math.pi / 4 - math.pi / 12);
    drawCornerTick(-math.pi / 4 + math.pi / 2 - math.pi / 12);
    drawCornerTick(-math.pi / 4 + math.pi - math.pi / 12);
    drawCornerTick(-math.pi / 4 + 3 * math.pi / 2 - math.pi / 12);

    // Crosshair reticle
    final crossPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.amberDim.withValues(alpha: 0.5);
    final crossGap = 10.0;
    final crossLen = 20.0;

    canvas.drawLine(Offset(center.dx - crossGap - crossLen, center.dy),
        Offset(center.dx - crossGap, center.dy), crossPaint);
    canvas.drawLine(Offset(center.dx + crossGap, center.dy),
        Offset(center.dx + crossGap + crossLen, center.dy), crossPaint);
    canvas.drawLine(Offset(center.dx, center.dy - crossGap - crossLen),
        Offset(center.dx, center.dy - crossGap), crossPaint);
    canvas.drawLine(Offset(center.dx, center.dy + crossGap),
        Offset(center.dx, center.dy + crossGap + crossLen), crossPaint);

    // Scan line (horizontal hairline sweeping vertically)
    final scanY = center.dy - radius + 2 + scanProgress * (radius * 2 - 4);
    final scanPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.amberGlow.withValues(alpha: 0.6);
    final scanWidth = radius * 1.2;
    canvas.drawLine(
      Offset(center.dx - scanWidth, scanY),
      Offset(center.dx + scanWidth, scanY),
      scanPaint,
    );

    // Vignette
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.4),
        ],
        stops: const [0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, vignettePaint);
  }

  @override
  bool shouldRepaint(_ViewfinderPainter oldDelegate) =>
      oldDelegate.pulseOpacity != pulseOpacity ||
      oldDelegate.scanProgress != scanProgress;
}
