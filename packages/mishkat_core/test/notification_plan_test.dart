import 'package:mishkat_core/mishkat_core.dart';
import 'package:test/test.dart';

void main() {
  const plan = NotificationPlan();
  final start = DateTime(2026, 11, 27);

  Map<PrayerName, DateTime> timesForDay(DateTime day) => {
        PrayerName.fajr: DateTime(day.year, day.month, day.day, 5),
        PrayerName.sunrise: DateTime(day.year, day.month, day.day, 6, 30),
        PrayerName.dhuhr: DateTime(day.year, day.month, day.day, 12),
        PrayerName.asr: DateTime(day.year, day.month, day.day, 15),
        PrayerName.maghrib: DateTime(day.year, day.month, day.day, 17, 30),
        PrayerName.isha: DateTime(day.year, day.month, day.day, 19),
      };

  group('جدولة الإشعارات', () {
    test('57 إشعاراً داخل سقف iOS', () {
      final slots = plan.build(
        startDate: start,
        timesForDay: timesForDay,
        iqamahMinutes: {for (final p in PrayerName.values) p: 15},
      );
      expect(slots.length, NotificationPlan.plannedSlotCount);
      expect(slots.length, 57);
      expect(plan.fitsIosCap, isTrue);
      expect(slots.length, lessThanOrEqualTo(NotificationPlan.iosPendingCap));
    });

    test('كل المفاتيح فريدة', () {
      final slots = plan.build(
        startDate: start,
        timesForDay: timesForDay,
        iqamahMinutes: {for (final p in PrayerName.values) p: 15},
      );
      expect(slots.map((s) => s.key).toSet().length, slots.length);
    });

    test('التذكير المسبق قبل الأذان بـ 15 دقيقة', () {
      final slots = plan.build(
        startDate: start,
        timesForDay: timesForDay,
      );
      final adhan = slots.firstWhere(
        (s) => s.key == 'adhan:20261127:fajr',
      );
      final pre = slots.firstWhere((s) => s.key == 'pre:20261127:fajr');
      expect(adhan.fireAt.difference(pre.fireAt), const Duration(minutes: 15));
    });

    test('التعديل اليدوي ±15 دقيقة ينعكس على الأذان', () {
      final slots = plan.build(
        startDate: start,
        timesForDay: timesForDay,
        minuteOffsets: {PrayerName.fajr: -15},
      );
      final adhan = slots.firstWhere(
        (s) => s.key == 'adhan:20261127:fajr',
      );
      expect(adhan.fireAt, DateTime(2026, 11, 27, 4, 45));
    });

    test('أذكار الصباح بعد الفجر بـ 15 دقيقة', () {
      final slots = plan.build(
        startDate: start,
        timesForDay: timesForDay,
      );
      final morning = slots.firstWhere(
        (s) => s.key == 'athkar:20261127:morning',
      );
      expect(morning.fireAt, DateTime(2026, 11, 27, 5, 15));
    });

    test('طابور سبعة أيام', () {
      final slots = plan.build(
        startDate: start,
        timesForDay: timesForDay,
      );
      final adhans = slots.where((s) => s.kind == NotificationKind.adhan);
      expect(adhans.length, 42);
      expect(adhans.last.fireAt.day, 3);
    });
  });
}
