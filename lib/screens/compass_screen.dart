import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:compass_2/providers/compass_provider.dart';
import 'package:compass_2/providers/location_provider.dart';
import 'package:compass_2/providers/celestial_provider.dart';
import 'package:compass_2/widgets/compass_widget.dart';
import 'package:compass_2/utils/app_theme.dart';

class CompassScreen extends StatefulWidget {
  const CompassScreen({super.key});

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keep state when switching tabs
  
  bool _hasShownCalibrationDialog = false;

  @override
  void initState() {
    super.initState();
    
    // Request location and initialize celestial data when screen is shown
    Future.microtask(() {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      final celestialProvider = Provider.of<CelestialProvider>(context, listen: false);
      
      locationProvider.getCurrentLocation().then((_) {
        if (locationProvider.currentPosition != null) {
          // Calculate celestial positions when we get location
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
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Consumer2<CompassProvider, LocationProvider>(
      builder: (context, compassProvider, locationProvider, _) {
        // Calculate Qibla direction when location is available
        if (locationProvider.currentPosition != null) {
          compassProvider.calculateQiblaDirection(
            locationProvider.currentPosition!.latitude,
            locationProvider.currentPosition!.longitude,
          );
          
          // Recalculate celestial times when location changes
          Provider.of<CelestialProvider>(context, listen: false).calculateCelestialPositions(
            locationProvider.currentPosition!.latitude,
            locationProvider.currentPosition!.longitude,
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

        // Show calibration dialog when needed (but only once per session)
        if (compassProvider.needsCalibration && !_hasShownCalibrationDialog) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showCalibrationDialog(context);
            _hasShownCalibrationDialog = true;
          });
        }

        return SingleChildScrollView( // Enable scrolling to prevent overflow
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                
                // Calibration alert if needed
                if (compassProvider.needsCalibration)
                  buildCalibrationBanner(),
                  
                // The main compass widget
                SizedBox(
                  height: 280, // Fixed height to prevent layout issues
                  child: CompassWidget(
                    heading: compassProvider.heading,
                    qiblaAngle: compassProvider.qiblaAngle,
                  ),
                ),
                const SizedBox(height: 24),
                // Heading text
                Text(
                  compassProvider.headingDegrees,
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                Text(
                  compassProvider.headingText,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 16),
                // Additional info cards
                Row(
                  children: [
                    _buildInfoCard(
                      context,
                      "Elevation",
                      locationProvider.elevationText,
                      Icons.terrain,
                    ),
                    const SizedBox(width: 16),
                    // Replace Qibla card with Sun Times card
                    Consumer<CelestialProvider>(
                      builder: (context, celestialProvider, _) => _buildSunCard(
                        context,
                        celestialProvider.formattedSunrise,
                        celestialProvider.formattedSunset,
                        celestialProvider.daylightDuration,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Location name card
                if (locationProvider.currentPosition?.placeName != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_on, color: AppTheme.accentColor),
                              SizedBox(width: 8),
                              Text(
                                'Current Location',
                                style: TextStyle(
                                  fontSize: 16, 
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            locationProvider.currentPosition?.placeName ?? '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(
      BuildContext context, String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                textAlign: TextAlign.center, // Center text for better alignment
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // New calibration banner to show as inline notice
  Widget buildCalibrationBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Compass needs calibration',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                Text(
                  'Move your device in a figure-eight pattern',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => showCalibrationDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              minimumSize: const Size(60, 32),
            ),
            child: const Text('Guide'),
          ),
        ],
      ),
    );
  }

  // New method to show calibration dialog with instructions
  void showCalibrationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.compass_calibration,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Compass Needs Calibration',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'For accurate readings, please calibrate your compass by:',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Calibration instructions
              ...[
                _buildCalibrationStep(1, 'Move your device in a figure-eight pattern'),
                _buildCalibrationStep(2, 'Rotate your device around all axes'),
                _buildCalibrationStep(3, 'Keep away from magnetic interference')
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: const Size(double.infinity, 45),
                ),
                child: const Text('Got it'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCalibrationStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }

  // Improved sun card with better time display
  Widget _buildSunCard(
    BuildContext context,
    String sunrise,
    String sunset,
    String dayLength,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wb_twilight, color: Colors.amber, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'Today',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wb_sunny_outlined, 
                       color: Colors.orange.shade300, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    sunrise,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.nights_stay_outlined, 
                       color: Colors.indigo.shade300, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    sunset,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                dayLength,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              Text(
                "(+54s)", // Add the daylight change
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
