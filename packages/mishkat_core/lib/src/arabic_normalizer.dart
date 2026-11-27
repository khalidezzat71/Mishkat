/// تطبيع للبحث فقط — لا يُعرض أبداً كنص قرآني.
///
/// يزيل الحركات وعلامات الوقف والتطويل، ويوحّد أشكال الألف والياء والهاء،
/// ليطابق البحثُ المستخدمَ حتى لو كتب الكلمة بدون تشكيل.
class ArabicSearchNormalizer {
  const ArabicSearchNormalizer();

  static const _diacritics = <int>[
    0x064B, // فتحتان
    0x064C, // ضمتان
    0x064D, // كسرتان
    0x064E, // فتحة
    0x064F, // ضمة
    0x0650, // كسرة
    0x0651, // شدة
    0x0652, // سكون
    0x0653, // مدة
    0x0654, // همزة فوقية
    0x0655, // همزة تحتية
    0x0656, // علامة صغيرة
    0x0670, // ألف فوقية
    0x0640, // تطويل
  ];

  static const _quranicMarks = <int>[
    0x06D6,
    0x06D7,
    0x06D8,
    0x06D9,
    0x06DA,
    0x06DB,
    0x06DC,
    0x06DD,
    0x06DE,
    0x06DF,
    0x06E0,
    0x06E1,
    0x06E2,
    0x06E3,
    0x06E4,
    0x06E7,
    0x06E8,
    0x06EA,
    0x06EB,
    0x06EC,
    0x06ED,
  ];

  /// يزيل التشكيل وعلامات الوقف مع إبقاء الحروف كما هي.
  String stripDiacritics(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      if (_diacritics.contains(rune) || _quranicMarks.contains(rune)) {
        continue;
      }
      buffer.writeCharCode(rune);
    }
    return buffer.toString();
  }

  /// التطبيع الكامل المستخدم لبناء عمود `text_search` في FTS5.
  ///
  /// الشدة تُهمَل هنا، لأن الرسم العثماني يكتب الحرف المشدّد غالباً مرتين
  /// (مثل الله) أو يمثّل إدغام حرف سابق مكتوب (مثل الرحيم).
  String normalize(String text) => _unify(stripDiacritics(text));

  /// صيغة بديلة توسّع الشدة بتكرار الحرف السابق.
  ///
  /// تُفهرَس ك عمود ثانٍ في FTS5 حتى يطابق البحث صيغاً مثل «الليل» و«الضحى»
  /// حين كُتبت الشدة على حرف مفرد في الرسم العثماني.
  String normalizeExpanded(String text) {
    final buffer = StringBuffer();
    String? lastBase;
    for (final rune in text.runes) {
      if (rune == 0x0651) {
        if (lastBase != null) buffer.write(lastBase);
        continue;
      }
      if (_diacritics.contains(rune) || _quranicMarks.contains(rune)) {
        continue;
      }
      final char = String.fromCharCode(rune);
      buffer.write(char);
      lastBase = char;
    }
    return _unify(buffer.toString());
  }

  String _unify(String stripped) {
    final unified = stripped
        .replaceAll(RegExp('[آأإٱ]'), 'ا')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي');
    return unified.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
