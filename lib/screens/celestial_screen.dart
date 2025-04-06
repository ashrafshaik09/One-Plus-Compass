import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:compass_2/providers/celestial_provider.dart';
import 'package:compass_2/providers/location_provider.dart';
import 'package:compass_2/providers/compass_provider.dart';
import 'package:compass_2/utils/app_theme.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart' as intl;
// import 'package:moon_phase/moon_widget.dart';
import 'package:compass_2/widgets/moon_widget.dart';

class CelestialScreen extends StatefulWidget {
  const CelestialScreen({super.key});

  @override
  State<CelestialScreen> createState() => _CelestialScreenState();
}

class MoonPhasePainter extends CustomPainter {
  final double phase;
  
  MoonPhasePainter(this.phase);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      paint
    );
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _CelestialScreenState extends State<CelestialScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final bool _showElevation = false;
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
          celestialProvider.calculateCelestialPositions(
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
          celestialProvider.calculateCelestialPositions(
            locationProvider.currentPosition!.latitude,
            locationProvider.currentPosition!.longitude,
          );
        }
        
        // Updated UI with better spacing and fixed overflow
        return Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  // Remove horizontal padding from the outer container to fix overflow
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Celestial vision header with animated background
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: _buildHeaderCard(celestialProvider),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Use padding inside the scroll view instead of on container
                        _buildCelestialCards(celestialProvider),

                        const SizedBox(height: 16),

                        // Add padding to individual cards instead of outer container
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: _buildDaylightProgressCard(celestialProvider),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Add padding to individual cards instead of outer container
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: _buildEnhancedMoonPhaseCard(celestialProvider),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(CelestialProvider celestialProvider) {
    final now = DateTime.now();
    final isDaytime = celestialProvider.sunrise != null && 
                     celestialProvider.sunset != null &&
                     now.isAfter(celestialProvider.sunrise!) && 
                     now.isBefore(celestialProvider.sunset!);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDaytime
                ? [Colors.blue.shade300, Colors.blue.shade600]  // Day colors
                : [Colors.indigo.shade800, Colors.black],      // Night colors
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isDaytime ? Icons.wb_sunny : Icons.nightlight_round,
                  color: Colors.white,
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Celestial Status',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(1, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        celestialProvider.sunPositionDescription,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTimeInfoColumn(
                  'Sunrise',
                  celestialProvider.formattedSunrise,
                  Icons.wb_twilight,
                  Colors.amber,
                ),
                _buildTimeInfoColumn(
                  'Sunset',
                  celestialProvider.formattedSunset,
                  Icons.bedtime,
                  Colors.blue.shade200,
                ),
                _buildTimeInfoColumn(
                  'Day Length',
                  celestialProvider.daylightHours,
                  Icons.timelapse,
                  Colors.white70,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfoColumn(String title, String time, IconData icon, Color iconColor) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        Text(
          time,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCelestialCards(CelestialProvider celestialProvider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildInfoCard(
            'Sun Position',
            '${celestialProvider.sunAzimuth.toStringAsFixed(1)}° ${celestialProvider.sunDirectionText}',
            Icons.wb_sunny,
            Colors.orange.shade400,
            subtitle: 'Current position in the sky',
          ),
          const SizedBox(width: 12),
          _buildInfoCard(
            'Moon Phase',
            celestialProvider.moonPhaseName,
            Icons.nightlight_round,
            Colors.blueGrey,
            subtitle: '${celestialProvider.moonIlluminationText} illuminated',
          ),
          const SizedBox(width: 12),
          _buildInfoCard(
            'Moon Position',
            '${celestialProvider.moonAzimuth.toStringAsFixed(1)}° ${celestialProvider.moonDirectionText}',
            Icons.explore,
            Colors.indigo.shade400,
            subtitle: 'Current position in the sky',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 160, // Fixed width
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                // Add Expanded to prevent text overflow
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Add constraints to prevent text overflow
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDaylightProgressCard(CelestialProvider celestialProvider) {
    final sunrise = celestialProvider.sunrise;
    final sunset = celestialProvider.sunset;
    final now = DateTime.now();
    
    if (sunrise == null || sunset == null) {
      return const SizedBox.shrink();
    }
    
    double progress = 0.0;
    String status = 'Night';
    
    final sunriseTime = sunrise.hour * 60 + sunrise.minute;
    final sunsetTime = sunset.hour * 60 + sunset.minute;
    final currentTime = now.hour * 60 + now.minute;
    final totalDaylight = sunsetTime - sunriseTime;
    
    if (currentTime < sunriseTime) {
      status = 'Pre-dawn';
      progress = 0.0;
    } else if (currentTime > sunsetTime) {
      status = 'Night';
      progress = 1.0;
    } else {
      status = 'Daylight';
      progress = (currentTime - sunriseTime) / totalDaylight;
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.wb_twilight,
                  color: Colors.orange.shade400,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Daylight Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Day/night cycle visualization
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Colors.indigo.shade900,  // Night
                    Colors.orange.shade300,  // Dawn
                    Colors.blue.shade300,    // Day
                    Colors.orange.shade700,  // Dusk
                    Colors.indigo.shade900,  // Night again
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Sun position indicator with drop shadow
                  Positioned(
                    left: MediaQuery.of(context).size.width * progress * 0.7, // Adjusted for card padding
                    top: 20,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Colors.yellow, Colors.orange.shade700],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.yellow.withOpacity(0.6),
                            blurRadius: 15,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.wb_sunny, color: Colors.white),
                    ),
                  ),
                  
                  // Time indicators
                  Positioned(
                    left: 10,
                    bottom: 5,
                    child: Text(
                      celestialProvider.formattedSunrise,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 3)],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 5,
                    child: Text(
                      celestialProvider.formattedSunset,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 3)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            Text(
              'Current: $status (${(progress * 100).toStringAsFixed(0)}% of daylight)',
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
            Text(
              'Total daylight: ${celestialProvider.daylightDuration}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              'Change today: ${celestialProvider.daylightChange}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedMoonPhaseCard(CelestialProvider celestialProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.nightlight, color: Colors.indigo.shade400),
                const SizedBox(width: 12),
                const Text(
                  'Moon Phase',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Replace old MoonWidget with our new one
            MoonWidget(
              phase: celestialProvider.moonPhase,
              size: 120,
              moonColor: Colors.amber.shade100,
              earthshineColor: Colors.blueGrey.shade900,
            ),
            
            const SizedBox(height: 12),
            
            // Moon cycle diagram
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Moon Cycle',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildMoonCycleDiagram(celestialProvider.moonPhase),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMoonCycleDiagram(double phase) {
    return SizedBox(
      height: 80,
      // Use a SingleChildScrollView to handle potential overflow on small devices
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMoonPhaseIcon('New Moon', 0.0, phase, 0.025),
            const SizedBox(width: 16),
            _buildMoonPhaseIcon('First Quarter', 0.25, phase, 0.025),
            const SizedBox(width: 16),
            _buildMoonPhaseIcon('Full Moon', 0.5, phase, 0.025),
            const SizedBox(width: 16),
            _buildMoonPhaseIcon('Last Quarter', 0.75, phase, 0.025),
          ],
        ),
      ),
    );
  }

  Widget _buildMoonPhaseIcon(String label, double phaseValue, double currentPhase, double threshold) {
    final isActive = (currentPhase >= phaseValue - threshold && 
                     currentPhase <= phaseValue + threshold) ||
                     (phaseValue == 0.0 && currentPhase >= 0.975);
                     
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
            border: Border.all(
              color: isActive ? Colors.blue.shade300 : Colors.transparent,
              width: 2,
            ),
            boxShadow: isActive ? [
              BoxShadow(
                color: Colors.blue.shade200.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ] : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: ClipOval(
              child: CustomPaint(
                painter: MoonPhasePainter(phaseValue),
                size: const Size(36, 36),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.blue.shade300 : Colors.grey.shade600,
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
}
