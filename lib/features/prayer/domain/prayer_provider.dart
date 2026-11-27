import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mishkat_core/mishkat_core.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../app/providers.dart';

const prayerTimesService = PrayerTimesService();

/// الإحداثيات لا تُرسل لأي خادم — تأتي من قائمة مدن محلية.
final coordinatesProvider =
    Provider<({double latitude, double longitude})?>((ref) {
      final city = ref.watch(selectedCityProvider);
      return (latitude: city.latitude, longitude: city.longitude);
    });

final timeZoneNameProvider = Provider<String>((ref) {
  return ref.watch(selectedCityProvider).timeZone;
});

final dailyPrayersProvider = Provider<DailyPrayers?>((ref) {
  final coordinates = ref.watch(coordinatesProvider);
  if (coordinates == null) return null;
  final method = ref.watch(calculationMethodProvider);
  final asr = ref.watch(asrJurisprudenceProvider);
  final zone = ref.watch(timeZoneNameProvider);
  tz.Location location;
  try {
    location = tz.getLocation(zone);
  } catch (_) {
    return null;
  }
  return prayerTimesService.calculate(
    date: tz.TZDateTime.now(location),
    latitude: coordinates.latitude,
    longitude: coordinates.longitude,
    method: method,
    asr: asr,
  );
});

final qiblaBearingProvider = Provider<double?>((ref) {
  final coordinates = ref.watch(coordinatesProvider);
  if (coordinates == null) return null;
  return const QiblaCalculator()
      .calculate(coordinates.latitude, coordinates.longitude)
      .bearingDegrees;
});
