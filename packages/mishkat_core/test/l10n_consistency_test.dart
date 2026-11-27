import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('كل ملفات ARB تحتوي على نفس مفاتيح الواجهة', () {
    final dir =
        Directory(p.join(Directory.current.path, '..', '..', 'lib', 'l10n'));
    final locales = ['ar', 'en', 'fr', 'ur', 'id'];
    Set<String>? reference;

    for (final locale in locales) {
      final file = File(p.join(dir.path, 'app_$locale.arb'));
      expect(file.existsSync(), isTrue, reason: 'missing $locale');
      final decoded =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final keys = decoded.keys.where((k) => !k.startsWith('@')).toSet();
      reference ??= keys;
      expect(keys, equals(reference), reason: 'key mismatch in $locale');
      expect(keys, isNotEmpty);
    }
  });

  test('العربية هي لغة القالب والاحتياط', () {
    final yaml = File(
      p.join(Directory.current.path, '..', '..', 'l10n.yaml'),
    ).readAsStringSync();
    expect(yaml, contains('template-arb-file: app_ar.arb'));
  });
}
