import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement('PRAGMA foreign_keys = ON');
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
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
}
