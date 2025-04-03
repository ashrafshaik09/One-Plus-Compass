import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:compass_2/providers/compass_provider.dart';
import 'package:compass_2/providers/location_provider.dart';
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
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Consumer2<CompassProvider, LocationProvider>(
      builder: (context, compassProvider, locationProvider, _) {
        // Calculate Qibla direction when location is available
        if (locationProvider.currentPosition != null) {
          compassProvider.calculateQiblaDirection(
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

        return SingleChildScrollView( // Enable scrolling to prevent overflow
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
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
                    _buildInfoCard(
                      context,
                      "Qibla Direction",
                      "${compassProvider.qiblaAngle.toStringAsFixed(0)}°",
                      Icons.mosque,
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
}
