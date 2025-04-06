import 'package:flutter/material.dart';
import 'package:compass_2/utils/app_theme.dart';
import 'dart:math' as math;

class QiblaCompass extends StatelessWidget {
  final double heading;
  final double qiblaAngle;
  final bool isFacingQibla;
  final Animation<double> pulseAnimation;

  const QiblaCompass({
    super.key,
    required this.heading,
    required this.qiblaAngle,
    required this.isFacingQibla,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated background for Qibla found state
          if (isFacingQibla)
            AnimatedBuilder(
              animation: pulseAnimation,
              builder: (context, child) => Transform.scale(
                scale: pulseAnimation.value,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.qiblaColor.withOpacity(0.2),
                        AppTheme.qiblaColor.withOpacity(0.05),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Rotating compass base
          Transform.rotate(
            angle: -heading * (math.pi / 180),
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Degree markings
                  CustomPaint(
                    painter: CompassMarkingsPainter(),
                  ),
                  
                  // Cardinal points
                  ...['N', 'E', 'S', 'W'].asMap().entries.map((entry) {
                    final int idx = entry.key;
                    final String dir = entry.value;
                    return Positioned(
                      top: idx == 0 ? 15 : null,
                      right: idx == 1 ? 15 : null,
                      bottom: idx == 2 ? 15 : null,
                      left: idx == 3 ? 15 : null,
                      child: Text(
                        dir,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: dir == 'N' 
                              ? Colors.red 
                              : Colors.grey[700],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Fixed center with Kaaba icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              Icons.mosque,
              size: 24,
              color: isFacingQibla 
                  ? AppTheme.qiblaColor 
                  : AppTheme.primaryColor,
            ),
          ),

          // Qibla direction arrow
          Transform.rotate(
            angle: qiblaAngle * (math.pi / 180),
            child: Container(
              width: 260,
              height: 260,
              alignment: Alignment.topCenter,
              child: CustomPaint(
                size: const Size(30, 140),
                painter: QiblaArrowPainter(
                  isFacingQibla: isFacingQibla,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CompassMarkingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.grey.withOpacity(0.3);

    // Draw degree markings
    for (int i = 0; i < 360; i += 15) {
      final angle = i * (math.pi / 180);
      final markerLength = i % 90 == 0 ? 20.0 : (i % 45 == 0 ? 15.0 : 10.0);
      
      final start = Offset(
        center.dx + (radius - markerLength) * math.cos(angle),
        center.dy + (radius - markerLength) * math.sin(angle),
      );
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class QiblaArrowPainter extends CustomPainter {
  final bool isFacingQibla;

  QiblaArrowPainter({required this.isFacingQibla});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          isFacingQibla ? AppTheme.qiblaColor : AppTheme.primaryColor,
          isFacingQibla ? AppTheme.qiblaColor.withOpacity(0.7) : AppTheme.primaryColor.withOpacity(0.7),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height / 3)
      ..lineTo(size.width * 0.6, size.height / 3)
      ..lineTo(size.width * 0.6, size.height)
      ..lineTo(size.width * 0.4, size.height)
      ..lineTo(size.width * 0.4, size.height / 3)
      ..lineTo(0, size.height / 3)
      ..close();

    // Add shadow
    canvas.drawShadow(path, Colors.black, 3, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant QiblaArrowPainter oldDelegate) => 
      oldDelegate.isFacingQibla != isFacingQibla;
}
