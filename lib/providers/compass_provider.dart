import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math' as math;
import 'dart:async';

class CompassProvider with ChangeNotifier {
  double _heading = 0.0;
  double _qiblaAngle = 0.0;
  bool _hasCompass = false;
  bool _needsCalibration = false;
  StreamSubscription<CompassEvent>? _compassSubscription;
  
  // Getters
  double get heading => _heading;
  double get qiblaAngle => _qiblaAngle;
  bool get hasCompass => _hasCompass;
  bool get needsCalibration => _needsCalibration;
  
  // Formatted heading display 
  String get headingDegrees => '${_heading.toStringAsFixed(0)}°';
  
  // Text direction based on heading
  String get headingText {
    double normalizedHeading = (_heading + 360) % 360;
    if (normalizedHeading >= 337.5 || normalizedHeading < 22.5) return 'North';
    if (normalizedHeading >= 22.5 && normalizedHeading < 67.5) return 'Northeast';
    if (normalizedHeading >= 67.5 && normalizedHeading < 112.5) return 'East';
    if (normalizedHeading >= 112.5 && normalizedHeading < 157.5) return 'Southeast';
    if (normalizedHeading >= 157.5 && normalizedHeading < 202.5) return 'South';
    if (normalizedHeading >= 202.5 && normalizedHeading < 247.5) return 'Southwest';
    if (normalizedHeading >= 247.5 && normalizedHeading < 292.5) return 'West';
    if (normalizedHeading >= 292.5 && normalizedHeading < 337.5) return 'Northwest';
    return 'North';
  }
  
  CompassProvider() {
    _initCompass();
  }
  
  void _initCompass() async {
    // Check if device has compass sensor
    _hasCompass = FlutterCompass.events != null;
    
    if (_hasCompass) {
      // Start listening to compass events
      _compassSubscription = FlutterCompass.events!.listen((event) {
        if (event.heading != null) {
          // Fix: Ensure heading is always between 0 and 359 degrees
          _heading = ((event.heading! % 360 + 360) % 360).floor().toDouble();
          if (_heading == 360) _heading = 0; // Fix for exact 360 degree case
          
          // Update calibration status
          _needsCalibration = event.accuracy == 0 || event.accuracy == -1;
          
          notifyListeners();
        }
      });
    }
  }

  // Calculate Qibla direction
  void calculateQiblaDirection(double latitude, double longitude) {
    // Kaaba coordinates
    const double kaabaLat = 21.422487;
    const double kaabaLng = 39.826206;
    
    // Convert to radians
    final double lat1 = latitude * (math.pi / 180);
    final double lng1 = longitude * (math.pi / 180);
    final double lat2 = kaabaLat * (math.pi / 180);
    final double lng2 = kaabaLng * (math.pi / 180);
    
    // Calculate Qibla direction
    final double y = math.sin(lng2 - lng1);
    final double x = math.cos(lat1) * math.tan(lat2) -
                    math.sin(lat1) * math.cos(lng2 - lng1);
    
    double qiblaRad = math.atan2(y, x);
    _qiblaAngle = (qiblaRad * (180 / math.pi) + 360) % 360;
    
    notifyListeners();
  }

  // Calculate distance to Kaaba
  double calculateDistanceToKaaba(double latitude, double longitude) {
    // Kaaba coordinates
    const double kaabaLat = 21.422487;
    const double kaabaLng = 39.826206;
    
    // Earth's radius in km
    const double earthRadius = 6371;
    
    // Convert to radians
    final double lat1 = latitude * (math.pi / 180);
    final double lng1 = longitude * (math.pi / 180);
    final double lat2 = kaabaLat * (math.pi / 180);
    final double lng2 = kaabaLng * (math.pi / 180);
    
    // Haversine formula for distance
    final double dLat = lat2 - lat1;
    final double dLng = lng2 - lng1;
    
    final double a = math.sin(dLat/2) * math.sin(dLat/2) +
                math.cos(lat1) * math.cos(lat2) *
                math.sin(dLng/2) * math.sin(dLng/2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a));
    
    return earthRadius * c;
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }
}
