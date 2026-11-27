import 'package:flutter/services.dart';
import 'package:mishkat_core/mishkat_core.dart';

/// مصدر نقاط النظر. التنفيذ الأصلي (كاميرا/ML Kit) اختياري ومعزول خلف العقد.
abstract class GazeSource {
  const GazeSource();

  Future<bool> requestPermission();

  Stream<({GazePoint point, String? targetId})> watch();

  Future<void> dispose();
}

/// جسر MethodChannel/EventChannel إلى تتبّع النظر الأصلي.
/// غياب التنفيذ الأصلي يعني ببساطة عدم وجود نقاط، ولا يوقف بقية التطبيق.
class MethodChannelGazeSource implements GazeSource {
  const MethodChannelGazeSource(this._channel, this._events);

  static const commandChannel = MethodChannel('mishkat/gaze');
  static const eventChannel = EventChannel('mishkat/gaze_events');

  final MethodChannel _channel;
  final EventChannel _events;

  @override
  Future<bool> requestPermission() async {
    try {
      return await _channel.invokeMethod<bool>('requestPermission') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Stream<({GazePoint point, String? targetId})> watch() {
    return _events.receiveBroadcastStream().map((dynamic event) {
      final map = event as Map<dynamic, dynamic>;
      final point = map['point'] as Map<dynamic, dynamic>;
      return (
        point: GazePoint(
          x: (point['x'] as num).toDouble(),
          y: (point['y'] as num).toDouble(),
          timestampMs: (point['timestampMs'] as num).toInt(),
        ),
        targetId: map['targetId'] as String?,
      );
    });
  }

  @override
  Future<void> dispose() async {}
}
