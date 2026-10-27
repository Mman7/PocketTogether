import 'dart:math' as math;

import 'package:flutter/material.dart';

class AmbientBackground extends StatefulWidget {
  const AmbientBackground({required this.child, super.key});

  final Widget child;

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion && _controller.isAnimating) {
      _controller.stop();
    } else if (!reduceMotion && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => CustomPaint(
                painter: _AmbientBackgroundPainter(_controller.value),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _AmbientBackgroundPainter extends CustomPainter {
  const _AmbientBackgroundPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFFFAF8FF), BlendMode.src);
    final travel = math.sin(progress * math.pi) * 24;
    final bottom = size.height;

    _paintGlow(
      canvas,
      center: Offset(size.width * 0.18 + travel, bottom * 0.88),
      radius: size.width * 0.62,
      colors: const [Color(0x322373F4), Color(0x1265D0F4), Color(0x00000000)],
    );
    _paintGlow(
      canvas,
      center: Offset(size.width * 0.86 - travel * 0.65, bottom * 0.76),
      radius: size.width * 0.54,
      colors: const [Color(0x2A65D0F4), Color(0x16B9A7F2), Color(0x00000000)],
    );
    _paintGlow(
      canvas,
      center: Offset(size.width * 0.64, bottom * 0.98),
      radius: size.width * 0.4,
      colors: const [Color(0x1CB9A7F2), Color(0x00000000)],
    );

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = const LinearGradient(
        colors: [
          Color(0x001E63D8),
          Color(0x4A2373F4),
          Color(0x3A65D0F4),
          Color(0x001E63D8),
        ],
        stops: [0, 0.3, 0.72, 1],
      ).createShader(Rect.fromLTWH(0, bottom * 0.55, size.width, bottom * 0.4));
    for (var index = 0; index < 3; index++) {
      final path = Path()
        ..moveTo(-size.width * 0.08, bottom * (0.72 + index * 0.1));
      path.cubicTo(
        size.width * 0.26,
        bottom * (0.57 + index * 0.1),
        size.width * 0.62,
        bottom * (0.93 + index * 0.06),
        size.width * 1.08,
        bottom * (0.73 + index * 0.1),
      );
      canvas.drawPath(path, linePaint);
    }
  }

  void _paintGlow(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required List<Color> colors,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(colors: colors)
          .createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_AmbientBackgroundPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
