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
    // Normalize the angles to ensure positive values
    final normalizedHeading = (heading % 360 + 360) % 360;
    final normalizedQiblaAngle = (qiblaAngle % 360 + 360) % 360;

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
        
        // Static red triangle direction indicator at top
        Positioned(
          top: 0,
          child: CustomPaint(
            size: const Size(24, 24),
            painter: DirectionTrianglePainter(),
          ),
        ),
        
        // Rotatable compass card with improved visibility
        Transform.rotate(
          angle: -normalizedHeading * (math.pi / 180),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
              ),
              CustomPaint(
                size: const Size(280, 280),
                painter: CompassPainter(),
              ),
            ],
          ),
        ),
        
        // Qibla direction indicator - only show if we have a valid angle
        if (qiblaAngle > 0)
          Transform.rotate(
            angle: (normalizedQiblaAngle - normalizedHeading) * (math.pi / 180),
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
        
        // Center point
        Container(
          width: 80,
          height: 80,
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
              angle: -normalizedHeading * (math.pi / 180),
              child: CustomPaint(
                size: const Size(60, 60),
                painter: HeadingIndicatorPainter(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Add new DirectionTrianglePainter
class DirectionTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 // Slightly thicker for better visibility
      ..color = AppTheme.textLight;
    
    // Draw circles
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius * 0.8, paint);
    
    // Draw degree markers
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    // Draw cardinal points with full text labels for clarity
    final Map<String, double> cardinalPoints = {
      'N': 0,
      'E': 90,
      'S': 180,
      'W': 270, // Make sure West is visible
    };
    
    // Add intercardinal points with full text
    final Map<String, double> intercardinalPoints = {
      'NE': 45,
      'SE': 135,
      'SW': 225,
      'NW': 315,
    };
    
    final cardinalStyle = const TextStyle(
      color: AppTheme.textPrimary,
      fontSize: 22, // Larger for better visibility
      fontWeight: FontWeight.bold,
    );
    
    final intercardinalStyle = const TextStyle(
      color: AppTheme.textSecondary,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    );
    
    // Updated cardinal points rendering
    cardinalPoints.forEach((direction, degrees) {
      final angle = degrees * (math.pi / 180);
      final x = center.dx + radius * 0.7 * math.sin(angle);
      final y = center.dy - radius * 0.7 * math.cos(angle);
      
      textPainter.text = TextSpan(
        text: direction,
        style: TextStyle(
          color: direction == 'N' ? Colors.red : AppTheme.textPrimary,
          fontSize: 24, // Increased size for better visibility
          fontWeight: FontWeight.bold,
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
    });
    
    // Draw intercardinal points
    intercardinalPoints.forEach((direction, degrees) {
      final angle = degrees * (math.pi / 180);
      final x = center.dx + radius * 0.7 * math.sin(angle);
      final y = center.dy - radius * 0.7 * math.cos(angle);
      
      textPainter.text = TextSpan(
        text: direction,
        style: intercardinalStyle,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          x - textPainter.width / 2,
          y - textPainter.height / 2,
        ),
      );
    });
    
    // Draw degree markers
    for (int i = 0; i < 360; i += 15) {
      // Skip points where we already have labels
      if (i % 45 == 0) continue;
      
      final angle = i * (math.pi / 180);
      
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
