import 'package:mishkat_core/src/memorization.dart';
import 'package:mishkat_core/src/sm2.dart';

/// عقد التعرف على الصوت: التنفيذ دائماً خلف Backend Proxy، بلا مفاتيح على الجهاز.
abstract class RecitationProxy {
  const RecitationProxy();

  Future<String> transcribe(
    List<int> audioBytes, {
    required String locale,
  });
}

class RecitationOutcome {
  const RecitationOutcome({
    required this.grade,
    required this.quality,
  });

  final RecitationGrade grade;
  final Sm2Quality quality;
}

/// يحوّل نسبة التطابق إلى جودة SM-2 دون أي حكم شخصي غير مُوثّق.
class RecitationQualityMapper {
  const RecitationQualityMapper({
    this.masteredAt = 90,
    this.goodAt = 70,
  })  : assert(masteredAt > goodAt),
        assert(goodAt > 0);

  final int masteredAt;
  final int goodAt;

  Sm2Quality map(int accuracyPercent) {
    if (accuracyPercent >= masteredAt) return Sm2Quality.mastered;
    if (accuracyPercent >= goodAt) return Sm2Quality.good;
    return Sm2Quality.needsReview;
  }
}

/// يربط المحاذاة اللغوية بجدولة التكرار المتباعد في مسار واحد مُختبَر.
class RecitationPipeline {
  const RecitationPipeline({
    this.grader = const RecitationGrader(),
    this.mapper = const RecitationQualityMapper(),
  });

  final RecitationGrader grader;
  final RecitationQualityMapper mapper;

  RecitationOutcome evaluate({
    required String expected,
    required String recognized,
  }) {
    final grade = grader.grade(expected, recognized);
    return RecitationOutcome(
      grade: grade,
      quality: mapper.map(grade.accuracyPercent),
    );
  }
}
