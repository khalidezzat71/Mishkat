import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mishkat/core/settings/opt_in_providers.dart';
import 'package:mishkat_core/mishkat_core.dart';

import '../../../app/advanced_providers.dart';
import '../../../app/providers.dart';
import '../data/quran_repository.dart';

final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  return QuranRepository(ref.watch(databaseProvider), rootBundle);
});

/// يبني الفهرس عند أول تشغيل — يعمل بالكامل بدون إنترنت.
final quranReadyProvider = FutureProvider<void>((ref) async {
  await ref.watch(quranRepositoryProvider).ensureIndexed();
});

final quranSearchProvider = FutureProvider.family<List<int>, String>((
  ref,
  query,
) async {
  if (query.trim().isEmpty) return <int>[];
  await ref.watch(quranReadyProvider.future);
  return ref.watch(quranRepositoryProvider).search(query);
});

/// النص الحرفي من Tanzil — لا يُعدَّل عند البحث ولا عند العرض.
final ayahTextProvider = FutureProvider.family<String?, int>((
  ref,
  ayahId,
) async {
  await ref.watch(quranReadyProvider.future);
  return ref.watch(quranRepositoryProvider).ayahText(ayahId);
});

/// توقيتات الكلمات عبر الوكيل فقط، وبعد OptIn صريح.
final wordTimingsProvider =
    FutureProvider.family<List<WordTiming>, ({int surah, int ayah})>((
      ref,
      reference,
    ) async {
      if (!ref.watch(optInProvider(OptInKey.wordSync)) ||
          !isAiProxyConfigured) {
        return const <WordTiming>[];
      }
      return ref
          .watch(wordSyncProxyProvider)
          .fetchTimings(
            reciterId: 'default',
            surah: reference.surah,
            ayah: reference.ayah,
          );
    });

/// يحوّل معرّف الآية العالمي إلى (سورة، آية) محلياً ثم يطلب التوقيتات.
final wordTimingsForAyahProvider = FutureProvider.family<List<WordTiming>, int>(
  (ref, ayahId) async {
    if (!ref.watch(optInProvider(OptInKey.wordSync)) || !isAiProxyConfigured) {
      return const <WordTiming>[];
    }
    final reference = await ref
        .watch(quranRepositoryProvider)
        .referenceFor(ayahId);
    if (reference == null) return const <WordTiming>[];
    return ref.watch(
      wordTimingsProvider((surah: reference.surah, ayah: reference.ayah))
          .future,
    );
  },
);
