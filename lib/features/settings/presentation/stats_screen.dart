import 'package:flutter/material.dart';
import 'package:mishkat/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/advanced_providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final stats = ref.watch(statsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.stats)),
      body: stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('$error')),
        data: (value) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              title: Text(l10n.khatmahProgress),
              trailing: Text('${value.units}'),
            ),
            ListTile(
              title: Text(l10n.recentRevision),
              trailing: Text('${value.attempts}'),
            ),
            ListTile(
              title: Text(l10n.averageAccuracy),
              trailing: Text('${value.averageAccuracy.toStringAsFixed(1)}%'),
            ),
            ListTile(
              title: Text(l10n.pagesRead),
              trailing: Text('${value.pagesRead}'),
            ),
          ],
        ),
      ),
    );
  }
}
