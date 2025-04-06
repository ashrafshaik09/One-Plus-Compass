import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

// Custom SunTime class to calculate sunrise/sunset times
class SunTime {
  final DateTime? sunrise;
  final DateTime? sunset;

  SunTime({required DateTime date, required double latitude, required double longitude}) :
    sunrise = _calculateSunrise(date, latitude, longitude),
    sunset = _calculateSunset(date, latitude, longitude);

  // Improved calculation for sunrise (still an approximation but with better time handling)
  static DateTime? _calculateSunrise(DateTime date, double latitude, double longitude) {
    // Base sunrise time adjusted for season (approximate)
    double baseHour = 6.0; // 6 AM approximate base sunrise
    
    // Adjust for season - earlier in summer, later in winter
    // Northern hemisphere: summer around June (month 6), winter around December (month 12)
    // Southern hemisphere: opposite
    final month = date.month;
    final seasonalAdjustment = latitude >= 0 
        ? -0.5 * math.cos((month - 1) * math.pi / 6) // Northern hemisphere
        : 0.5 * math.cos((month - 1) * math.pi / 6);  // Southern hemisphere
    
    baseHour += seasonalAdjustment;
    
    // Adjust for longitude (east is earlier, west is later)
    // 15 degrees corresponds to 1 hour
    final longitudeHour = longitude / 15.0;
    
    // Current timezone offset in hours
    final timezoneOffset = date.timeZoneOffset.inHours;
    
    // Adjusted hour = base + seasonal adjustment - longitude effect + timezone offset
    final adjustedHour = baseHour - longitudeHour + timezoneOffset;
    
    // Create sunrise DateTime in local time
    return DateTime(
      date.year, 
      date.month, 
      date.day, 
      adjustedHour.floor(), 
      ((adjustedHour - adjustedHour.floor()) * 60).round()
    );
  }
  
  // Improved calculation for sunset (still an approximation but with better time handling)
  static DateTime? _calculateSunset(DateTime date, double latitude, double longitude) {
    // Base sunset time adjusted for season (approximate)
    double baseHour = 18.0; // 6 PM approximate base sunset
    
    // Adjust for season - later in summer, earlier in winter
    // Northern hemisphere: summer around June (month 6), winter around December (month 12)
    // Southern hemisphere: opposite
    final month = date.month;
    final seasonalAdjustment = latitude >= 0 
        ? 0.5 * math.cos((month - 1) * math.pi / 6) // Northern hemisphere
        : -0.5 * math.cos((month - 1) * math.pi / 6);  // Southern hemisphere
    
    baseHour += seasonalAdjustment;
    
    // Adjust for longitude (east is earlier, west is later)
    final longitudeHour = longitude / 15.0;
    
    // Current timezone offset in hours
    final timezoneOffset = date.timeZoneOffset.inHours;
    
    // Adjusted hour = base + seasonal adjustment - longitude effect + timezone offset
    final adjustedHour = baseHour - longitudeHour + timezoneOffset;
    
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
  
  // Format time to 12-hour format with improved handling
  String formatTime(DateTime? time) {
    if (time == null) return '-- : --';
    
    // Use the current date for consistency and just take the time component
    final now = DateTime.now();
    final adjustedTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute
    );
    
    return DateFormat('h:mm a').format(adjustedTime);
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
