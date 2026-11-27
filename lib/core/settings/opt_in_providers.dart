import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';

/// كل ميزة اختيارية متوقفة افتراضياً ولا تُفعّل إلا بقرار صريح من المستخدم.
enum OptInKey { tafsir, wordSync, gaze, grading, widget, watch }

final optInProvider = StateProvider.family<bool, OptInKey>((ref, key) {
  final prefs = ref.watch(preferencesProvider);
  return prefs.maybeWhen(
    data: (p) => p.getBool('optIn.${key.name}') ?? false,
    orElse: () => false,
  );
});

Future<void> setOptIn(WidgetRef ref, OptInKey key, bool value) async {
  final prefs = await ref.read(preferencesProvider.future);
  await prefs.setBool('optIn.${key.name}', value);
  ref.read(optInProvider(key).notifier).state = value;
}

/// عنوان خادم الوكيل يُحقن وقت البناء فقط — لا مفاتيح داخل التطبيق.
const String aiProxyBaseUrl = String.fromEnvironment('MISHKAT_AI_PROXY_URL');

bool get isAiProxyConfigured => aiProxyBaseUrl.isNotEmpty;
