import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Custom SunTime class to calculate sunrise/sunset times
class SunTime {
  final DateTime? sunrise;
  final DateTime? sunset;

  SunTime({required DateTime date, required double latitude, required double longitude}) :
    sunrise = _calculateSunrise(date, latitude, longitude),
    sunset = _calculateSunset(date, latitude, longitude);

  // Simple calculation for sunrise (approximation)
  static DateTime? _calculateSunrise(DateTime date, double latitude, double longitude) {
    // Base sunrise time (approximation - more accurate would use astronomical calculations)
    final baseHour = 6; // 6 AM approximate sunrise
    final longitudeHour = longitude / 15; // 15 degrees per hour
    
    // Adjust for longitude (east is earlier, west is later)
    final adjustedHour = baseHour - longitudeHour;
    
    // Create sunrise DateTime
    return DateTime(
      date.year, 
      date.month, 
      date.day, 
      adjustedHour.floor(), 
      ((adjustedHour - adjustedHour.floor()) * 60).round()
    );
  }
  
  // Simple calculation for sunset (approximation)
  static DateTime? _calculateSunset(DateTime date, double latitude, double longitude) {
    // Base sunset time (approximation)
    final baseHour = 18; // 6 PM approximate sunset
    final longitudeHour = longitude / 15; // 15 degrees per hour
    
    // Adjust for longitude
    final adjustedHour = baseHour - longitudeHour;
    
    // Create sunset DateTime
    return DateTime(
      date.year, 
      date.month, 
      date.day, 
      adjustedHour.floor(), 
      ((adjustedHour - adjustedHour.floor()) * 60).round()
    );
  }
}

class CelestialProvider with ChangeNotifier {
  DateTime? _sunrise;
  DateTime? _sunset;
  double _sunAzimuth = 0.0;
  double _moonAzimuth = 0.0;
  
  // Getters
  DateTime? get sunrise => _sunrise;
  DateTime? get sunset => _sunset;
  double get sunAzimuth => _sunAzimuth;
  double get moonAzimuth => _moonAzimuth;
  
  // Initialize method for setup
  void initialize() {
    // This will be called when the provider is created
  }
  
  // Calculate sun position based on location and time
  void calculateSunPosition(double latitude, double longitude) {
    try {
      // Get sunrise/sunset times using the SunTime class
      final now = DateTime.now();
      final sunTimes = SunTime(date: now, latitude: latitude, longitude: longitude);
      _sunrise = sunTimes.sunrise;
      _sunset = sunTimes.sunset;
      
      // Calculate sun azimuth (approximate)
      final hour = now.hour + now.minute / 60.0;
      
      // Simple sun azimuth approximation (east in morning, west in evening)
      if (_sunrise != null && _sunset != null) {
        final sunriseHour = _sunrise!.hour + _sunrise!.minute / 60.0;
        final sunsetHour = _sunset!.hour + _sunset!.minute / 60.0;
        final totalDaylight = sunsetHour - sunriseHour;
        
        if (hour < sunriseHour) {
          // Before sunrise, sun is in the east-northeast
          _sunAzimuth = 65.0;
        } else if (hour > sunsetHour) {
          // After sunset, sun is in the west-northwest
          _sunAzimuth = 295.0;
        } else {
          // During daylight, calculate position along sun's arc
          final progress = (hour - sunriseHour) / totalDaylight;
          _sunAzimuth = 90.0 + (progress * 180.0); // 90° (east) to 270° (west)
        }
      } else {
        // Default approximation if we can't calculate
        if (hour < 12) {
          _sunAzimuth = 90.0 + (hour / 12.0) * 90.0;
        } else {
          _sunAzimuth = 180.0 + ((hour - 12.0) / 12.0) * 90.0;
        }
      }
      
      // Approximate moon azimuth (simplified)
      // In reality, moon position calculations are complex and depend on lunar phase
      // This is a very simplified approximation
      final dayOfMonth = now.day;
      final monthProgress = dayOfMonth / 30.0;
      
      // Moon is roughly opposite the sun during full moon and similar to sun during new moon
      final lunarPhaseOffset = (monthProgress * 360.0) % 360.0;
      _moonAzimuth = (_sunAzimuth + lunarPhaseOffset) % 360.0;
      
      notifyListeners();
    } catch (e) {
      print('Error calculating celestial positions: $e');
    }
  }
  
  // Format time to 12-hour format
  String formatTime(DateTime? time) {
    if (time == null) return '-- : --';
    return DateFormat('h:mm a').format(time);
  }
  
  // Get sun position direction as string
  String get sunDirectionText {
    if (_sunAzimuth >= 337.5 || _sunAzimuth < 22.5) return 'N';
    if (_sunAzimuth >= 22.5 && _sunAzimuth < 67.5) return 'NE';
    if (_sunAzimuth >= 67.5 && _sunAzimuth < 112.5) return 'E';
    if (_sunAzimuth >= 112.5 && _sunAzimuth < 157.5) return 'SE';
    if (_sunAzimuth >= 157.5 && _sunAzimuth < 202.5) return 'S';
    if (_sunAzimuth >= 202.5 && _sunAzimuth < 247.5) return 'SW';
    if (_sunAzimuth >= 247.5 && _sunAzimuth < 292.5) return 'W';
    return 'NW';
  }
  
  // Get moon position direction as string
  String get moonDirectionText {
    if (_moonAzimuth >= 337.5 || _moonAzimuth < 22.5) return 'N';
    if (_moonAzimuth >= 22.5 && _moonAzimuth < 67.5) return 'NE';
    if (_moonAzimuth >= 67.5 && _moonAzimuth < 112.5) return 'E';
    if (_moonAzimuth >= 112.5 && _moonAzimuth < 157.5) return 'SE';
    if (_moonAzimuth >= 157.5 && _moonAzimuth < 202.5) return 'S';
    if (_moonAzimuth >= 202.5 && _moonAzimuth < 247.5) return 'SW';
    if (_moonAzimuth >= 247.5 && _moonAzimuth < 292.5) return 'W';
    return 'NW';
  }
  
  // Get formatted sunrise
  String get formattedSunrise => formatTime(_sunrise);
  
  // Get formatted sunset
  String get formattedSunset => formatTime(_sunset);
  
  // Get day length
  String get daylightDuration {
    if (_sunrise == null || _sunset == null) return '--:--';
    
    final diff = _sunset!.difference(_sunrise!);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    
    return '$hours hours $minutes minutes';
  }
}
