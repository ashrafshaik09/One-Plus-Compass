import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:compass_2/providers/celestial_provider.dart';
import 'package:compass_2/providers/location_provider.dart';
import 'package:compass_2/providers/compass_provider.dart';
import 'package:compass_2/utils/app_theme.dart';
import 'dart:math' as math;

class CelestialScreen extends StatefulWidget {
  const CelestialScreen({super.key});

  @override
  State<CelestialScreen> createState() => _CelestialScreenState();
}

class _CelestialScreenState extends State<CelestialScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _showElevation = false;
  final double _celBodySize = 50.0;

  @override
  void initState() {
    super.initState();
    
    // Initialize location and celestial data
    Future.microtask(() {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      final celestialProvider = Provider.of<CelestialProvider>(context, listen: false);
      
      locationProvider.getCurrentLocation().then((_) {
        if (locationProvider.currentPosition != null) {
          celestialProvider.calculateSunPosition(
            locationProvider.currentPosition!.latitude,
            locationProvider.currentPosition!.longitude,
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Consumer3<LocationProvider, CelestialProvider, CompassProvider>(
      builder: (context, locationProvider, celestialProvider, compassProvider, _) {
        // Loading state
        if (locationProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // Error state
        if (locationProvider.errorMessage.isNotEmpty) {
          return _buildErrorState(locationProvider);
        }
        
        // No location data yet
        if (locationProvider.currentPosition == null) {
          return const Center(child: Text('Waiting for location data...'));
        }
        
        // Calculate celestial positions if not already done
        if (celestialProvider.sunrise == null) {
          celestialProvider.calculateSunPosition(
            locationProvider.currentPosition!.latitude,
            locationProvider.currentPosition!.longitude,
          );
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Segmented control to switch between celestial and elevation view
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSegmentButton(
                        'Celestial', 
                        !_showElevation,
                        () => setState(() => _showElevation = false),
                      ),
                      _buildSegmentButton(
                        'Elevation', 
                        _showElevation,
                        () => setState(() => _showElevation = true),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Display either celestial or elevation content
              _showElevation 
                  ? _buildElevationContent(locationProvider)
                  : _buildCelestialContent(locationProvider, celestialProvider, compassProvider),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildSegmentButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
  
  Widget _buildCelestialContent(
      LocationProvider locationProvider,
      CelestialProvider celestialProvider,
      CompassProvider compassProvider) {
    final sunAzimuth = celestialProvider.sunAzimuth;
    final moonAzimuth = celestialProvider.moonAzimuth;
    final heading = compassProvider.heading ?? 0.0;
    
    // Calculate relative angles
    final sunRelativeAngle = (sunAzimuth - heading + 360) % 360;
    final moonRelativeAngle = (moonAzimuth - heading + 360) % 360;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Celestial compass
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(16),
            height: 320,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Compass ring
                Container(
                  width: 270,
                  height: 270,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade50,
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                ),
                
                // Degree markers and cardinal directions
                CustomPaint(
                  size: const Size(270, 270),
                  painter: CelestialCompassPainter(),
                ),
                
                // Sun indicator
                Transform.rotate(
                  angle: sunRelativeAngle * (math.pi / 180),
                  child: Transform.translate(
                    offset: Offset(0, -115),
                    child: Container(
                      width: _celBodySize,
                      height: _celBodySize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.yellow.shade300,
                            Colors.orange.shade400,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.5),
                            blurRadius: 12,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.wb_sunny,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                
                // Moon indicator
                Transform.rotate(
                  angle: moonRelativeAngle * (math.pi / 180),
                  child: Transform.translate(
                    offset: Offset(0, -115),
                    child: Container(
                      width: _celBodySize - 10,
                      height: _celBodySize - 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey.shade100,
                            Colors.grey.shade300,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade100.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.nightlight_round,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                
                // Center user position
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppTheme.primaryColor,
                  ),
                ),
                
                // North indicator
                Positioned(
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'N',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Sun and Moon info cards
        Row(
          children: [
            Expanded(
              child: _buildCelestialInfoCard(
                'Sun',
                Icons.wb_sunny,
                Colors.amber,
                celestialProvider.sunDirectionText,
                celestialProvider.formattedSunrise,
                celestialProvider.formattedSunset,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCelestialInfoCard(
                'Moon',
                Icons.nightlight_round,
                Colors.blueGrey,
                celestialProvider.moonDirectionText,
                null,
                null,
                isFullWidth: false,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Day length card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daylight',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.timelapse, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      'Duration: ${celestialProvider.daylightDuration}',
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Daylight progress bar
                _buildDaylightProgress(celestialProvider),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDaylightProgress(CelestialProvider celestialProvider) {
    final sunrise = celestialProvider.sunrise;
    final sunset = celestialProvider.sunset;
    final now = DateTime.now();
    
    if (sunrise == null || sunset == null) {
      return const SizedBox.shrink();
    }
    
    // Calculate percentage of day completed
    double progress = 0.0;
    String status = 'Night';
    
    final day = DateTime(now.year, now.month, now.day);
    final sunriseTime = sunrise.hour * 60 + sunrise.minute;
    final sunsetTime = sunset.hour * 60 + sunset.minute;
    final currentTime = now.hour * 60 + now.minute;
    final totalDaylight = sunsetTime - sunriseTime;
    
    if (currentTime < sunriseTime) {
      // Before sunrise
      status = 'Pre-dawn';
      progress = 0.0;
    } else if (currentTime > sunsetTime) {
      // After sunset
      status = 'Night';
      progress = 1.0;
    } else {
      // During daylight
      status = 'Daylight';
      progress = (currentTime - sunriseTime) / totalDaylight;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress indicator
        Stack(
          children: [
            // Background bar
            Container(
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade200,
              ),
            ),
            // Progress indicator
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.shade400,
                      Colors.amber.shade300,
                    ],
                  ),
                ),
              ),
            ),
            // Sun/moon icons at appropriate positions
            Positioned(
              left: 12,
              top: 4,
              child: Icon(Icons.wb_twilight, color: Colors.orange.shade800, size: 16),
            ),
            Positioned(
              right: 12,
              top: 4,
              child: Icon(Icons.nightlight, color: Colors.indigo.shade400, size: 16),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Status text
        Text(
          'Current: $status (${(progress * 100).toStringAsFixed(0)}% of daylight)',
          style: const TextStyle(
            fontStyle: FontStyle.italic,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  Widget _buildCelestialInfoCard(
    String title,
    IconData icon,
    Color color,
    String direction,
    String? riseTime,
    String? setTime,
    {bool isFullWidth = true}
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.explore, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Direction: $direction',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            if (isFullWidth) ...[
              const SizedBox(height: 8),
              if (riseTime != null) ...[
                Row(
                  children: [
                    const Icon(Icons.wb_twilight, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Rise: $riseTime',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              if (setTime != null) ...[
                Row(
                  children: [
                    const Icon(Icons.nightlight, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Set: $setTime',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildElevationContent(LocationProvider locationProvider) {
    final elevation = locationProvider.currentElevation;
    final formattedElevation = locationProvider.elevationText;
    
    return Column(
      children: [
        // Enhanced elevation meter with improved visualization
        Container(
          height: 250,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: AppTheme.elevationBackgroundColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Elevation scale markers
              Positioned(
                right: 8,
                top: 20,
                bottom: 20,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (index) {
                    final value = (1000 - index * 500).toString();
                    return Text(
                      '$value m',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    );
                  }),
                ),
              ),

              // Sea level indicator
              Positioned(
                left: 24,
                right: 40, // Adjusted for scale markers
                top: 125, // Centered
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade700,
                        Colors.blue.shade700.withOpacity(0.3),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Sea Level',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Enhanced elevation indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                left: 0,
                right: 0,
                top: elevation >= 0 
                    ? _calculateTopPosition(elevation)
                    : _calculateBottomPosition(elevation),
                child: Center(
                  child: Container(
                    width: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          elevation < 0 ? Icons.arrow_downward : Icons.arrow_upward,
                          size: 32,
                          color: elevation < 0 ? Colors.red : AppTheme.primaryColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formattedElevation,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: elevation < 0 ? Colors.red : AppTheme.primaryColor,
                          ),
                        ),
                        Text(
                          _getElevationDescription(elevation),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Location info card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (locationProvider.currentPosition?.placeName != null) ...[
                  ListTile(
                    leading: const Icon(Icons.location_on, color: AppTheme.primaryColor),
                    title: const Text('Current Location'),
                    subtitle: Text(
                      locationProvider.currentPosition?.placeName ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Divider(),
                ],
                
                ListTile(
                  leading: const Icon(Icons.location_on, color: AppTheme.accentColor),
                  title: const Text('Coordinates'),
                  subtitle: Text(
                    '${locationProvider.currentPosition!.latitude.toStringAsFixed(6)}, ${locationProvider.currentPosition!.longitude.toStringAsFixed(6)}',
                  ),
                ),
                
                const Divider(),
                
                ListTile(
                  leading: const Icon(Icons.speed, color: AppTheme.accentColor),
                  title: const Text('Elevation Accuracy'),
                  subtitle: Text(
                    '±${locationProvider.currentPosition!.accuracy.toStringAsFixed(0)} meters',
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Refresh button
        ElevatedButton.icon(
          onPressed: () {
            locationProvider.getCurrentLocation();
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh Location Data'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
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

  double _calculateTopPosition(double elevation) {
    const double maxElevation = 1000.0;
    const double minTop = 20.0;
    const double maxTop = 125.0;
    
    final double clampedElevation = elevation.clamp(0.0, maxElevation);
    return maxTop - ((clampedElevation / maxElevation) * (maxTop - minTop));
  }

  double _calculateBottomPosition(double elevation) {
    const double maxDepth = -200.0;
    const double minBottom = 125.0;
    const double maxBottom = 230.0;
    
    final double clampedElevation = elevation.clamp(maxDepth, 0.0);
    return minBottom + ((clampedElevation.abs() / maxDepth.abs()) * (maxBottom - minBottom));
  }
}

class CelestialCompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw degree markings
    for (int i = 0; i < 360; i += 15) {
      final angle = i * (math.pi / 180);
      final isCardinal = i % 90 == 0;
      final isInterCardinal = i % 45 == 0 && !isCardinal;
      
      final markerLength = isCardinal ? 15.0 : (isInterCardinal ? 12.0 : 8.0);
      final strokeWidth = isCardinal ? 2.0 : (isInterCardinal ? 1.5 : 1.0);
      
      final paint = Paint()
        ..color = isCardinal ? 
            (i == 0 ? Colors.red : Colors.black87) : 
            Colors.grey.shade400
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      
      final outerX = center.dx + radius * math.cos(angle);
      final outerY = center.dy + radius * math.sin(angle);
      final innerX = center.dx + (radius - markerLength) * math.cos(angle);
      final innerY = center.dy + (radius - markerLength) * math.sin(angle);
      
      canvas.drawLine(
        Offset(innerX, innerY),
        Offset(outerX, outerY),
        paint,
      );
      
      // Draw cardinal and intercardinal direction labels
      if (isCardinal || isInterCardinal) {
        String text;
        
        switch (i) {
          case 0: text = 'N'; break;
          case 45: text = 'NE'; break;
          case 90: text = 'E'; break;
          case 135: text = 'SE'; break;
          case 180: text = 'S'; break;
          case 225: text = 'SW'; break;
          case 270: text = 'W'; break;
          case 315: text = 'NW'; break;
          default: text = ''; break;
        }
        
        if (text.isNotEmpty) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: text,
              style: TextStyle(
                color: i == 0 ? Colors.red : Colors.black87,
                fontSize: isCardinal ? 14 : 12,
                fontWeight: isCardinal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
          )..layout();
          
          final textX = center.dx + (radius - 30) * math.cos(angle);
          final textY = center.dy + (radius - 30) * math.sin(angle);
          
          textPainter.paint(
            canvas, 
            Offset(textX - textPainter.width / 2, textY - textPainter.height / 2)
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Helper to add contextual information about elevation
String _getElevationDescription(double elevation) {
  if (elevation < -200) return "Deep depression (well below sea level)";
  if (elevation < 0) return "Depression (below sea level)";
  if (elevation < 200) return "Lowland area (near sea level)";
  if (elevation < 500) return "Low elevation";
  if (elevation < 1000) return "Moderate elevation";
  if (elevation < 2000) return "High elevation";
  if (elevation < 3000) return "Very high elevation";
  return "Extremely high elevation (mountainous)";
}
