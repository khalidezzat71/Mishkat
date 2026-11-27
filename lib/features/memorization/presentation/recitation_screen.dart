import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mishkat/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mishkat/core/database/app_database.dart';
import 'package:mishkat/core/settings/opt_in_providers.dart';
import 'package:mishkat_core/mishkat_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../../app/advanced_providers.dart';
import '../../../app/providers.dart';
import '../../quran/presentation/quran_providers.dart';

/// التسميع الصوتي: تسجيل محلي → وكيل اختياري → محاذاة → SM-2.
/// لا يُفعّل إلا بعد OptIn صريح، ولا يُرسل أي صوت بدون طلب المستخدم.
class RecitationScreen extends ConsumerStatefulWidget {
  const RecitationScreen({super.key});

  @override
  ConsumerState<RecitationScreen> createState() => _RecitationScreenState();
}

class _RecitationScreenState extends ConsumerState<RecitationScreen> {
  final _recorder = AudioRecorder();
  final _unitId = TextEditingController(text: '1');
  String? _result;
  bool _recording = false;

  @override
  void dispose() {
    _recorder.dispose();
    _unitId.dispose();
    super.dispose();
  }

  String _qualityLabel(AppLocalizations l10n, Sm2Quality quality) =>
      switch (quality) {
        Sm2Quality.mastered => l10n.qualityMastered,
        Sm2Quality.good => l10n.qualityGood,
        Sm2Quality.needsReview => l10n.qualityNeedsReview,
      };

  Future<void> _start() async {
    final l10n = AppLocalizations.of(context)!;
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      setState(() => _result = l10n.recordPermissionDenied);
      return;
    }
    final path = '${Directory.systemTemp.path}/mishkat_recitation.m4a';
    await _recorder.start(const RecordConfig(), path: path);
    setState(() {
      _recording = true;
      _result = null;
    });
  }

  Future<void> _stop() async {
    final path = await _recorder.stop();
    setState(() => _recording = false);
    if (path == null) return;

    final l10n = AppLocalizations.of(context)!;
    final unitId = int.tryParse(_unitId.text) ?? 1;
    final db = ref.read(databaseProvider);
    final units = await (db.select(
      db.hifzUnits,
    )..where((u) => u.id.equals(unitId))).get();
    if (units.isEmpty) {
      setState(() => _result = l10n.errorGeneric);
      return;
    }
    final expected =
        await ref
            .read(quranRepositoryProvider)
            .ayahText(units.first.startAyahId) ??
        '';
    final bytes = await File(path).readAsBytes();
    final recognized = await ref
        .read(recitationProxyProvider)
        .transcribe(bytes, locale: 'ar');
    final outcome = const RecitationPipeline().evaluate(
      expected: expected,
      recognized: recognized,
    );
    await db
        .into(db.recitationAttempts)
        .insert(
          RecitationAttemptsCompanion.insert(
            unitId: unitId,
            accuracyPercent: outcome.grade.accuracyPercent,
            matched: outcome.grade.matched,
            substituted: outcome.grade.substituted,
            omitted: outcome.grade.omitted,
            createdAt: DateTime.now(),
          ),
        );
    setState(() {
      _result =
          '${l10n.recitationResult}: ${outcome.grade.accuracyPercent}% — '
          '${_qualityLabel(l10n, outcome.quality)}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final enabled = ref.watch(optInProvider(OptInKey.grading));
    final ready = enabled && isAiProxyConfigured;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.optInGrading)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _unitId,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.unitId),
          ),
          const SizedBox(height: 16),
          Text(
            ready ? l10n.optInGradingDesc : l10n.proxyNotConfigured,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: ready && !_recording ? _start : null,
            icon: const Icon(Icons.mic_none),
            label: Text(l10n.startRecitation),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: ready && _recording ? _stop : null,
            icon: const Icon(Icons.stop_circle_outlined),
            label: Text(l10n.stopRecitation),
          ),
          if (_result != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_result!),
            ),
        ],
      ),
    );
  }
}
