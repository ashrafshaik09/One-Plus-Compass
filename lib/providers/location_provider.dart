import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart' as permission;
import 'package:geocoding/geocoding.dart';
import 'dart:async';

class LocationData {
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;
  final double heading;
  final double speed;
  final double speedAccuracy;
  final double time;
  String? placeName; // Add place name field

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
}

class LocationProvider with ChangeNotifier {
  final loc.Location _location = loc.Location();
  LocationData? _currentPosition;
  bool _isLoading = false;
  String _errorMessage = '';
  final List<LocationData> _pathHistory = [];
  Timer? _positionUpdateTimer;
  bool _isRecordingPath = false;
  
  // Getters
  LocationData? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<LocationData> get pathHistory => _pathHistory;
  bool get isRecordingPath => _isRecordingPath;
  
  // Current elevation in meters - ensure it's positive for display purposes
  double get currentElevation => _currentPosition?.altitude ?? 0.0;
  
  // Formatted elevation (e.g., "123 m")
  String get elevationText {
    if (_currentPosition == null) return "-- m";
    
    // Always display elevation as positive with proper formatting
    final double elevation = _currentPosition!.altitude;
    
    // Format elevation with appropriate precision
    return "${elevation.abs().toStringAsFixed(1)} m";
  }
  
  LocationProvider() {
    _initializeLocation();
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
