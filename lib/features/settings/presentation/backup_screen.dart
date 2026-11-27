import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/advanced_providers.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  final _passphrase = TextEditingController();
  final _payload = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _passphrase.dispose();
    _payload.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final service = ref.watch(backupServiceProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.backup)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _passphrase,
            obscureText: true,
            decoration: InputDecoration(labelText: l10n.passphrase),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _payload,
            maxLines: 8,
            decoration: InputDecoration(labelText: l10n.pasteBackupJson),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              try {
                final raw = await service.export(_passphrase.text);
                setState(() {
                  _payload.text = raw;
                  _message = l10n.backupCreated;
                });
              } on Object {
                setState(() => _message = l10n.wrongPassphrase);
              }
            },
            icon: const Icon(Icons.save_outlined),
            label: Text(l10n.exportBackupAction),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              try {
                await service.restore(_payload.text, _passphrase.text);
                setState(() => _message = l10n.backupRestored);
              } on Object {
                setState(() => _message = l10n.wrongPassphrase);
              }
            },
            icon: const Icon(Icons.restore_outlined),
            label: Text(l10n.importBackupAction),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_message!),
            ),
        ],
      ),
    );
  }
}
