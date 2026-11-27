import 'package:flutter/material.dart';
import 'package:mishkat/l10n/generated/app_localizations.dart';

class AthkarScreen extends StatelessWidget {
  const AthkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navAthkar)),
      body: Center(child: Text(l10n.sunniOnlyPolicy)),
    );
  }
}
