import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:mishkat/core/database/app_database.dart';
import 'package:mishkat_core/mishkat_core.dart';

/// تصدير/استعادة محلي مشفّر — لا تُرسل النسخة إلى أي خادم.
class BackupService {
  const BackupService(this._db);

  final AppDatabase _db;
  static const codec = BackupCodec();

  Future<String> export(String passphrase) async {
    final entries = <String, String>{};
    for (final row in await _db.select(_db.appSettings).get()) {
      entries['settings.${row.key}'] = row.valueJson;
    }
    for (final row in await _db.select(_db.hifzUnits).get()) {
      entries['hifz.${row.id}'] = jsonEncode({
        'id': row.id,
        'startAyahId': row.startAyahId,
        'endAyahId': row.endAyahId,
        'status': row.status,
        'easeFactor': row.easeFactor,
        'intervalDays': row.intervalDays,
        'repetitions': row.repetitions,
        'nextReviewAt': row.nextReviewAt?.toUtc().toIso8601String(),
      });
    }
    final payload = BackupPayload(
      version: BackupCodec.currentVersion,
      createdAt: DateTime.now(),
      entries: entries,
    );
    return codec.encrypt(payload, passphrase).toJson();
  }

  Future<void> restore(String raw, String passphrase) async {
    final backup = codec.decrypt(EncryptedBackup.fromJson(raw), passphrase);
    if (backup.version != BackupCodec.currentVersion) {
      throw const FormatException('unsupported backup version');
    }
    for (final entry in backup.entries.entries) {
      if (entry.key.startsWith('settings.')) {
        final key = entry.key.substring('settings.'.length);
        await _db
            .into(_db.appSettings)
            .insertOnConflictUpdate(
              AppSettingsCompanion.insert(key: key, valueJson: entry.value),
            );
      } else if (entry.key.startsWith('hifz.')) {
        final decoded = jsonDecode(entry.value) as Map<String, dynamic>;
        await _db
            .into(_db.hifzUnits)
            .insertOnConflictUpdate(
              HifzUnitsCompanion.insert(
                id: Value(decoded['id'] as int),
                startAyahId: decoded['startAyahId'] as int,
                endAyahId: decoded['endAyahId'] as int,
                status: Value(decoded['status'] as String),
                easeFactor: Value((decoded['easeFactor'] as num).toDouble()),
                intervalDays: Value(decoded['intervalDays'] as int),
                repetitions: Value(decoded['repetitions'] as int),
                nextReviewAt: Value(
                  decoded['nextReviewAt'] == null
                      ? null
                      : DateTime.parse(decoded['nextReviewAt'] as String),
                ),
              ),
            );
      }
    }
  }
}
