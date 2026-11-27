import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mishkat/core/settings/opt_in_providers.dart';
import 'package:mishkat/l10n/generated/app_localizations.dart';
import 'package:mishkat_core/mishkat_core.dart';

import '../../../app/advanced_providers.dart';
import '../../../app/providers.dart';
import '../domain/prayer_provider.dart';

class PrayerScreen extends ConsumerStatefulWidget {
  const PrayerScreen({super.key});

  @override
  ConsumerState<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends ConsumerState<PrayerScreen> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setState(() => _now = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _prayerName(AppLocalizations l10n, PrayerName name) => switch (name) {
    PrayerName.fajr => l10n.prayerFajr,
    PrayerName.sunrise => l10n.prayerSunrise,
    PrayerName.dhuhr => l10n.prayerDhuhr,
    PrayerName.asr => l10n.prayerAsr,
    PrayerName.maghrib => l10n.prayerMaghrib,
    PrayerName.isha => l10n.prayerIsha,
  };

  String _time(DateTime value) => TimeOfDay.fromDateTime(value).format(context);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prayers = ref.watch(dailyPrayersProvider);
    final bearing = ref.watch(qiblaBearingProvider);
    final city = ref.watch(selectedCityProvider);

    if (prayers == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.navPrayer),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: l10n.prayerSettings,
              onPressed: () => context.push('/prayer-settings'),
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time, size: 56),
                const SizedBox(height: 16),
                Text(l10n.noPrayerTimes, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.push('/prayer-settings'),
                  child: Text(l10n.prayerSettings),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final next = prayers.nextPrayer(_now);
    final remaining = prayers.timeUntilNext(_now).inMinutes;
    final hijri = const HijriCalendar()
        .fromGregorian(_now.year, _now.month, _now.day)
        .toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navPrayer),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.prayerSettings,
            onPressed: () => context.push('/prayer-settings'),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.nextPrayer,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _prayerName(l10n, next),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${l10n.timeRemaining}: ${remaining ~/ 60}:'
                        '${(remaining % 60).toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${l10n.selectCity}: ${city.label(l10n.localeName == 'ar')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${l10n.hijriDate}: $hijri',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.prayerTimesTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    for (final name in PrayerName.values)
                      ListTile(
                        leading: Icon(
                          name == next
                              ? Icons.access_time_filled
                              : Icons.access_time_outlined,
                          color: name == next
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        title: Text(_prayerName(l10n, name)),
                        trailing: Text(_time(prayers.timeOf(name))),
                        selected: name == next,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (bearing != null)
                Card(
                  child: ListTile(
                    leading: Transform.rotate(
                      angle: bearing * math.pi / 180,
                      child: const Icon(Icons.navigation),
                    ),
                    title: Text(l10n.qiblaDirection),
                    subtitle: Text(
                      '${bearing.round()}° — ${l10n.qiblaCalibrationWarning}',
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                l10n.notificationsDesc,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const _SurfaceBridge(),
        ],
      ),
    );
  }
}

/// يرسل بيانات الصلاة إلى اليدجت والساعة فقط بعد تفعيل OptIn.
class _SurfaceBridge extends ConsumerStatefulWidget {
  const _SurfaceBridge();

  @override
  ConsumerState<_SurfaceBridge> createState() => _SurfaceBridgeState();
}

class _SurfaceBridgeState extends ConsumerState<_SurfaceBridge> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _publish());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(dailyPrayersProvider, (_, __) => _publish());
    ref.listen(qiblaBearingProvider, (_, __) => _publish());
    ref.listen(optInProvider(OptInKey.widget), (_, __) => _publish());
    ref.listen(optInProvider(OptInKey.watch), (_, __) => _publish());
    return const SizedBox.shrink();
  }

  Future<void> _publish() async {
    final prayers = ref.read(dailyPrayersProvider);
    if (prayers == null) return;
    final now = DateTime.now();
    final next = prayers.nextPrayer(now);
    final remaining = prayers.timeUntilNext(now).inMinutes;
    final hijri = const HijriCalendar()
        .fromGregorian(now.year, now.month, now.day)
        .toString();
    final bearing = ref.read(qiblaBearingProvider) ?? 0.0;

    if (ref.read(optInProvider(OptInKey.widget))) {
      await ref
          .read(widgetServiceProvider)
          .update(
            WidgetPayload(
              nextPrayerKey: next.name,
              nextPrayerTime: prayers.timeOf(next).toString().substring(11, 16),
              minutesRemaining: remaining,
              hijriLabel: hijri,
              qiblaBearing: bearing,
              updatedAt: now,
            ),
          );
    }
    if (ref.read(optInProvider(OptInKey.watch))) {
      await ref
          .read(watchServiceProvider)
          .send(
            WatchMessage(
              command: WatchCommand.nextPrayer,
              titleKey: 'nextPrayer',
              value: prayers.timeOf(next).toString().substring(11, 16),
              sentAt: now,
            ),
          );
    }
  }
}
