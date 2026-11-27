import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mishkat/core/settings/opt_in_providers.dart';
import 'package:mishkat_core/mishkat_core.dart';

import '../../../app/advanced_providers.dart';
import '../domain/prayer_provider.dart';

class PrayerScreen extends ConsumerWidget {
  const PrayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navPrayer)),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time, size: 64),
                const SizedBox(height: 16),
                Text(
                  l10n.nextPrayer,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(l10n.commonOffline),
              ],
            ),
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
