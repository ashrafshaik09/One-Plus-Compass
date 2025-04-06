import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart' as permission;
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:compass_2/models/trail_path.dart';

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
  final double distance;
  final double elevationGain;
  
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
  
  List<SavedPath> _savedPaths = [];
  
  LocationData? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<LocationData> get pathHistory => _pathHistory;
  bool get isRecordingPath => _isRecordingPath;
  List<SavedPath> get savedPaths => _savedPaths;
  
  double get currentElevation {
    if (_currentPosition == null) return 0.0;
    double value = _currentPosition!.altitude;
    if (value < -1000) return 0.0;
    return value;
  }
  
  String get elevationText {
    if (_currentPosition == null) return "-- m";
    double elevation = _currentPosition!.altitude;
    if (elevation < -1000) {
      return "Sensor error";
    }
    if (elevation < 0) {
      return "${elevation.abs().toStringAsFixed(1)} m (below sea level)";
    }
    return "${elevation.toStringAsFixed(1)} m";
  }
  
  double get safeElevation {
    if (_currentPosition == null) return 0.0;
    double rawElevation = _currentPosition!.altitude;
    if (rawElevation < -1000) return 0.0;
    if (rawElevation > -10 && rawElevation < 0) {
      if (_currentPosition!.accuracy > 20) return 0.0;
    }
    if (rawElevation > 8848) {
      return 8848.0;
    }
    return rawElevation;
  }
  
  LocationProvider() {
    _initializeLocation();
    _loadSavedPaths();
    initHive();
  }
  
  Future<void> initHive() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TrailPathAdapter());
    Hive.registerAdapter(PathPointAdapter());
    await Hive.openBox<TrailPath>('trails');
  }

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
  
  Future<bool> saveCurrentPath(String name) async {
    if (_pathHistory.isEmpty) return false;
    
    try {
      final box = Hive.box<TrailPath>('trails');
      
      final pathPoints = _pathHistory.map((loc) => PathPoint(
        latitude: loc.latitude,
        longitude: loc.longitude,
        altitude: loc.altitude,
        placeName: loc.placeName,
      )).toList();
      
      final trailPath = TrailPath(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        createdAt: DateTime.now(),
        points: pathPoints,
        distance: _calculatePathDistance(),
        elevationGain: _calculateElevationGain(),
      );
      
      await box.add(trailPath);
      _pathHistory.clear();
      notifyListeners();
      return true;
    } catch (e) {
      print('Error saving trail: $e');
      return false;
    }
  }
  
  List<LocationData> _simplifyPath(List<LocationData> path) {
    if (path.length <= 100) return path;
    final simplificationFactor = (path.length / 100).ceil();
    final simplified = <LocationData>[];
    simplified.add(path.first);
    for (int i = simplificationFactor; i < path.length - simplificationFactor; i += simplificationFactor) {
      simplified.add(path[i]);
    }
    simplified.add(path.last);
    return simplified;
  }
  
  Future<void> deleteSavedPath(String id) async {
    _savedPaths.removeWhere((path) => path.id == id);
    await _persistSavedPaths();
    notifyListeners();
  }
  
  void loadSavedPath(String id) {
    final savedPath = _savedPaths.firstWhere((path) => path.id == id);
    _pathHistory.clear();
    _pathHistory.addAll(savedPath.points);
    notifyListeners();
  }
  
  Future<void> _persistSavedPaths() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> pathsJson = [];
      for (final path in _savedPaths) {
        try {
          final pathJson = path.toJson();
          pathsJson.add(pathJson);
        } catch (e) {
          print('Error converting path ${path.id} to JSON: $e');
        }
      }
      final jsonData = jsonEncode(pathsJson);
      await prefs.setString('saved_paths', jsonData);
    } catch (e) {
      print('Error persisting saved paths: $e');
    }
  }
  
  double _calculatePathDistance() {
    if (_pathHistory.length < 2) return 0;
    double totalDistance = 0;
    for (int i = 0; i < _pathHistory.length - 1; i++) {
      final point1 = _pathHistory[i];
      final point2 = _pathHistory[i + 1];
      const int earthRadius = 6371000;
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

  double calculatePathDistance() {
    if (_pathHistory.length < 2) return 0;
    double totalDistance = 0;
    for (int i = 0; i < _pathHistory.length - 1; i++) {
      final point1 = _pathHistory[i];
      final point2 = _pathHistory[i + 1];
      const int earthRadius = 6371000;
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
      await _getPlaceName();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to get location: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
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
    }
  }
  
  void startRecordingPath() {
    if (_isRecordingPath) return;
    _isRecordingPath = true;
    _pathHistory.clear();
    if (_currentPosition != null) {
      _pathHistory.add(_currentPosition!);
    }
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
