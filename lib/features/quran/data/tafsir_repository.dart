import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:mishkat/core/database/app_database.dart';
import 'package:mishkat_core/mishkat_core.dart';

/// التفسير يُجلب وقت التشغيل فقط من مصدر سني، ويُخزَّن محلياً ≤ 7 أيام.
/// لا يُضمّن أي نص تفسير في حزمة التطبيق أو المستودع.
class TafsirRepository {
  TafsirRepository(this._db, this._client);

  final AppDatabase _db;
  final Dio _client;

  /// يُضبط وقت البناء عبر --dart-define؛ فارغ = الميزة متوقفة تماماً.
  static const baseUrl = String.fromEnvironment('MISHKAT_TAFSIR_BASE_URL');

  static const cacheTtl = Duration(days: 7);
  static const policy = TafsirSourcePolicy();

  Future<String?> cached(int ayahId, String editionId) async {
    policy.requireApproved(editionId);
    final editionRows = await (_db.select(
      _db.tafsirs,
    )..where((t) => t.edition.equals(editionId))).get();
    if (editionRows.isEmpty) return null;
    final tafsir = editionRows.first;
    final syncedAt = tafsir.syncedAt;
    if (syncedAt == null || DateTime.now().difference(syncedAt) > cacheTtl) {
      return null;
    }
    final rows =
        await (_db.select(_db.tafsirTexts)..where(
              (t) => t.tafsirId.equals(tafsir.id) & t.ayahId.equals(ayahId),
            ))
            .get();
    return rows.isEmpty ? null : rows.first.textValue;
  }

  /// يجلب التفسير عند الاتصال، ويعيد null بأمان عند تعذّر الشبكة.
  Future<String?> fetch(int ayahId, String editionId) async {
    final edition = policy.requireApproved(editionId);
    if (baseUrl.isEmpty) return null;

    final existing = await cached(ayahId, editionId);
    if (existing != null) return existing;

    try {
      final response = await _client.get<String>(
        '$baseUrl/tafsirs/${edition.id}/by_ayah/$ayahId',
        options: Options(responseType: ResponseType.plain),
      );
      final decoded = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
      final text =
          (decoded['tafsir'] as Map<String, dynamic>?)?['text'] as String?;
      if (text == null || text.trim().isEmpty) return null;

      final now = DateTime.now();
      await pruneExpired(now: now);
      final editionRows = await (_db.select(
        _db.tafsirs,
      )..where((t) => t.edition.equals(edition.id))).get();
      final int tafsirId;
      if (editionRows.isEmpty) {
        tafsirId = await _db
            .into(_db.tafsirs)
            .insert(
              TafsirsCompanion.insert(
                edition: edition.id,
                language: edition.language,
                license: Value(edition.license),
                syncedAt: Value(now),
              ),
            );
      } else {
        tafsirId = editionRows.first.id;
        await (_db.update(_db.tafsirs)..where((t) => t.id.equals(tafsirId)))
            .write(TafsirsCompanion(syncedAt: Value(now)));
      }
      await _db
          .into(_db.tafsirTexts)
          .insertOnConflictUpdate(
            TafsirTextsCompanion.insert(
              tafsirId: tafsirId,
              ayahId: ayahId,
              textValue: text,
            ),
          );
      return text;
    } on DioException {
      return null; // يعمل التطبيق بالكامل بدون اتصال.
    } on FormatException {
      return null;
    }
  }

  /// يمنع بقاء أي تفسير أكثر من 7 أيام على الجهاز.
  Future<int> pruneExpired({DateTime? now}) async {
    final reference = now ?? DateTime.now();
    final cutoff = reference.subtract(cacheTtl);
    final expired =
        await (_db.select(_db.tafsirs)..where(
              (t) =>
                  t.syncedAt.isSmallerThanValue(cutoff) | t.syncedAt.isNull(),
            ))
            .get();
    for (final row in expired) {
      await (_db.delete(
        _db.tafsirTexts,
      )..where((t) => t.tafsirId.equals(row.id))).go();
      await (_db.delete(_db.tafsirs)..where((t) => t.id.equals(row.id))).go();
    }
    return expired.length;
  }
}
