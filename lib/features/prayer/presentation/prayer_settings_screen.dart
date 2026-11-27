import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mishkat/l10n/generated/app_localizations.dart';
import 'package:mishkat_core/mishkat_core.dart';

import '../../../app/providers.dart';
import '../domain/prayer_settings.dart';

class PrayerSettingsScreen extends ConsumerWidget {
  const PrayerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cities = ref.watch(prayerCityCatalogProvider);
    final city = ref.watch(selectedCityProvider);
    final method = ref.watch(calculationMethodProvider);
    final asr = ref.watch(asrJurisprudenceProvider);
    final notifications = ref.watch(notificationsEnabledProvider);

    final methodLabel = switch (method) {
      SunniCalculationMethod.ummAlQura => l10n.methodUmmAlQura,
      SunniCalculationMethod.muslimWorldLeague =>
        l10n.methodMuslimWorldLeague,
      SunniCalculationMethod.egyptian => l10n.methodEgyptian,
      SunniCalculationMethod.karachi => l10n.methodKarachi,
      SunniCalculationMethod.isna => l10n.methodIsna,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.prayerSettings)),
      body: ListView(
        padding: const EdgeInsets.only(top: 8),
        children: [
          ListTile(
            leading: const Icon(Icons.location_city_outlined),
            title: Text(l10n.selectCity),
            subtitle: Text(city.label(l10n.localeName == 'ar')),
            trailing: cities.when(
              loading: () => const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => Text(defaultPrayerCity.nameAr),
              data: (items) => DropdownButton<int>(
                value: city.id,
                items: [
                  for (final item in items)
                    DropdownMenuItem<int>(
                      value: item.id,
                      child: Text(item.label(l10n.localeName == 'ar')),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) persistCity(ref, value);
                },
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calculate_outlined),
            title: Text(l10n.calculationMethod),
            subtitle: Text(methodLabel),
            trailing: DropdownButton<SunniCalculationMethod>(
              value: method,
              items: [
                for (final item in SunniCalculationMethod.values)
                  DropdownMenuItem<SunniCalculationMethod>(
                    value: item,
                    child: Text(
                      switch (item) {
                        SunniCalculationMethod.ummAlQura =>
                          l10n.methodUmmAlQura,
                        SunniCalculationMethod.muslimWorldLeague =>
                          l10n.methodMuslimWorldLeague,
                        SunniCalculationMethod.egyptian => l10n.methodEgyptian,
                        SunniCalculationMethod.karachi => l10n.methodKarachi,
                        SunniCalculationMethod.isna => l10n.methodIsna,
                      },
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) persistCalculationMethod(ref, value);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.wb_sunny_outlined),
            title: Text(l10n.asrJurisprudence),
            trailing: DropdownButton<AsrJurisprudence>(
              value: asr,
              items: [
                DropdownMenuItem(
                  value: AsrJurisprudence.shafi,
                  child: Text(l10n.asrShafi),
                ),
                DropdownMenuItem(
                  value: AsrJurisprudence.hanafi,
                  child: Text(l10n.asrHanafi),
                ),
              ],
              onChanged: (value) {
                if (value != null) persistAsrJurisprudence(ref, value);
              },
            ),
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_none_outlined),
            title: Text(l10n.notificationsEnabled),
            subtitle: Text(l10n.notificationsDesc),
            value: notifications,
            onChanged: (value) => persistNotificationsEnabled(ref, value),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () async {
                final granted = await ref
                    .read(notificationServiceProvider)
                    .requestPermissions();
                if (!granted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.notificationPermissionDenied),
                    ),
                  );
                  return;
                }
                await ref
                    .read(notificationServiceProvider)
                    .showTest(l10n.appName, l10n.notificationTestSent);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.notificationTestSent)),
                  );
                }
              },
              icon: const Icon(Icons.notifications_active_outlined),
              label: Text(l10n.testNotification),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.sunniOnlyDesc,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
