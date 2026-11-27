import 'quran_dataset.dart';

/// فهرس بحث في الذاكرة يطابق سلوك عمودي FTS5 في Drift.
///
/// يُستخدم للاختبار وللبحث قبل تهيئة قاعدة البيانات على الجهاز.
class QuranSearchIndex {
  QuranSearchIndex(Iterable<QuranAyah> ayahs) {
    for (final ayah in ayahs) {
      _texts[ayah.id] = ayah;
      for (final token in _tokens(ayah.textSearch)) {
        _plain.putIfAbsent(token, () => <int>{}).add(ayah.id);
      }
      for (final token in _tokens(ayah.textSearchExpanded)) {
        _expanded.putIfAbsent(token, () => <int>{}).add(ayah.id);
      }
    }
  }

  final Map<int, QuranAyah> _texts = <int, QuranAyah>{};
  final Map<String, Set<int>> _plain = <String, Set<int>>{};
  final Map<String, Set<int>> _expanded = <String, Set<int>>{};

  Iterable<String> _tokens(String text) =>
      text.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);

  /// بحث بكل الكلمات (AND) مع تطابق بادئ، في العمودين معاً.
  List<int> search(String query) {
    final terms =
        query.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (terms.isEmpty) return <int>[];

    Set<int>? matches;
    for (final term in terms) {
      final found = <int>{};
      for (final entry in _plain.entries) {
        if (entry.key.startsWith(term)) found.addAll(entry.value);
      }
      for (final entry in _expanded.entries) {
        if (entry.key.startsWith(term)) found.addAll(entry.value);
      }
      matches = matches == null ? found : matches.intersection(found);
      if (matches.isEmpty) break;
    }
    final result = matches?.toList() ?? <int>[];
    result.sort();
    return result;
  }

  QuranAyah? ayah(int id) => _texts[id];
}
