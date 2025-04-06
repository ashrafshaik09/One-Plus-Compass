import 'dart:math' as math;

class MoonPosition {
  // Calculate moon position based on time and location
  static Map<String, double> calculate(double latitude, double longitude, DateTime time) {
    // Convert to radians
    final lat = latitude * math.pi / 180;
    
    // Calculate Julian date
    final julianDate = _calculateJulianDate(time);
    
    // Moon phase calculation
    final phase = _calculateMoonPhase(julianDate);
    
    // Simplified moon position calculation based on phase
    // This is a simple approximation for visualization purposes
    final azimuth = (phase * 360) % 360;
    
    // Approximating elevation based on time of day
    double elevation = 0;
    final hourOfDay = time.hour + time.minute / 60;
    
    // Crude approximation of moon elevation during day
    if (hourOfDay < 6) {
      elevation = 30 * (1 - hourOfDay / 6);
    } else if (hourOfDay < 12) {
      elevation = -30 * ((hourOfDay - 6) / 6);
    } else if (hourOfDay < 18) {
      elevation = -30 * (1 - (hourOfDay - 12) / 6);
    } else {
      elevation = 30 * ((hourOfDay - 18) / 6);
    }
    
    // Adjust based on moon phase
    elevation *= (1 - math.cos(phase * 2 * math.pi)) / 2;
    
    return {
      'azimuth': azimuth,
      'elevation': elevation,
      'phase': phase,
      'illumination': _calculateMoonIllumination(phase),
    };
  }
  
  // Calculate Julian Date
  static double _calculateJulianDate(DateTime date) {
    int Y = date.year;
    int M = date.month;
    int D = date.day;
    int h = date.hour;
    int m = date.minute;
    
    if (M <= 2) {
      Y -= 1;
      M += 12;
    }
    
    double JDN = ((1461 * (Y + 4800 + (M - 14) ~/ 12)) ~/ 4) +
        ((367 * (M - 2 - 12 * ((M - 14) ~/ 12))) ~/ 12) -
        ((3 * ((Y + 4900 + (M - 14) ~/ 12) ~/ 100)) ~/ 4) +
        D - 32075;
        
    double JD = JDN + (h - 12) / 24.0 + m / 1440.0;
    
    return JD;
  }

  // Calculate Moon Phase (0-1)
  static double _calculateMoonPhase(double jd) {
    const synodicMonth = 29.53058867; // Days
    final refJD = 2451550.1; // Known new moon reference
    final daysSinceRef = jd - refJD;
    final numMonths = daysSinceRef / synodicMonth;
    return (numMonths - numMonths.floor());
  }

  // Calculate Moon Illumination (0-100)
  static double _calculateMoonIllumination(double phase) {
    // Convert phase (0-1) to illumination percentage
    if (phase <= 0.5) {
      return phase * 200; // Waxing
    } else {
      return (1 - phase) * 200; // Waning
    }
  }
}
