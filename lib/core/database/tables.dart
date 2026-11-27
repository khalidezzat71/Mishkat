import 'package:drift/drift.dart';

/// بيانات سورة ثابتة من Tanzil.
class Surahs extends Table {
  IntColumn get id => integer()();
  TextColumn get nameAr => text().named('name_ar')();
  TextColumn get nameEn => text().named('name_en').nullable()();
  TextColumn get revelationType => text().named('revelation_type')();
  IntColumn get ayahCount => integer().named('ayah_count')();
  IntColumn get pageStart => integer().named('page_start').nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

/// الآية: النص الحرفي غير القابل للتعديل + عمودا بحث مشتقّان محلياً.
class Ayahs extends Table {
  IntColumn get id => integer()();
  IntColumn get surahId =>
      integer().named('surah_id').references(Surahs, #id)();
  IntColumn get ayahNo => integer().named('ayah_no')();
  IntColumn get page => integer()();
  IntColumn get juz => integer()();
  IntColumn get hizb => integer()();
  IntColumn get quarter => integer().nullable()();
  TextColumn get textUthmani => text().named('text_uthmani')();
  TextColumn get textSearch => text().named('text_search')();
  TextColumn get textSearchExpanded => text().named('text_search_expanded')();
  @override
  Set<Column> get primaryKey => {id};
}

/// قارئ معتمد (مصدره مجاني أو مدفوع موثّق في LICENSES_AND_SOURCES.md).
class Reciters extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nameAr => text().named('name_ar')();
  TextColumn get riwayah => text().nullable()();
  TextColumn get urlTemplate => text().named('url_template')();
  TextColumn get pattern =>
      text().named('pattern').withDefault(const Constant('SSSAAA'))();
  TextColumn get source => text()();
  BoolColumn get verified => boolean().withDefault(const Constant(false))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
}

/// توقيتات الكلمات القادمة من Quran.com أو محاذاة محلية.
class WordTimings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get reciterId =>
      integer().named('reciter_id').references(Reciters, #id)();
  IntColumn get ayahId => integer().named('ayah_id').references(Ayahs, #id)();
  IntColumn get wordIndex => integer().named('word_index')();
  IntColumn get startMs => integer().named('start_ms')();
  IntColumn get endMs => integer().named('end_ms')();
  TextColumn get source => text()();
  TextColumn get checksum => text().nullable()();
}

/// التفسير يُجلب وقت التشغيل فقط — لا يُضمّن في المستودع.
class Tafsirs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get edition => text()();
  TextColumn get language => text()();
  TextColumn get license => text().nullable()();
  DateTimeColumn get syncedAt => dateTime().named('synced_at').nullable()();
}

class TafsirTexts extends Table {
  IntColumn get tafsirId =>
      integer().named('tafsir_id').references(Tafsirs, #id)();
  IntColumn get ayahId => integer().named('ayah_id').references(Ayahs, #id)();
  TextColumn get textValue => text().named('text')();
  @override
  Set<Column> get primaryKey => {tafsirId, ayahId};
}

/// أذكار سنية المصدر فقط (قرآن / حديث صحيح).
class Athkar extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get category => text()();
  TextColumn get textValue => text().named('text')();
  IntColumn get repeatCount =>
      integer().named('repeat_count').withDefault(const Constant(1))();
  TextColumn get virtue => text().nullable()();
  TextColumn get sourceRef => text().named('source_ref')();
}

/// وحدة الحفظ: نطاق آيات مع حقول SM-2.
class HifzUnits extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planId => integer().named('plan_id').nullable()();
  IntColumn get startAyahId =>
      integer().named('start_ayah_id').references(Ayahs, #id)();
  IntColumn get endAyahId =>
      integer().named('end_ayah_id').references(Ayahs, #id)();
  IntColumn get pageFrom => integer().named('page_from').nullable()();
  IntColumn get faceFrom => integer().named('face_from').nullable()();
  TextColumn get status => text().withDefault(const Constant('new'))();
  RealColumn get easeFactor =>
      real().named('ease_factor').withDefault(const Constant(2.5))();
  IntColumn get intervalDays =>
      integer().named('interval_days').withDefault(const Constant(0))();
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  IntColumn get lastQuality => integer().named('last_quality').nullable()();
  DateTimeColumn get nextReviewAt =>
      dateTime().named('next_review_at').nullable()();
  IntColumn get accuracyPercent =>
      integer().named('accuracy_percent').nullable()();
}

class HifzPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  IntColumn get dailyNew =>
      integer().named('daily_new').withDefault(const Constant(0))();
  IntColumn get dailyRecent =>
      integer().named('daily_recent').withDefault(const Constant(0))();
  IntColumn get dailyCumulative =>
      integer().named('daily_cumulative').withDefault(const Constant(0))();
  DateTimeColumn get startDate => dateTime().named('start_date')();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
}

class RecitationAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get unitId =>
      integer().named('unit_id').references(HifzUnits, #id)();
  IntColumn get accuracyPercent => integer().named('accuracy_percent')();
  IntColumn get matched => integer()();
  IntColumn get substituted => integer()();
  IntColumn get omitted => integer()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
}

class ReadingSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get day => dateTime()();
  IntColumn get pagesRead =>
      integer().named('pages_read').withDefault(const Constant(0))();
  IntColumn get ayahsRead =>
      integer().named('ayahs_read').withDefault(const Constant(0))();
  TextColumn get source => text().nullable()();
}

class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ayahId => integer().named('ayah_id').references(Ayahs, #id)();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
}

class PrayerSettings extends Table {
  TextColumn get prayerKey => text()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  IntColumn get offsetMin =>
      integer().named('offset_min').withDefault(const Constant(0))();
  IntColumn get preReminderMin =>
      integer().named('pre_reminder_min').withDefault(const Constant(15))();
  IntColumn get iqamahMin =>
      integer().named('iqamah_min').withDefault(const Constant(15))();
  BoolColumn get iqamahEnabled =>
      boolean().named('iqamah_enabled').withDefault(const Constant(false))();
  IntColumn get adhanReciterId =>
      integer().named('adhan_reciter_id').nullable()();
  @override
  Set<Column> get primaryKey => {prayerKey};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get valueJson => text()();
  @override
  Set<Column> get primaryKey => {key};
}

class Downloads extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get reciterId =>
      integer().named('reciter_id').references(Reciters, #id)();
  IntColumn get surahId => integer().named('surah_id')();
  TextColumn get path => text()();
  IntColumn get bytes => integer()();
  TextColumn get sha256 => text()();
  DateTimeColumn get lastAccessedAt => dateTime().named('last_accessed_at')();
}

class NotificationSchedule extends Table {
  TextColumn get key => text()();
  DateTimeColumn get fireAt => dateTime().named('fire_at')();
  TextColumn get type => text()();
  TextColumn get status => text()();
  @override
  Set<Column> get primaryKey => {key};
}

/// سجل أخطاء محلي — بدون أي إرسال شخصي.
class ErrorLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get route => text()();
  TextColumn get code => text()();
  TextColumn get message => text()();
  TextColumn get stack => text().nullable()();
  TextColumn get appVersion => text().named('app_version')();
  TextColumn get osVersion => text().named('os_version')();
}

class SchemaMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}
