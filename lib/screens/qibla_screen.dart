import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';
import 'package:provider/provider.dart';
import 'package:compass_2/providers/compass_provider.dart';
import 'package:compass_2/providers/location_provider.dart';
import 'package:compass_2/providers/prayer_times_provider.dart';
import 'package:compass_2/utils/app_theme.dart';
import 'dart:math' as math;

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Animation controllers
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initialize location and prayer times
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      final prayerTimesProvider = Provider.of<PrayerTimesProvider>(context, listen: false);

      locationProvider.getCurrentLocation().then((_) {
        if (locationProvider.currentPosition != null) {
          prayerTimesProvider.calculatePrayerTimes(
            locationProvider.currentPosition!.latitude,
            locationProvider.currentPosition!.longitude,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer2<CompassProvider, LocationProvider>(
      builder: (context, compassProvider, locationProvider, _) {
        // Calculate Qibla direction when location is available
        if (locationProvider.currentPosition != null) {
          compassProvider.calculateQiblaDirection(
            locationProvider.currentPosition!.latitude,
            locationProvider.currentPosition!.longitude,
          );
        }

        // Show loading or error states
        if (locationProvider.isLoading) {
          return _buildLoadingState();
        }

        if (locationProvider.errorMessage.isNotEmpty) {
          return _buildErrorState(locationProvider);
        }

        if (!compassProvider.hasCompass) {
          return _buildNoCompassState();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            // Calculate flexible heights for sections
            final availableHeight = constraints.maxHeight;
            final compassHeight = availableHeight * 0.6;
            final infoHeight = availableHeight * 0.4;

            return Column(
              children: [
                // Main compass section
                SizedBox(
                  height: compassHeight,
                  child: _buildQiblaCompass(
                    compassProvider.heading,
                    compassProvider.qiblaAngle,
                    (compassProvider.qiblaAngle - compassProvider.heading + 360) % 360,
                    locationProvider.currentPosition != null,
                  ),
                ),

                // Prayer times and info section
                Container(
                  height: infoHeight,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Consumer<PrayerTimesProvider>(
                      builder: (context, prayerProvider, _) {
                        final nextPrayer = prayerProvider.getNextPrayer();
                        return Column(
                          children: [
                            // Qibla direction indicator
                            _buildQiblaDirectionIndicator(
                              compassProvider.qiblaAngle,
                              compassProvider.heading,
                            ),
                            
                            if (locationProvider.currentPosition != null)
                              _buildDistancePill(compassProvider, locationProvider),

                            if (nextPrayer != null) 
                              _buildNextPrayerInfo(nextPrayer),

                            _buildPrayerTimesList(prayerProvider),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDistancePill(CompassProvider compass, LocationProvider location) {
    final distance = compass.calculateDistanceToKaaba(
      location.currentPosition!.latitude,
      location.currentPosition!.longitude,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.qiblaColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, color: AppTheme.qiblaColor),
          const SizedBox(width: 8),
          Text(
            '${distance.toStringAsFixed(0)} km to Kaaba',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.qiblaColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimesList(PrayerTimesProvider provider) {
    // Ensure prayer times are calculated
    if (provider.fajrTime == null) {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      if (locationProvider.currentPosition != null) {
        provider.calculatePrayerTimes(
          locationProvider.currentPosition!.latitude,
          locationProvider.currentPosition!.longitude,
        );
      }
    }

    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildPrayerTimeCard('Fajr', provider.formattedFajr, Icons.wb_twilight),
          _buildPrayerTimeCard('Sunrise', provider.formattedSunrise, Icons.wb_sunny),
          _buildPrayerTimeCard('Dhuhr', provider.formattedDhuhr, Icons.wb_sunny),
          _buildPrayerTimeCard('Asr', provider.formattedAsr, Icons.wb_sunny_outlined),
          _buildPrayerTimeCard('Maghrib', provider.formattedMaghrib, Icons.nights_stay_outlined),
          _buildPrayerTimeCard('Isha', provider.formattedIsha, Icons.nights_stay),
        ],
      ),
    );
  }

  Widget _buildPrayerTimeCard(String name, String time, IconData icon) {
    final Map<String, dynamic>? nextPrayer = Provider.of<PrayerTimesProvider>(context).getNextPrayer();
    final bool isNext = nextPrayer != null && nextPrayer['name'] == name;

    return Card(
      elevation: isNext ? 4 : 1,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isNext ? BorderSide(
          color: AppTheme.qiblaColor,
          width: 2,
        ) : BorderSide.none,
      ),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isNext ? AppTheme.qiblaColor : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isNext ? AppTheme.qiblaColor : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                color: isNext ? AppTheme.qiblaColor : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    ).scale(isNext ? 1.05 : 1.0)
     .animate(
       trigger: isNext,
       duration: const Duration(milliseconds: 300),
       curve: Curves.easeInOut,
     );
  }

  Widget _buildNextPrayerInfo(Map<String, dynamic> nextPrayer) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        children: [
          Text(
            'Next Prayer',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${nextPrayer['name']} at ${nextPrayer['time']}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.qiblaColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQiblaCompass(
    double heading,
    double qiblaAngle,
    double relativeAngle,
    bool isFacingQibla,
  ) {
    return FittedBox(
      fit: BoxFit.contain,
      child: Container(
        width: 300,
        height: 300,
        padding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background glow when facing Qibla
            if (isFacingQibla)
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, _) {
                  return Container(
                    width: 300 * _pulseAnimation.value,
                    height: 300 * _pulseAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.qiblaColor.withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),

            // Main compass ring with gradient border
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 2,
                ),
                gradient: RadialGradient(
                  colors: [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),

            // Rotating compass face
            Transform.rotate(
              angle: -heading * (math.pi / 180),
              child: CustomPaint(
                size: const Size(280, 280),
                painter: QiblaCompassPainter(),
              ),
            ),

            // Dynamic Qibla indicator
            Transform.rotate(
              angle: (qiblaAngle - heading) * (math.pi / 180),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Qibla pointer
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, _) {
                      return Transform.scale(
                        scale: isFacingQibla ? _pulseAnimation.value : 1.0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isFacingQibla ? 
                                AppTheme.qiblaColor : 
                                AppTheme.qiblaColor.withOpacity(0.7),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.qiblaColor.withOpacity(0.3),
                                blurRadius: isFacingQibla ? 8 : 4,
                                spreadRadius: isFacingQibla ? 2 : 0,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.mosque_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      );
                    },
                  ),
                  // Gradient line pointing to Qibla
                  Container(
                    width: 2,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.qiblaColor.withOpacity(0.8),
                          AppTheme.qiblaColor.withOpacity(0.0),
                        ],
                        stops: const [0.0, 0.8],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Center point with dynamic color
            Container(
              width: 60,
              height: 60,
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
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: isFacingQibla
                          ? [AppTheme.qiblaColor, AppTheme.qiblaColor.withOpacity(0.7)]
                          : [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.7)],
                      startAngle: 0,
                      endAngle: math.pi * 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.explore,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQiblaDirectionIndicator(double qiblaAngle, double currentHeading) {
    final relativeAngle = (qiblaAngle - currentHeading + 360) % 360;
    final isFacingQibla = relativeAngle < 5 || relativeAngle > 355;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Direction arrow with animation
          TweenAnimationBuilder(
            tween: Tween<double>(
              begin: 0,
              end: relativeAngle * (math.pi / 180),
            ),
            duration: const Duration(milliseconds: 500),
            builder: (context, double angle, child) {
              return Transform.rotate(
                angle: angle,
                child: Icon(
                  Icons.arrow_upward,
                  color: isFacingQibla ? AppTheme.qiblaColor : Colors.grey,
                  size: 36,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // Direction text
          Text(
            isFacingQibla
                ? 'Facing Qibla'
                : _getDirectionText(relativeAngle),
            style: TextStyle(
              color: isFacingQibla ? AppTheme.qiblaColor : Colors.grey[600],
              fontWeight: isFacingQibla ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${relativeAngle.toStringAsFixed(1)}°',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _getDirectionText(double angle) {
    if (angle <= 180) {
      return 'Turn right ${angle.toStringAsFixed(0)}°';
    } else {
      return 'Turn left ${(360 - angle).toStringAsFixed(0)}°';
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(color: AppTheme.qiblaColor),
          SizedBox(height: 24),
          Text(
            'Finding Qibla Direction...',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(LocationProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text(provider.errorMessage),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => provider.requestLocationPermission(),
            icon: const Icon(Icons.location_on),
            label: const Text('Grant Location Permission'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoCompassState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.compass_calibration_outlined, color: Colors.orange, size: 64),
          SizedBox(height: 16),
          Text(
            'Compass sensor not found on this device',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'This device does not have a compass sensor\nor it is not accessible.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class QiblaCompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw base circles
    canvas.drawCircle(
      center,
      radius * 0.95,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.grey.shade300
        ..strokeWidth = 2,
    );

    // Draw degree markers and labels
    for (int i = 0; i < 360; i += 15) {
      final angle = (i - 90) * (math.pi / 180);
      final isCardinal = i % 90 == 0;
      final isInterCardinal = i % 45 == 0 && !isCardinal;
      
      final markerLength = isCardinal ? 20.0 : (isInterCardinal ? 15.0 : 10.0);
      final paint = Paint()
        ..color = isCardinal ? 
            (i == 0 ? Colors.red : Colors.black87) : 
            Colors.grey.shade400
        ..strokeWidth = isCardinal ? 2.0 : 1.0;

      // Draw marker line
      final outerPoint = center + Offset(
        radius * 0.95 * math.cos(angle),
        radius * 0.95 * math.sin(angle),
      );
      final innerPoint = center + Offset(
        radius * (0.95 - markerLength / radius) * math.cos(angle),
        radius * (0.95 - markerLength / radius) * math.sin(angle),
      );
      canvas.drawLine(innerPoint, outerPoint, paint);

      // Draw cardinal and intercardinal labels
      if (isCardinal || isInterCardinal) {
        final String label;
        switch (i) {
          case 0: label = 'N'; break;
          case 45: label = 'NE'; break;
          case 90: label = 'E'; break;
          case 135: label = 'SE'; break;
          case 180: label = 'S'; break;
          case 225: label = 'SW'; break;
          case 270: label = 'W'; break;
          case 315: label = 'NW'; break;
          default: label = '';
        }

        final textPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: i == 0 ? Colors.red : (isCardinal ? Colors.black87 : Colors.grey.shade600),
              fontSize: isCardinal ? 22 : 16,
              fontWeight: isCardinal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
        
        // Set textDirection property separately
        textPainter.textDirection = TextDirection.ltr;
        
        textPainter.layout();

        final labelRadius = radius * (isCardinal ? 0.7 : 0.75);
        textPainter.paint(
          canvas,
          center + Offset(
            labelRadius * math.cos(angle) - textPainter.width / 2,
            labelRadius * math.sin(angle) - textPainter.height / 2,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
