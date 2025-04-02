import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:compass_2/utils/app_theme.dart';

class CompassWidget extends StatelessWidget {
  final double heading;
  final double qiblaAngle;

  const CompassWidget({
    super.key,
    required this.heading,
    required this.qiblaAngle,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer circle
        Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.cardBackground,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        
        // Rotatable compass card
        Transform.rotate(
          angle: -heading * (math.pi / 180),
          child: CustomPaint(
            size: const Size(280, 280),
            painter: CompassPainter(),
          ),
        ),
        
        // Qibla direction indicator
        Transform.rotate(
          angle: (qiblaAngle - heading) * (math.pi / 180),
          child: Container(
            width: 250,
            height: 250,
            alignment: Alignment.topCenter,
            child: Container(
              width: 3,
              height: 125,
              color: AppTheme.qiblaColor,
            ),
          ),
        ),
        
        // Center point with heading indicator
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Transform.rotate(
              angle: -heading * (math.pi / 180),
              child: CustomPaint(
                size: const Size(80, 80),
                painter: HeadingIndicatorPainter(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppTheme.textLight;
    
    // Draw circles
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius * 0.8, paint);
    
    // Draw degree markers
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    // Draw cardinal points
    const List<String> cardinalPoints = ['N', 'E', 'S', 'W'];
    final textStyle = const TextStyle(
      color: AppTheme.textPrimary,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    );
    
    for (int i = 0; i < 4; i++) {
      final angle = i * 90 * (math.pi / 180);
      final x = center.dx + radius * 0.7 * math.sin(angle);
      final y = center.dy - radius * 0.7 * math.cos(angle);
      
      textPainter.text = TextSpan(
        text: cardinalPoints[i],
        style: textStyle,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          x - textPainter.width / 2,
          y - textPainter.height / 2,
        ),
      );
    }
    
    // Draw degree markers
    for (int i = 0; i < 360; i += 15) {
      final angle = i * (math.pi / 180);
      
      if (i % 90 != 0) {
        // Draw text for 30 degree increments
        if (i % 30 == 0) {
          final x = center.dx + radius * 0.7 * math.sin(angle);
          final y = center.dy - radius * 0.7 * math.cos(angle);
          
          textPainter.text = TextSpan(
            text: i.toString(),
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          );
          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(
              x - textPainter.width / 2,
              y - textPainter.height / 2,
            ),
          );
        }
        
        // Draw line markers
        final markerLength = i % 30 == 0 ? 15.0 : 8.0;
        
        final x1 = center.dx + radius * 0.9 * math.sin(angle);
        final y1 = center.dy - radius * 0.9 * math.cos(angle);
        final x2 = center.dx + (radius - markerLength) * 0.9 * math.sin(angle);
        final y2 = center.dy - (radius - markerLength) * 0.9 * math.cos(angle);
        
        canvas.drawLine(
          Offset(x1, y1),
          Offset(x2, y2),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HeadingIndicatorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    final northPaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.fill;
    
    final southPaint = Paint()
      ..color = AppTheme.textLight
      ..style = PaintingStyle.fill;
    
    final northPath = Path()
      ..moveTo(center.dx, center.dy - size.height / 2)
      ..lineTo(center.dx + 8, center.dy)
      ..lineTo(center.dx - 8, center.dy)
      ..close();
    
    final southPath = Path()
      ..moveTo(center.dx, center.dy + size.height / 2)
      ..lineTo(center.dx + 8, center.dy)
      ..lineTo(center.dx - 8, center.dy)
      ..close();
    
    canvas.drawPath(northPath, northPaint);
    canvas.drawPath(southPath, southPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
