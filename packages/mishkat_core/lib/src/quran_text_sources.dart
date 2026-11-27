/// مصادر نص المصحف القابلة للتبديل. كلها سنية المرجعية، والنص لا يُعدَّل.
///
/// الافتراضي هو المصدر المدمج ليعمل التطبيق بلا إنترنت. المصادر الشبكية
/// تُجلب وقت التشغيل وتُخزَّن محلياً، ولا تُضمَّن بياناتها الخام في المستودع.
enum QuranTextSource {
  tanzilUthmani,
  quranComUthmani;

  static QuranTextSource fromId(String id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    return QuranTextSource.tanzilUthmani;
  }

  String get id => switch (this) {
    QuranTextSource.tanzilUthmani => 'tanzil_uthmani',
    QuranTextSource.quranComUthmani => 'quran_com_uthmani',
  };

  bool get requiresNetwork => this == QuranTextSource.quranComUthmani;
}
