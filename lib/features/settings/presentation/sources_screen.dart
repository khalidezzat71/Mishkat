import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mishkat/l10n/generated/app_localizations.dart';
import 'package:flutter/services.dart';

class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sourcesAndAttribution)),
      body: FutureBuilder<String>(
        future: rootBundle.loadString('assets/data/sources.json'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final decoded = jsonDecode(snapshot.data!) as Map<String, dynamic>;
          final sources = decoded['sources'] as List<dynamic>;
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.verified_outlined),
                title: Text(l10n.sunniOnlyPolicy),
              ),
              ListTile(
                leading: const Icon(Icons.volunteer_activism_outlined),
                title: Text(l10n.freeSourcesPolicy),
              ),
              const Divider(),
              ...sources.map(
                (item) => ListTile(
                  title: Text(item['name'] as String),
                  subtitle: Text('${item['license']}\n${item['url']}'),
                  trailing: Text(
                    item['bundled'] == true ? l10n.bundled : l10n.runtimeOnly,
                  ),
                  isThreeLine: true,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
