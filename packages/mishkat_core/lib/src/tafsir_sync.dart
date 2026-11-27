/// إدارة مصادر التفسير وقت التشغيل.
///
/// لا يُضمّن أي نص تفسير في المستودع: التفسير يُجلب عبر Content Sync فقط،
/// ويُخزَّن مؤقتاً ≤ 7 أيام. كل الإصدارات المعتمدة سنية المرجعية.
enum Sect { sunni, other }

class TafsirEdition {
  const TafsirEdition({
    required this.id,
    required this.nameAr,
    required this.language,
    required this.license,
    required this.sect,
    required this.runtimeOnly,
  });

  final String id;
  final String nameAr;
  final String language;
  final String license;
  final Sect sect;
  final bool runtimeOnly;
}

/// الإصدارات السنية المجانية المعتمدة للجلب وقت التشغيل.
const List<TafsirEdition> kApprovedTafsirEditions = [
  TafsirEdition(
    id: 'ar.muyassar',
    nameAr: 'التفسير الميسّر',
    language: 'ar',
    license: 'Quran Foundation Content Sync — runtime only',
    sect: Sect.sunni,
    runtimeOnly: true,
  ),
  TafsirEdition(
    id: 'ar.saadi',
    nameAr: 'تفسير السعدي',
    language: 'ar',
    license: 'Quran Foundation Content Sync — runtime only',
    sect: Sect.sunni,
    runtimeOnly: true,
  ),
  TafsirEdition(
    id: 'ar.ibnkatheer',
    nameAr: 'تفسير ابن كثير',
    language: 'ar',
    license: 'Quran Foundation Content Sync — runtime only',
    sect: Sect.sunni,
    runtimeOnly: true,
  ),
  TafsirEdition(
    id: 'ar.jalalayn',
    nameAr: 'تفسير الجلالين',
    language: 'ar',
    license: 'Quran Foundation Content Sync — runtime only',
    sect: Sect.sunni,
    runtimeOnly: true,
  ),
];

class TafsirCacheEntry {
  const TafsirCacheEntry({
    required this.editionId,
    required this.ayahId,
    required this.text,
    required this.fetchedAt,
  });

  final String editionId;
  final int ayahId;
  final String text;
  final DateTime fetchedAt;
}

/// كاش ذاكرة مقيّد بالزمن والسعة — لا يكتب في Git ولا يرسل بيانات شخصية.
class TafsirCache {
  TafsirCache({this.ttl = const Duration(days: 7), this.maxEntries = 2000});

  final Duration ttl;
  final int maxEntries;
  final Map<String, TafsirCacheEntry> _entries = {};

  static String _key(String editionId, int ayahId) => '$editionId:$ayahId';

  void put(TafsirCacheEntry entry) {
    if (_entries.length >= maxEntries &&
        !_entries.containsKey(_key(entry.editionId, entry.ayahId))) {
      final oldest = _entries.values.reduce(
        (a, b) => a.fetchedAt.isBefore(b.fetchedAt) ? a : b,
      );
      _entries.remove(_key(oldest.editionId, oldest.ayahId));
    }
    _entries[_key(entry.editionId, entry.ayahId)] = entry;
  }

  /// يُعيد النص فقط إن كان ضمن 7 أيام، وإلا يُزيله ويُعيد null.
  String? get(String editionId, int ayahId, {DateTime? now}) {
    final key = _key(editionId, ayahId);
    final entry = _entries[key];
    if (entry == null) return null;
    final reference = now ?? DateTime.now();
    if (reference.difference(entry.fetchedAt) > ttl) {
      _entries.remove(key);
      return null;
    }
    return entry.text;
  }

  int prune({DateTime? now}) {
    final reference = now ?? DateTime.now();
    final expired = _entries.entries
        .where((e) => reference.difference(e.value.fetchedAt) > ttl)
        .map((e) => e.key)
        .toList();
    for (final key in expired) {
      _entries.remove(key);
    }
    return expired.length;
  }

  int get length => _entries.length;
}

/// يمنع أي مصدر غير سني أو أي مصدر يخالف قيد «وقت التشغيل فقط».
class TafsirSourcePolicy {
  const TafsirSourcePolicy();

  bool isApproved(TafsirEdition edition) =>
      edition.sect == Sect.sunni &&
      edition.runtimeOnly &&
      kApprovedTafsirEditions.any((e) => e.id == edition.id);

  TafsirEdition requireApproved(String id) {
    final edition = kApprovedTafsirEditions.where((e) => e.id == id);
    if (edition.isEmpty || !isApproved(edition.first)) {
      throw ArgumentError.value(
          id, 'editionId', 'not an approved Sunni runtime source');
    }
    return edition.first;
  }
}
