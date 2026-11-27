import 'dart:math' as math;

import 'package:mishkat_core/mishkat_core.dart';

/// يحوّل قراءات البوصلة إلى حالة محاذاة للقبلة.
///
/// البثّ الفعلي من حساس الجهاز يُحقن هنا، فتبقى المنطقية قابلة للاختبار
/// دون جهاز أو حساسات.
class QiblaCompassController {
  QiblaCompassController({
    required Stream<double> headingDegrees,
    required double targetBearing,
    this.toleranceDegrees = 5,
  }) : _heading = headingDegrees,
       _target = targetBearing;

  final Stream<double> _heading;
  final double _target;
  final double toleranceDegrees;

  Stream<bool> get alignment => _heading
      .map((h) => isAligned(h, _target, toleranceDegrees: toleranceDegrees))
      .distinct();

  /// اهتزاز لطيف عند المحاذاة — يُستدعى من طبقة الواجهة مرة واحدة لكل انتقال.
  Stream<double> deviations() =>
      _heading.map((h) => angularDifference(h, _target));

  static double radiansToDegrees(double radians) =>
      (radians * 180 / math.pi + 360) % 360;
}
