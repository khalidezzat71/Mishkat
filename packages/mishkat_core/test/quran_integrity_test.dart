import 'dart:convert';

import 'package:mishkat_core/mishkat_core.dart';
import 'package:test/test.dart';

import 'support/dataset.dart';

void main() {
  group('سلامة النص القرآني المدمج', () {
    test('114 سورة و6236 آية و604 صفحة وSHA-256 مطابق', () {
      final report = const QuranIntegrityVerifier().verify(
        uthmaniXml: uthmaniXml,
        metadataXml: metadataXml,
      );
      expect(report.issues, isEmpty, reason: report.issues.join('; '));
      expect(report.surahCount, 114);
      expect(report.ayahCount, 6236);
      expect(report.pageCount, 604);
      expect(report.isValid, isTrue);
    });

    test('النص الأول مطابق للمصدر الموثق', () {
      final report = const QuranIntegrityVerifier().verify(
        uthmaniXml: uthmaniXml,
        metadataXml: metadataXml,
      );
      expect(report.issues, isEmpty);
      expect(report.toJson()['uthmani']['sha256'], expectedUthmaniSha256);
    });

    test('يُكتشف أي تعديل على النص', () {
      final tampered = uthmaniXml.replaceFirst('بِسْمِ', 'بِسْم');
      final report = const QuranIntegrityVerifier().verify(
        uthmaniXml: tampered,
        metadataXml: metadataXml,
      );
      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.contains('SHA-256 mismatch')), isTrue);
    });

    test('manifest قابل للإنتاج بصيغة JSON', () {
      final report = const QuranIntegrityVerifier().verify(
        uthmaniXml: uthmaniXml,
        metadataXml: metadataXml,
      );
      final decoded = jsonDecode(jsonEncode(report.toJson())) as Map;
      expect(decoded['valid'], isTrue);
      expect(decoded['uthmani']['ayahs'], 6236);
    });
  });
}
