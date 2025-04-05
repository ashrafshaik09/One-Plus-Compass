import 'package:flutter/material.dart';
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

        // Calculate angle to Kaaba
        final double qiblaAngle = compassProvider.qiblaAngle;
        final double currentHeading = compassProvider.heading;
        final double relativeAngle = (qiblaAngle - currentHeading + 360) % 360;
        final bool isFacingQibla = relativeAngle < 5 || relativeAngle > 355;
        
        // Calculate distance to Kaaba
        double distanceToKaaba = 0;
        if (locationProvider.currentPosition != null) {
          distanceToKaaba = compassProvider.calculateDistanceToKaaba(
            locationProvider.currentPosition!.latitude,
            locationProvider.currentPosition!.longitude,
          );
        }
        
        // Update rotation animation for smoother motion
        _rotationController.animateTo(
          currentHeading / 360,
          curve: Curves.easeOut,
        );

        return Consumer<PrayerTimesProvider>(
          builder: (context, prayerTimesProvider, _) {
            // Get next prayer
            final nextPrayer = prayerTimesProvider.getNextPrayer();
            
            return Column(
              children: [
                // Information cards
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Qibla information card
                      _buildQiblaInfoCard(qiblaAngle, distanceToKaaba),
                      const SizedBox(height: 16),
                      // Next prayer information
                      if (nextPrayer != null)
                        _buildNextPrayerCard(nextPrayer),
                    ],
                  ),
                ),
                
                // Main compass widget
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: _buildQiblaCompass(
                        currentHeading,
                        qiblaAngle,
                        relativeAngle,
                        isFacingQibla,
                      ),
                    ),
                  ),
                ),
                
                // Direction guidance
                if (!isFacingQibla)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildDirectionGuidance(relativeAngle),
                  ),
                
                // All prayer times card
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _buildPrayerTimesCard(prayerTimesProvider),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  Widget _buildQiblaInfoCard(double qiblaAngle, double distance) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.qiblaColor,
              AppTheme.qiblaColor.withOpacity(0.8),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Kaaba icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mosque_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Kaaba text info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Qibla Direction',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.explore,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${qiblaAngle.toStringAsFixed(1)}°',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.map,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${distance.toStringAsFixed(0)} km',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNextPrayerCard(Map<String, dynamic> nextPrayer) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Timer icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.qiblaColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.access_time_filled,
                color: AppTheme.qiblaColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Next prayer info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Next Prayer: ${nextPrayer['name']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        nextPrayer['time'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.qiblaColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nextPrayer['remaining'],
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQiblaCompass(
    double heading,
    double qiblaAngle,
    double relativeAngle,
    bool isFacingQibla,
  ) {
    return Stack(
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
                      AppTheme.qiblaColor.withOpacity(0.3),
                      AppTheme.qiblaColor.withOpacity(0.0),
                    ],
                  ),
                ),
              );
            },
          ),
        
        // Outer ring with shadows for depth
        Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey.shade200,
                Colors.white,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
        ),
        
        // Inner compass bezel
        Container(
          width: 260,
          height: 260,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey.shade50,
                    Colors.white,
                  ],
                ),
              ),
              // Rotating compass part
              child: AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: -heading * (math.pi / 180),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // New improved compass dial design
                        CustomPaint(
                          size: const Size(240, 240),
                          painter: EnhancedQiblaCompassPainter(),
                        ),
                        
                        // Qibla indicator (fixed relative to compass)
                        Transform.rotate(
                          angle: qiblaAngle * (math.pi / 180),
                          child: _buildQiblaIndicator(isFacingQibla),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        
        // Center point (user's position) with 3D effect
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isFacingQibla 
                      ? [AppTheme.qiblaColor.withOpacity(0.8), AppTheme.qiblaColor]
                      : [AppTheme.primaryColor.withOpacity(0.8), AppTheme.primaryColor],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isFacingQibla ? AppTheme.qiblaColor : AppTheme.primaryColor)
                        .withOpacity(0.3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQiblaIndicator(bool isFacingQibla) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Kaaba icon with animation
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, _) {
            return Transform.scale(
              scale: isFacingQibla ? _pulseAnimation.value : 1.0,
              child: Container(
                width: isFacingQibla ? 50 : 40,
                height: isFacingQibla ? 50 : 40,
                decoration: BoxDecoration(
                  color: isFacingQibla
                      ? AppTheme.qiblaColor
                      : AppTheme.qiblaColor.withOpacity(0.7),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.qiblaColor.withOpacity(isFacingQibla ? 0.6 : 0.3),
                      blurRadius: isFacingQibla ? 12 : 5,
                      spreadRadius: isFacingQibla ? 3 : 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.mosque_rounded,
                    color: Colors.white,
                    size: isFacingQibla ? 32 : 24,
                  ),
                ),
              ),
            );
          },
        ),
        
        // Line from center to Kaaba
        Container(
          width: 3,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.qiblaColor,
                AppTheme.qiblaColor.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDirectionGuidance(double angle) {
    final String direction = angle > 180 ? "Turn left" : "Turn right";
    final double adjustedAngle = angle > 180 ? 360 - angle : angle;
    final double progress = (180 - adjustedAngle) / 180;
    
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  angle > 180 ? Icons.turn_left : Icons.turn_right,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        direction,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        "Rotate ${adjustedAngle.toStringAsFixed(1)}° to face Qibla",
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                CircularProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPrayerTimesCard(PrayerTimesProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Prayer Times',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPrayerTime('Fajr', provider.formattedFajr),
                _buildPrayerTime('Dhuhr', provider.formattedDhuhr),
                _buildPrayerTime('Asr', provider.formattedAsr),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPrayerTime('Maghrib', provider.formattedMaghrib),
                _buildPrayerTime('Isha', provider.formattedIsha),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                _showCalculationMethodDialog(context, provider);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.settings,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Calculation method: ${provider.currentCalculationMethod}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPrayerTime(String name, String time) {
    final Map<String, dynamic>? nextPrayer = Provider.of<PrayerTimesProvider>(context).getNextPrayer();
    final bool isNext = nextPrayer != null && nextPrayer['name'] == name;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isNext ? AppTheme.qiblaColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isNext ? Colors.white : Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
            color: isNext ? AppTheme.qiblaColor : Colors.black87,
          ),
        ),
      ],
    );
  }
  
  void _showCalculationMethodDialog(BuildContext context, PrayerTimesProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Prayer Calculation Method'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: PrayerTimesProvider.calculationMethodNames.length,
              itemBuilder: (context, index) {
                return RadioListTile<int>(
                  title: Text(PrayerTimesProvider.calculationMethodNames[index]),
                  value: index,
                  groupValue: PrayerTimesProvider.calculationMethodNames.indexOf(provider.currentCalculationMethod),
                  onChanged: (value) {
                    provider.setCalculationMethod(value!);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
  
  // Loading, error and no compass states
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

// Replace PremiumCompassPainter with this new enhanced painter
class EnhancedQiblaCompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw outer ring
    final outerRingPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    canvas.drawCircle(center, radius * 0.95, outerRingPaint);
    
    // Draw intermediate ring
    final intermediateRingPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawCircle(center, radius * 0.85, intermediateRingPaint);
    
    // Draw inner ring
    final innerRingPaint = Paint()
      ..color = Colors.grey.shade100
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawCircle(center, radius * 0.7, innerRingPaint);
    
    // Draw degree tick marks
    for (int i = 0; i < 360; i += 5) {
      final isMultipleOf30 = i % 30 == 0;
      final isMultipleOf10 = i % 10 == 0;
      
      final tickLength = isMultipleOf30 ? 15.0 : (isMultipleOf10 ? 10.0 : 5.0);
      final tickWidth = isMultipleOf30 ? 2.0 : (isMultipleOf10 ? 1.5 : 0.8);
      
      final paint = Paint()
        ..color = isMultipleOf30 ? Colors.black87 : Colors.grey.shade400
        ..strokeWidth = tickWidth;
        
      final angle = (i - 90) * (math.pi / 180); // Adjust by 90 degrees so North is at top
      
      final outerX = center.dx + radius * 0.95 * math.cos(angle);
      final outerY = center.dy + radius * 0.95 * math.sin(angle);
      final innerX = center.dx + (radius * 0.95 - tickLength) * math.cos(angle);
      final innerY = center.dy + (radius * 0.95 - tickLength) * math.sin(angle);
      
      canvas.drawLine(
        Offset(innerX, innerY),
        Offset(outerX, outerY),
        paint,
      );
      
      // Draw degree numbers for multiples of 30
      if (isMultipleOf30) {
        final textSpan = TextSpan(
          text: '$i°',
          style: TextStyle(
            color: i == 0 ? Colors.red : Colors.black87,
            fontSize: 12,
            fontWeight: i == 0 ? FontWeight.bold : FontWeight.normal,
          ),
        );
        
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout();
        
        final textX = center.dx + radius * 0.75 * math.cos(angle);
        final textY = center.dy + radius * 0.75 * math.sin(angle);
        
        textPainter.paint(
          canvas, 
          Offset(textX - textPainter.width / 2, textY - textPainter.height / 2)
        );
      }
    }
    
    // Draw cardinal directions with enhanced style
    final cardinalDirections = ['N', 'E', 'S', 'W'];
    final interCardinalDirections = ['NE', 'SE', 'SW', 'NW'];
    
    for (int i = 0; i < 4; i++) {
      final cardinalAngle = (i * 90 - 90) * (math.pi / 180);
      final interCardinalAngle = ((i * 90 + 45) - 90) * (math.pi / 180);
      
      // Cardinal direction (N, E, S, W)
      final cardinalX = center.dx + radius * 0.6 * math.cos(cardinalAngle);
      final cardinalY = center.dy + radius * 0.6 * math.sin(cardinalAngle);
      
      final cardinalTextSpan = TextSpan(
        text: cardinalDirections[i],
        style: TextStyle(
          color: i == 0 ? Colors.red : Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      );
      
      final cardinalTextPainter = TextPainter(
        text: cardinalTextSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      
      cardinalTextPainter.paint(
        canvas, 
        Offset(cardinalX - cardinalTextPainter.width / 2, cardinalY - cardinalTextPainter.height / 2)
      );
      
      // Inter-cardinal direction (NE, SE, SW, NW)
      final interCardinalX = center.dx + radius * 0.55 * math.cos(interCardinalAngle);
      final interCardinalY = center.dy + radius * 0.55 * math.sin(interCardinalAngle);
      
      final interCardinalTextSpan = TextSpan(
        text: interCardinalDirections[i],
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
      );
      
      final interCardinalTextPainter = TextPainter(
        text: interCardinalTextSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      
      interCardinalTextPainter.paint(
        canvas, 
        Offset(interCardinalX - interCardinalTextPainter.width / 2, interCardinalY - interCardinalTextPainter.height / 2)
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
