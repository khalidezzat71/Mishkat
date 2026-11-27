import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../features/prayer/domain/notification_schedule_provider.dart';
import 'providers.dart';
import 'router.dart';

/// يُهيّئ الإشعارات ويبني طابور اليوم عند التشغيل وعند العودة للتطبيق.
/// يعمل محلياً بالكامل؛ لا تُرسل أي بيانات للشبكة.
class NotificationBootstrap extends ConsumerStatefulWidget {
  const NotificationBootstrap({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<NotificationBootstrap> createState() =>
      _NotificationBootstrapState();
}

class _NotificationBootstrapState extends ConsumerState<NotificationBootstrap>
    with WidgetsBindingObserver {
  DateTime? _lastScheduledDay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _scheduleIfNeeded(force: true);
  }

  Future<void> _bootstrap() async {
    final service = ref.read(notificationServiceProvider);
    await service.initialize(
      onTap: (response) {
        final route = response.payload;
        if (route != null && route.startsWith('/')) {
          appRouter.go(route);
        }
      },
    );

    final city = ref.read(selectedCityProvider);
    try {
      tz.setLocalLocation(tz.getLocation(city.timeZone));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    if (ref.read(notificationsEnabledProvider)) {
      await service.requestPermissions();
    }
    await _scheduleIfNeeded(force: true);
  }

  Future<void> _scheduleIfNeeded({bool force = false}) async {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    if (!force && _lastScheduledDay == day) return;

    final city = ref.read(selectedCityProvider);
    try {
      tz.setLocalLocation(tz.getLocation(city.timeZone));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    final service = ref.read(notificationServiceProvider);
    if (!ref.read(notificationsEnabledProvider)) {
      await service.cancelAll();
      _lastScheduledDay = day;
      return;
    }

    await service.scheduleAll(ref.read(notificationSlotsProvider));
    _lastScheduledDay = day;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(notificationsEnabledProvider, (_, __) => _scheduleIfNeeded());
    ref.listen(selectedCityIdProvider, (_, __) => _scheduleIfNeeded());
    ref.listen(selectedCityProvider, (_, __) => _scheduleIfNeeded());
    ref.listen(calculationMethodProvider, (_, __) => _scheduleIfNeeded());
    ref.listen(asrJurisprudenceProvider, (_, __) => _scheduleIfNeeded());
    return widget.child;
  }
}
