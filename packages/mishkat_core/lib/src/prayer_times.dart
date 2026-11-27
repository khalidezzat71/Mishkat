import 'package:adhan_dart/adhan_dart.dart';
import 'package:timezone/timezone.dart' as tz;

/// الطرق الفلكية السنية الخمس المدعومة فقط.
///
/// لا تُعرَض طرق أخرى (مثل الجعفرية/طهران) التزاماً بسياسة المرجعية السنية.
enum SunniCalculationMethod {
  ummAlQura,
  muslimWorldLeague,
  egyptian,
  karachi,
  isna;

  CalculationParameters get parameters => switch (this) {
        SunniCalculationMethod.ummAlQura =>
          CalculationMethodParameters.ummAlQura(),
        SunniCalculationMethod.muslimWorldLeague =>
          CalculationMethodParameters.muslimWorldLeague(),
        SunniCalculationMethod.egyptian =>
          CalculationMethodParameters.egyptian(),
        SunniCalculationMethod.karachi => CalculationMethodParameters.karachi(),
        SunniCalculationMethod.isna =>
          CalculationMethodParameters.northAmerica(),
      };
}

/// مذهب العصر.
enum AsrJurisprudence { shafi, hanafi }

/// أسماء المواقيت الستة.
enum PrayerName { fajr, sunrise, dhuhr, asr, maghrib, isha }

/// مواقيت يوم كامل محسوبة محلياً دون إنترنت.
class DailyPrayers {
  const DailyPrayers({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  DateTime timeOf(PrayerName name) => switch (name) {
        PrayerName.fajr => fajr,
        PrayerName.sunrise => sunrise,
        PrayerName.dhuhr => dhuhr,
        PrayerName.asr => asr,
        PrayerName.maghrib => maghrib,
        PrayerName.isha => isha,
      };

  /// الصلاة القادمة بعد [now] (الفجر في اليوم التالي إن لزم).
  PrayerName nextPrayer(DateTime now) {
    for (final name in PrayerName.values) {
      if (timeOf(name).isAfter(now)) return name;
    }
    return PrayerName.fajr;
  }

  Duration timeUntilNext(DateTime now) {
    final next = nextPrayer(now);
    final target = timeOf(next);
    if (next == PrayerName.fajr && target.isBefore(now)) {
      return target.add(const Duration(days: 1)).difference(now);
    }
    return target.difference(now);
  }
}

class PrayerTimesService {
  const PrayerTimesService();

  DailyPrayers calculate({
    required tz.TZDateTime date,
    required double latitude,
    required double longitude,
    required SunniCalculationMethod method,
    AsrJurisprudence asr = AsrJurisprudence.shafi,
  }) {
    final params = method.parameters;
    params.madhab =
        asr == AsrJurisprudence.hanafi ? Madhab.hanafi : Madhab.shafi;
    final times = PrayerTimes(
      coordinates: Coordinates(latitude, longitude),
      date: date,
      calculationParameters: params,
    );
    final location = date.location;
    return DailyPrayers(
      fajr: tz.TZDateTime.from(times.fajr, location),
      sunrise: tz.TZDateTime.from(times.sunrise, location),
      dhuhr: tz.TZDateTime.from(times.dhuhr, location),
      asr: tz.TZDateTime.from(times.asr, location),
      maghrib: tz.TZDateTime.from(times.maghrib, location),
      isha: tz.TZDateTime.from(times.isha, location),
    );
  }
}
