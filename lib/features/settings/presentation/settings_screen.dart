import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        children: [
          ListTile(
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
          ListTile(title: Text(l10n.themeLayout)),
          ListTile(title: Text(l10n.notifications)),
          ListTile(
            title: Text(l10n.advancedSettings),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => context.push('/advanced'),
          ),
          ListTile(
            title: Text(l10n.sourcesAndAttribution),
            onTap: () => context.push('/sources'),
          ),
          ListTile(title: Text(l10n.sunniOnlyPolicy)),
          ListTile(title: Text(l10n.freeSourcesPolicy)),
          ListTile(title: Text(l10n.backup)),
          ListTile(
            title: Text(l10n.about),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => context.push('/diagnostics'),
          ),
        ],
      ),
    );
  }
}
