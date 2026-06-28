import 'dart:math' as math;
import 'package:flutter/material.dart';

class Viewfinder extends StatefulWidget {
  final double size;
  final bool isScanning;
  final Color primaryColor;

  const Viewfinder({
    super.key,
    this.size = 260,
    this.isScanning = false,
    required this.primaryColor,
  });

  @override
  State<Viewfinder> createState() => _ViewfinderState();
}

class _ViewfinderState extends State<Viewfinder>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _scanController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseController,
        _scanController,
        _glowController,
      ]),
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _ViewfinderPainter(
            pulseOpacity: _pulseAnimation.value,
            scanProgress: _scanController.value,
            glowIntensity: _glowController.value,
            isScanning: widget.isScanning,
            primaryColor: widget.primaryColor,
          ),
        );
      },
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  final double pulseOpacity;
  final double scanProgress;
  final double glowIntensity;
  final bool isScanning;
  final Color primaryColor;

  _ViewfinderPainter({
    required this.pulseOpacity,
    required this.scanProgress,
    required this.glowIntensity,
    required this.isScanning,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    _drawOuterGlow(center, radius, canvas);
    _drawMainRing(center, radius, canvas);
    _drawCornerBrackets(center, radius, canvas);
    _drawCrosshair(center, canvas);
    _drawScanLine(center, radius, canvas);
  }

  void _drawOuterGlow(Offset center, double radius, Canvas canvas) {
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = primaryColor.withValues(alpha: pulseOpacity * 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(center, radius + 6, glowPaint);

    final midGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = primaryColor.withValues(alpha: pulseOpacity * 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, radius + 2, midGlowPaint);
  }

  void _drawMainRing(Offset center, double radius, Canvas canvas) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = primaryColor.withValues(alpha: pulseOpacity);
    canvas.drawCircle(center, radius, paint);
  }

  void _drawCornerBrackets(Offset center, double radius, Canvas canvas) {
    final bracketPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = primaryColor.withValues(alpha: 0.9);

    final glowBracket = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = primaryColor.withValues(alpha: glowIntensity * 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    const bracketLen = 22.0;
    const gap = 2.0;

    // 4 cardinal points: top, right, bottom, left
    final angles = [-math.pi / 2, 0.0, math.pi / 2, math.pi];

    for (final angle in angles) {
      final cx = center.dx + (radius - gap) * math.cos(angle);
      final cy = center.dy + (radius - gap) * math.sin(angle);

      // Perpendicular direction
      final perpX = -math.sin(angle);
      final perpY = math.cos(angle);

      final path = Path();
      path.moveTo(cx + perpX * bracketLen * 0.8, cy + perpY * bracketLen * 0.8);
      path.lineTo(cx, cy);
      path.lineTo(cx + perpX * bracketLen * 0.8, cy + perpY * bracketLen * 0.8);

      // Along direction short arm
      final armPath = Path();
      armPath.moveTo(cx, cy);
      armPath.lineTo(
        cx + math.cos(angle) * bracketLen,
        cy + math.sin(angle) * bracketLen,
      );

      canvas.drawPath(path, glowBracket);
      canvas.drawPath(path, bracketPaint);
      canvas.drawPath(armPath, glowBracket);
      canvas.drawPath(armPath, bracketPaint);
    }
  }

  void _drawCrosshair(Offset center, Canvas canvas) {
    final crossPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = primaryColor.withValues(alpha: 0.4);

    const crossGap = 14.0;
    const crossLen = 16.0;

    canvas.drawLine(
      Offset(center.dx - crossGap - crossLen, center.dy),
      Offset(center.dx - crossGap, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx + crossGap, center.dy),
      Offset(center.dx + crossGap + crossLen, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - crossGap - crossLen),
      Offset(center.dx, center.dy - crossGap),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + crossGap),
      Offset(center.dx, center.dy + crossGap + crossLen),
      crossPaint,
    );

    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = primaryColor.withValues(alpha: 0.6);
    canvas.drawCircle(center, 2, dotPaint);
  }

  void _drawScanLine(Offset center, double radius, Canvas canvas) {
    final scanY = center.dy - radius + 4 + scanProgress * (radius * 2 - 8);
    final scanWidth = radius * 0.8;

    final trailShader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.transparent,
        primaryColor.withValues(alpha: 0.5),
        primaryColor,
        primaryColor.withValues(alpha: 0.5),
        Colors.transparent,
      ],
      stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
    ).createShader(
      Rect.fromCenter(
        center: Offset(center.dx, scanY),
        width: scanWidth * 2,
        height: 2,
      ),
    );

    final trailLinePaint = Paint()
      ..shader = trailShader
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx - scanWidth, scanY),
      Offset(center.dx + scanWidth, scanY),
      trailLinePaint,
    );

    final scanGlowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = primaryColor.withValues(alpha: 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx, scanY),
        width: scanWidth * 2,
        height: 24,
      ),
      scanGlowPaint,
    );
  }

  @override
  bool shouldRepaint(_ViewfinderPainter oldDelegate) =>
      oldDelegate.pulseOpacity != pulseOpacity ||
      oldDelegate.scanProgress != scanProgress ||
      oldDelegate.glowIntensity != glowIntensity ||
      oldDelegate.isScanning != isScanning;
}
