import 'package:mishkat_core/mishkat_core.dart';
import 'package:test/test.dart';

void main() {
  const calendar = HijriCalendar();

  group('التقويم الهجري', () {
    test('تحويلات مرجعية', () {
      expect(calendar.fromGregorian(2024, 1, 1).toString(), '1445-6-19');
      expect(calendar.fromGregorian(2026, 11, 27).toString(), '1448-6-16');
      expect(calendar.fromGregorian(2030, 1, 1).toString(), '1451-8-25');
    });

    test('إزاحة رؤية الهلال ±2 يوم', () {
      final base = calendar.fromGregorian(2026, 11, 27);
      expect(calendar.fromGregorian(2026, 11, 27, moonSightingOffset: 1).day,
          base.day + 1);
      expect(calendar.fromGregorian(2026, 11, 27, moonSightingOffset: -2).day,
          base.day - 2);
    });

    test('رفض إزاحة خارج النطاق', () {
      expect(
        () => calendar.fromGregorian(2026, 11, 27, moonSightingOffset: 3),
        throwsArgumentError,
      );
    });

    test('الأيام البيض والاثنين والخميس', () {
      expect(
          calendar.isWhiteDay(const HijriDate(year: 1448, month: 6, day: 13)),
          isTrue);
      expect(
          calendar.isWhiteDay(const HijriDate(year: 1448, month: 6, day: 15)),
          isTrue);
      expect(
          calendar.isWhiteDay(const HijriDate(year: 1448, month: 6, day: 12)),
          isFalse);
      expect(calendar.isMondayOrThursday(DateTime(2026, 11, 30)), isTrue);
      expect(calendar.isMondayOrThursday(DateTime(2026, 11, 29)), isFalse);
    });
  });
}
