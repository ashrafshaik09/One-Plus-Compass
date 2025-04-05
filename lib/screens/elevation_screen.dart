import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:compass_2/providers/location_provider.dart';
import 'package:compass_2/utils/app_theme.dart';

class ElevationScreen extends StatefulWidget {
  const ElevationScreen({super.key});

  @override
  State<ElevationScreen> createState() => _ElevationScreenState();
}

class _ElevationScreenState extends State<ElevationScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Add this to preserve the state

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
    super.build(context); // Required for keep alive mixin
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
        
        // Enhanced elevation screen with better data visualization
        return ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // Enhanced elevation meter with improved visualization
            Container(
              height: 250, // Increased height for better visualization
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
                  // New: Elevation scale markers
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

                  // Improved sea level indicator
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
            
            // Enhanced refresh button with elevation accuracy information
            Container(
              margin: const EdgeInsets.only(top: 24, bottom: 16),
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
            
            // Add elevation accuracy note
            Text(
              'Note: Elevation accuracy can vary by ±${locationProvider.currentPosition!.accuracy.toStringAsFixed(0)}m depending on your device sensors.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        );
      },
    );
  }

  // New helper methods for elevation positioning
  double _calculateTopPosition(double elevation) {
    const double maxElevation = 1000.0; // Maximum elevation to consider
    const double minTop = 20.0; // Minimum distance from top
    const double maxTop = 125.0; // Sea level position
    
    // Clamp elevation between 0 and maxElevation
    final double clampedElevation = elevation.clamp(0.0, maxElevation);
    
    // Calculate position proportionally
    return maxTop - ((clampedElevation / maxElevation) * (maxTop - minTop));
  }

  double _calculateBottomPosition(double elevation) {
    const double maxDepth = -200.0; // Maximum depth to consider
    const double minBottom = 125.0; // Sea level position
    const double maxBottom = 230.0; // Maximum distance from top
    
    // Clamp elevation between maxDepth and 0
    final double clampedElevation = elevation.clamp(maxDepth, 0.0);
    
    // Calculate position proportionally
    return minBottom + ((clampedElevation.abs() / maxDepth.abs()) * (maxBottom - minBottom));
  }
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
