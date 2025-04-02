import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:compass_2/providers/compass_provider.dart';
import 'package:compass_2/providers/location_provider.dart';
import 'package:compass_2/utils/app_theme.dart';
import 'dart:math' as math;

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  @override
  void initState() {
    super.initState();
    // Request location when this screen is shown
    Future.microtask(() {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      locationProvider.getCurrentLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CompassProvider, LocationProvider>(
      builder: (context, compassProvider, locationProvider, _) {
        if (locationProvider.currentPosition != null) {
          compassProvider.calculateQiblaDirection(
            locationProvider.currentPosition!.latitude,
            locationProvider.currentPosition!.longitude,
          );
        }

        if (locationProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (locationProvider.errorMessage.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 50),
                const SizedBox(height: 16),
                Text(locationProvider.errorMessage),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => locationProvider.requestLocationPermission(),
                  child: const Text('Grant Location Permission'),
                ),
              ],
            ),
          );
        }

        if (!compassProvider.hasCompass) {
          return const Center(
            child: Text(
              "Compass sensor not found on this device",
              style: TextStyle(fontSize: 16, color: Colors.red),
            ),
          );
        }

        // Calculate relative angle between heading and qibla
        double relativeAngle = compassProvider.qiblaAngle - compassProvider.heading;
        relativeAngle = (relativeAngle + 360) % 360;

        // Determine if user is facing Qibla direction (within 5 degrees)
        bool isFacingQibla = relativeAngle < 5 || relativeAngle > 355;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Direction card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'Qibla Direction',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    Text(
                      'Direction to Holy Kaaba',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Qibla compass
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFacingQibla 
                          ? AppTheme.qiblaColor.withOpacity(0.1) 
                          : AppTheme.cardBackground,
                      ),
                    ),
                    // Qibla arrow
                    Transform.rotate(
                      angle: relativeAngle * (math.pi / 180),
                      child: CustomPaint(
                        size: const Size(200, 200),
                        painter: QiblaArrowPainter(
                          isFacingQibla: isFacingQibla,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Info text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isFacingQibla 
                    ? AppTheme.qiblaColor.withOpacity(0.1)
                    : AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: isFacingQibla
                    ? Border.all(color: AppTheme.qiblaColor)
                    : null,
                ),
                child: Column(
                  children: [
                    Text(
                      isFacingQibla
                        ? '✓ You are facing the Qibla direction'
                        : 'Rotate your device to find Qibla direction',
                      style: TextStyle(
                        color: isFacingQibla 
                          ? AppTheme.qiblaColor
                          : AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Qibla is ${compassProvider.qiblaAngle.toStringAsFixed(1)}°',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class QiblaArrowPainter extends CustomPainter {
  final bool isFacingQibla;

  QiblaArrowPainter({required this.isFacingQibla});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final arrowColor = isFacingQibla 
        ? AppTheme.qiblaColor 
        : AppTheme.primaryColor;
    
    final paint = Paint()
      ..color = arrowColor
      ..style = PaintingStyle.fill;
    
    final path = Path()
      ..moveTo(center.dx, 0)  // Top point
      ..lineTo(center.dx + 25, center.dy - 15)  // Right shoulder
      ..lineTo(center.dx + 10, center.dy - 15)  // Right inner
      ..lineTo(center.dx + 10, size.height)  // Bottom right
      ..lineTo(center.dx - 10, size.height)  // Bottom left
      ..lineTo(center.dx - 10, center.dy - 15)  // Left inner
      ..lineTo(center.dx - 25, center.dy - 15)  // Left shoulder
      ..close();
    
    canvas.drawPath(path, paint);
    
    // Draw a mosque icon
    if (isFacingQibla) {
      final iconPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      
      // Simple mosque dome
      final iconPath = Path()
        ..addOval(Rect.fromCenter(
          center: Offset(center.dx, center.dy + 30),
          width: 30,
          height: 30,
        ));
      
      canvas.drawPath(iconPath, iconPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => 
      oldDelegate is QiblaArrowPainter && oldDelegate.isFacingQibla != isFacingQibla;
}
