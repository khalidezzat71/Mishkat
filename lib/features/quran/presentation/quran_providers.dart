import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mishkat/core/settings/opt_in_providers.dart';
import 'package:mishkat_core/mishkat_core.dart';

import '../../../app/advanced_providers.dart';
import '../../../app/providers.dart';
import '../data/quran_repository.dart';

final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  return QuranRepository(
    ref.watch(databaseProvider),
    rootBundle,
    ref.watch(dioProvider),
  );
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

typedef QuranQuery = ({String term, AyahFilter filter});

/// بحث محلي بالكامل: FTS5 ثم فلترة سورة/جزء/صفحة/حزب على الجهاز.
final quranFilteredSearchProvider =
    FutureProvider.family<List<int>, QuranQuery>((ref, query) async {
      if (query.term.trim().isEmpty) return <int>[];
      await ref.watch(quranReadyProvider.future);
      return ref
          .watch(quranRepositoryProvider)
          .search(query.term, filter: query.filter);
    });

/// النص الحرفي من Tanzil — لا يُعدَّل عند البحث ولا عند العرض.
final ayahTextProvider = FutureProvider.family<String?, int>((
  ref,
  ayahId,
) async {
  await ref.watch(quranReadyProvider.future);
  return ref.watch(quranRepositoryProvider).ayahText(ayahId);
});

/// صفحة كاملة من المصحف من المصدر المختار.
final mushafPageProvider =
    FutureProvider.family<
      List<MushafAyah>,
      ({int page, QuranTextSource source})
    >((ref, request) async {
      await ref.watch(quranReadyProvider.future);
      return ref
          .watch(quranRepositoryProvider)
          .pageAyahs(request.page, source: request.source);
    });

/// يقرأ المصدر الحالي من الإعدادات ثم يعرض الصفحة المطلوبة.
final activeMushafPageProvider = FutureProvider.family<List<MushafAyah>, int>((
  ref,
  page,
) async {
  final source = ref.watch(mushafSourceProvider);
  return ref.watch(mushafPageProvider((page: page, source: source)).future);
});

/// فهرس السور لأول صفحة لكل سورة.
final surahListProvider =
    FutureProvider<
      List<
        ({int id, String nameAr, String? nameEn, int ayahCount, int pageStart})
      >
    >((ref) async {
      await ref.watch(quranReadyProvider.future);
      return ref.watch(quranRepositoryProvider).surahList();
    });

/// مرجع الآية لعرض نتائج البحث والقفز إلى صفحتها.
final ayahMetaProvider =
    FutureProvider.family<
      ({int surahId, int ayahNo, int page, String text})?,
      int
    >((ref, ayahId) async {
      await ref.watch(quranReadyProvider.future);
      return ref.watch(quranRepositoryProvider).ayahMeta(ayahId);
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
