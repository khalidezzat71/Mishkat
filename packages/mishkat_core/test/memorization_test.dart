import 'package:mishkat_core/mishkat_core.dart';
import 'package:test/test.dart';

void main() {
  const planner = KhatmahPlanner();
  final start = DateTime(2026, 11, 27);

  group('خطة الختمة', () {
    test('صفحتان يومياً = 302 يوماً و604 صفحة', () {
      final days = planner.build(
        HifzPlan(
          type: HifzPlanType.page,
          startDate: start,
          dailyNew: 2,
          dailyRecent: 3,
          dailyCumulative: 2,
        ),
      );
      expect(days.length, 302);
      expect(days.first.firstUnit, 1);
      expect(days.first.lastUnit, 2);
      expect(days.last.lastUnit, 604);
      expect(days.first.recentReviews, 3);
      expect(days.first.cumulativeReviews, 2);
      expect(days.first.estimatedMinutes, 2 * 4 + 3 * 2 + 2 * 3);
    });

    test('الوجه: 1208 وجهاً، 4 يومياً = 302 يوماً', () {
      final days = planner.build(
        HifzPlan(
          type: HifzPlanType.face,
          startDate: start,
          dailyNew: 4,
          dailyRecent: 0,
          dailyCumulative: 0,
        ),
      );
      expect(days.length, 302);
      expect(days.last.lastUnit, 1208);
    });

    test('الجزء: 30 يوماً', () {
      final days = planner.build(
        HifzPlan(
          type: HifzPlanType.juz,
          startDate: start,
          dailyNew: 1,
          dailyRecent: 0,
          dailyCumulative: 0,
        ),
      );
      expect(days.length, 30);
    });

    test('رفض خطة بلا ورد جديد', () {
      expect(
        () => planner.build(
          HifzPlan(
            type: HifzPlanType.page,
            startDate: start,
            dailyNew: 0,
            dailyRecent: 1,
            dailyCumulative: 1,
          ),
        ),
        throwsArgumentError,
      );
    });
  });

  group('تقييم التسميع', () {
    const grader = RecitationGrader();
    const verse = 'بسم الله الرحمن الرحيم';

    test('تطابق كامل = 100%', () {
      final grade = grader.grade(verse, verse);
      expect(grade.accuracyPercent, 100);
      expect(grade.matched, 4);
      expect(grade.omitted, 0);
      expect(grade.substituted, 0);
    });

    test('كلمة ناقصة تخصم 25%', () {
      final grade = grader.grade(verse, 'بسم الله الرحمن');
      expect(grade.accuracyPercent, 75);
      expect(grade.omitted, 1);
    });

    test('كلمة مبدّلة تُحسب خطأ', () {
      final grade = grader.grade(verse, 'بسم الله الرحمن كلام آخر');
      expect(grade.accuracyPercent, lessThan(100));
      expect(grade.substituted, greaterThanOrEqualTo(1));
    });

    test('لا كلمات متوقعة', () {
      expect(grader.grade('  ', 'بسم').accuracyPercent, 0);
    });
  });

  group('إخفاء الكلمات للتدريب', () {
    const builder = ClozeBuilder();
    const verse = 'بسم الله الرحمن الرحيم';

    test('نص المصحف الأصلي لا يتغير', () {
      expect(verse, 'بسم الله الرحمن الرحيم');
      expect(builder.build(verse), isNot(verse));
    });

    test('عدد الكلمات المخفية ثابت لنفس البذرة', () {
      final first = builder.build(verse, ratio: 0.5, seed: 7);
      final second = builder.build(verse, ratio: 0.5, seed: 7);
      expect(first, second);
      expect(
          RecitationGrader.words(first).where((w) => w == '______').length, 2);
    });

    test('بذرة أخرى تعطي توزيعاً مختلفاً', () {
      expect(
          builder.build(verse, seed: 1), isNot(builder.build(verse, seed: 2)));
    });
  });
}
