import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:compass_2/providers/location_provider.dart';
import 'package:compass_2/utils/app_theme.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class TrailScreen extends StatefulWidget {
  const TrailScreen({super.key});

  @override
  State<TrailScreen> createState() => _TrailScreenState();
}

class _TrailScreenState extends State<TrailScreen> {
  final MapController _mapController = MapController();

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
        
        final currentPosition = LatLng(
          locationProvider.currentPosition!.latitude,
          locationProvider.currentPosition!.longitude,
        );

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Map view
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: currentPosition,
                      initialZoom: 16.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.compass_2',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: currentPosition,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.my_location,
                              color: AppTheme.primaryColor,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                      if (locationProvider.pathHistory.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: locationProvider.pathHistory
                                  .map((loc) => LatLng(loc.latitude, loc.longitude))
                                  .toList(),
                              color: AppTheme.primaryColor,
                              strokeWidth: 4.0,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Controls
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Trail Navigation',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            context,
                            locationProvider.isRecordingPath ? 'Stop' : 'Record',
                            locationProvider.isRecordingPath 
                                ? Icons.stop_circle
                                : Icons.fiber_manual_record,
                            locationProvider.isRecordingPath
                                ? Colors.red
                                : AppTheme.primaryColor,
                            () {
                              if (locationProvider.isRecordingPath) {
                                locationProvider.stopRecordingPath();
                              } else {
                                locationProvider.startRecordingPath();
                              }
                            },
                          ),
                          _buildActionButton(
                            context,
                            'Clear',
                            Icons.clear_all,
                            AppTheme.textLight,
                            () {
                              locationProvider.clearPathHistory();
                            },
                          ),
                          _buildActionButton(
                            context,
                            'Center',
                            Icons.my_location,
                            AppTheme.accentColor,
                            () {
                              if (locationProvider.currentPosition != null) {
                                _mapController.move(
                                  LatLng(
                                    locationProvider.currentPosition!.latitude,
                                    locationProvider.currentPosition!.longitude,
                                  ),
                                  18,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      if (locationProvider.isRecordingPath) ...[
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(
                          backgroundColor: AppTheme.cardBackground,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Recording path... (${locationProvider.pathHistory.length} points)',
                          style: const TextStyle(color: AppTheme.primaryColor),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withOpacity(0.1),
            foregroundColor: color,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
          ),
          child: Icon(icon),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }
}
