import 'package:flutter/services.dart';
import 'package:mishkat_core/mishkat_core.dart';

/// جسر بسيط إلى تطبيقات Wear OS / watchOS عبر MethodChannel.
/// الملفات الأصلية تُضاف في المنصة لاحقاً؛ الجهاز الذي لا يدعمها يتجاهل الرسالة.
class WatchService {
  const WatchService(this._channel);

  static const methodChannel = MethodChannel('mishkat/watch');

  final MethodChannel _channel;
  static const _guard = WatchPayloadGuard();

  Future<bool> send(WatchMessage message) async {
    if (!_guard.accepts(message)) return false;
    try {
      final result = await _channel.invokeMethod<bool>(
        'sendMessage',
        message.toMap(),
      );
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
