import 'dart:math' as math;

/// نقطة نظر على الشاشة.
class GazePoint {
  const GazePoint({
    required this.x,
    required this.y,
    required this.timestampMs,
  });

  final double x;
  final double y;
  final int timestampMs;
}

/// نتيجة اكتمال التثبيت (dwell) على عنصر واجهة.
class GazeSelection {
  const GazeSelection({required this.targetId, required this.timestampMs});

  final String targetId;
  final int timestampMs;
}

/// كاشف تثبيت النظر — يعمل فقط بعد تفعيل صريح من المستخدم.
class GazeDwellDetector {
  GazeDwellDetector({required this.dwellMs, required this.radiusPx})
    : assert(dwellMs > 0),
      assert(radiusPx > 0);

  final int dwellMs;
  final double radiusPx;

  String? _candidateId;
  double? _anchorX;
  double? _anchorY;
  int? _startedAt;

  /// يُغذّى بنقاط الكاميرا ويعيد اختياراً عند اكتمال التثبيت.
  GazeSelection? feed(GazePoint point, {required String? targetIdAt}) {
    if (targetIdAt == null) return _reset();

    final anchorX = _anchorX;
    final anchorY = _anchorY;
    final startedAt = _startedAt;
    final sameTarget = _candidateId == targetIdAt;

    // لا توجد جلسة تثبيت نشطة: ابدأ جلسة جديدة من هذه النقطة.
    if (_candidateId == null ||
        anchorX == null ||
        anchorY == null ||
        startedAt == null) {
      _candidateId = targetIdAt;
      _anchorX = point.x;
      _anchorY = point.y;
      _startedAt = point.timestampMs;
      return null;
    }

    // الحركة خارج النطاق أو تغيّر العنصر يُلغي الجلسة؛ يحتاج المستخدم ثباتاً جديداً.
    if (!sameTarget ||
        _distance(point.x, point.y, anchorX, anchorY) > radiusPx) {
      return _reset();
    }

    if (point.timestampMs - startedAt >= dwellMs) {
      final selection = GazeSelection(
        targetId: targetIdAt,
        timestampMs: point.timestampMs,
      );
      _reset();
      return selection;
    }
    return null;
  }

  GazeSelection? _reset() {
    _candidateId = null;
    _anchorX = null;
    _anchorY = null;
    _startedAt = null;
    return null;
  }

  double _distance(double x1, double y1, double x2, double y2) =>
      math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
}
