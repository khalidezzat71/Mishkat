import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mishkat/core/theme_layouts/layout_registry.dart';
import 'package:mishkat/l10n/generated/app_localizations.dart';
import 'package:mishkat_core/mishkat_core.dart';

import '../../../app/providers.dart';
import '../../quran/presentation/quran_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _layoutLabel(AppLocalizations l10n, String key) => switch (key) {
    'layoutClassicMushaf' => l10n.layoutClassicMushaf,
    'layoutBento' => l10n.layoutBento,
    'layoutKalaRadial' => l10n.layoutKalaRadial,
    'layoutTahajjudOled' => l10n.layoutTahajjudOled,
    'layoutMihrabGlass' => l10n.layoutMihrabGlass,
    'layoutPillarsZen' => l10n.layoutPillarsZen,
    'layoutQuranCompact' => l10n.layoutQuranCompact,
    'layoutTarteelEditorial' => l10n.layoutTarteelEditorial,
    'layoutNusukAccessible' => l10n.layoutNusukAccessible,
    'layoutMaterialYou' => l10n.layoutMaterialYou,
    _ => l10n.layoutClassicMushaf,
  };

  String _mushafSourceLabel(AppLocalizations l10n, QuranTextSource source) =>
      switch (source) {
        QuranTextSource.tanzilUthmani => l10n.mushafSourceTanzil,
        QuranTextSource.quranComUthmani => l10n.mushafSourceQuranCom,
      };

  String _themeLabel(AppLocalizations l10n, ThemeMode mode) => switch (mode) {
    ThemeMode.system => l10n.themeSystem,
    ThemeMode.light => l10n.themeLight,
    ThemeMode.dark => l10n.themeDark,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final layoutId = ref.watch(layoutIdProvider);
    final mushafSource = ref.watch(mushafSourceProvider);
    final layout = kLayouts.firstWhere(
      (item) => item.id == layoutId,
      orElse: () => kLayouts.first,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: Text(l10n.language),
            subtitle: Text(locale?.languageCode ?? 'ar'),
            trailing: DropdownButton<Locale>(
              value: locale ?? const Locale('ar'),
              items: const [
                DropdownMenuItem(value: Locale('ar'), child: Text('العربية')),
                DropdownMenuItem(value: Locale('en'), child: Text('English')),
                DropdownMenuItem(value: Locale('fr'), child: Text('Français')),
                DropdownMenuItem(value: Locale('ur'), child: Text('اردو')),
                DropdownMenuItem(
                  value: Locale('id'),
                  child: Text('Bahasa Indonesia'),
                ),
              ],
              onChanged: (value) {
                if (value != null) persistLocale(ref, value);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: Text(l10n.theme),
            subtitle: Text(_themeLabel(l10n, themeMode)),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              items: [
                for (final mode in ThemeMode.values)
                  DropdownMenuItem<ThemeMode>(
                    value: mode,
                    child: Text(_themeLabel(l10n, mode)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) persistThemeMode(ref, value);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: Text(l10n.themeLayout),
            subtitle: Text(_layoutLabel(l10n, layout.key)),
            trailing: DropdownButton<int>(
              value: layoutId,
              items: [
                for (final item in kLayouts)
                  DropdownMenuItem<int>(
                    value: item.id,
                    child: Text(_layoutLabel(l10n, item.key)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) persistLayout(ref, value);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: Text(l10n.mushafSource),
            subtitle: Text(_mushafSourceLabel(l10n, mushafSource)),
            trailing: DropdownButton<QuranTextSource>(
              value: mushafSource,
              items: [
                for (final source in QuranTextSource.values)
                  DropdownMenuItem<QuranTextSource>(
                    value: source,
                    child: Text(_mushafSourceLabel(l10n, source)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) persistMushafSource(ref, value);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.mushafSourceDesc,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (mushafSource.requiresNetwork)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.clearMushafCache),
              onTap: () async {
                await ref.read(databaseProvider).clearMushafTextCache();
                ref.invalidate(mushafPageProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.mushafCacheCleared)),
                  );
                }
              },
            ),
          ListTile(
            leading: const Icon(Icons.access_time_outlined),
            title: Text(l10n.prayerSettings),
            subtitle: Text(l10n.notificationsDesc),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => context.push('/prayer-settings'),
          ),
          ListTile(
            leading: const Icon(Icons.tune_outlined),
            title: Text(l10n.advancedSettings),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => context.push('/advanced'),
          ),
          ListTile(
            leading: const Icon(Icons.verified_outlined),
            title: Text(l10n.sourcesAndAttribution),
            onTap: () => context.push('/sources'),
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: Text(l10n.backup),
            onTap: () => context.push('/backup'),
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart_outlined),
            title: Text(l10n.stats),
            onTap: () => context.push('/stats'),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.sunniOnlyPolicy,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.sunniOnlyDesc,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.freeSourcesPolicy,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.aboutDesc,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                TextButton.icon(
                  onPressed: () => context.push('/diagnostics'),
                  icon: const Icon(Icons.info_outline),
                  label: Text(l10n.about),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
