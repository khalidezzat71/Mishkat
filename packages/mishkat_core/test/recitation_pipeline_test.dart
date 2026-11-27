import 'package:mishkat_core/mishkat_core.dart';
import 'package:test/test.dart';

class _FakeProxy implements RecitationProxy {
  const _FakeProxy(this.text);

  final String text;

  @override
  Future<String> transcribe(List<int> audioBytes,
      {required String locale}) async {
    return text;
  }
}

void main() {
  group('مسار تقييم التسميع', () {
    const pipeline = RecitationPipeline();
    const mapper = RecitationQualityMapper();

    test('الحدود: 90 متقن، 70 جيد، أقل من ذلك إعادة', () {
      expect(mapper.map(100), Sm2Quality.mastered);
      expect(mapper.map(90), Sm2Quality.mastered);
      expect(mapper.map(89), Sm2Quality.good);
      expect(mapper.map(70), Sm2Quality.good);
      expect(mapper.map(69), Sm2Quality.needsReview);
    });

    test('تطابق تام يعطي 100٪ وجودة متقنة', () {
      final outcome = pipeline.evaluate(
        expected: 'بسم الله الرحمن الرحيم',
        recognized: 'بسم الله الرحمن الرحيم',
      );
      expect(outcome.grade.accuracyPercent, 100);
      expect(outcome.grade.matched, 4);
      expect(outcome.grade.omitted, 0);
      expect(outcome.quality, Sm2Quality.mastered);
    });

    test('كلمة ناقصة تُخفّض الجودة إلى إعادة', () {
      final outcome = pipeline.evaluate(
        expected: 'بسم الله الرحمن',
        recognized: 'بسم الرحمن',
      );
      expect(outcome.grade.matched, 2);
      expect(outcome.grade.omitted, 1);
      expect(outcome.grade.accuracyPercent, 67);
      expect(outcome.quality, Sm2Quality.needsReview);
    });

    test('نص متوقع فارغ لا يمنح درجة', () {
      final outcome = pipeline.evaluate(expected: '', recognized: 'بسم');
      expect(outcome.grade.accuracyPercent, 0);
      expect(outcome.quality, Sm2Quality.needsReview);
    });

    test('يعمل مع عقد الوكيل دون معرفة مصدر الصوت', () async {
      const proxy = _FakeProxy('بسم الله');
      final recognized = await proxy.transcribe(
        const [1, 2, 3],
        locale: 'ar',
      );
      final outcome = pipeline.evaluate(
        expected: 'بسم الله',
        recognized: recognized,
      );
      expect(outcome.grade.matched, 2);
      expect(outcome.quality, Sm2Quality.mastered);
    });
  });
}
