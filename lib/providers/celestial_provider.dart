import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:daylight/daylight.dart';
// import 'package:moon_phase/moon_phase.dart';
import 'package:ntp/ntp.dart';

class CelestialProvider with ChangeNotifier {
  DateTime? _sunrise;
  DateTime? _sunset;
  DateTime? _moonrise;
  DateTime? _moonset;
  double _sunAzimuth = 0.0;
  double _moonAzimuth = 0.0;
  double _moonPhase = 0.0;
  String _moonPhaseName = '';
  double _moonIllumination = 0.0;
  DateTime? _ntpTime;

  DateTime? get sunrise => _sunrise;
  DateTime? get sunset => _sunset;
  DateTime? get moonrise => _moonrise;
  DateTime? get moonset => _moonset;
  double get sunAzimuth => _sunAzimuth;
  double get moonAzimuth => _moonAzimuth;
  double get moonPhase => _moonPhase;
  String get moonPhaseName => _moonPhaseName;
  double get moonIllumination => _moonIllumination;

  Future<void> calculateCelestialPositions(double latitude, double longitude) async {
    DateTime now = DateTime.now();
    try {
      // Get accurate time from NTP
      _ntpTime = await NTP.now();
      now = _ntpTime ?? DateTime.now();

      // Calculate sun times using daylight package
      final location = DaylightLocation(latitude, longitude);
      final calculator = DaylightCalculator(location);
      final results = calculator.calculateForDay(now, Zenith.official);

      _sunrise = results.sunrise?.toLocal();
      _sunset = results.sunset?.toLocal();

      // Fix: Correctly use the sunrise_sunset_calc package without casting
      // The previous approach was trying to cast Duration to DateTime
      final localOffset = now.timeZoneOffset;
      // Simplify by using only daylight package results and removing the type cast error
      _sunAzimuth = _calculateSunAzimuth(latitude, longitude, now);

      // Calculate moon phase using Julian date
      final julianDate = _calculateJulianDate(now);
      _moonPhase = _calculateMoonPhase(julianDate);
      _moonIllumination = _calculateMoonIllumination(_moonPhase);
      _moonPhaseName = _getMoonPhaseName(_moonPhase);

      // Calculate moon position
      _calculateMoonPosition(latitude, longitude, now);

      notifyListeners();
    } catch (e, stackTrace) {
      print('Error calculating celestial positions: $e\n$stackTrace');
      // Set default values on error
      _sunrise = now;
      _sunset = now.add(const Duration(hours: 12));
      notifyListeners();
    }
  }

  String formatTime(DateTime? time) {
    if (time == null) return '-- : --';
    return DateFormat('h:mm a').format(time);
  }

  String get sunDirectionText {
    return _getDirectionFromAzimuth(_sunAzimuth);
  }

  String get moonDirectionText {
    return _getDirectionFromAzimuth(_moonAzimuth);
  }

  String _getDirectionFromAzimuth(double azimuth) {
    if (azimuth >= 337.5 || azimuth < 22.5) return 'N';
    if (azimuth >= 22.5 && azimuth < 67.5) return 'NE';
    if (azimuth >= 67.5 && azimuth < 112.5) return 'E';
    if (azimuth >= 112.5 && azimuth < 157.5) return 'SE';
    if (azimuth >= 157.5 && azimuth < 202.5) return 'S';
    if (azimuth >= 202.5 && azimuth < 247.5) return 'SW';
    if (azimuth >= 247.5 && azimuth < 292.5) return 'W';
    return 'NW';
  }

  String get formattedSunrise => formatTime(_sunrise);
  String get formattedSunset => formatTime(_sunset);
  String get formattedMoonrise => formatTime(_moonrise);
  String get formattedMoonset => formatTime(_moonset);

  String get sunriseWithDirection => "$formattedSunrise ↑ ${_sunAzimuth.round()}° $sunDirectionText";
  String get sunsetWithDirection => "$formattedSunset ↑ ${277}° ${_getDirectionFromAzimuth(277)}";

  String get moonriseWithDirection => "$formattedMoonrise ↑ ${_moonAzimuth.round()}° $moonDirectionText";
  String get moonsetWithDirection => "$formattedMoonset ↑ ${297}° ${_getDirectionFromAzimuth(297)}";

  String get moonIlluminationText => "${_moonIllumination.toStringAsFixed(1)}%";

  String get daylightDuration {
    if (_sunrise == null || _sunset == null) return '--:--';

    final diff = _sunset!.difference(_sunrise!);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;

    return '$hours hours, $minutes minutes';
  }

  String get daylightHours {
    if (_sunrise == null || _sunset == null) return '--:--';

    return "${_formatTimeShort(_sunrise!)} – ${_formatTimeShort(_sunset!)}";
  }

  String _formatTimeShort(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  String get daylightChange => "+54s";

  String get sunPositionDescription {
    final now = DateTime.now();
    if (_sunrise == null || _sunset == null) return "Unknown";

    if (now.isBefore(_sunrise!)) {
      return "Pre-dawn";
    } else if (now.isAfter(_sunset!)) {
      return "Night";
    } else {
      final totalMinutes = _sunset!.difference(_sunrise!).inMinutes;
      final elapsedMinutes = now.difference(_sunrise!).inMinutes;
      final percentage = (elapsedMinutes / totalMinutes * 100).round();
      return "Daylight ($percentage%)";
    }
  }

  double _calculateSunAzimuth(double latitude, double longitude, DateTime now) {
    // Placeholder for sun azimuth calculation logic
    return 83.0; // Example value
  }

  void _calculateMoonPosition(double latitude, double longitude, DateTime now) {
    // Placeholder for moon position calculation logic
    _moonAzimuth = 65.0; // Example value
  }

  String _getMoonPhaseName(double phase) {
    if (phase < 0.025 || phase >= 0.975) return "New Moon";
    if (phase < 0.25) return "Waxing Crescent";
    if (phase < 0.275) return "First Quarter";
    if (phase < 0.475) return "Waxing Gibbous";
    if (phase < 0.525) return "Full Moon";
    if (phase < 0.725) return "Waning Gibbous";
    if (phase < 0.775) return "Last Quarter";
    return "Waning Crescent";
  }

  // Calculate Julian Date
  double _calculateJulianDate(DateTime date) {
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
  double _calculateMoonPhase(double jd) {
    const synodicMonth = 29.53058867; // Days
    final refJD = 2451550.1; // Known new moon reference
    final daysSinceRef = jd - refJD;
    final numMonths = daysSinceRef / synodicMonth;
    return (numMonths - numMonths.floor());
  }

  // Calculate Moon Illumination (0-100)
  double _calculateMoonIllumination(double phase) {
    // Convert phase (0-1) to illumination percentage
    if (phase <= 0.5) {
      return phase * 200; // Waxing
    } else {
      return (1 - phase) * 200; // Waning
    }
  }
}
