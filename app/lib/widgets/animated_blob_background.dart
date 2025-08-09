import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedBlobBackground extends StatefulWidget {
  const AnimatedBlobBackground({super.key});

  @override
  State<AnimatedBlobBackground> createState() => _AnimatedBlobBackgroundState();
}

class _AnimatedBlobBackgroundState extends State<AnimatedBlobBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _BlobPainter(t: _controller.value),
            );
          },
        ),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final double t; // 0..1
  _BlobPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    // Slight parallax movement for centers
    final double rads = t * 2 * math.pi;

    // Blob 1 - pink, top-left
    _drawBlob(
      canvas,
      size,
      center: Offset(size.width * (0.25 + 0.03 * math.sin(rads)),
          size.height * (0.28 + 0.02 * math.cos(rads * 1.2))),
      baseRadius: size.shortestSide * 0.28,
      amplitude: size.shortestSide * 0.04,
      frequency: 3,
      colors: const [Color(0xFFF472B6), Color(0xFFF472B6)],
      startOpacity: 0.22,
      endOpacity: 0.04,
      phase: rads,
    );

    // Blob 2 - orange, bottom-right
    _drawBlob(
      canvas,
      size,
      center: Offset(size.width * (0.78 + 0.03 * math.cos(rads * 0.9)),
          size.height * (0.75 + 0.03 * math.sin(rads * 1.1))),
      baseRadius: size.shortestSide * 0.32,
      amplitude: size.shortestSide * 0.05,
      frequency: 4,
      colors: const [Color(0xFFFB923C), Color(0xFFFB923C)],
      startOpacity: 0.20,
      endOpacity: 0.04,
      phase: -rads * 0.8,
    );

    // Blob 3 - blend between pink/orange, center
    _drawBlob(
      canvas,
      size,
      center: Offset(size.width * (0.55 + 0.02 * math.sin(rads * 1.3)),
          size.height * (0.5 + 0.015 * math.cos(rads * 0.7))),
      baseRadius: size.shortestSide * 0.24,
      amplitude: size.shortestSide * 0.035,
      frequency: 5,
      colors: const [Color(0xFFF472B6), Color(0xFFFB923C)],
      startOpacity: 0.16,
      endOpacity: 0.03,
      phase: rads * 0.5,
    );
  }

  void _drawBlob(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double baseRadius,
    required double amplitude,
    required int frequency,
    required List<Color> colors,
    required double startOpacity,
    required double endOpacity,
    required double phase,
  }) {
    final Path path = Path();
    const int steps = 120;

    Offset pointFor(double angle) {
      final double r = baseRadius + amplitude * math.sin(frequency * angle + phase);
      return Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
    }

    // Build wavy circle path
    path.moveTo(center.dx + baseRadius, center.dy);
    for (int i = 0; i <= steps; i++) {
      final double a = (i / steps) * 2 * math.pi;
      final p = pointFor(a);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();

    final Rect shaderRect = Rect.fromCircle(center: center, radius: baseRadius + amplitude + 10);
    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          colors.first.withAlpha((startOpacity * 255).round()),
          colors.last.withAlpha((endOpacity * 255).round()),
        ],
        stops: const [0.0, 1.0],
      ).createShader(shaderRect);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) => oldDelegate.t != t;
}
