import 'package:mishkat_core/mishkat_core.dart';
import 'package:test/test.dart';

void main() {
  final ayahs = [
    const AyahMetadata(id: 1, surahId: 1, page: 1, juz: 1, hizb: 1),
    const AyahMetadata(id: 2, surahId: 1, page: 1, juz: 1, hizb: 1),
    const AyahMetadata(id: 3, surahId: 2, page: 2, juz: 1, hizb: 1),
    const AyahMetadata(id: 4, surahId: 2, page: 604, juz: 30, hizb: 60),
  ];

  group('فلاتر البحث المحلية', () {
    test('فلتر فارغ يعيد كل الآيات', () {
      expect(applyAyahFilter(ayahs, const AyahFilter()).map((a) => a.id), [
        1,
        2,
        3,
        4,
      ]);
    });

    test('الفلترة بالسورة', () {
      final result = applyAyahFilter(ayahs, const AyahFilter(surahId: 2));
      expect(result.map((a) => a.id), [3, 4]);
    });

    test('دمج أكثر من شرط (AND)', () {
      final result = applyAyahFilter(
        ayahs,
        const AyahFilter(surahId: 1, juz: 1, page: 1, hizb: 1),
      );
      expect(result.map((a) => a.id), [1, 2]);
    });

    test('صفحة غير موجودة تعيد قائمة فارغة', () {
      expect(
        applyAyahFilter(ayahs, const AyahFilter(page: 300)),
        isEmpty,
      );
    });

    test('فلاتر متساوية القيم تُعدّ متطابقة لتجنّب إعادة البحث', () {
      expect(const AyahFilter(surahId: 1), const AyahFilter(surahId: 1));
      expect(
        const AyahFilter(surahId: 1).hashCode,
        const AyahFilter(surahId: 1).hashCode,
      );
      expect(const AyahFilter(surahId: 1), isNot(const AyahFilter(surahId: 2)));
    });

    test('القيم خارج النطاق تُرفض قبل التنفيذ', () {
      expect(
          () => const AyahFilter(surahId: 115).validate(), throwsArgumentError);
      expect(() => const AyahFilter(juz: 31).validate(), throwsArgumentError);
      expect(() => const AyahFilter(page: 605).validate(), throwsArgumentError);
      expect(() => const AyahFilter(hizb: 61).validate(), throwsArgumentError);
    });
  });
}
