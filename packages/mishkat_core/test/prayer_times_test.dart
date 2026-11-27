import 'package:mishkat_core/mishkat_core.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

String hhmm(DateTime time, tz.Location location) {
  final local = tz.TZDateTime.from(time, location);
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

void main() {
  setUpAll(() => tzdata.initializeTimeZones());

  const service = PrayerTimesService();

  group('المواقيت — مرجع adhan-js', () {
    test('ISNA + حنفي — رالي 2015-07-12', () {
      final location = tz.getLocation('America/New_York');
      final prayers = service.calculate(
        date: tz.TZDateTime(location, 2015, 7, 12),
        latitude: 35.775,
        longitude: -78.6336,
        method: SunniCalculationMethod.isna,
        asr: AsrJurisprudence.hanafi,
      );
      expect(hhmm(prayers.fajr, location), '04:42');
      expect(hhmm(prayers.sunrise, location), '06:08');
      expect(hhmm(prayers.dhuhr, location), '13:21');
      expect(hhmm(prayers.asr, location), '18:22');
      expect(hhmm(prayers.maghrib, location), '20:32');
      expect(hhmm(prayers.isha, location), '21:57');
    });

    test('MWL + شافعي — رالي 2015-12-01', () {
      final location = tz.getLocation('America/New_York');
      final prayers = service.calculate(
        date: tz.TZDateTime(location, 2015, 12, 1),
        latitude: 35.775,
        longitude: -78.6336,
        method: SunniCalculationMethod.muslimWorldLeague,
      );
      expect(hhmm(prayers.fajr, location), '05:35');
      expect(hhmm(prayers.sunrise, location), '07:06');
      expect(hhmm(prayers.dhuhr, location), '12:05');
      expect(hhmm(prayers.asr, location), '14:42');
      expect(hhmm(prayers.maghrib, location), '17:01');
      expect(hhmm(prayers.isha, location), '18:26');
    });

    test('الطرق الخمس السنية فقط', () {
      expect(SunniCalculationMethod.values.length, 5);
      expect(
        SunniCalculationMethod.values.map((m) => m.name),
        isNot(contains('jafari')),
      );
      expect(
        SunniCalculationMethod.values.map((m) => m.name),
        isNot(contains('tehran')),
      );
    });

    test('الطرق غير المعتمدة غير معروضة', () {
      expect(SunniCalculationMethod.values.map((m) => m.name),
          isNot(contains('algerian')));
    });
  });

  group('الصلاة القادمة', () {
    final prayers = DailyPrayers(
      fajr: DateTime(2026, 11, 27, 5),
      sunrise: DateTime(2026, 11, 27, 6, 30),
      dhuhr: DateTime(2026, 11, 27, 12),
      asr: DateTime(2026, 11, 27, 15),
      maghrib: DateTime(2026, 11, 27, 17, 30),
      isha: DateTime(2026, 11, 27, 19),
    );

    test('قبل الفجر', () {
      expect(prayers.nextPrayer(DateTime(2026, 11, 27, 4)), PrayerName.fajr);
    });

    test('بين المغرب والعشاء', () {
      expect(prayers.nextPrayer(DateTime(2026, 11, 27, 18)), PrayerName.isha);
    });

    test('بعد العشاء يعود لفجر الغد', () {
      final now = DateTime(2026, 11, 27, 23);
      expect(prayers.nextPrayer(now), PrayerName.fajr);
      expect(prayers.timeUntilNext(now), const Duration(hours: 6));
    });
  });
}
