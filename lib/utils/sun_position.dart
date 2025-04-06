import 'dart:math' as math;

class SunPosition {
  // Calculate sun position based on time and location
  static Map<String, double> calculate(double latitude, double longitude, DateTime time) {
    // Convert to radians
    final lat = latitude * math.pi / 180;
    final lon = longitude * math.pi / 180;
    
    // Calculate day of year
    final dayOfYear = time.difference(DateTime(time.year, 1, 1)).inDays;
    
    // Time as UTC decimal hours
    final utc = time.hour + time.minute / 60 + time.second / 3600;
    
    // Calculate solar declination angle
    final decl = 0.4093 * math.sin(2 * math.pi * (284 + dayOfYear) / 365);
    
    // Calculate hour angle
    final hourAngle = 15 * (utc - 12) * math.pi / 180;
    
    // Calculate solar elevation
    final sinElevation = math.sin(lat) * math.sin(decl) + 
                        math.cos(lat) * math.cos(decl) * math.cos(hourAngle);
    final elevation = math.asin(sinElevation);
    
    // Calculate solar azimuth
    final sinAzimuth = -math.cos(decl) * math.sin(hourAngle) / math.cos(elevation);
    var azimuth = math.asin(sinAzimuth);
    
    if (math.cos(hourAngle) < math.tan(decl) / math.tan(lat)) {
      azimuth = math.pi - azimuth;
    }
    
    if (azimuth < 0) {
      azimuth += 2 * math.pi;
    }
    
    // Convert to degrees
    final elevationDeg = elevation * 180 / math.pi;
    final azimuthDeg = azimuth * 180 / math.pi;
    
    return {
      'elevation': elevationDeg,
      'azimuth': azimuthDeg,
    };
  }
}
