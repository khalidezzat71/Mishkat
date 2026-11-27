import 'prayer_times.dart';

enum NotificationKind { adhan, preReminder, iqamah, athkar }

class NotificationSlot {
  const NotificationSlot({
    required this.key,
    required this.kind,
    required this.fireAt,
    required this.prayer,
  });

  final String key;
  final NotificationKind kind;
  final DateTime fireAt;
  final PrayerName? prayer;
}

/// طابور الإشعارات المتجدد — مصمّم ليناسب سقف iOS البالغ 64 إشعاراً.
class NotificationPlan {
  const NotificationPlan();

  static const int iosPendingCap = 64;
  static const int adhanRollingDays = 7;
  static const int preReminderMinutes = 15;
  static const int athkarCount = 3;

  /// 42 أذان + 6 تذكير مسبق + 6 إقامة + 3 أذكار = 57 إشعاراً.
  static const int plannedSlotCount =
      adhanRollingDays * 6 + 6 + 6 + athkarCount;

  bool get fitsIosCap => plannedSlotCount <= iosPendingCap;

  List<NotificationSlot> build({
    required DateTime startDate,
    required Map<PrayerName, DateTime> Function(DateTime day) timesForDay,
    Map<PrayerName, int> minuteOffsets = const {},
    Map<PrayerName, int> iqamahMinutes = const {},
  }) {
    final slots = <NotificationSlot>[];

    for (var d = 0; d < adhanRollingDays; d++) {
      final day = DateTime(startDate.year, startDate.month, startDate.day + d);
      final times = timesForDay(day);
      final dateKey = '${day.year}${_two(day.month)}${_two(day.day)}';
      for (final prayer in PrayerName.values) {
        final base = times[prayer] ?? day;
        final offset = minuteOffsets[prayer] ?? 0;
        final fireAt = base.add(Duration(minutes: offset));
        slots.add(
          NotificationSlot(
            key: 'adhan:$dateKey:${prayer.name}',
            kind: NotificationKind.adhan,
            fireAt: fireAt,
            prayer: prayer,
          ),
        );

        // التذكيرات المساندة تُجدول ليوم واحد فقط لتجنّب تجاوز سقف iOS.
        if (d == 0) {
          slots.add(
            NotificationSlot(
              key: 'pre:$dateKey:${prayer.name}',
              kind: NotificationKind.preReminder,
              fireAt: fireAt.subtract(Duration(minutes: preReminderMinutes)),
              prayer: prayer,
            ),
          );
          final iqamah = iqamahMinutes[prayer];
          if (iqamah != null) {
            slots.add(
              NotificationSlot(
                key: 'iqamah:$dateKey:${prayer.name}',
                kind: NotificationKind.iqamah,
                fireAt: fireAt.add(Duration(minutes: iqamah)),
                prayer: prayer,
              ),
            );
          }
        }
      }

      if (d == 0) {
        final fajr = times[PrayerName.fajr] ?? day;
        final asr = times[PrayerName.asr] ?? day;
        slots.add(
          NotificationSlot(
            key: 'athkar:$dateKey:morning',
            kind: NotificationKind.athkar,
            fireAt: fajr.add(const Duration(minutes: 15)),
            prayer: PrayerName.fajr,
          ),
        );
        slots.add(
          NotificationSlot(
            key: 'athkar:$dateKey:evening',
            kind: NotificationKind.athkar,
            fireAt: asr.add(const Duration(minutes: 15)),
            prayer: PrayerName.asr,
          ),
        );
        slots.add(
          NotificationSlot(
            key: 'athkar:$dateKey:sleep',
            kind: NotificationKind.athkar,
            fireAt: DateTime(day.year, day.month, day.day, 22),
            prayer: null,
          ),
        );
      }
    }
    return slots;
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}
