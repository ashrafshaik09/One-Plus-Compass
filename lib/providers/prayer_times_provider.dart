import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';

class PrayerTimesProvider with ChangeNotifier {
  PrayerTimes? _prayerTimes;
  final String _timeZoneName = '';
  DateTime? _lastCalculationDate;
  int _calculationMethod = 0; // 0 = Muslim World League (default)
  Coordinates? _coordinates; // Added to store coordinates

  // Prayer times getters
  DateTime? get fajrTime => _prayerTimes?.fajr;
  DateTime? get sunriseTime => _prayerTimes?.sunrise;
  DateTime? get dhuhrTime => _prayerTimes?.dhuhr;
  DateTime? get asrTime => _prayerTimes?.asr;
  DateTime? get maghribTime => _prayerTimes?.maghrib;
  DateTime? get ishaTime => _prayerTimes?.isha;

  // Calculation method names
  static const List<String> calculationMethodNames = [
    "Muslim World League",
    "Egyptian",
    "Karachi",
    "Umm al-Qura",
    "Dubai",
    "Qatar",
    "Kuwait",
    "Moonsighting Committee",
    "Singapore",
    "Turkey",
    "Tehran",
    "North America"
  ];

  String get currentCalculationMethod => calculationMethodNames[_calculationMethod];

  // Calculate and cache prayer times
  void calculatePrayerTimes(double latitude, double longitude) {
    try {
      final now = DateTime.now();
      final date = DateComponents(now.year, now.month, now.day);
      final params = _getCalculationParameters();

      // Get timezone offset for the location
      _coordinates = Coordinates(latitude, longitude);
      final localDate = DateTime.now().toLocal();
      
      // Calculate prayer times with correct timezone offset
      _prayerTimes = PrayerTimes(
        _coordinates!, 
        date, 
        params,
        utcOffset: localDate.timeZoneOffset,
      );
      _lastCalculationDate = localDate;

      notifyListeners();
    } catch (e) {
      print('Error calculating prayer times: $e');
      _prayerTimes = null;
      notifyListeners();
    }
  }

  // Get the calculation parameters based on selected method
  CalculationParameters _getCalculationParameters() {
    CalculationParameters params;

    switch (_calculationMethod) {
      case 0:
        params = CalculationMethod.muslim_world_league.getParameters();
        break;
      case 1:
        params = CalculationMethod.egyptian.getParameters();
        break;
      case 2:
        params = CalculationMethod.karachi.getParameters();
        break;
      case 3:
        params = CalculationMethod.umm_al_qura.getParameters();
        break;
      case 4:
        params = CalculationMethod.dubai.getParameters();
        break;
      case 5:
        params = CalculationMethod.qatar.getParameters();
        break;
      case 6:
        params = CalculationMethod.kuwait.getParameters();
        break;
      case 7:
        params = CalculationMethod.moon_sighting_committee.getParameters();
        break;
      case 8:
        params = CalculationMethod.singapore.getParameters();
        break;
      case 9:
        params = CalculationMethod.turkey.getParameters();
        break;
      case 10:
        params = CalculationMethod.tehran.getParameters();
        break;
      case 11:
        params = CalculationMethod.north_america.getParameters();
        break;
      default:
        params = CalculationMethod.muslim_world_league.getParameters();
    }

    params.madhab = Madhab.shafi;
    return params;
  }

  // Get next prayer info with improved time formatting and proper time zone handling
  Map<String, dynamic>? getNextPrayer() {
    if (_prayerTimes == null || _coordinates == null) return null;

    // Ensure we're using local time for all comparisons
    final now = DateTime.now();

    // Debug time values
    print("Current time: ${DateFormat('HH:mm:ss').format(now)}");

    // Get prayer times for today and ensure they're properly compared as local time
    final prayers = {
      'Fajr': _prayerTimes!.fajr,
      'Dhuhr': _prayerTimes!.dhuhr,
      'Asr': _prayerTimes!.asr,
      'Maghrib': _prayerTimes!.maghrib,
      'Isha': _prayerTimes!.isha,
    };

    // Print each prayer time for debugging
    prayers.forEach((name, time) {
      print("$name time: ${DateFormat('HH:mm:ss').format(time)}");
    });

    // Check if all prayers for today have passed
    bool allPassed = true;
    String nextPrayer = '';
    DateTime? nextPrayerTime;

    prayers.forEach((name, time) {
      // Compare hours and minutes only (ignore seconds and milliseconds)
      final currentTimeMinutes = now.hour * 60 + now.minute;
      final prayerTimeMinutes = time.hour * 60 + time.minute;
      
      if (prayerTimeMinutes >= currentTimeMinutes) {
        if (nextPrayerTime == null || 
            time.hour * 60 + time.minute < nextPrayerTime!.hour * 60 + nextPrayerTime!.minute) {
          nextPrayer = name;
          nextPrayerTime = time;
        }
        allPassed = false;
      }
    });

    // If all prayers have passed, calculate tomorrow's Fajr
    if (allPassed && _coordinates != null) {
      final tomorrowDate = DateTime.now().add(const Duration(days: 1));
      final tomorrow = DateComponents(tomorrowDate.year, tomorrowDate.month, tomorrowDate.day);
      final params = _getCalculationParameters();
      final tomorrowPrayers = PrayerTimes(_coordinates!, tomorrow, params);
      nextPrayer = 'Fajr';
      nextPrayerTime = tomorrowPrayers.fajr;
    }

    // Calculate remaining time with improved formatting
    if (nextPrayerTime != null) {
      // Convert next prayer time to DateTime with today's date for correct difference calculation
      final nextPrayerDateTime = DateTime(
        now.year, 
        now.month, 
        allPassed ? now.day + 1 : now.day,
        nextPrayerTime!.hour,
        nextPrayerTime!.minute
      );
      
      final difference = nextPrayerDateTime.difference(now);
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;

      // More human-readable remaining time format
      String remainingTimeText;
      if (hours > 0) {
        remainingTimeText = '$hours hr $minutes min remaining';
      } else {
        remainingTimeText = '$minutes min remaining';
      }

      return {
        'name': nextPrayer,
        'time': _format12Hour(nextPrayerTime),
        'remaining': remainingTimeText,
      };
    }

    return null;
  }

  // Change calculation method
  void setCalculationMethod(int methodIndex) {
    if (methodIndex >= 0 && methodIndex < calculationMethodNames.length) {
      _calculationMethod = methodIndex;

      // Recalculate prayer times if we have coordinates
      if (_coordinates != null) {
        calculatePrayerTimes(_coordinates!.latitude, _coordinates!.longitude);
      }
    }
  }

  // Format time to 12-hour format with AM/PM
  String _format12Hour(DateTime? time) {
    if (time == null) return '-- : --';
    return DateFormat('h:mm a').format(time);
  }

  // Get formatted prayer times in 12-hour format
  String get formattedFajr => _format12Hour(fajrTime);
  String get formattedSunrise => _format12Hour(sunriseTime);
  String get formattedDhuhr => _format12Hour(dhuhrTime);
  String get formattedAsr => _format12Hour(asrTime);
  String get formattedMaghrib => _format12Hour(maghribTime);
  String get formattedIsha => _format12Hour(ishaTime);
}