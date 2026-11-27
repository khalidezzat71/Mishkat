import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('الأصول القرآنية المدمجة موجودة', () {
    expect(File('assets/quran/manifest.json').existsSync(), isTrue);
    expect(File('assets/quran/quran-dataset.json').existsSync(), isTrue);
    expect(File('assets/quran/quran-uthmani-v1.1.xml').existsSync(), isTrue);
  });
}
