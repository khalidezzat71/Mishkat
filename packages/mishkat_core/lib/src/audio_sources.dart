import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:mishkat_core/src/tafsir_sync.dart';

/// مصدر صوت قابل للتبديل — مجاني أولاً، والقرّاء معتمدون سنيون.
class AudioSource {
  const AudioSource({
    required this.id,
    required this.nameAr,
    required this.reciterName,
    required this.riwayah,
    required this.urlTemplate,
    required this.pattern,
    required this.license,
    required this.free,
    required this.verified,
    required this.sect,
  });

  final String id;
  final String nameAr;
  final String reciterName;
  final String riwayah;
  final String urlTemplate;

  /// رموز النمط: SSS رقم السورة بثلاث خانات، AAA رقم الآية بثلاث خانات.
  final String pattern;
  final String license;
  final bool free;
  final bool verified;
  final Sect sect;
}

/// مصادر مجانية مرشحة — تُفعَّل بعد مراجعة الترخيص، ويمكن استبدالها بمصدر مدفوع.
const List<AudioSource> kCandidateAudioSources = [
  AudioSource(
    id: 'alafasy_128',
    nameAr: 'مشاري العفاسي',
    reciterName: 'مشاري بن راشد العفاسي',
    riwayah: 'حفص',
    urlTemplate:
        'https://cdn.islamic.network/quran/audio/128/ar.alafasy/SSSAAA.mp3',
    pattern: 'SSSAAA',
    license:
        'rights pending review — do not ship commercially before verification',
    free: true,
    verified: false,
    sect: Sect.sunni,
  ),
  AudioSource(
    id: 'minshawi_128',
    nameAr: 'محمد صديق المنشاوي',
    reciterName: 'محمد صديق المنشاوي',
    riwayah: 'حفص',
    urlTemplate:
        'https://cdn.islamic.network/quran/audio/128/ar.minshawi/SSSAAA.mp3',
    pattern: 'SSSAAA',
    license:
        'rights pending review — do not ship commercially before verification',
    free: true,
    verified: false,
    sect: Sect.sunni,
  ),
];

class ReciterManager {
  ReciterManager(Iterable<AudioSource> sources) {
    for (final source in sources) {
      register(source);
    }
  }

  final Map<String, AudioSource> _sources = {};
  String? _selectedId;

  void register(AudioSource source) {
    if (source.sect != Sect.sunni) {
      throw ArgumentError.value(
          source.id, 'source', 'non-Sunni source rejected');
    }
    _sources[source.id] = source;
  }

  Iterable<AudioSource> list({bool freeFirst = true}) {
    final values = _sources.values.toList();
    if (!freeFirst) return values;
    values.sort((a, b) {
      if (a.free != b.free) return a.free ? -1 : 1;
      if (a.verified != b.verified) return a.verified ? -1 : 1;
      return a.id.compareTo(b.id);
    });
    return values;
  }

  AudioSource? get selected {
    final id = _selectedId;
    return id == null ? null : _sources[id];
  }

  bool select(String id) {
    if (!_sources.containsKey(id)) return false;
    _selectedId = id;
    return true;
  }

  /// يبني رابط الآية من نمط المصدر دون أي مفتاح API داخل التطبيق.
  String resolveUrl(AudioSource source, int surah, int ayah) {
    if (surah < 1 || surah > 114 || ayah < 1 || ayah > 286) {
      throw ArgumentError('invalid ayah reference');
    }
    final surahCode = surah.toString().padLeft(3, '0');
    final ayahCode = ayah.toString().padLeft(3, '0');
    return source.urlTemplate
        .replaceAll('SSS', surahCode)
        .replaceAll('AAA', ayahCode);
  }
}

class DownloadEntry {
  const DownloadEntry({
    required this.id,
    required this.bytes,
    required this.sha256,
    required this.lastAccessedAt,
  });

  final String id;
  final int bytes;
  final String sha256;
  final DateTime lastAccessedAt;
}

/// يتحقق من تنزيلات الصوت ويطبّق سياسة الحذف عند تجاوز الحصة.
class DownloadPolicy {
  const DownloadPolicy();

  String checksum(List<int> bytes) => sha256.convert(bytes).toString();

  bool verify(List<int> bytes, String expectedSha) =>
      checksum(bytes) == expectedSha;

  List<DownloadEntry> evict(
    Iterable<DownloadEntry> entries, {
    required int maxBytes,
  }) {
    final sorted = entries.toList()
      ..sort((a, b) => a.lastAccessedAt.compareTo(b.lastAccessedAt));
    var total = sorted.fold<int>(0, (sum, e) => sum + e.bytes);
    final kept = <DownloadEntry>[];
    for (final entry in sorted) {
      if (total <= maxBytes) {
        kept.add(entry);
      } else {
        total -= entry.bytes;
      }
    }
    return kept..sort((a, b) => b.lastAccessedAt.compareTo(a.lastAccessedAt));
  }

  String manifestJson(Iterable<DownloadEntry> entries) => jsonEncode({
        'version': 1,
        'policy': 'private_storage_user_requested_only',
        'entries': entries
            .map((e) => {
                  'id': e.id,
                  'bytes': e.bytes,
                  'sha256': e.sha256,
                  'lastAccessedAt': e.lastAccessedAt.toUtc().toIso8601String(),
                })
            .toList(),
      });
}
