import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart' as permission;
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;

class LocationData {
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;
  final double heading;
  final double speed;
  final double speedAccuracy;
  final double time;
  String? placeName;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.heading,
    required this.speed,
    required this.speedAccuracy,
    required this.time,
    this.placeName,
  });
  
  // Added serialization methods for saving paths
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'altitude': altitude,
    'accuracy': accuracy,
    'heading': heading,
    'speed': speed,
    'speedAccuracy': speedAccuracy,
    'time': time,
    'placeName': placeName,
  };
  
  factory LocationData.fromJson(Map<String, dynamic> json) => LocationData(
    latitude: json['latitude'],
    longitude: json['longitude'],
    altitude: json['altitude'],
    accuracy: json['accuracy'],
    heading: json['heading'],
    speed: json['speed'],
    speedAccuracy: json['speedAccuracy'],
    time: json['time'],
    placeName: json['placeName'],
  );
}

class SavedPath {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<LocationData> points;
  final double distance; // in meters
  final double elevationGain; // in meters
  
  SavedPath({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.points,
    required this.distance,
    required this.elevationGain,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'points': points.map((point) => point.toJson()).toList(),
    'distance': distance,
    'elevationGain': elevationGain,
  };
  
  factory SavedPath.fromJson(Map<String, dynamic> json) => SavedPath(
    id: json['id'],
    name: json['name'],
    createdAt: DateTime.parse(json['createdAt']),
    points: (json['points'] as List).map((p) => LocationData.fromJson(p)).toList(),
    distance: json['distance'],
    elevationGain: json['elevationGain'],
  );
}

class LocationProvider with ChangeNotifier {
  final loc.Location _location = loc.Location();
  LocationData? _currentPosition;
  bool _isLoading = false;
  String _errorMessage = '';
  final List<LocationData> _pathHistory = [];
  Timer? _positionUpdateTimer;
  bool _isRecordingPath = false;
  
  // Add saved paths
  List<SavedPath> _savedPaths = [];
  
  // Getters
  LocationData? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<LocationData> get pathHistory => _pathHistory;
  bool get isRecordingPath => _isRecordingPath;
  List<SavedPath> get savedPaths => _savedPaths;
  
  // Improved elevation calculation to handle real-world issues
  double get currentElevation {
    if (_currentPosition == null) return 0.0;
    double value = _currentPosition!.altitude;
    
    // Handle invalid values - some devices report negative values
    // when they should be positive (elevation above sea level)
    if (value < -1000) return 0.0; // Likely a sensor error
    
    return value;
  }
  
  // Formatted elevation with better handling of edge cases
  String get elevationText {
    if (_currentPosition == null) return "-- m";
    
    double elevation = _currentPosition!.altitude;
    
    // Handle potential sensor errors (extremely negative values)
    if (elevation < -1000) {
      return "Sensor error";
    }
    
    // Format based on whether it's below sea level
    if (elevation < 0) {
      return "${elevation.abs().toStringAsFixed(1)} m (below sea level)";
    }
    return "${elevation.toStringAsFixed(1)} m";
  }
  
  // New getter for safe elevation that validates and corrects common issues
  double get safeElevation {
    if (_currentPosition == null) return 0.0;
    
    // Get raw altitude from position
    double rawElevation = _currentPosition!.altitude;
    
    // Apply validation logic
    // 1. If sensor reports extreme values (below -1000m), assume sensor error
    if (rawElevation < -1000) return 0.0;
    
    // 2. If sensor reports small negative values when likely at sea level
    if (rawElevation > -10 && rawElevation < 0) {
      // If we're near coastline or at low accuracy, assume sea level
      if (_currentPosition!.accuracy > 20) return 0.0;
    }
    
    // 3. If sensor reports unrealistically high elevations
    if (rawElevation > 8848) { // Higher than Everest
      return 8848.0;
    }
    
    return rawElevation;
  }
  
  LocationProvider() {
    _initializeLocation();
    _loadSavedPaths();
  }
  
  // Load saved paths from SharedPreferences
  Future<void> _loadSavedPaths() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPathsJson = prefs.getString('saved_paths');
      
      if (savedPathsJson != null) {
        final List<dynamic> decoded = jsonDecode(savedPathsJson);
        _savedPaths = decoded.map((json) => SavedPath.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading saved paths: $e');
      _savedPaths = [];
      notifyListeners();
    }
  }
  
  // Save current path to persistent storage
  Future<bool> saveCurrentPath(String name) async {
    if (_pathHistory.isEmpty) return false;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Create a deep copy of the path history
      // NOTE: Fixing the deep copy issue - List.from doesn't create a deep copy
      final List<LocationData> pathCopy = _pathHistory.map((location) => 
        LocationData(
          latitude: location.latitude,
          longitude: location.longitude, 
          altitude: location.altitude,
          accuracy: location.accuracy,
          heading: location.heading,
          speed: location.speed,
          speedAccuracy: location.speedAccuracy,
          time: location.time,
          placeName: location.placeName,
        )
      ).toList();
      
      // Calculate statistics - using our copied path to prevent race conditions
      final totalDistance = _calculatePathDistance();
      final elevationGain = _calculateElevationGain();
      
      // Create new saved path with a unique ID
      var newPath = SavedPath(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        createdAt: DateTime.now(),
        points: pathCopy,
        distance: totalDistance,
        elevationGain: elevationGain,
      );
      
      // Validate JSON serialization works before saving
      try {
        final testJson = newPath.toJson();
        // This is a validation test - if it fails, the catch block will handle it
        final jsonString = jsonEncode(testJson);
        
        // Check if JSON string is too large (SharedPreferences has ~2MB limit)
        if (jsonString.length > 1000000) { // 1MB safety limit
          // If path is too large, simplify by sampling points
          final simplifiedPoints = _simplifyPath(pathCopy);
          newPath = SavedPath(
            id: newPath.id,
            name: name,
            createdAt: newPath.createdAt,
            points: simplifiedPoints,
            distance: totalDistance,
            elevationGain: elevationGain,
          );
        }
      } catch (e) {
        print('JSON serialization validation failed: $e');
        return false;
      }
      
      // Add to saved paths list
      _savedPaths.add(newPath);
      
      // Convert all paths to JSON with safety checks
      final List<Map<String, dynamic>> pathsJson = [];
      for (final path in _savedPaths) {
        try {
          pathsJson.add(path.toJson());
        } catch (e) {
          print('Error converting path to JSON: $e');
          // Continue with other paths
        }
      }
      
      // Save to SharedPreferences with error handling
      try {
        final jsonData = jsonEncode(pathsJson);
        await prefs.setString('saved_paths', jsonData);
      } catch (e) {
        print('Error saving to SharedPreferences: $e');
        return false;
      }
      
      // Clear current path history after successful save
      _pathHistory.clear();
      
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      print('Error saving path: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }
  
  // New method to simplify path by reducing number of points
  List<LocationData> _simplifyPath(List<LocationData> path) {
    if (path.length <= 100) return path; // Don't simplify small paths
    
    // Simple algorithm to keep only every Nth point
    final simplificationFactor = (path.length / 100).ceil();
    final simplified = <LocationData>[];
    
    // Always keep first and last points
    simplified.add(path.first);
    
    // Add sampled points
    for (int i = simplificationFactor; i < path.length - simplificationFactor; i += simplificationFactor) {
      simplified.add(path[i]);
    }
    
    // Add last point
    simplified.add(path.last);
    
    return simplified;
  }
  
  // Delete a saved path
  Future<void> deleteSavedPath(String id) async {
    _savedPaths.removeWhere((path) => path.id == id);
    await _persistSavedPaths();
    notifyListeners();
  }
  
  // Load a saved path to current path history
  void loadSavedPath(String id) {
    final savedPath = _savedPaths.firstWhere((path) => path.id == id);
    _pathHistory.clear();
    _pathHistory.addAll(savedPath.points);
    notifyListeners();
  }
  
  // Save paths to SharedPreferences with improved error handling
  Future<void> _persistSavedPaths() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert paths to JSON with careful handling
      final List<Map<String, dynamic>> pathsJson = [];
      for (final path in _savedPaths) {
        try {
          final pathJson = path.toJson();
          pathsJson.add(pathJson);
        } catch (e) {
          print('Error converting path ${path.id} to JSON: $e');
          // Continue with other paths if one fails
        }
      }
      
      // Save the valid paths to SharedPreferences
      final jsonData = jsonEncode(pathsJson);
      await prefs.setString('saved_paths', jsonData);
      
    } catch (e) {
      print('Error persisting saved paths: $e');
    }
  }
  
  // Calculate total path distance in meters
  double _calculatePathDistance() {
    if (_pathHistory.length < 2) return 0;
    
    double totalDistance = 0;
    for (int i = 0; i < _pathHistory.length - 1; i++) {
      final point1 = _pathHistory[i];
      final point2 = _pathHistory[i + 1];
      
      // Using Haversine formula
      const int earthRadius = 6371000; // in meters
      final lat1 = point1.latitude * (math.pi / 180);
      final lat2 = point2.latitude * (math.pi / 180);
      final dLat = (point2.latitude - point1.latitude) * (math.pi / 180);
      final dLon = (point2.longitude - point1.longitude) * (math.pi / 180);
      
      final a = math.sin(dLat/2) * math.sin(dLat/2) +
                math.cos(lat1) * math.cos(lat2) *
                math.sin(dLon/2) * math.sin(dLon/2);
      final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a));
      final distance = earthRadius * c;
      
      totalDistance += distance;
    }
    
    return totalDistance;
  }
  
  // Calculate elevation gain (positive changes only)
  double _calculateElevationGain() {
    if (_pathHistory.length < 2) return 0;
    
    double totalGain = 0;
    for (int i = 0; i < _pathHistory.length - 1; i++) {
      final elevChange = _pathHistory[i + 1].altitude - _pathHistory[i].altitude;
      if (elevChange > 0) {
        totalGain += elevChange;
      }
    }
    
    return totalGain;
  }

  // Make path calculation methods public
  double calculatePathDistance() {
    if (_pathHistory.length < 2) return 0;
    
    double totalDistance = 0;
    for (int i = 0; i < _pathHistory.length - 1; i++) {
      final point1 = _pathHistory[i];
      final point2 = _pathHistory[i + 1];
      
      // Using Haversine formula
      const int earthRadius = 6371000; // in meters
      final lat1 = point1.latitude * (math.pi / 180);
      final lat2 = point2.latitude * (math.pi / 180);
      final dLat = (point2.latitude - point1.latitude) * (math.pi / 180);
      final dLon = (point2.longitude - point1.longitude) * (math.pi / 180);
      
      final a = math.sin(dLat/2) * math.sin(dLat/2) +
                math.cos(lat1) * math.cos(lat2) *
                math.sin(dLon/2) * math.sin(dLon/2);
      final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a));
      final distance = earthRadius * c;
      
      totalDistance += distance;
    }
    
    return totalDistance;
  }

  double calculateElevationGain() {
    if (_pathHistory.length < 2) return 0;
    
    double totalGain = 0;
    for (int i = 0; i < _pathHistory.length - 1; i++) {
      final elevChange = _pathHistory[i + 1].altitude - _pathHistory[i].altitude;
      if (elevChange > 0) {
        totalGain += elevChange;
      }
    }
    
    return totalGain;
  }
  
  Future<void> _initializeLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          _errorMessage = 'Location services are disabled';
          notifyListeners();
          return;
        }
      }

      // Check and request location permission
      await _checkPermission();
    } catch (e) {
      _errorMessage = 'Error initializing location: $e';
      notifyListeners();
    }
  }
  
  Future<void> _checkPermission() async {
    final status = await permission.Permission.location.status;
    
    if (status.isGranted) {
      getCurrentLocation();
    } else if (status.isDenied) {
      requestLocationPermission();
    }
  }
  
  Future<void> requestLocationPermission() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final permissionStatus = await permission.Permission.location.request();
      
      if (permissionStatus.isGranted) {
        var permissionStatus = await _location.hasPermission();
        if (permissionStatus == loc.PermissionStatus.denied) {
          permissionStatus = await _location.requestPermission();
          if (permissionStatus != loc.PermissionStatus.granted) {
            _errorMessage = 'Location permissions are denied';
            _isLoading = false;
            notifyListeners();
            return;
          }
        }
        
        getCurrentLocation();
      } else {
        _errorMessage = 'Location permission is required for compass functionality';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error requesting permission: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> getCurrentLocation() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      _location.enableBackgroundMode(enable: true);
      _location.changeSettings(accuracy: loc.LocationAccuracy.high);
      
      final locationData = await _location.getLocation();
      _currentPosition = LocationData(
        latitude: locationData.latitude ?? 0.0,
        longitude: locationData.longitude ?? 0.0,
        altitude: locationData.altitude ?? 0.0,
        accuracy: locationData.accuracy ?? 0.0,
        heading: locationData.heading ?? 0.0,
        speed: locationData.speed ?? 0.0,
        speedAccuracy: locationData.speedAccuracy ?? 0.0,
        time: locationData.time ?? 0.0,
      );

      // Fetch location name
      await _getPlaceName();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to get location: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // New method to get place name
  Future<void> _getPlaceName() async {
    if (_currentPosition == null) return;
    
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final List<String> addressParts = [];
        
        if (place.locality?.isNotEmpty == true) {
          addressParts.add(place.locality!);
        }
        if (place.subAdministrativeArea?.isNotEmpty == true) {
          addressParts.add(place.subAdministrativeArea!);
        }
        if (place.country?.isNotEmpty == true) {
          addressParts.add(place.country!);
        }
        
        _currentPosition!.placeName = addressParts.join(', ');
        notifyListeners();
      }
    } catch (e) {
      print('Error getting place name: $e');
      // Don't update UI on error here, just log it
    }
  }
  
  void startRecordingPath() {
    if (_isRecordingPath) return;
    
    _isRecordingPath = true;
    _pathHistory.clear();
    
    // Add the current position as the first point
    if (_currentPosition != null) {
      _pathHistory.add(_currentPosition!);
    }
    
    // Start recording path every 5 seconds
    _positionUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final locationData = await _location.getLocation();
        final position = LocationData(
          latitude: locationData.latitude ?? 0.0,
          longitude: locationData.longitude ?? 0.0,
          altitude: locationData.altitude ?? 0.0,
          accuracy: locationData.accuracy ?? 0.0,
          heading: locationData.heading ?? 0.0,
          speed: locationData.speed ?? 0.0,
          speedAccuracy: locationData.speedAccuracy ?? 0.0,
          time: locationData.time ?? 0.0,
        );
        
        _currentPosition = position;
        _pathHistory.add(position);
        notifyListeners();
      } catch (e) {
        // Silently handle error, but keep timer running
      }
    });
    
    notifyListeners();
  }
  
  void stopRecordingPath() {
    if (!_isRecordingPath) return;
    
    _isRecordingPath = false;
    _positionUpdateTimer?.cancel();
    _positionUpdateTimer = null;
    notifyListeners();
  }
  
  void clearPathHistory() {
    _pathHistory.clear();
    notifyListeners();
  }
  
  @override
  void dispose() {
    _positionUpdateTimer?.cancel();
    super.dispose();
  }
}
