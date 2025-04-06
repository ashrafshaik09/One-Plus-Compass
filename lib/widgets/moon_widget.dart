import 'package:flutter/material.dart';

class MoonWidget extends StatelessWidget {
  final double phase; // 0.0 to 1.0
  final double size;
  final Color moonColor;
  final Color earthshineColor;

  const MoonWidget({
    super.key,
    required this.phase,
    this.size = 120,
    this.moonColor = const Color(0xFFFFF4D6),
    this.earthshineColor = const Color(0xFF1E1E1E),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: earthshineColor,
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: _MoonPhasePainter(
          phase: phase,
          moonColor: moonColor,
          earthshineColor: earthshineColor,
        ),
      ),
    );
  }
}

class _MoonPhasePainter extends CustomPainter {
  final double phase;
  final Color moonColor;
  final Color earthshineColor;

  _MoonPhasePainter({
    required this.phase,
    required this.moonColor,
    required this.earthshineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = moonColor
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw base moon circle
    canvas.drawCircle(center, radius, paint);

    // Calculate shadow parameters based on phase
    final shadowPaint = Paint()
      ..color = earthshineColor
      ..style = PaintingStyle.fill;

    if (phase <= 0.5) {
      // Waxing moon (right side illuminated)
      final rect = Rect.fromLTRB(
        center.dx,
        0,
        size.width,
        size.height,
      );
      canvas.drawRect(rect, shadowPaint);

      // Draw curve based on phase
      final curve = Path()
        ..moveTo(center.dx, 0)
        ..arcToPoint(
          Offset(center.dx, size.height),
          radius: Radius.circular(radius),
          clockwise: false,
          largeArc: false,
        )
        ..close();

      canvas.drawPath(curve, paint);
    } else {
      // Waning moon (left side illuminated)
      final rect = Rect.fromLTRB(
        0,
        0,
        center.dx,
        size.height,
      );
      canvas.drawRect(rect, shadowPaint);

      // Draw curve based on phase
      final curve = Path()
        ..moveTo(center.dx, 0)
        ..arcToPoint(
          Offset(center.dx, size.height),
          radius: Radius.circular(radius),
          clockwise: true,
          largeArc: false,
        )
        ..close();

      canvas.drawPath(curve, shadowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
