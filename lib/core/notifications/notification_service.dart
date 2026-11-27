import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mishkat_core/mishkat_core.dart';
import 'package:timezone/timezone.dart' as tz;

/// جدولة الإشعارات المحلية.
///
/// يعتمد على [NotificationPlan] في طبقة المنطق: 57 إشعاراً كحد أقصى،
/// ويُعاد بناؤها يومياً حتى لا يتجاوز طابور iOS سقف الـ 64.
class NotificationService {
  NotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const _channelId = 'mishkat_adhan';
  static const _channelName = 'Adhan';
  static const _channelDescription = 'Prayer times and reminders';

  Future<void> initialize({void Function(NotificationResponse)? onTap}) async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: onTap,
    );
  }

  Future<bool> requestPermissions() async {
    final android = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    final ios = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return (android ?? false) || (ios ?? false);
  }

  Future<void> scheduleAll(List<NotificationSlot> slots) async {
    await _plugin.cancelAll();
    for (final slot in slots) {
      await zonedSchedule(slot);
    }
  }

  Future<void> zonedSchedule(NotificationSlot slot) async {
    final id = _stableId(slot.key);
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    await _plugin.zonedSchedule(
      id,
      slot.kind.name,
      slot.key,
      tz.TZDateTime.from(slot.fireAt, tz.local),
      const NotificationDetails(android: androidDetails, iOS: darwinDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: slot.key,
    );
  }

  /// المفاتيح النصية تُحوَّل إلى معرّف عددى ثابت داخل نطاق 32-بت.
  int _stableId(String key) => key.codeUnits.fold<int>(
    0,
    (hash, code) => ((hash * 31) + code) & 0x7fffffff,
  );
}
