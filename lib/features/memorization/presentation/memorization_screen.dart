import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mishkat/core/settings/opt_in_providers.dart';

import '../domain/hifz_providers.dart';

class MemorizationScreen extends ConsumerWidget {
  const MemorizationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final workload = ref.watch(todayWorkloadProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navMemorization)),
      body: ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${l10n.hifzToday}: ${workload?.newUnits ?? 0}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          ListTile(
            title: Text(l10n.newHifz),
            subtitle: Text('${workload?.newUnits ?? 0}'),
          ),
          ListTile(
            title: Text(l10n.recentRevision),
            subtitle: Text('${workload?.recentReviews ?? 0}'),
          ),
          ListTile(
            title: Text(l10n.cumulativeRevision),
            subtitle: Text('${workload?.cumulativeReviews ?? 0}'),
          ),
          if (ref.watch(optInProvider(OptInKey.grading)))
            ListTile(
              title: Text(l10n.optInGrading),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => context.push('/recitation'),
            ),
          ListTile(title: Text(l10n.streak)),
        ],
      ),
    );
  }
}
