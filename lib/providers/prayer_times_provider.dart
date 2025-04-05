import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';

class PrayerTimesProvider with ChangeNotifier {
  PrayerTimes? _prayerTimes;
  String _timeZoneName = '';
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
    final now = DateTime.now();
    final date = DateComponents(now.year, now.month, now.day);
    final params = _getCalculationParameters();

    // Get coordinates and timezone
    _coordinates = Coordinates(latitude, longitude); // Store coordinates
    _timeZoneName = now.timeZoneName;

    // Calculate prayer times
    _prayerTimes = PrayerTimes(_coordinates!, date, params);
    _lastCalculationDate = now;

    notifyListeners();
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

  // Get next prayer info with improved time formatting
  Map<String, dynamic>? getNextPrayer() {
    if (_prayerTimes == null || _coordinates == null) return null;

    final now = DateTime.now();

    // Get prayer times for today
    final prayers = {
      'Fajr': _prayerTimes!.fajr,
      'Dhuhr': _prayerTimes!.dhuhr,
      'Asr': _prayerTimes!.asr,
      'Maghrib': _prayerTimes!.maghrib,
      'Isha': _prayerTimes!.isha,
    };

    // Check if all prayers for today have passed
    bool allPassed = true;
    String nextPrayer = '';
    DateTime? nextPrayerTime;

    prayers.forEach((name, time) {
      if (time.isAfter(now)) {
        if (nextPrayerTime == null || time.isBefore(nextPrayerTime!)) {
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
      final difference = nextPrayerTime!.difference(now);
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