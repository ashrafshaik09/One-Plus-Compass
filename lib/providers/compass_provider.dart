import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:async';

class CompassProvider with ChangeNotifier {
  double _heading = 0.0;
  double _qiblaAngle = 0.0;
  bool _hasCompass = false;
  StreamSubscription<CompassEvent>? _compassSubscription;
  
  // Getters
  double get heading => _heading;
  double get qiblaAngle => _qiblaAngle;
  bool get hasCompass => _hasCompass;
  
  // Formatted heading (e.g., "N", "NE", etc.)
  String get headingText {
    if (_heading < 0) return "Unknown";
    
    // Use exact boundary checks to ensure West is shown correctly
    final double normalizedHeading = _heading % 360;
    
    if (normalizedHeading >= 337.5 || normalizedHeading < 22.5) {
      return "N";
    } else if (normalizedHeading >= 22.5 && normalizedHeading < 67.5) {
      return "NE";
    } else if (normalizedHeading >= 67.5 && normalizedHeading < 112.5) {
      return "E";
    } else if (normalizedHeading >= 112.5 && normalizedHeading < 157.5) {
      return "SE";
    } else if (normalizedHeading >= 157.5 && normalizedHeading < 202.5) {
      return "S";
    } else if (normalizedHeading >= 202.5 && normalizedHeading < 247.5) {
      return "SW";
    } else if (normalizedHeading >= 247.5 && normalizedHeading < 292.5) {
      return "W";
    } else if (normalizedHeading >= 292.5 && normalizedHeading < 337.5) {
      return "NW";
    }
    
    return "N"; // Default fallback
  }
  
  // Formatted heading in degrees
  String get headingDegrees {
    if (_heading < 0) return "--°";
    return "${_heading.toStringAsFixed(0)}°";
  }
  
  CompassProvider() {
    _checkCompassAvailability();
  }
  
  void _checkCompassAvailability() async {
    _hasCompass = FlutterCompass.events != null;
    
    if (_hasCompass) {
      _startListening();
    } else {
      _heading = -1;
      notifyListeners();
    }
  }
  
  void _startListening() {
    _compassSubscription = FlutterCompass.events?.listen((event) {
      _heading = event.heading ?? 0.0;
      notifyListeners();
    });
  }
  
  void calculateQiblaDirection(double latitude, double longitude) {
    // Coordinates of the Kaaba in Mecca
    const double kaabaLatitude = 21.4225;
    const double kaabaLongitude = 39.8262;
    
    // Convert to radians
    final double latRad = latitude * math.pi / 180;
    final double longRad = longitude * math.pi / 180;
    const double kaabaLatRad = kaabaLatitude * math.pi / 180;
    const double kaabaLongRad = kaabaLongitude * math.pi / 180;
    
    // Calculate the qibla direction
    final double y = math.sin(kaabaLongRad - longRad);
    final double x = math.cos(latRad) * math.tan(kaabaLatRad) - 
                   math.sin(latRad) * math.cos(kaabaLongRad - longRad);
    
    double qibla = math.atan2(y, x) * 180 / math.pi;
    qibla = (qibla + 360) % 360;
    
    _qiblaAngle = qibla;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }
}
