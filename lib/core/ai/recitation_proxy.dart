import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:mishkat/core/settings/opt_in_providers.dart';
import 'package:mishkat_core/mishkat_core.dart';

/// تحويل الصوت إلى نص خلف Backend Proxy. لا مفاتيح ولا نماذج داخل التطبيق.
class HttpRecitationProxy implements RecitationProxy {
  HttpRecitationProxy(this._client, {required this.baseUrl});

  final Dio _client;
  final String baseUrl;

  @override
  Future<String> transcribe(
    List<int> audioBytes, {
    required String locale,
  }) async {
    if (baseUrl.isEmpty) return '';
    try {
      final response = await _client.post<String>(
        '$baseUrl/recitation/transcribe',
        data: audioBytes,
        queryParameters: {'locale': locale},
        options: Options(
          contentType: 'audio/m4a',
          responseType: ResponseType.plain,
        ),
      );
      final decoded = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
      return decoded['text'] as String? ?? '';
    } on DioException {
      return '';
    } on FormatException {
      return '';
    }
  }
}

RecitationProxy buildRecitationProxy(Dio client) =>
    HttpRecitationProxy(client, baseUrl: aiProxyBaseUrl);
