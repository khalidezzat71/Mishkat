import 'package:mishkat_core/mishkat_core.dart';
import 'package:test/test.dart';

void main() {
  const scheduler = Sm2Scheduler();
  final now = DateTime(2026, 11, 27);

  group('SM-2', () {
    test('أول تقييم ناجح يعطي فترة يوم واحد', () {
      final next =
          scheduler.review(Sm2State.initial(), Sm2Quality.good, now: now);
      expect(next.repetitions, 1);
      expect(next.intervalDays, 1);
      expect(next.nextReview, now.add(const Duration(days: 1)));
    });

    test('التقييم الثاني يعطي 6 أيام', () {
      var state =
          scheduler.review(Sm2State.initial(), Sm2Quality.mastered, now: now);
      state = scheduler.review(state, Sm2Quality.mastered, now: now);
      expect(state.intervalDays, 6);
      expect(state.easeFactor, closeTo(2.7, 0.0001));
    });

    test('التقييم الثالث يضرب في معامل السهولة', () {
      var state =
          scheduler.review(Sm2State.initial(), Sm2Quality.mastered, now: now);
      state = scheduler.review(state, Sm2Quality.mastered, now: now);
      state = scheduler.review(state, Sm2Quality.mastered, now: now);
      expect(state.intervalDays, 16);
    });

    test('النسيان يعيد الوحدة لليوم التالي وصفر التكرارات', () {
      var state =
          scheduler.review(Sm2State.initial(), Sm2Quality.mastered, now: now);
      state = scheduler.review(state, Sm2Quality.needsReview, now: now);
      expect(state.repetitions, 0);
      expect(state.intervalDays, 1);
      expect(state.nextReview, now.add(const Duration(days: 1)));
    });

    test('عامل السهولة لا يقل عن 1.3', () {
      var state = Sm2State(
          easeFactor: 1.4,
          intervalDays: 10,
          repetitions: 5,
          nextReview: now,
          lastQuality: Sm2Quality.good);
      state = scheduler.review(state, Sm2Quality.needsReview, now: now);
      expect(state.easeFactor, greaterThanOrEqualTo(1.3));
    });

    test('نسبة التسميع تحدد التقييم', () {
      expect(scheduler.qualityFromAccuracy(96), Sm2Quality.mastered);
      expect(scheduler.qualityFromAccuracy(85), Sm2Quality.good);
      expect(scheduler.qualityFromAccuracy(79), Sm2Quality.needsReview);
    });

    test('الربط التلقائي: 96% تنتج موعد مراجعة أطول من 79%', () {
      final high = scheduler.review(
          Sm2State.initial(), scheduler.qualityFromAccuracy(96),
          now: now);
      final low = scheduler.review(
          Sm2State.initial(), scheduler.qualityFromAccuracy(79),
          now: now);
      expect(high.repetitions, greaterThan(low.repetitions));
    });
  });
}
