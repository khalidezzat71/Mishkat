import 'dart:math';

/// نوع خطة الختمة/الحفظ.
enum HifzPlanType { juz, page, face, surah, custom }

/// خطة حفظ/ختمة كاملة قابلة للتسلسل في قاعدة البيانات.
class HifzPlan {
  const HifzPlan({
    required this.type,
    required this.startDate,
    required this.dailyNew,
    required this.dailyRecent,
    required this.dailyCumulative,
    this.endDate,
  });

  final HifzPlanType type;
  final DateTime startDate;
  final DateTime? endDate;
  final int dailyNew;
  final int dailyRecent;
  final int dailyCumulative;

  int get dailyTotal => dailyNew + dailyRecent + dailyCumulative;
}

/// وحدة عمل يومية واحدة.
class DailyWorkload {
  const DailyWorkload({
    required this.day,
    required this.newUnits,
    required this.recentReviews,
    required this.cumulativeReviews,
    required this.firstUnit,
    required this.lastUnit,
  });

  final DateTime day;
  final int newUnits;
  final int recentReviews;
  final int cumulativeReviews;
  final int firstUnit;
  final int lastUnit;

  int get total => newUnits + recentReviews + cumulativeReviews;

  /// تقدير تقريبي: 4 دقائق للجديد، 2 للمراجعة الصغرى، 3 للكبرى.
  int get estimatedMinutes =>
      newUnits * 4 + recentReviews * 2 + cumulativeReviews * 3;
}

/// يوزّع ختمة على الأيام دون أي اعتماد على الشبكة.
class KhatmahPlanner {
  const KhatmahPlanner();

  static const int totalPages = 604;
  static const int facesPerPage = 2;
  static const int totalJuz = 30;
  static const int totalFaces = totalPages * facesPerPage;

  List<DailyWorkload> build(HifzPlan plan) {
    final unitCount = switch (plan.type) {
      HifzPlanType.page => totalPages,
      HifzPlanType.face => totalFaces,
      HifzPlanType.juz => totalJuz,
      // تُحدَّد لاحقاً من عدد آيات السور عند بناء خطة سورة/مخصصة.
      HifzPlanType.surah || HifzPlanType.custom => totalPages,
    };
    if (plan.dailyNew <= 0) {
      throw ArgumentError.value(plan.dailyNew, 'dailyNew', 'must be positive');
    }
    final days = (unitCount / plan.dailyNew).ceil();
    return List.generate(days, (index) {
      final first = index * plan.dailyNew + 1;
      final last = min(first + plan.dailyNew - 1, unitCount);
      return DailyWorkload(
        day: plan.startDate.add(Duration(days: index)),
        newUnits: last - first + 1,
        recentReviews: plan.dailyRecent,
        cumulativeReviews: plan.dailyCumulative,
        firstUnit: first,
        lastUnit: last,
      );
    });
  }
}

/// نتيجة تقييم التسميع بمقارنة الكلمات.
class RecitationGrade {
  const RecitationGrade({
    required this.accuracyPercent,
    required this.matched,
    required this.substituted,
    required this.omitted,
  });

  final int accuracyPercent;
  final int matched;
  final int substituted;
  final int omitted;
}

/// يقارن الكلمات المتوقعة بالمسموعة بأقرب محاذاة (LCS) لحساب الدقة.
class RecitationGrader {
  const RecitationGrader();

  static List<String> words(String text) =>
      text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

  RecitationGrade grade(String expected, String recognized) {
    final a = words(expected);
    final b = words(recognized);
    if (a.isEmpty) {
      return const RecitationGrade(
        accuracyPercent: 0,
        matched: 0,
        substituted: 0,
        omitted: 0,
      );
    }

    final dp = List.generate(
      a.length + 1,
      (_) => List<int>.filled(b.length + 1, 0),
    );
    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        dp[i][j] = a[i - 1] == b[j - 1]
            ? dp[i - 1][j - 1] + 1
            : max(dp[i - 1][j], dp[i][j - 1]);
      }
    }
    final matched = dp[a.length][b.length];
    final omitted = a.length - matched;
    final substituted = max(0, b.length - matched);
    final accuracy = ((matched / a.length) * 100).round();
    return RecitationGrade(
      accuracyPercent: accuracy,
      matched: matched,
      substituted: substituted,
      omitted: omitted,
    );
  }
}

/// يبني نصاً مخفياً للتدريب (Cloze) دون تعديل نص المصحف الأصلي.
class ClozeBuilder {
  const ClozeBuilder();

  /// يخفي [ratio] من الكلمات باختيار ثابت حسب [seed] لضمان قابلية التكرار.
  String build(String uthmaniText, {double ratio = 0.3, int seed = 1}) {
    final tokens = RecitationGrader.words(uthmaniText);
    if (tokens.isEmpty) return '';
    final random = Random(seed);
    final count = min(tokens.length, (tokens.length * ratio).round());
    final hidden = <int>{};
    while (hidden.length < count) {
      hidden.add(random.nextInt(tokens.length));
    }
    return tokens
        .asMap()
        .map(
          (index, word) =>
              MapEntry(index, hidden.contains(index) ? '______' : word),
        )
        .values
        .join(' ');
  }
}
