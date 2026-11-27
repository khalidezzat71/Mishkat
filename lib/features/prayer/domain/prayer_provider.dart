import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mishkat_core/mishkat_core.dart';
import 'package:timezone/timezone.dart' as tz;

const prayerTimesService = PrayerTimesService();

/// الطرق السنية الخمس فقط.
final calculationMethodProvider = StateProvider<SunniCalculationMethod>(
  (ref) => SunniCalculationMethod.ummAlQura,
);

final asrJurisprudenceProvider = StateProvider<AsrJurisprudence>(
  (ref) => AsrJurisprudence.shafi,
);

/// الإحداثيات لا تُرسل لأي خادم — تأتي من GPS عند الطلب أو من قائمة مدن محلية.
final coordinatesProvider =
    StateProvider<({double latitude, double longitude})?>((ref) => null);

final timeZoneNameProvider = StateProvider<String>((ref) => 'Asia/Riyadh');

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
