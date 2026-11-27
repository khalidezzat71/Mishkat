/// توقيت كلمة داخل تلاوة آية.
class WordTiming {
  const WordTiming({
    required this.wordIndex,
    required this.startMs,
    required this.endMs,
  });

  final int wordIndex;
  final int startMs;
  final int endMs;
}

class AlignedWord {
  const AlignedWord({
    required this.token,
    required this.index,
    required this.startMs,
    required this.endMs,
  });

  final String token;
  final int index;
  final int startMs;
  final int endMs;
}

/// يربط كلمات الآية بتوقيتاتها للتمييز اللحظي أثناء التلاوة.
class WordAligner {
  const WordAligner();

  List<AlignedWord> align(
      Iterable<String> tokens, Iterable<WordTiming> timings) {
    final sorted = timings.toList()
      ..sort((a, b) => a.wordIndex.compareTo(b.wordIndex));
    final tokenList = tokens.toList();
    final result = <AlignedWord>[];
    for (final timing in sorted) {
      if (timing.wordIndex < 0 || timing.wordIndex >= tokenList.length) {
        continue;
      }
      result.add(
        AlignedWord(
          token: tokenList[timing.wordIndex],
          index: timing.wordIndex,
          startMs: timing.startMs < 0 ? 0 : timing.startMs,
          endMs: timing.endMs < timing.startMs ? timing.startMs : timing.endMs,
        ),
      );
    }
    return result;
  }

  AlignedWord? activeAt(List<AlignedWord> words, int positionMs) {
    for (final word in words) {
      if (positionMs >= word.startMs && positionMs < word.endMs) return word;
    }
    return null;
  }
}

/// يتحقق من صحة التوقيتات قبل Accept؛ أي خطأ يلغي الميزة ولا يعرض تمييزاً خاطئاً.
class AlignmentValidator {
  const AlignmentValidator();

  bool isValid(Iterable<WordTiming> timings, {required int audioDurationMs}) {
    final sorted = timings.toList()
      ..sort((a, b) => a.startMs.compareTo(b.startMs));
    for (var i = 0; i < sorted.length; i++) {
      final t = sorted[i];
      if (t.startMs < 0 || t.endMs <= t.startMs) return false;
      if (t.endMs > audioDurationMs) return false;
      if (i > 0 && t.startMs < sorted[i - 1].endMs) return false;
    }
    final indices = timings.map((t) => t.wordIndex).toSet();
    return indices.length == timings.length;
  }
}

/// عقد_proxy فقط: لا مفاتيح ولا عناوين سرية داخل التطبيق.
abstract class WordSyncProxy {
  const WordSyncProxy();

  Future<List<WordTiming>> fetchTimings({
    required String reciterId,
    required int surah,
    required int ayah,
  });
}
