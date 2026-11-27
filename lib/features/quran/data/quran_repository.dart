import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:mishkat/core/database/app_database.dart';
import 'package:mishkat_core/mishkat_core.dart';

typedef MushafAyah = ({
  int id,
  int surahId,
  int ayahNo,
  int page,
  String text,
});

typedef MushafSurah = ({
  int id,
  String nameAr,
  String? nameEn,
  int ayahCount,
  int pageStart,
});

/// يحمّل بيانات Tanzil المدمجة ويبني فهرس FTS5 مرة واحدة عند أول تشغيل.
/// عند اختيار مصدر شبكي تُجلب الصفحة وقت التشغيل وتُخزَّن محلياً فقط.
class QuranRepository {
  QuranRepository(this._db, this._bundle, this._dio);

  final AppDatabase _db;
  final AssetBundle _bundle;
  final Dio _dio;

  static const _asset = 'assets/quran/quran-dataset.json';
  static const _datasetVersion = 'tanzil-v1.1';
  static const _remoteBase = 'https://api.quran.com/api/v4';

  Map<int, ({int surah, int ayah})>? _references;

  Future<Map<String, dynamic>> _loadDataset() async {
    return jsonDecode(await _bundle.loadString(_asset)) as Map<String, dynamic>;
  }

  void _cacheReferences(List<dynamic> ayahs) {
    _references = {
      for (final item in ayahs)
        (item as Map<String, dynamic>)['id'] as int: (
          surah: item['surahId'] as int,
          ayah: item['ayahNo'] as int,
        ),
    };
  }

  Future<void> ensureIndexed() async {
    final existing = await (_db.select(
      _db.schemaMeta,
    )..where((m) => m.key.equals('dataset_version'))).getSingleOrNull();
    final decoded = await _loadDataset();
    _cacheReferences(decoded['ayahs'] as List<dynamic>);
    final indexedCount =
        (await _db.customSelect('SELECT COUNT(*) AS total FROM ayah_fts')
                .getSingle())
            .read<int>('total');
    final expectedCount = (decoded['ayahs'] as List<dynamic>).length;
    if (existing?.value == _datasetVersion && indexedCount == expectedCount) {
      return;
    }

    final surahs = decoded['surahs'] as List<dynamic>;
    final ayahs = decoded['ayahs'] as List<dynamic>;

    await _db.transaction(() async {
      await _db.customStatement('DELETE FROM ayah_fts');
      await _db.delete(_db.ayahs).go();
      await _db.delete(_db.surahs).go();

      await _db.batch((batch) {
        for (final item in surahs) {
          final s = item as Map<String, dynamic>;
          batch.insert(
            _db.surahs,
            SurahsCompanion.insert(
              id: Value(s['id'] as int),
              nameAr: s['nameAr'] as String,
              nameEn: Value(s['nameEn'] as String?),
              revelationType: s['revelationType'] as String,
              ayahCount: s['ayahCount'] as int,
              pageStart: const Value(null),
            ),
          );
        }
        for (final item in ayahs) {
          final a = item as Map<String, dynamic>;
          batch.insert(
            _db.ayahs,
            AyahsCompanion.insert(
              id: Value(a['id'] as int),
              surahId: a['surahId'] as int,
              ayahNo: a['ayahNo'] as int,
              page: a['page'] as int,
              juz: a['juz'] as int,
              hizb: a['hizb'] as int,
              quarter: Value(a['quarter'] as int?),
              textUthmani: a['textUthmani'] as String,
              textSearch: a['textSearch'] as String,
              textSearchExpanded: a['textSearchExpanded'] as String,
            ),
          );
        }
      });

      for (final item in ayahs) {
        final a = item as Map<String, dynamic>;
        await _db.indexAyah(
          a['id'] as int,
          a['textSearch'] as String,
          a['textSearchExpanded'] as String,
        );
      }

      await _db
          .into(_db.schemaMeta)
          .insert(
            SchemaMetaCompanion.insert(
              key: 'dataset_version',
              value: _datasetVersion,
            ),
          );
    });
  }

  /// البحث الكامل محلياً عبر FTS5 ثم تصفية النتائج على الجهاز أيضاً.
  Future<List<int>> search(String term, {AyahFilter? filter}) async {
    final ids = await _db.searchAyahIds(term);
    if (filter == null || filter.isEmpty) return ids;
    filter.validate();

    Expression<bool>? condition;
    void add(Expression<bool> expression) {
      condition = condition == null ? expression : condition! & expression;
    }

    if (filter.surahId != null) {
      add(_db.ayahs.surahId.equals(filter.surahId!));
    }
    if (filter.juz != null) add(_db.ayahs.juz.equals(filter.juz!));
    if (filter.page != null) add(_db.ayahs.page.equals(filter.page!));
    if (filter.hizb != null) add(_db.ayahs.hizb.equals(filter.hizb!));

    final rows = await (_db.select(_db.ayahs)..where((a) => condition!)).get();
    final allowed = rows.map((row) => row.id).toSet();
    return ids.where(allowed.contains).toList();
  }

  /// المرجع المحلي للآية لتوقيتات الكلمات — لا اتصال شبكي هنا.
  Future<({int surah, int ayah})?> referenceFor(int id) async {
    if (_references == null) {
      final decoded = await _loadDataset();
      _cacheReferences(decoded['ayahs'] as List<dynamic>);
    }
    return _references?[id];
  }

  Future<String?> ayahText(int id) async {
    final row = await (_db.select(
      _db.ayahs,
    )..where((a) => a.id.equals(id))).getSingleOrNull();
    return row?.textUthmani;
  }

  Future<List<MushafAyah>> _localPageAyahs(int page) async {
    final rows =
        await (_db.select(_db.ayahs)
              ..where((a) => a.page.equals(page))
              ..orderBy([(a) => OrderingTerm.asc(a.id)]))
            .get();
    return [
      for (final row in rows)
        (
          id: row.id,
          surahId: row.surahId,
          ayahNo: row.ayahNo,
          page: row.page,
          text: row.textUthmani,
        ),
    ];
  }

  static MushafAyah _withText(MushafAyah ayah, String text) => (
    id: ayah.id,
    surahId: ayah.surahId,
    ayahNo: ayah.ayahNo,
    page: ayah.page,
    text: text,
  );

  /// صفحة كاملة من المصحف، حرفياً من المصدر المختار.
  /// الترقيم والمetadata تأتي دائماً من بيانات Tanzil المدمجة.
  Future<List<MushafAyah>> pageAyahs(
    int page, {
    QuranTextSource source = QuranTextSource.tanzilUthmani,
  }) async {
    final local = await _localPageAyahs(page);
    if (!source.requiresNetwork || local.isEmpty) return local;
    return _remotePageAyahs(page, local, source);
  }

  Future<List<MushafAyah>> _remotePageAyahs(
    int page,
    List<MushafAyah> local,
    QuranTextSource source,
  ) async {
    final byKey = {
      for (final ayah in local) '${ayah.surahId}:${ayah.ayahNo}': ayah.id,
    };
    final ids = local.map((a) => a.id).toList()..sort();
    final fromId = ids.first;
    final toId = ids.last;

    var cached = await _db.cachedMushafText(fromId, toId);
    if (byKey.values.every(cached.containsKey)) {
      return [for (final ayah in local) _withText(ayah, cached[ayah.id]!)];
    }

    var apiPage = 1;
    while (true) {
      final response = await _dio.get<dynamic>(
        '$_remoteBase/verses/by_page/$page',
        queryParameters: {
          'fields': 'text_uthmani',
          'per_page': 50,
          'page': apiPage,
        },
        options: Options(receiveTimeout: const Duration(seconds: 20)),
      );
      final data = response.data as Map<String, dynamic>;
      final verses = data['verses'] as List<dynamic>? ?? const [];
      for (final verse in verses) {
        final map = verse as Map<String, dynamic>;
        final key = map['verse_key'] as String?;
        final text = map['text_uthmani'] as String?;
        final ayahId = key == null ? null : byKey[key];
        if (ayahId == null || text == null) continue;
        await _db.cacheMushafText(ayahId, text, source.id);
      }
      final pagination = data['pagination'] as Map<String, dynamic>?;
      final current = pagination?['current_page'] as int? ?? apiPage;
      final total = pagination?['total_pages'] as int? ?? 1;
      if (verses.isEmpty || current >= total) break;
      apiPage = current + 1;
    }

    cached = await _db.cachedMushafText(fromId, toId);
    return [for (final ayah in local) _withText(ayah, cached[ayah.id] ?? ayah.text)];
  }

  /// قائمة السور مع أول صفحة تظهر فيها كل سورة.
  Future<List<MushafSurah>> surahList() async {
    final starts = await _db
        .customSelect(
          'SELECT surah_id, MIN(page) AS page_start FROM ayahs GROUP BY surah_id',
        )
        .get();
    final pageBySurah = {
      for (final row in starts)
        row.read<int>('surah_id'): row.read<int>('page_start'),
    };
    final rows = await (_db.select(
      _db.surahs,
    )..orderBy([(s) => OrderingTerm.asc(s.id)])).get();
    return [
      for (final row in rows)
        (
          id: row.id,
          nameAr: row.nameAr,
          nameEn: row.nameEn,
          ayahCount: row.ayahCount,
          pageStart: pageBySurah[row.id] ?? 1,
        ),
    ];
  }

  /// مرجع الآية لعرض نتيجة البحث والقفز إلى صفحتها.
  Future<({int surahId, int ayahNo, int page, String text})?> ayahMeta(
    int id,
  ) async {
    final row = await (_db.select(
      _db.ayahs,
    )..where((a) => a.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return (
      surahId: row.surahId,
      ayahNo: row.ayahNo,
      page: row.page,
      text: row.textUthmani,
    );
  }
}
