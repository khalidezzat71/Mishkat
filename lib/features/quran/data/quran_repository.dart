import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:mishkat/core/database/app_database.dart';
import 'package:mishkat_core/mishkat_core.dart';

/// يحمّل بيانات Tanzil المدمجة ويبني فهرس FTS5 مرة واحدة عند أول تشغيل.
class QuranRepository {
  QuranRepository(this._db, this._bundle);

  final AppDatabase _db;
  final AssetBundle _bundle;

  static const _asset = 'assets/quran/quran-dataset.json';
  static const _datasetVersion = 'tanzil-v1.1';

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
    if (existing?.value == _datasetVersion) return;

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

  /// البحث الكامل محلياً عبر FTS5، ثم تصفية النتائج على الجهاز también.
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
}
