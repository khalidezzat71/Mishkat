import 'package:drift/drift.dart';

/// بيانات سورة ثابتة من Tanzil.
class Surahs extends Table {
  IntColumn get id => integer();
  @Name('name_ar')
  TextColumn get nameAr => text();
  @Name('name_en')
  TextColumn get nameEn => text().nullable();
  @Name('revelation_type')
  TextColumn get revelationType => text();
  @Name('ayah_count')
  IntColumn get ayahCount => integer();
  @Name('page_start')
  IntColumn get pageStart => integer().nullable();
  @override
  Set<Column> get primaryKey => {id};
}

/// الآية: النص الحرفي غير القابل للتعديل + عمودا بحث مشتقّان محلياً.
class Ayahs extends Table {
  IntColumn get id => integer();
  @Name('surah_id')
  IntColumn get surahId => integer().references(Surahs, #id);
  @Name('ayah_no')
  IntColumn get ayahNo => integer();
  IntColumn get page => integer();
  IntColumn get juz => integer();
  IntColumn get hizb => integer();
  IntColumn get quarter => integer().nullable();
  @Name('text_uthmani')
  TextColumn get textUthmani => text();
  @Name('text_search')
  TextColumn get textSearch => text();
  @Name('text_search_expanded')
  TextColumn get textSearchExpanded => text();
  @override
  Set<Column> get primaryKey => {id};
}

/// فهرس FTS5 مستقل: يحتوي على معرّف الآية كعمود غير مفهرس.
class AyahFts extends CustomTable {
  @override
  String get tableName => 'ayah_fts';

  @override
  String get createTable => '''
    CREATE VIRTUAL TABLE IF NOT EXISTS ayah_fts USING fts5(
      ayah_id UNINDEXED,
      text_search,
      text_search_expanded,
      tokenize = 'unicode61'
    )
  ''';
}

/// قارئ معتمد (مصدره مجاني أو مدفوع موثّق في LICENSES_AND_SOURCES.md).
class Reciters extends Table {
  IntColumn get id => integer().autoIncrement();
  @Name('name_ar')
  TextColumn get nameAr => text();
  TextColumn get riwayah => text().nullable();
  @Name('url_template')
  TextColumn get urlTemplate => text();
  @Name('pattern')
  TextColumn get pattern => text().withDefault(const Constant('SSSAAA'));
  TextColumn get source => text();
  BoolColumn get verified => boolean().withDefault(const Constant(false));
  BoolColumn get enabled => boolean().withDefault(const Constant(true));
}

/// توقيتات الكلمات القادمة من Quran.com أو محاذاة محلية.
class WordTimings extends Table {
  IntColumn get id => integer().autoIncrement();
  @Name('reciter_id')
  IntColumn get reciterId => integer().references(Reciters, #id);
  @Name('ayah_id')
  IntColumn get ayahId => integer().references(Ayahs, #id);
  @Name('word_index')
  IntColumn get wordIndex => integer();
  @Name('start_ms')
  IntColumn get startMs => integer();
  @Name('end_ms')
  IntColumn get endMs => integer();
  TextColumn get source => text();
  TextColumn get checksum => text().nullable();
}

/// التفسير يُجلب وقت التشغيل فقط — لا يُضمّن في المستودع.
class Tafsirs extends Table {
  IntColumn get id => integer().autoIncrement();
  TextColumn get edition => text();
  TextColumn get language => text();
  TextColumn get license => text().nullable();
  @Name('synced_at')
  DateTimeColumn get syncedAt => dateTime().nullable();
}

class TafsirTexts extends Table {
  @Name('tafsir_id')
  IntColumn get tafsirId => integer().references(Tafsirs, #id);
  @Name('ayah_id')
  IntColumn get ayahId => integer().references(Ayahs, #id);
  TextColumn get text => text();
  @override
  Set<Column> get primaryKey => {tafsirId, ayahId};
}

/// أذكار سنية المصدر فقط (قرآن / حديث صحيح).
class Athkar extends Table {
  IntColumn get id => integer().autoIncrement();
  TextColumn get category => text();
  TextColumn get text => text();
  @Name('repeat_count')
  IntColumn get repeatCount => integer().withDefault(const Constant(1));
  TextColumn get virtue => text().nullable();
  @Name('source_ref')
  TextColumn get sourceRef => text();
}

/// وحدة الحفظ: نطاق آيات مع حقول SM-2.
class HifzUnits extends Table {
  IntColumn get id => integer().autoIncrement();
  @Name('plan_id')
  IntColumn get planId => integer().nullable();
  @Name('start_ayah_id')
  IntColumn get startAyahId => integer().references(Ayahs, #id);
  @Name('end_ayah_id')
  IntColumn get endAyahId => integer().references(Ayahs, #id);
  @Name('page_from')
  IntColumn get pageFrom => integer().nullable();
  @Name('face_from')
  IntColumn get faceFrom => integer().nullable();
  TextColumn get status => text().withDefault(const Constant('new'));
  @Name('ease_factor')
  RealColumn get easeFactor => real().withDefault(const Constant(2.5));
  @Name('interval_days')
  IntColumn get intervalDays => integer().withDefault(const Constant(0));
  IntColumn get repetitions => integer().withDefault(const Constant(0));
  @Name('last_quality')
  IntColumn get lastQuality => integer().nullable();
  @Name('next_review_at')
  DateTimeColumn get nextReviewAt => dateTime().nullable();
  @Name('accuracy_percent')
  IntColumn get accuracyPercent => integer().nullable();
}

class HifzPlans extends Table {
  IntColumn get id => integer().autoIncrement();
  TextColumn get name => text();
  TextColumn get type => text();
  @Name('daily_new')
  IntColumn get dailyNew => integer().withDefault(const Constant(0));
  @Name('daily_recent')
  IntColumn get dailyRecent => integer().withDefault(const Constant(0));
  @Name('daily_cumulative')
  IntColumn get dailyCumulative => integer().withDefault(const Constant(0));
  @Name('start_date')
  DateTimeColumn get startDate => dateTime();
  BoolColumn get active => boolean().withDefault(const Constant(true));
}

class RecitationAttempts extends Table {
  IntColumn get id => integer().autoIncrement();
  @Name('unit_id')
  IntColumn get unitId => integer().references(HifzUnits, #id);
  @Name('accuracy_percent')
  IntColumn get accuracyPercent => integer();
  IntColumn get matched => integer();
  IntColumn get substituted => integer();
  IntColumn get omitted => integer();
  @Name('created_at')
  DateTimeColumn get createdAt => dateTime();
}

class ReadingSessions extends Table {
  IntColumn get id => integer().autoIncrement();
  DateTimeColumn get day => dateTime();
  @Name('pages_read')
  IntColumn get pagesRead => integer().withDefault(const Constant(0));
  @Name('ayahs_read')
  IntColumn get ayahsRead => integer().withDefault(const Constant(0));
  TextColumn get source => text().nullable();
}

class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement();
  @Name('ayah_id')
  IntColumn get ayahId => integer().references(Ayahs, #id);
  TextColumn get note => text().nullable();
  @Name('created_at')
  DateTimeColumn get createdAt => dateTime();
}

class PrayerSettings extends Table {
  TextColumn get prayerKey => text();
  BoolColumn get enabled => boolean().withDefault(const Constant(true));
  @Name('offset_min')
  IntColumn get offsetMin => integer().withDefault(const Constant(0));
  @Name('pre_reminder_min')
  IntColumn get preReminderMin => integer().withDefault(const Constant(15));
  @Name('iqamah_min')
  IntColumn get iqamahMin => integer().withDefault(const Constant(15));
  @Name('iqamah_enabled')
  BoolColumn get iqamahEnabled => boolean().withDefault(const Constant(false));
  @Name('adhan_reciter_id')
  IntColumn get adhanReciterId => integer().nullable();
  @override
  Set<Column> get primaryKey => {prayerKey};
}

class AppSettings extends Table {
  TextColumn get key => text();
  TextColumn get valueJson => text();
  @override
  Set<Column> get primaryKey => {key};
}

class Downloads extends Table {
  IntColumn get id => integer().autoIncrement();
  @Name('reciter_id')
  IntColumn get reciterId => integer().references(Reciters, #id);
  @Name('surah_id')
  IntColumn get surahId => integer();
  TextColumn get path => text();
  IntColumn get bytes => integer();
  TextColumn get sha256 => text();
  @Name('last_accessed_at')
  DateTimeColumn get lastAccessedAt => dateTime();
}

class NotificationSchedule extends Table {
  TextColumn get key => text();
  @Name('fire_at')
  DateTimeColumn get fireAt => dateTime();
  TextColumn get type => text();
  TextColumn get status => text();
  @override
  Set<Column> get primaryKey => {key};
}

/// سجل أخطاء محلي — بدون أي إرسال شخصي.
class ErrorLogs extends Table {
  IntColumn get id => integer().autoIncrement();
  DateTimeColumn get timestamp => dateTime();
  TextColumn get route => text();
  TextColumn get code => text();
  TextColumn get message => text();
  TextColumn get stack => text().nullable();
  @Name('app_version')
  TextColumn get appVersion => text();
  @Name('os_version')
  TextColumn get osVersion => text();
}

class SchemaMeta extends Table {
  TextColumn get key => text();
  TextColumn get value => text();
  @override
  Set<Column> get primaryKey => {key};
}
