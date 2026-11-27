import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

const _createAyahFts = '''
CREATE VIRTUAL TABLE IF NOT EXISTS ayah_fts USING fts5(
  ayah_id UNINDEXED,
  text_search,
  text_search_expanded,
  tokenize = 'unicode61 remove_diacritics 2'
)
''';

const _createMushafOverrides = '''
CREATE TABLE IF NOT EXISTS mushaf_text_overrides (
  ayah_id INTEGER PRIMARY KEY,
  text TEXT NOT NULL,
  source TEXT NOT NULL,
  synced_at INTEGER NOT NULL
)
''';

@DriftDatabase(
  tables: [
    Surahs,
    Ayahs,
    Reciters,
    WordTimings,
    Tafsirs,
    TafsirTexts,
    Athkar,
    HifzPlans,
    HifzUnits,
    RecitationAttempts,
    ReadingSessions,
    Bookmarks,
    PrayerSettings,
    AppSettings,
    Downloads,
    NotificationSchedule,
    ErrorLogs,
    SchemaMeta,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement(_createAyahFts);
      await customStatement(_createMushafOverrides);
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await customStatement(_createAyahFts);
        await customStatement('DELETE FROM ayah_fts');
        await customStatement(
          "DELETE FROM schema_meta WHERE key = 'dataset_version'",
        );
      }
      if (from < 3) {
        await customStatement(_createMushafOverrides);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement(_createAyahFts);
      await customStatement(_createMushafOverrides);
    },
  );

  static QueryExecutor _open() => driftDatabase(name: 'mishkat');

  /// يضيف آية إلى الفهرسين المشتقّين (بدون تعديل النص الحرفي).
  Future<void> indexAyah(
    int ayahId,
    String searchText,
    String expandedText,
  ) async {
    await customStatement(
      'INSERT INTO ayah_fts(ayah_id, text_search, text_search_expanded) '
      'VALUES (?, ?, ?)',
      [ayahId, searchText, expandedText],
    );
  }

  /// بحث فوري: أي كلمة بدون تشكيل، من العمودين معاً.
  Future<List<int>> searchAyahIds(String term) async {
    final safe = term.trim().replaceAll(RegExp(r'["*]'), '');
    if (safe.isEmpty) return <int>[];
    final rows = await customSelect(
      'SELECT ayah_id FROM ayah_fts WHERE ayah_fts MATCH ?1 '
      'ORDER BY bm25(ayah_fts) LIMIT 50',
      variables: [Variable<String>('"$safe"*')],
    ).get();
    return rows.map((row) => row.read<int>('ayah_id')).toList();
  }

  /// يقرأ النص المخزّن مؤقتاً من مصدر شبكي، إن وُجد، وإلا يعيد خريطة فارغة.
  Future<Map<int, String>> cachedMushafText(int fromId, int toId) async {
    final rows = await customSelect(
      'SELECT ayah_id, text FROM mushaf_text_overrides '
      'WHERE ayah_id BETWEEN ?1 AND ?2',
      variables: [Variable<int>(fromId), Variable<int>(toId)],
    ).get();
    return {
      for (final row in rows)
        row.read<int>('ayah_id'): row.read<String>('text'),
    };
  }

  Future<void> cacheMushafText(
    int ayahId,
    String text,
    String source,
  ) async {
    await customStatement(
      'INSERT INTO mushaf_text_overrides(ayah_id, text, source, synced_at) '
      'VALUES (?, ?, ?, ?) ON CONFLICT(ayah_id) DO UPDATE SET '
      'text = excluded.text, source = excluded.source, '
      'synced_at = excluded.synced_at',
      [ayahId, text, source, DateTime.now().millisecondsSinceEpoch],
    );
  }

  Future<void> clearMushafTextCache() =>
      customStatement('DELETE FROM mushaf_text_overrides');
}
