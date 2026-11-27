/// تقييم جودة التسميع في نظام التكرار المتباعد SM-2.
enum Sm2Quality {
  mastered(5),
  good(4),
  needsReview(2);

  const Sm2Quality(this.value);
  final int value;
}

/// حالة مراجعة محفوظة في قاعدة البيانات.
class Sm2State {
  const Sm2State({
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    required this.nextReview,
    required this.lastQuality,
  });

  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime nextReview;
  final Sm2Quality lastQuality;

  factory Sm2State.initial() => Sm2State(
        easeFactor: 2.5,
        intervalDays: 0,
        repetitions: 0,
        nextReview: DateTime.now(),
        lastQuality: Sm2Quality.good,
      );

  Sm2State copyWith({
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
    DateTime? nextReview,
    Sm2Quality? lastQuality,
  }) {
    return Sm2State(
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      nextReview: nextReview ?? this.nextReview,
      lastQuality: lastQuality ?? this.lastQuality,
    );
  }
}

/// جدولة SM-2 الكلاسيكية، مع ربط نسبة التسميع بالتقييم.
class Sm2Scheduler {
  const Sm2Scheduler();

  Sm2State review(Sm2State state, Sm2Quality quality, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final q = quality.value;

    if (q < 3) {
      // استعادة التعلم: يعود للغد ويعاد بناء عدد التكرارات.
      return state.copyWith(
        repetitions: 0,
        intervalDays: 1,
        easeFactor: state.easeFactor < 1.3 ? 1.3 : state.easeFactor,
        nextReview: reference.add(const Duration(days: 1)),
        lastQuality: quality,
      );
    }

    final interval = state.repetitions == 0
        ? 1
        : state.repetitions == 1
            ? 6
            : (state.intervalDays * state.easeFactor).round();

    var ease = state.easeFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
    if (ease < 1.3) ease = 1.3;

    return state.copyWith(
      easeFactor: ease,
      intervalDays: interval < 1 ? 1 : interval,
      repetitions: state.repetitions + 1,
      nextReview: reference.add(Duration(days: interval < 1 ? 1 : interval)),
      lastQuality: quality,
    );
  }

  /// تحويل نسبة دقة التسميع (0..100) إلى تقييم SM-2.
  Sm2Quality qualityFromAccuracy(num accuracyPercent) {
    if (accuracyPercent >= 95) return Sm2Quality.mastered;
    if (accuracyPercent >= 80) return Sm2Quality.good;
    return Sm2Quality.needsReview;
  }
}
