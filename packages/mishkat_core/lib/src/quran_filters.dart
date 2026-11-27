/// بيانات وصفية مختصرة للآية تكفي لتطبيق الفلاتر محلياً بلا اتصال شبكي.
class AyahMetadata {
  const AyahMetadata({
    required this.id,
    required this.surahId,
    required this.page,
    required this.juz,
    required this.hizb,
  });

  final int id;
  final int surahId;
  final int page;
  final int juz;
  final int hizb;
}

/// فلاتر البحث كلها تُطبَّق على الجهاز — لا تُرسل لأي خادم.
class AyahFilter {
  const AyahFilter({this.surahId, this.juz, this.page, this.hizb});

  final int? surahId;
  final int? juz;
  final int? page;
  final int? hizb;

  bool get isEmpty =>
      surahId == null && juz == null && page == null && hizb == null;

  /// يرفض القيم خارج النطاق المعروف قبل أي استخدام في SQL.
  void validate() {
    if (surahId != null && (surahId! < 1 || surahId! > 114)) {
      throw ArgumentError.value(surahId, 'surahId', 'must be 1..114');
    }
    if (juz != null && (juz! < 1 || juz! > 30)) {
      throw ArgumentError.value(juz, 'juz', 'must be 1..30');
    }
    if (page != null && (page! < 1 || page! > 604)) {
      throw ArgumentError.value(page, 'page', 'must be 1..604');
    }
    if (hizb != null && (hizb! < 1 || hizb! > 60)) {
      throw ArgumentError.value(hizb, 'hizb', 'must be 1..60');
    }
  }

  bool matches(AyahMetadata ayah) =>
      (surahId == null || ayah.surahId == surahId) &&
      (juz == null || ayah.juz == juz) &&
      (page == null || ayah.page == page) &&
      (hizb == null || ayah.hizb == hizb);
}

/// نسخة قابلة للاختبار من الفلترة، تُستخدم عند العمل في الذاكرة.
List<AyahMetadata> applyAyahFilter(
  Iterable<AyahMetadata> ayahs,
  AyahFilter filter,
) {
  filter.validate();
  if (filter.isEmpty) return ayahs.toList();
  return ayahs.where(filter.matches).toList();
}
