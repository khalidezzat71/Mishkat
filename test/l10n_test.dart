import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('كل ملفات ARB تشترك في نفس مفاتيح الواجهة', () {
    final files = Directory('lib/l10n')
        .listSync()
        .where((entity) => entity.path.endsWith('.arb'))
        .map((entity) => File(entity.path))
        .toList();
    expect(files.length, 5);

    final keySets = files.map((file) {
      final decoded =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      return decoded.keys.where((key) => !key.startsWith('@')).toSet();
    }).toList();

    for (final keys in keySets.skip(1)) {
      expect(keys, keySets.first);
    }
  });
}
