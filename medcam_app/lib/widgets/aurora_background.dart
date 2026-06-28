import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class AuroraBackground extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final double blurSigma;

  const AuroraBackground({
    super.key,
    required this.child,
    this.colors = const [
      Color(0xFFFFB3BA), // pastel pink — top-left
      Color(0xFFD4B3FF), // pastel lavender — bottom-right
    ],
    this.blurSigma = 80,
  });

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _xAnims;
  late final List<Animation<double>> _yAnims;
  late final List<Animation<double>> _scaleAnims;

  static const List<Alignment> _anchors = [
    Alignment(-1.2, -1.2), // top-left
    Alignment(1.2, 1.2),   // bottom-right
  ];

  static const List<double> _xDrift = [0.6, -0.6];
  static const List<double> _yDrift = [0.6, 0.6];

  final _random = math.Random(42);

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.colors.length.clamp(0, 2), (i) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 8000 + _random.nextInt(4000)),
      )..repeat(reverse: true);
    });

    _xAnims = List.generate(_controllers.length, (i) {
      return Tween<double>(begin: 0.0, end: _xDrift[i]).animate(
        CurvedAnimation(parent: _controllers[i], curve: Curves.easeInOutSine),
      );
    });

    _yAnims = List.generate(_controllers.length, (i) {
      return Tween<double>(begin: 0.0, end: _yDrift[i]).animate(
        CurvedAnimation(parent: _controllers[i], curve: Curves.easeInOutSine),
      );
    });

    _scaleAnims = List.generate(_controllers.length, (i) {
      return Tween<double>(begin: 0.8, end: 1.2).animate(
        CurvedAnimation(parent: _controllers[i], curve: Curves.easeInOutSine),
      );
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.colors.length.clamp(0, 2);

    return AnimatedBuilder(
      animation: Listenable.merge(_controllers),
      builder: (context, _) {
        return Stack(
          children: [
            Positioned.fill(
              child: ClipRect(
                child: Stack(
                  children: [
                    for (int i = 0; i < count; i++)
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment(
                            _anchors[i].x + _xAnims[i].value,
                            _anchors[i].y + _yAnims[i].value,
                          ),
                          child: Transform.scale(
                            scale: _scaleAnims[i].value,
                            child: Container(
                              width: 260,
                              height: 260,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.colors[i]
                                    .withValues(alpha: 0.25),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: widget.blurSigma,
                  sigmaY: widget.blurSigma,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            widget.child,
          ],
        );
      },
    );
  }
}
