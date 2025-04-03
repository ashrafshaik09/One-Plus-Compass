import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:compass_2/providers/location_provider.dart';
import 'package:compass_2/utils/app_theme.dart';

class ElevationScreen extends StatefulWidget {
  const ElevationScreen({super.key});

  @override
  State<ElevationScreen> createState() => _ElevationScreenState();
}

class _ElevationScreenState extends State<ElevationScreen> {
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
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, _) {
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

        if (locationProvider.currentPosition == null) {
          return const Center(child: Text('Waiting for location...'));
        }

        final elevation = locationProvider.currentElevation;
        final formattedElevation = locationProvider.elevationText;
        
        // Use ListView to enable scrolling and prevent overflow
        return ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // Elevation meter
            Container(
              height: 220, // Reduce height to avoid overflow
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppTheme.elevationBackgroundColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.terrain,
                      size: 48,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Current Elevation',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formattedElevation,
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Above Sea Level',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            
            // Location name card
            if (locationProvider.currentPosition?.placeName != null)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          locationProvider.currentPosition?.placeName ?? 'Unknown Location',
                          style: const TextStyle(
                            fontSize: 20, 
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            
            // Additional information
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.location_on, color: AppTheme.accentColor),
                      title: const Text('Latitude'),
                      trailing: Text(
                        locationProvider.currentPosition!.latitude.toStringAsFixed(6),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.location_on, color: AppTheme.accentColor),
                      title: const Text('Longitude'),
                      trailing: Text(
                        locationProvider.currentPosition!.longitude.toStringAsFixed(6),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.speed, color: AppTheme.accentColor),
                      title: const Text('Accuracy'),
                      trailing: Text(
                        '${locationProvider.currentPosition!.accuracy.toStringAsFixed(1)} m',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Refresh button
            Container(
              margin: const EdgeInsets.only(top: 24),
              child: ElevatedButton.icon(
                onPressed: () {
                  locationProvider.getCurrentLocation();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Location Data'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
