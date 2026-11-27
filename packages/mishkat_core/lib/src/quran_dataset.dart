import 'dart:convert';

import 'package:mishkat_core/src/arabic_normalizer.dart';
import 'package:xml/xml.dart';

/// آية جاهزة للإدراج في Drift. النص الحرفي لا يُغيَّر أبداً.
class QuranAyah {
  const QuranAyah({
    required this.id,
    required this.surahId,
    required this.ayahNo,
    required this.page,
    required this.juz,
    required this.hizb,
    required this.quarter,
    required this.textUthmani,
    required this.textSearch,
    required this.textSearchExpanded,
  });

  final int id;
  final int surahId;
  final int ayahNo;
  final int page;
  final int juz;
  final int hizb;
  final int quarter;
  final String textUthmani;
  final String textSearch;
  final String textSearchExpanded;

  Map<String, dynamic> toJson() => {
    'id': id,
    'surahId': surahId,
    'ayahNo': ayahNo,
    'page': page,
    'juz': juz,
    'hizb': hizb,
    'quarter': quarter,
    'textUthmani': textUthmani,
    'textSearch': textSearch,
    'textSearchExpanded': textSearchExpanded,
  };
}

/// سورة مع بياناتها الوصفية.
class QuranSurah {
  const QuranSurah({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.revelationType,
    required this.ayahCount,
  });

  final int id;
  final String nameAr;
  final String nameEn;
  final String revelationType;
  final int ayahCount;

  Map<String, dynamic> toJson() => {
    'id': id,
    'nameAr': nameAr,
    'nameEn': nameEn,
    'revelationType': revelationType,
    'ayahCount': ayahCount,
  };
}

class QuranDataset {
  const QuranDataset({required this.surahs, required this.ayahs});

  final List<QuranSurah> surahs;
  final List<QuranAyah> ayahs;

  String toJson() => jsonEncode({
    'version': 1,
    'source': 'Tanzil Uthmani v1.1 + metadata v1.0',
    'surahs': surahs.map((s) => s.toJson()).toList(),
    'ayahs': ayahs.map((a) => a.toJson()).toList(),
  });
}

class _Boundary {
  const _Boundary({required this.global, this.page, this.juz, this.quarter});

  final int global;
  final int? page;
  final int? juz;
  final int? quarter;
}

/// يبني مجموعة بيانات من ملفي Tanzil دون تعديل النص الحرفي.
class QuranDatasetBuilder {
  const QuranDatasetBuilder();

  QuranDataset build({
    required String uthmaniXml,
    required String metadataXml,
  }) {
    final normalizer = const ArabicSearchNormalizer();
    final meta = XmlDocument.parse(metadataXml);
    final uthmani = XmlDocument.parse(uthmaniXml);

    final starts = <int, int>{};
    final surahs = <QuranSurah>[];
    for (final element in meta.root.findAllElements('sura')) {
      final index = int.parse(element.getAttribute('index')!);
      starts[index] = int.parse(element.getAttribute('start')!);
      surahs.add(
        QuranSurah(
          id: index,
          nameAr: element.getAttribute('name') ?? '',
          nameEn: element.getAttribute('ename') ?? '',
          revelationType: element.getAttribute('type') ?? '',
          ayahCount: int.parse(element.getAttribute('ayas') ?? '0'),
        ),
      );
    }
    surahs.sort((a, b) => a.id.compareTo(b.id));

    final pageBounds = <_Boundary>[];
    for (final element in meta.root.findAllElements('page')) {
      final sura = int.parse(element.getAttribute('sura')!);
      final aya = int.parse(element.getAttribute('aya')!);
      pageBounds.add(
        _Boundary(
          global: starts[sura]! + aya,
          page: int.parse(element.getAttribute('index')!),
        ),
      );
    }
    final juzBounds = <_Boundary>[];
    for (final element in meta.root.findAllElements('juz')) {
      final sura = int.parse(element.getAttribute('sura')!);
      final aya = int.parse(element.getAttribute('aya')!);
      juzBounds.add(
        _Boundary(
          global: starts[sura]! + aya,
          juz: int.parse(element.getAttribute('index')!),
        ),
      );
    }
    final quarterBounds = <_Boundary>[];
    for (final element in meta.root.findAllElements('quarter')) {
      final sura = int.parse(element.getAttribute('sura')!);
      final aya = int.parse(element.getAttribute('aya')!);
      quarterBounds.add(
        _Boundary(
          global: starts[sura]! + aya,
          quarter: int.parse(element.getAttribute('index')!),
        ),
      );
    }

    int resolve(List<_Boundary> bounds, int global) {
      var result =
          bounds.first.page ?? bounds.first.juz ?? bounds.first.quarter ?? 1;
      for (final b in bounds) {
        if (b.global > global) break;
        result = b.page ?? b.juz ?? b.quarter ?? result;
      }
      return result;
    }

    pageBounds.sort((a, b) => a.global.compareTo(b.global));
    juzBounds.sort((a, b) => a.global.compareTo(b.global));
    quarterBounds.sort((a, b) => a.global.compareTo(b.global));

    final ayahs = <QuranAyah>[];
    for (final suraElement in uthmani.root.findAllElements('sura')) {
      final surahId = int.parse(suraElement.getAttribute('index')!);
      final offset = starts[surahId]!;
      for (final ayaElement in suraElement.findAllElements('aya')) {
        final ayahNo = int.parse(ayaElement.getAttribute('index')!);
        final global = offset + ayahNo;
        final text = ayaElement.getAttribute('text') ?? '';
        final quarter = resolve(quarterBounds, global);
        ayahs.add(
          QuranAyah(
            id: global,
            surahId: surahId,
            ayahNo: ayahNo,
            page: resolve(pageBounds, global),
            juz: resolve(juzBounds, global),
            hizb: ((quarter - 1) ~/ 4) + 1,
            quarter: quarter,
            textUthmani: text,
            textSearch: normalizer.normalize(text),
            textSearchExpanded: normalizer.normalizeExpanded(text),
          ),
        );
      }
    }
    ayahs.sort((a, b) => a.id.compareTo(b.id));
    return QuranDataset(surahs: surahs, ayahs: ayahs);
  }
}
