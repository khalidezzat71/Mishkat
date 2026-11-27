import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mishkat_core/mishkat_core.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DiagnosticsScreen extends StatelessWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.diagnostics)),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final info = snapshot.data;
          final report = const DiagnosticsCollector().collect(
            appVersion: info?.version ?? '0.1.0',
            osVersion: Platform.operatingSystemVersion,
            locale: Localizations.localeOf(context).languageCode,
            datasetValid: true,
            ayahCount: expectedAyahCount,
            notificationSlots: NotificationPlan.plannedSlotCount,
            recentErrors: const [],
          );
          final json = report.toRedactedJson();
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SelectableText(json),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => Clipboard.setData(ClipboardData(text: json)),
                  icon: const Icon(Icons.copy_outlined),
                  label: Text(l10n.copyReport),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
