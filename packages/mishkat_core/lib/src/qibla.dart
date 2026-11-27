import 'dart:math' as math;

/// الكعبة المشرفة — خط العرض وخط الطول بالدرجات.
const kaabaLatitude = 21.4225;
const kaabaLongitude = 39.8262;

/// نتيجة حساب زاوية القبلة.
class QiblaResult {
  const QiblaResult({
    required this.bearingDegrees,
    required this.magneticDeclination,
  });

  /// الزاوية من الشمال الحقيقي باتجاه عقارب الساعة (0..360).
  final double bearingDegrees;

  /// انحراف البوصلة المغناطيسية بالدرجات (يُضاف للشمال الحقيقي).
  final double magneticDeclination;

  /// الزاوية بالنسبة للشمال المغناطيسي، وهي ما يعرضه حساس الجهاز.
  double get magneticBearing =>
      (bearingDegrees - magneticDeclination + 360) % 360;
}

/// حاسبة زاوية القبلة بطريقة الدائرة العظمى (Great-Circle Bearing).
class QiblaCalculator {
  const QiblaCalculator();

  /// تحسب الزاوية من موقع المستخدم إلى الكعبة.
  ///
  /// [latitude]/[longitude] بالدرجات، [magneticDeclination] اختياري افتراضه صفر.
  QiblaResult calculate(
    double latitude,
    double longitude, {
    double magneticDeclination = 0,
  }) {
    final phi1 = latitude * math.pi / 180;
    final phi2 = kaabaLatitude * math.pi / 180;
    final deltaLambda = (kaabaLongitude - longitude) * math.pi / 180;

    final y = math.sin(deltaLambda) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);

    final degrees = math.atan2(y, x) * 180 / math.pi;
    return QiblaResult(
      bearingDegrees: (degrees + 360) % 360,
      magneticDeclination: magneticDeclination,
    );
  }
}

/// أصغر فرق زاوي بين زاويتين (0..180).
double angularDifference(double a, double b) {
  final diff = (a - b).abs() % 360;
  return diff > 180 ? 360 - diff : diff;
}

/// هل البوصلة محاذاة للقبلة خلال هامش [toleranceDegrees]؟
bool isAligned(
  double currentBearing,
  double targetBearing, {
  double toleranceDegrees = 5,
}) {
  return angularDifference(currentBearing, targetBearing) <= toleranceDegrees;
}
