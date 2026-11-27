import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:mishkat/core/database/app_database.dart';
import 'package:mishkat_core/mishkat_core.dart';
import 'package:path_provider/path_provider.dart';

/// سجل القرّاء والتنزيلات. المصادر المجانية أولاً، وكل مصدر قابل للاستبدال.
class ReciterRepository {
  ReciterRepository(this._db, this._client, this._documentsDir);

  final AppDatabase _db;
  final Dio _client;
  final Directory _documentsDir;

  static const _policy = DownloadPolicy();

  static Future<ReciterRepository> create(AppDatabase db, Dio client) async {
    final dir = await getApplicationDocumentsDirectory();
    return ReciterRepository(db, client, dir);
  }

  Directory get _privateDir => Directory('${_documentsDir.path}/reciters');

  /// يُسجَّل مرة واحدة من مرشحات mishkat_core — لا مصادر شيعية ولا مفاتيح.
  Future<void> ensureSeeded() async {
    final count = (await _db.select(_db.reciters).get()).length;
    if (count > 0) return;
    for (final source in kCandidateAudioSources) {
      await _db
          .into(_db.reciters)
          .insert(
            RecitersCompanion.insert(
              nameAr: source.nameAr,
              riwayah: Value(source.riwayah),
              urlTemplate: source.urlTemplate,
              pattern: Value(source.pattern),
              source: source.id,
              verified: Value(source.verified),
              enabled: const Value(true),
            ),
          );
    }
  }

  Future<List<Reciter>> list() async {
    await ensureSeeded();
    final rows = await (_db.select(
      _db.reciters,
    )..where((r) => r.enabled.equals(true))).get();
    rows.sort((a, b) {
      final aFree = kCandidateAudioSources.any(
        (s) => s.id == a.source && s.free,
      );
      final bFree = kCandidateAudioSources.any(
        (s) => s.id == b.source && s.free,
      );
      if (aFree != bFree) return aFree ? -1 : 1;
      return a.nameAr.compareTo(b.nameAr);
    });
    return rows;
  }

  /// يبني الرابط من نمط المصدر عبر منطق mishkat_core المُختبَر.
  String resolveUrl(Reciter reciter, int surah, int ayah) {
    final source = AudioSource(
      id: reciter.source,
      nameAr: reciter.nameAr,
      reciterName: reciter.nameAr,
      riwayah: reciter.riwayah ?? '',
      urlTemplate: reciter.urlTemplate,
      pattern: reciter.pattern,
      license: 'see LICENSES_AND_SOURCES.md',
      free: kCandidateAudioSources.any((s) => s.id == reciter.source && s.free),
      verified: reciter.verified,
      sect: Sect.sunni,
    );
    return ReciterManager([source]).resolveUrl(source, surah, ayah);
  }

  /// تنزيل صوت آية في مساحة خاصة، مع تحقق SHA-256 اختياري من المصدر.
  Future<String?> download(
    Reciter reciter, {
    required int surah,
    required int ayah,
    String? expectedSha,
  }) async {
    final url = resolveUrl(reciter, surah, ayah);
    try {
      final response = await _client.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) return null;
      if (expectedSha != null && !_policy.verify(bytes, expectedSha)) {
        return null; // رفض ملف غير مطابق للبصمة المعلنة.
      }
      final sha = _policy.checksum(bytes);
      final target = File(
        '${_privateDir.path}/${reciter.id}_${surah.toString().padLeft(3, '0')}'
        '${ayah.toString().padLeft(3, '0')}.mp3',
      );
      await target.parent.create(recursive: true);
      await target.writeAsBytes(bytes, flush: true);

      final existing =
          await (_db.select(_db.downloads)..where(
                (d) => d.reciterId.equals(reciter.id) & d.surahId.equals(surah),
              ))
              .get();
      if (existing.isEmpty) {
        await _db
            .into(_db.downloads)
            .insert(
              DownloadsCompanion.insert(
                reciterId: reciter.id,
                surahId: surah,
                path: target.path,
                bytes: bytes.length,
                sha256: sha,
                lastAccessedAt: DateTime.now(),
              ),
            );
      } else {
        await (_db.update(
          _db.downloads,
        )..where((d) => d.id.equals(existing.first.id))).write(
          DownloadsCompanion(
            path: Value(target.path),
            bytes: Value(bytes.length),
            sha256: Value(sha),
            lastAccessedAt: Value(DateTime.now()),
          ),
        );
      }
      return target.path;
    } on DioException {
      return null;
    }
  }

  /// حذف عند تجاوز الحصة، بدءاً بالأقل استخداماً (سياسة mishkat_core).
  Future<void> enforceQuota({required int maxBytes}) async {
    final rows = await _db.select(_db.downloads).get();
    final entries = rows.map(
      (row) => DownloadEntry(
        id: row.id.toString(),
        bytes: row.bytes,
        sha256: row.sha256,
        lastAccessedAt: row.lastAccessedAt,
      ),
    );
    final kept = _policy
        .evict(entries, maxBytes: maxBytes)
        .map((e) => int.parse(e.id))
        .toSet();
    for (final row in rows) {
      if (kept.contains(row.id)) continue;
      final file = File(row.path);
      if (await file.exists()) await file.delete();
      await (_db.delete(_db.downloads)..where((d) => d.id.equals(row.id))).go();
    }
  }

  /// حذف صريح بطلب المستخدم فقط.
  Future<void> removeDownload(int id) async {
    final rows = await (_db.select(
      _db.downloads,
    )..where((d) => d.id.equals(id))).get();
    for (final row in rows) {
      final file = File(row.path);
      if (await file.exists()) await file.delete();
    }
    await (_db.delete(_db.downloads)..where((d) => d.id.equals(id))).go();
  }
}
