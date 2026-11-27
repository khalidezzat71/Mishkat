import 'package:mishkat_core/mishkat_core.dart';
import 'package:test/test.dart';

void main() {
  const normalizer = ArabicSearchNormalizer();

  group('تطبيع البحث', () {
    test('البسملة بدون تشكيل', () {
      const uthmani = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ';
      expect(normalizer.normalize(uthmani), 'بسم الله الرحمن الرحيم');
    });

    test('توحيد أشكال الألف والهاء والياء', () {
      expect(normalizer.normalize('آأإٱ'), 'اااا');
      expect(normalizer.normalize('ؤئ'), 'وي');
      expect(normalizer.normalize('ةى'), 'هي');
    });

    test('إزالة علامات الوقف القرآنية دون حذف الحروف', () {
      final withMarks = 'قُلْ هُوَ ٱللَّهُ أَحَدٌ ۞';
      expect(normalizer.normalize(withMarks), 'قل هو الله احد');
    });

    test('المستخدم يكتب الكلمة نفسها بدون تشكيل فيطابق النص المخزن', () {
      const verse = 'وَٱلضُّحَىٰ ۙ وَٱلَّيْلِ إِذَا سَجَىٰ';
      // الشدة في «ٱلضُّحَىٰ» تمثّل إدغام اللام (فالصيغة المعتادة والضحى)،
      // وفي «ٱلَّيْلِ» حرف مفرد (فالصيغة المعتادة والليل). لذلك يُفهرَس
      // عمودان في FTS5: صيغة إسقاط الشدة وصيغة توسيعها، ويطابق البحث أياً منهما.
      final plain = normalizer.normalize(verse);
      final expanded = normalizer.normalizeExpanded(verse);
      expect(plain, contains('والضحي'));
      expect(expanded, contains('والليل'));
      expect(
        normalizer.normalize('والضحى والليل إذا سجى'),
        'والضحي والليل اذا سجي',
      );
    });

    test('توحيد المسافات', () {
      expect(normalizer.normalize('  الحمد   لله  '), 'الحمد لله');
    });

    test('لا يعدّل الحروف الأساسية', () {
      expect(normalizer.stripDiacritics('الْحَمْدُ'), 'الحمد');
    });
  });
}
