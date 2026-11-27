import 'dart:convert';

/// بيانات شاشة القفل/اليدجت — تُرسل من Dart إلى Glance/WidgetKit عبر home_widget.
class WidgetPayload {
  const WidgetPayload({
    required this.nextPrayerKey,
    required this.nextPrayerTime,
    required this.minutesRemaining,
    required this.hijriLabel,
    required this.qiblaBearing,
    required this.updatedAt,
  });

  final String nextPrayerKey;
  final String nextPrayerTime;
  final int minutesRemaining;
  final String hijriLabel;
  final double qiblaBearing;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
    'nextPrayerKey': nextPrayerKey,
    'nextPrayerTime': nextPrayerTime,
    'minutesRemaining': minutesRemaining,
    'hijriLabel': hijriLabel,
    'qiblaBearing': qiblaBearing.round(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  String toJson() => jsonEncode(toMap());

  /// حجم البيانات صغير جداً لتفادي حدود UserDefaults/SharedPreferences.
  int get byteLength => utf8.encode(toJson()).length;
}
