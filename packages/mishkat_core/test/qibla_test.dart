import 'dart:math';

import 'package:mishkat_core/mishkat_core.dart';
import 'package:test/test.dart';

void main() {
  const calculator = QiblaCalculator();

  group('اتجاه القبلة (great-circle bearing)', () {
    test('من مكة نفسها ≈ 0 درجة', () {
      final result = calculator.calculate(kaabaLatitude, kaabaLongitude);
      expect(result.bearingDegrees, lessThan(0.01));
    });

    test('القاهرة ≈ 136.1 درجة', () {
      final result = calculator.calculate(30.0444, 31.2357);
      expect(result.bearingDegrees, closeTo(136.137, 0.05));
    });

    test('لندن ≈ 119.0 درجة', () {
      final result = calculator.calculate(51.5074, -0.1278);
      expect(result.bearingDegrees, closeTo(118.987, 0.05));
    });

    test('جاكرتا ≈ 295.2 درجة (غرباً)', () {
      final result = calculator.calculate(-6.2088, 106.8456);
      expect(result.bearingDegrees, closeTo(295.152, 0.05));
    });

    test('نيويورك ≈ 58.5 درجة', () {
      final result = calculator.calculate(40.7128, -74.006);
      expect(result.bearingDegrees, closeTo(58.482, 0.05));
    });

    test('الزاوية دائماً في المدى [0, 360)', () {
      for (var lon = -180; lon < 180; lon += 17) {
        for (var lat = -80; lat <= 80; lat += 23) {
          final b = calculator
              .calculate(lat.toDouble(), lon.toDouble())
              .bearingDegrees;
          expect(b, inInclusiveRange(0, 360));
        }
      }
    });

    test('انحراف البوصلة يعدّل الزاوية المقروءة', () {
      final result = calculator.calculate(
        30.0444,
        31.2357,
        magneticDeclination: 5,
      );
      expect(result.magneticBearing, closeTo(result.bearingDegrees - 5, 0.001));
    });
  });

  group('المحاذاة', () {
    test('أصغر فرق زاوي يتجاوز خط 180', () {
      expect(angularDifference(359, 1), closeTo(2, 0.001));
      expect(angularDifference(10, 190), closeTo(180, 0.001));
    });

    test('المحاذاة داخل الهامش فقط', () {
      expect(isAligned(134, 136, toleranceDegrees: 5), isTrue);
      expect(isAligned(120, 136, toleranceDegrees: 5), isFalse);
    });

    test('نتيجة عكسية لا تخرج عن المدى', () {
      expect(
        calculator
            .calculate(30.0444, 31.2357, magneticDeclination: 200)
            .magneticBearing,
        inInclusiveRange(0, 360),
      );
      expect(max(0, 1), 1);
    });
  });
}
