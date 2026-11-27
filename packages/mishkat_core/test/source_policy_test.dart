import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final root = Directory(p.join(Directory.current.path, '..', '..'));
  String readData(String name) =>
      File(p.join(root.path, 'assets', 'data', name)).readAsStringSync();

  test('الأذكار من مصادر سنية فقط', () {
    final decoded = jsonDecode(readData('athkar.json')) as Map<String, dynamic>;
    expect(decoded['policy'], 'sunni_only');
    final items = decoded['items'] as List<dynamic>;
    expect(items, isNotEmpty);
    const allowed = <String>[
      'البخاري',
      'مسلم',
      'أبي داود',
      'الترمذي',
      'النسائي',
      'ابن ماجه',
      'سورة',
    ];
    for (final item in items) {
      final source = item['source'] as String;
      expect(
        allowed.any(source.contains),
        isTrue,
        reason: 'unapproved source: $source',
      );
    }
  });

  test('سياسة المصادر العامة مسجّلة', () {
    final decoded =
        jsonDecode(readData('sources.json')) as Map<String, dynamic>;
    expect(decoded['policy'], 'free_first_sunni_only');
    final sources = decoded['sources'] as List<dynamic>;
    expect(sources, isNotEmpty);
    for (final source in sources) {
      expect(source['license'], isA<String>());
      expect(source['url'], startsWith('http'));
    }
  });
}
