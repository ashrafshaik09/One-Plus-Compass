import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:compass_2/providers/location_provider.dart';
import 'package:compass_2/providers/compass_provider.dart';
import 'package:compass_2/utils/app_theme.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

class TrailScreen extends StatefulWidget {
  const TrailScreen({super.key});

  @override
  State<TrailScreen> createState() => _TrailScreenState();
}

class _TrailScreenState extends State<TrailScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  final MapController _mapController = MapController();
  final TextEditingController _pathNameController = TextEditingController();
  String? _selectedPathId;
  bool _showPathsList = false;

  @override
  void initState() {
    super.initState();
    
    Future.microtask(() {
      Provider.of<LocationProvider>(context, listen: false).getCurrentLocation();
    });
  }
  
  @override
  void dispose() {
    _pathNameController.dispose();
    super.dispose();
  }

  double _getPathDistance(LocationProvider provider) {
    return provider.pathHistory.isEmpty ? 0 : 
           provider.calculatePathDistance() / 1000; // Convert to km
  }

  double _getElevationGain(LocationProvider provider) {
    return provider.pathHistory.isEmpty ? 0 : 
           provider.calculateElevationGain();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Consumer2<LocationProvider, CompassProvider>(
      builder: (context, locationProvider, compassProvider, _) {
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
              // Map view with rotating marker
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      FlutterMap(
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
                          // Polylines from current or loaded path
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
                          // Dynamic arrow marker (replaces static dot)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: currentPosition,
                                width: 40,
                                height: 40,
                                child: Transform.rotate(
                                  angle: ((compassProvider.heading ?? 0) * (math.pi / 180)),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.navigation,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      // Path selection overlay
                      if (_showPathsList)
                        _buildPathsListOverlay(locationProvider),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Trail statistics card - NEW!
              if (locationProvider.pathHistory.isNotEmpty)
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          'Points',
                          '${locationProvider.pathHistory.length}',
                          Icons.timeline
                        ),
                        const SizedBox(
                          height: 40,
                          child: VerticalDivider(),
                        ),
                        _buildStatItem(
                          'Distance',
                          '${_getPathDistance(locationProvider).toStringAsFixed(2)} km',
                          Icons.straighten
                        ),
                        const SizedBox(
                          height: 40,
                          child: VerticalDivider(),
                        ),
                        _buildStatItem(
                          'Elev. Gain',
                          '${_getElevationGain(locationProvider).toStringAsFixed(1)} m',
                          Icons.trending_up
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Controls
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Trail Navigation',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          
                          // Added saved paths toggle button
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _showPathsList = !_showPathsList;
                              });
                            },
                            icon: Icon(
                              _showPathsList ? Icons.close : Icons.folder_open,
                              size: 18,
                            ),
                            label: Text(_showPathsList ? 'Close' : 'Paths'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Main action buttons
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
                                // Show save dialog when stopping recording
                                if (locationProvider.pathHistory.isNotEmpty) {
                                  _showSavePathDialog(context, locationProvider);
                                }
                              } else {
                                locationProvider.startRecordingPath();
                              }
                            },
                          ),
                          
                          // Save button instead of Clear - CHANGED
                          _buildActionButton(
                            context,
                            'Save',
                            Icons.save_alt,
                            AppTheme.accentColor,
                            () {
                              if (locationProvider.pathHistory.isNotEmpty) {
                                _showSavePathDialog(context, locationProvider);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('No path to save')),
                                );
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
                              setState(() {
                                _selectedPathId = null;
                              });
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
                      
                      // Show active saved path name if selected
                      if (_selectedPathId != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.route, size: 16, color: AppTheme.textLight),
                            const SizedBox(width: 6),
                            Text(
                              locationProvider.savedPaths
                                  .firstWhere((p) => p.id == _selectedPathId)
                                  .name,
                              style: TextStyle(
                                fontStyle: FontStyle.italic, 
                                color: AppTheme.textLight,
                              ),
                            ),
                          ],
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
  
  // Overlay for saved paths list
  Widget _buildPathsListOverlay(LocationProvider provider) {
    return Positioned.fill(
      child: Container(
        color: Colors.white.withOpacity(0.9),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Saved Paths',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            if (provider.savedPaths.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.hiking, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No saved paths yet'),
                      SizedBox(height: 8),
                      Text(
                        'Record a path and save it to see it here',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: provider.savedPaths.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final path = provider.savedPaths[index];
                    final isSelected = path.id == _selectedPathId;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
                      child: ListTile(
                        leading: Icon(
                          Icons.route,
                          color: isSelected ? AppTheme.primaryColor : Colors.grey,
                        ),
                        title: Text(path.name),
                        subtitle: Text(
                          '${(path.distance / 1000).toStringAsFixed(2)} km • ${path.points.length} points • ${_formatDate(path.createdAt)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () {
                                provider.deleteSavedPath(path.id);
                                if (path.id == _selectedPathId) {
                                  setState(() {
                                    _selectedPathId = null;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            _selectedPathId = path.id;
                            _showPathsList = false;
                          });
                          provider.loadSavedPath(path.id);
                          
                          // Center map on the first point of the path
                          if (path.points.isNotEmpty) {
                            _mapController.move(
                              LatLng(
                                path.points.first.latitude,
                                path.points.first.longitude,
                              ),
                              14,
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  void _showSavePathDialog(BuildContext context, LocationProvider provider) {
    bool isSaving = false;
    
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal while saving
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Save Path'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _pathNameController,
                decoration: const InputDecoration(
                  hintText: 'Enter path name',
                  border: OutlineInputBorder(),
                ),
                enabled: !isSaving,
                autofocus: true,
              ),
              if (isSaving) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                const Text('Saving path data...', style: TextStyle(color: Colors.grey)),
              ]
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: isSaving ? null : () async {
                if (_pathNameController.text.trim().isNotEmpty) {
                  setState(() => isSaving = true);
                  
                  // Track points count for diagnostics
                  final pointCount = provider.pathHistory.length;
                  
                  final success = await provider.saveCurrentPath(
                    _pathNameController.text.trim(),
                  );
                  
                  // Even if we pop later, let's clear the text field now
                  final enteredName = _pathNameController.text;
                  _pathNameController.clear();
                  
                  Navigator.pop(context);
                  
                  // Show detailed feedback
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success 
                          ? 'Path "$enteredName" saved successfully ($pointCount points)' 
                          : 'Error saving path: Data may be too large or invalid',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                      action: success ? null : SnackBarAction(
                        label: 'RETRY',
                        onPressed: () => _showSavePathDialog(context, provider),
                      ),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.textLight, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textLight,
          ),
        ),
      ],
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
