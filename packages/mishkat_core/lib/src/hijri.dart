/// تقويم هجري مدني خالص (خوارزمية الكويت) بدون إنترنت.
///
/// يمكن تعديل الناتج بـ ±2 يوم لمطابقة رؤية الهلال المحلية.
class HijriDate {
  const HijriDate({required this.year, required this.month, required this.day});

  final int year;
  final int month;
  final int day;

  @override
  String toString() => '$year-$month-$day';

  @override
  bool operator ==(Object other) =>
      other is HijriDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);
}

class HijriCalendar {
  const HijriCalendar();

  /// تحويل تاريخ ميلادي إلى هجري مع إزاحة رؤية الهلال [-2..2].
  HijriDate fromGregorian(
    int year,
    int month,
    int day, {
    int moonSightingOffset = 0,
  }) {
    if (moonSightingOffset < -2 || moonSightingOffset > 2) {
      throw ArgumentError.value(
        moonSightingOffset,
        'moonSightingOffset',
        'must be between -2 and 2',
      );
    }
    final jd = _gregorianToJd(year, month, day) + moonSightingOffset;
    return _jdToHijri(jd);
  }

  /// هل اليوم من الأيام البيض (13، 14، 15 من الشهر الهجري)؟
  bool isWhiteDay(HijriDate date) => date.day >= 13 && date.day <= 15;

  /// هل اليوم الاثنين أو الخميس (2 أو 5 حسب ترقيم Dart: الأحد=1)؟
  bool isMondayOrThursday(DateTime date) =>
      date.weekday == DateTime.monday || date.weekday == DateTime.thursday;

  int _gregorianToJd(int year, int month, int day) {
    final a = (14 - month) ~/ 12;
    final y = year + 4800 - a;
    final m = month + 12 * a - 3;
    return day +
        (153 * m + 2) ~/ 5 +
        365 * y +
        y ~/ 4 -
        y ~/ 100 +
        y ~/ 400 -
        32045;
  }

  HijriDate _jdToHijri(int jd) {
    var l = jd - 1948440 + 10632;
    final n = (l - 1) ~/ 10631;
    l = l - 10631 * n + 354;
    final j =
        ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) +
        (l ~/ 5670) * ((43 * l) ~/ 15238);
    l =
        l -
        ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
        (j ~/ 16) * ((15238 * j) ~/ 43) +
        29;
    final m = (24 * l) ~/ 709;
    final d = l - (709 * m) ~/ 24;
    final y = 30 * n + j - 30;
    return HijriDate(year: y, month: m, day: d);
  }
}
