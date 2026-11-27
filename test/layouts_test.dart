import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mishkat/core/theme_layouts/layout_registry.dart';

void main() {
  test('عشرة قوالب بمعرّفات فريدة ومفاتيح ترجمة موجودة', () {
    expect(kLayouts.length, 10);
    expect(kLayouts.map((layout) => layout.id).toSet().length, 10);

    final decoded = jsonDecode(
      File('lib/l10n/app_ar.arb').readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final layout in kLayouts) {
      expect(decoded.containsKey(layout.key), isTrue, reason: layout.key);
    }
  });

  test('كل كل أسلوب تنقل مستخدم في قالب واحد على الأقل', () {
    for (final style in NavigationStyle.values) {
      expect(kLayouts.any((layout) => layout.navigationStyle == style), isTrue);
    }
  });
}
