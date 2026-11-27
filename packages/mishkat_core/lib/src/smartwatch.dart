import 'dart:convert';

enum WatchCommand { nextPrayer, qibla, hifzReminder, athkar }

/// رسالة مختصرة إلى الساعة الذكية (Wear OS / watchOS).
class WatchMessage {
  const WatchMessage({
    required this.command,
    required this.titleKey,
    required this.value,
    required this.sentAt,
  });

  final WatchCommand command;
  final String titleKey;
  final String value;
  final DateTime sentAt;

  Map<String, dynamic> toMap() => {
        'command': command.name,
        'titleKey': titleKey,
        'value': value,
        'sentAt': sentAt.toUtc().toIso8601String(),
      };

  String toJson() => jsonEncode(toMap());
}

/// يمنع إرسال بيانات تتجاوز حدود BLE/Wearable.
class WatchPayloadGuard {
  const WatchPayloadGuard({this.maxBytes = 512});

  final int maxBytes;

  bool accepts(WatchMessage message) =>
      utf8.encode(message.toJson()).length <= maxBytes;
}
