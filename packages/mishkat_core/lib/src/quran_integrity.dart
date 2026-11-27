import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:mishkat_core/src/arabic_normalizer.dart';
import 'package:xml/xml.dart';

/// الأرقام المرجعية التي لا يجوز تغييرها.
const int expectedSurahCount = 114;
const int expectedAyahCount = 6236;
const int expectedMadinahPageCount = 604;

/// SHA-256 لملفات Tanzil كما نُزّلت من tanzil.net في 2026-11-27.
const String expectedUthmaniSha256 =
    'af9311c521b5dadab01ea1ef259c281ffa83cf224bad24ee89469ce1c3c72916';
const String expectedMetadataSha256 =
    '8867c1d88191472adec9db694b3cd9f135b1a2ef580574d32cf888dcb22c5c7a';

/// نتيجة فحص سلامة بيانات المصحف المدمجة.
class QuranIntegrityReport {
  const QuranIntegrityReport({
    required this.uthmaniSha256,
    required this.metadataSha256,
    required this.surahCount,
    required this.ayahCount,
    required this.metadataSurahCount,
    required this.pageCount,
    required this.issues,
  });

  final String uthmaniSha256;
  final String metadataSha256;
  final int surahCount;
  final int ayahCount;
  final int metadataSurahCount;
  final int pageCount;
  final List<String> issues;

  bool get isValid => issues.isEmpty;

  Map<String, dynamic> toJson() => {
    'version': 1,
    'source': 'https://tanzil.net',
    'license': 'CC BY 3.0 — verbatim copies only, attribution required',
    'uthmani': {
      'file': 'quran-uthmani-v1.1.xml',
      'sha256': uthmaniSha256,
      'surahs': surahCount,
      'ayahs': ayahCount,
    },
    'metadata': {
      'file': 'quran-data-v1.0.xml',
      'sha256': metadataSha256,
      'surahs': metadataSurahCount,
      'pages': pageCount,
    },
    'valid': isValid,
    'issues': issues,
  };
}

/// يتحقق من SHA-256 ومن عدد السور والآيات والصفحات قبل أي استخدام للتطبيق.
class QuranIntegrityVerifier {
  const QuranIntegrityVerifier();

  QuranIntegrityReport verify({
    required String uthmaniXml,
    required String metadataXml,
  }) {
    final issues = <String>[];

    final uthmaniSha = sha256.convert(utf8.encode(uthmaniXml)).toString();
    final metadataSha = sha256.convert(utf8.encode(metadataXml)).toString();
    if (uthmaniSha != expectedUthmaniSha256) {
      issues.add('Uthmani SHA-256 mismatch: $uthmaniSha');
    }
    if (metadataSha != expectedMetadataSha256) {
      issues.add('Metadata SHA-256 mismatch: $metadataSha');
    }

    final uthmani = XmlDocument.parse(uthmaniXml);
    final metadata = XmlDocument.parse(metadataXml);

    final surahs = uthmani.root.findAllElements('sura').toList();
    final ayahs = surahs.expand((s) => s.findAllElements('aya')).toList();
    final metaSurahs = metadata.root.findAllElements('sura').toList();
    final pages = metadata.root.findAllElements('page').toList();

    if (surahs.length != expectedSurahCount) {
      issues.add('Surah count ${surahs.length} != $expectedSurahCount');
    }
    if (ayahs.length != expectedAyahCount) {
      issues.add('Ayah count ${ayahs.length} != $expectedAyahCount');
    }
    if (metaSurahs.length != expectedSurahCount) {
      issues.add('Metadata surah count ${metaSurahs.length}');
    }
    if (pages.length != expectedMadinahPageCount) {
      issues.add('Madinah page count ${pages.length}');
    }

    final declaredTotal = metaSurahs.fold<int>(
      0,
      (sum, s) => sum + (int.tryParse(s.getAttribute('ayas') ?? '') ?? 0),
    );
    if (declaredTotal != expectedAyahCount) {
      issues.add('Declared ayah total $declaredTotal');
    }

    if (surahs.isNotEmpty) {
      final first = surahs.first.findAllElements('aya').first;
      final normalized = const ArabicSearchNormalizer().normalize(
        first.getAttribute('text') ?? '',
      );
      if (normalized != 'بسم الله الرحمن الرحيم') {
        issues.add('First ayah text does not match the verified source');
      }
      final fatihaCount = surahs.first.findAllElements('aya').length;
      if (fatihaCount != 7) issues.add('Al-Fatiha ayah count $fatihaCount');
      if (surahs.length > 8) {
        final tawbahCount = surahs[8].findAllElements('aya').length;
        if (tawbahCount != 129) issues.add('At-Tawbah ayah count $tawbahCount');
      }
      if (surahs.length == expectedSurahCount) {
        final nasCount = surahs.last.findAllElements('aya').length;
        if (nasCount != 6) issues.add('An-Nas ayah count $nasCount');
      }
    }

    return QuranIntegrityReport(
      uthmaniSha256: uthmaniSha,
      metadataSha256: metadataSha,
      surahCount: surahs.length,
      ayahCount: ayahs.length,
      metadataSurahCount: metaSurahs.length,
      pageCount: pages.length,
      issues: issues,
    );
  }
}
