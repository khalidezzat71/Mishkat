import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:mishkat/core/settings/opt_in_providers.dart';
import 'package:mishkat_core/mishkat_core.dart';

/// عميل Backend Proxy لتوقيتات الكلمات. العنوان يُحقن وقت البناء، بلا مفاتيح.
class HttpWordSyncProxy implements WordSyncProxy {
  HttpWordSyncProxy(this._client, {required this.baseUrl});

  final Dio _client;
  final String baseUrl;

  @override
  Future<List<WordTiming>> fetchTimings({
    required String reciterId,
    required int surah,
    required int ayah,
  }) async {
    if (baseUrl.isEmpty) return const <WordTiming>[];
    try {
      final response = await _client.get<String>(
        '$baseUrl/word-timings',
        queryParameters: {'reciter': reciterId, 'surah': surah, 'ayah': ayah},
        options: Options(responseType: ResponseType.plain),
      );
      final decoded = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
      final raw = decoded['timings'] as List<dynamic>? ?? const <dynamic>[];
      final timings = raw.whereType<Map<String, dynamic>>().map((item) {
        return WordTiming(
          wordIndex: (item['wordIndex'] as num?)?.toInt() ?? 0,
          startMs: (item['startMs'] as num?)?.toInt() ?? 0,
          endMs: (item['endMs'] as num?)?.toInt() ?? 0,
        );
      }).toList();
      const validator = AlignmentValidator();
      return validator.isValid(timings, audioDurationMs: 60 * 60 * 1000)
          ? timings
          : const <WordTiming>[];
    } on DioException {
      return const <WordTiming>[];
    } on FormatException {
      return const <WordTiming>[];
    }
  }
}

WordSyncProxy buildWordSyncProxy(Dio client) =>
    HttpWordSyncProxy(client, baseUrl: aiProxyBaseUrl);
