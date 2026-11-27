import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mishkat_core/mishkat_core.dart';

import 'gaze_source.dart';

/// يستقبل نقاط تتبّع النظر من طبقة أصلية ويطبّق كاشف التثبيت المُختبَر.
/// لا يعمل إلا بعد تفعيل OptIn صريح من الإعدادات.
class GazeController {
  GazeController({this.dwellMs = 800, this.radiusPx = 24})
    : _detector = GazeDwellDetector(dwellMs: dwellMs, radiusPx: radiusPx);

  final int dwellMs;
  final double radiusPx;
  final GazeDwellDetector _detector;

  final ValueNotifier<String?> focusedTarget = ValueNotifier<String?>(null);
  final ValueNotifier<GazeSelection?> lastSelection =
      ValueNotifier<GazeSelection?>(null);

  StreamSubscription<({GazePoint point, String? targetId})>? _subscription;

  void onPoint({
    required double x,
    required double y,
    required int timestampMs,
    required String? targetId,
  }) {
    focusedTarget.value = targetId;
    final selection = _detector.feed(
      GazePoint(x: x, y: y, timestampMs: timestampMs),
      targetIdAt: targetId,
    );
    if (selection != null) lastSelection.value = selection;
  }

  /// يطلب الإذن ثم يبدأ الاستماع فقط بعد موافقة المستخدم.
  Future<bool> enable(GazeSource source) async {
    final granted = await source.requestPermission();
    if (!granted) return false;
    bind(source);
    return true;
  }

  void bind(GazeSource source) {
    _subscription?.cancel();
    _subscription = source.watch().listen((sample) {
      onPoint(
        x: sample.point.x,
        y: sample.point.y,
        timestampMs: sample.point.timestampMs,
        targetId: sample.targetId,
      );
    });
  }

  void clear() {
    focusedTarget.value = null;
    lastSelection.value = null;
  }

  void dispose() {
    _subscription?.cancel();
    focusedTarget.dispose();
    lastSelection.dispose();
  }
}
