import 'package:mishkat_core/mishkat_core.dart';
import 'package:test/test.dart';

void main() {
  test('مصدر المصحف المدمج هو الافتراض ولا يحتاج شبكة', () {
    const source = QuranTextSource.tanzilUthmani;
    expect(source.id, 'tanzil_uthmani');
    expect(source.requiresNetwork, isFalse);
    expect(QuranTextSource.fromId(''), source);
    expect(QuranTextSource.fromId('unknown'), source);
  });

  test('المصدر الشبكي قابل للتبديل ومعرّف بمعرّف ثابت', () {
    const source = QuranTextSource.quranComUthmani;
    expect(source.id, 'quran_com_uthmani');
    expect(source.requiresNetwork, isTrue);
    expect(QuranTextSource.fromId(source.id), source);
    expect(
      QuranTextSource.values.map((item) => item.id).toSet(),
      containsAll(<String>['tanzil_uthmani', 'quran_com_uthmani']),
    );
  });
}
