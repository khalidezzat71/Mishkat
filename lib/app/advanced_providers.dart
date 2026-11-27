import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mishkat/core/ai/recitation_proxy.dart';
import 'package:mishkat/core/ai/word_sync_proxy.dart';
import 'package:mishkat/core/database/app_database.dart';
import 'package:mishkat/core/gaze/gaze_controller.dart';
import 'package:mishkat/core/gaze/gaze_source.dart';
import 'package:mishkat/core/settings/opt_in_providers.dart';
import 'package:mishkat/core/watch/watch_service.dart';
import 'package:mishkat/core/widget/prayer_widget_service.dart';
import 'package:mishkat/features/quran/data/reciter_repository.dart';
import 'package:mishkat/features/quran/data/tafsir_repository.dart';
import 'package:mishkat/features/settings/data/backup_service.dart';
import 'package:mishkat_core/mishkat_core.dart';

import 'providers.dart';

final dioProvider = Provider<Dio>((ref) => Dio());

final tafsirRepositoryProvider = Provider<TafsirRepository>((ref) {
  return TafsirRepository(ref.watch(databaseProvider), ref.watch(dioProvider));
});

final tafsirProvider =
    FutureProvider.family<String?, ({int ayahId, String editionId})>((
      ref,
      request,
    ) async {
      if (!ref.watch(optInProvider(OptInKey.tafsir))) return null;
      final repo = ref.watch(tafsirRepositoryProvider);
      final cached = await repo.cached(request.ayahId, request.editionId);
      return cached ?? await repo.fetch(request.ayahId, request.editionId);
    });

final reciterRepositoryProvider = FutureProvider<ReciterRepository>((
  ref,
) async {
  return ReciterRepository.create(
    ref.watch(databaseProvider),
    ref.watch(dioProvider),
  );
});

final recitersProvider = FutureProvider<List<Reciter>>((ref) async {
  return (await ref.watch(reciterRepositoryProvider.future)).list();
});

final recitationProxyProvider = Provider<RecitationProxy>((ref) {
  return buildRecitationProxy(ref.watch(dioProvider));
});

final wordSyncProxyProvider = Provider<WordSyncProxy>((ref) {
  return buildWordSyncProxy(ref.watch(dioProvider));
});

final widgetServiceProvider = Provider<PrayerWidgetService>((ref) {
  return const PrayerWidgetService();
});

final watchServiceProvider = Provider<WatchService>((ref) {
  return const WatchService(WatchService.methodChannel);
});

final gazeSourceProvider = Provider<GazeSource>((ref) {
  return const MethodChannelGazeSource(
    MethodChannelGazeSource.commandChannel,
    MethodChannelGazeSource.eventChannel,
  );
});

final gazeControllerProvider = Provider<GazeController>((ref) {
  final controller = GazeController();
  ref.onDispose(controller.dispose);
  return controller;
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(databaseProvider));
});

/// إحصائيات محلية فقط — لا تُرسل لأي خادم.
final statsProvider =
    FutureProvider<
      ({int units, int attempts, double averageAccuracy, int pagesRead})
    >((ref) async {
      final db = ref.watch(databaseProvider);
      final units = (await db.select(db.hifzUnits).get()).length;
      final attempts = await db.select(db.recitationAttempts).get();
      final sessions = await db.select(db.readingSessions).get();
      final accuracy = attempts.isEmpty
          ? 0.0
          : attempts.map((a) => a.accuracyPercent).reduce((a, b) => a + b) /
                attempts.length;
      return (
        units: units,
        attempts: attempts.length,
        averageAccuracy: accuracy.toDouble(),
        pagesRead: sessions.fold<int>(0, (sum, s) => sum + s.pagesRead),
      );
    });
