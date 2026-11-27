import 'package:mishkat_core/mishkat_core.dart';
import 'package:test/test.dart';

import 'support/dataset.dart';

void main() {
  late QuranDataset dataset;

  setUpAll(() {
    dataset = const QuranDatasetBuilder().build(
      uthmaniXml: uthmaniXml,
      metadataXml: metadataXml,
    );
  });

  group('مجموعة البيانات', () {
    test('114 سورة و6236 آية', () {
      expect(dataset.surahs.length, 114);
      expect(dataset.ayahs.length, 6236);
      expect(dataset.ayahs.first.id, 1);
      expect(dataset.ayahs.last.id, 6236);
    });

    test('رقم الصفحة والجزء والحزب من بيانات مجمع/تنزيل', () {
      final first = dataset.ayahs.first;
      expect(first.page, 1);
      expect(first.juz, 1);
      expect(first.hizb, 1);
      final baqarahFirst = dataset.ayahs.firstWhere(
        (a) => a.surahId == 2 && a.ayahNo == 1,
      );
      expect(baqarahFirst.page, 2);
      expect(dataset.ayahs.last.page, 604);
    });

    test('النص الحرفي لم يُعدَّل', () {
      expect(dataset.ayahs.first.textUthmani,
          'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ');
    });

    test('عمودا البحث مشتقّان وليسا النص المعروض', () {
      expect(dataset.ayahs.first.textSearch, 'بسم الله الرحمن الرحيم');
      expect(dataset.ayahs.first.textUthmani,
          isNot(dataset.ayahs.first.textSearch));
    });
  });

  group('البحث بدون تشكيل', () {
    late QuranSearchIndex index;

    setUpAll(() => index = QuranSearchIndex(dataset.ayahs));

    test('كلمة واحدة', () {
      expect(index.search('بسم'), contains(1));
    });

    test('بدون تشكيل وبأشكال الألف', () {
      expect(index.search('الرحمن'), contains(1));
      expect(index.search('الرحيم'), contains(1));
    });

    test('كلمتان معاً (AND)', () {
      expect(index.search('بسم الله'), contains(1));
      expect(index.search('بسم زززز'), isEmpty);
    });

    test('نتيجة غير موجودة', () {
      expect(index.search('zzzz'), isEmpty);
      expect(index.search('   '), isEmpty);
    });

    test('استرجاع الآية من الفهرس', () {
      expect(index.ayah(1)?.surahId, 1);
      expect(index.ayah(1)?.ayahNo, 1);
    });
  });
}
