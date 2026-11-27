import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mishkat_core/mishkat_core.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../app/providers.dart';
import 'prayer_provider.dart';

/// طابور الإشعارات المحلي: 57 إشعاراً كحد أقصى، يُعاد بناؤه عند كل تشغيل
/// وعند تغيير المدينة أو طريقة الحساب، دون أي اتصال شبكي.
final notificationSlotsProvider = Provider<List<NotificationSlot>>((ref) {
  final prayers = ref.watch(dailyPrayersProvider);
  final coordinates = ref.watch(coordinatesProvider);
  if (prayers == null || coordinates == null) {
    return const <NotificationSlot>[];
  }

  final method = ref.watch(calculationMethodProvider);
  final asr = ref.watch(asrJurisprudenceProvider);
  final zoneName = ref.watch(timeZoneNameProvider);
  tz.Location zone;
  try {
    zone = tz.getLocation(zoneName);
  } catch (_) {
    return const <NotificationSlot>[];
  }

  final now = tz.TZDateTime.now(zone);
  final start = DateTime(now.year, now.month, now.day);
  final slots = const NotificationPlan().build(
    startDate: start,
    timesForDay: (day) {
      final calculated = prayerTimesService.calculate(
        date: tz.TZDateTime.from(day, zone),
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        method: method,
        asr: asr,
      );
      return {
        for (final name in PrayerName.values)
          name: calculated.timeOf(name),
      };
    },
    minuteOffsets: const {},
    iqamahMinutes: const {
      PrayerName.fajr: 15,
      PrayerName.sunrise: 15,
      PrayerName.dhuhr: 15,
      PrayerName.asr: 15,
      PrayerName.maghrib: 15,
      PrayerName.isha: 15,
    },
  );
  return slots.where((slot) => slot.fireAt.isAfter(now)).toList();
});
