import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mishkat/core/settings/opt_in_providers.dart';

import '../../../app/advanced_providers.dart';

class AdvancedSettingsScreen extends ConsumerWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.advancedSettings)),
      body: ListView(
        children: [
          _tile(ref, OptInKey.tafsir, l10n.optInTafsir, l10n.optInTafsirDesc),
          _tile(
            ref,
            OptInKey.wordSync,
            l10n.optInWordSync,
            l10n.optInWordSyncDesc,
          ),
          _tile(ref, OptInKey.gaze, l10n.optInGaze, l10n.optInGazeDesc),
          _tile(
            ref,
            OptInKey.grading,
            l10n.optInGrading,
            l10n.optInGradingDesc,
          ),
          _tile(ref, OptInKey.widget, l10n.optInWidget, ''),
          _tile(ref, OptInKey.watch, l10n.optInWatch, ''),
          const Divider(),
          ListTile(
            title: Text(l10n.reciters),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => context.push('/reciters'),
          ),
          ListTile(
            title: Text(l10n.stats),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => context.push('/stats'),
          ),
          ListTile(
            title: Text(l10n.backup),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => context.push('/backup'),
          ),
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

  Widget _tile(WidgetRef ref, OptInKey key, String title, String subtitle) {
    return SwitchListTile(
      title: Text(title),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      value: ref.watch(optInProvider(key)),
      onChanged: (value) async {
        await setOptIn(ref, key, value);
        if (key == OptInKey.gaze && value) {
          final granted = await ref
              .read(gazeControllerProvider)
              .enable(ref.read(gazeSourceProvider));
          if (!granted && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.gazePermissionDenied,
                ),
              ),
            );
          }
        }
      },
    );
  }
}
