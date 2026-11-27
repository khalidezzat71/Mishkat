import 'dart:convert';

import 'package:mishkat_core/mishkat_core.dart';
import 'package:test/test.dart';

void main() {
  group('مزامنة التفسير', () {
    final policy = const TafsirSourcePolicy();
    final now = DateTime.utc(2026, 11, 27, 12);

    test('أربعة تفاسير سنية معتمدة كلها وقت تشغيل فقط', () {
      expect(kApprovedTafsirEditions.length, 4);
      for (final edition in kApprovedTafsirEditions) {
        expect(edition.sect, Sect.sunni);
        expect(edition.runtimeOnly, isTrue);
        expect(policy.isApproved(edition), isTrue);
      }
    });

    test('تُرفض المرجعية غير السنية', () {
      final shiaEdition = TafsirEdition(
        id: 'rejected',
        nameAr: 'مرجع غير معتمد',
        language: 'ar',
        license: 'unknown',
        sect: Sect.other,
        runtimeOnly: false,
      );
      expect(policy.isApproved(shiaEdition), isFalse);
      expect(() => policy.requireApproved('rejected'), throwsArgumentError);
    });

    test('كاش 7 أيام: ينتهي بعدها ويُحذف', () {
      final cache = TafsirCache();
      cache.put(
        TafsirCacheEntry(
          editionId: 'ar.muyassar',
          ayahId: 1,
          text: 'نص تجريبي للاختبار',
          fetchedAt: now,
        ),
      );
      expect(
        cache.get('ar.muyassar', 1, now: now.add(const Duration(days: 6))),
        'نص تجريبي للاختبار',
      );
      expect(
        cache.get('ar.muyassar', 1, now: now.add(const Duration(days: 8))),
        isNull,
      );
      expect(cache.length, 0);
    });

    test('prune تحذف المنتهية فقط', () {
      final cache = TafsirCache();
      cache.put(
        TafsirCacheEntry(editionId: 'a', ayahId: 1, text: 'x', fetchedAt: now),
      );
      cache.put(
        TafsirCacheEntry(
          editionId: 'a',
          ayahId: 2,
          text: 'y',
          fetchedAt: now.add(const Duration(days: 6)),
        ),
      );
      final removed = cache.prune(now: now.add(const Duration(days: 8)));
      expect(removed, 1);
      expect(cache.length, 1);
    });

    test('السعة القصوى تطرد الأقدم', () {
      final cache = TafsirCache(maxEntries: 2);
      cache.put(
        TafsirCacheEntry(
          editionId: 'a',
          ayahId: 1,
          text: 'old',
          fetchedAt: now,
        ),
      );
      cache.put(
        TafsirCacheEntry(
          editionId: 'a',
          ayahId: 2,
          text: 'new',
          fetchedAt: now.add(const Duration(minutes: 1)),
        ),
      );
      cache.put(
        TafsirCacheEntry(
          editionId: 'a',
          ayahId: 3,
          text: 'newest',
          fetchedAt: now.add(const Duration(minutes: 2)),
        ),
      );
      expect(cache.length, 2);
      expect(cache.get('a', 1, now: now), isNull);
      expect(cache.get('a', 3, now: now), 'newest');
    });
  });

  group('إدارة القرّاء والصوت', () {
    final paid = AudioSource(
      id: 'paid',
      nameAr: 'مصدر مدفوع',
      reciterName: 'قارئ',
      riwayah: 'حفص',
      urlTemplate: 'https://example.com/SSS/AAA.mp3',
      pattern: 'SSSAAA',
      license: 'paid license #123',
      free: false,
      verified: true,
      sect: Sect.sunni,
    );

    test('تبني الرابط من النمط SSSAAA', () {
      final manager = ReciterManager(kCandidateAudioSources);
      final source = manager.list().first;
      expect(manager.resolveUrl(source, 2, 3), contains('002003'));
    });

    test('المجاني أولاً حتى لو سُجّل المدفوع قبله', () {
      final manager = ReciterManager([paid, ...kCandidateAudioSources]);
      expect(manager.list().first.free, isTrue);
      expect(manager.list(freeFirst: false).first.id, 'paid');
    });

    test('تُرفض المصادر غير السنية', () {
      final manager = ReciterManager([]);
      final other = AudioSource(
        id: 'other',
        nameAr: 'غير معتمد',
        reciterName: 'قارئ',
        riwayah: 'حفص',
        urlTemplate: 'https://example.com/SSSAAA.mp3',
        pattern: 'SSSAAA',
        license: 'none',
        free: true,
        verified: false,
        sect: Sect.other,
      );
      expect(() => manager.register(other), throwsArgumentError);
    });

    test('اختيار قارئ والقراءة منه', () {
      final manager = ReciterManager(kCandidateAudioSources);
      expect(manager.select('alafasy_128'), isTrue);
      expect(manager.selected?.id, 'alafasy_128');
      expect(manager.select('unknown'), isFalse);
    });

    test('التحقق من SHA-256 وإخراج manifest', () {
      const policy = DownloadPolicy();
      final bytes = utf8.encode('audio-bytes');
      final sha = policy.checksum(bytes);
      expect(policy.verify(bytes, sha), isTrue);
      expect(policy.verify(bytes, '0' * 64), isFalse);
    });

    test('الحذف عند تجاوز الحصة يبدأ بالأقل استخداماً', () {
      const policy = DownloadPolicy();
      final entries = [
        DownloadEntry(
          id: 'old',
          bytes: 100,
          sha256: 'a',
          lastAccessedAt: DateTime(2026, 1, 1),
        ),
        DownloadEntry(
          id: 'new',
          bytes: 100,
          sha256: 'b',
          lastAccessedAt: DateTime(2026, 11, 1),
        ),
      ];
      final kept = policy.evict(entries, maxBytes: 100);
      expect(kept.map((e) => e.id), ['new']);
      expect(
        policy.manifestJson(kept),
        contains('private_storage_user_requested_only'),
      );
    });
  });

  group('مزامنة الكلمات', () {
    const aligner = WordAligner();
    const timings = [
      WordTiming(wordIndex: 0, startMs: 0, endMs: 400),
      WordTiming(wordIndex: 1, startMs: 400, endMs: 900),
      WordTiming(wordIndex: 2, startMs: 900, endMs: 1400),
    ];

    test('الكلمة النشطة حسب الزمن', () {
      final words = aligner.align(['بسم', 'الله', 'الرحمن'], timings);
      expect(words.length, 3);
      expect(aligner.activeAt(words, 500)?.token, 'الله');
      expect(aligner.activeAt(words, 1500), isNull);
    });

    test('التحقق يرفض التداخل والخروج من المدة والتكرار', () {
      const validator = AlignmentValidator();
      expect(validator.isValid(timings, audioDurationMs: 2000), isTrue);
      expect(
        validator.isValid(const [
          WordTiming(wordIndex: 0, startMs: 0, endMs: 500),
          WordTiming(wordIndex: 1, startMs: 400, endMs: 900),
        ], audioDurationMs: 2000),
        isFalse,
      );
      expect(
        validator.isValid(const [
          WordTiming(wordIndex: 0, startMs: 0, endMs: 500),
          WordTiming(wordIndex: 0, startMs: 500, endMs: 900),
        ], audioDurationMs: 2000),
        isFalse,
      );
      expect(validator.isValid(timings, audioDurationMs: 1000), isFalse);
    });
  });

  group('التحكم بالنظر', () {
    test('التثبيت يصدر اختياراً بعد العتبة', () {
      final detector = GazeDwellDetector(dwellMs: 800, radiusPx: 20);
      expect(
        detector.feed(
          const GazePoint(x: 100, y: 100, timestampMs: 0),
          targetIdAt: 'next',
        ),
        isNull,
      );
      final selection = detector.feed(
        const GazePoint(x: 103, y: 101, timestampMs: 800),
        targetIdAt: 'next',
      );
      expect(selection?.targetId, 'next');
    });

    test('الحركة خارج النطاق تُعيد العدّ', () {
      final detector = GazeDwellDetector(dwellMs: 800, radiusPx: 20);
      detector.feed(
        const GazePoint(x: 100, y: 100, timestampMs: 0),
        targetIdAt: 'next',
      );
      expect(
        detector.feed(
          const GazePoint(x: 300, y: 300, timestampMs: 700),
          targetIdAt: 'next',
        ),
        isNull,
      );
      expect(
        detector.feed(
          const GazePoint(x: 300, y: 300, timestampMs: 1500),
          targetIdAt: 'next',
        ),
        isNull,
      );
    });

    test('تغيير العنصر يُلغي التثبيت السابق', () {
      final detector = GazeDwellDetector(dwellMs: 800, radiusPx: 20);
      detector.feed(
        const GazePoint(x: 100, y: 100, timestampMs: 0),
        targetIdAt: 'next',
      );
      expect(
        detector.feed(
          const GazePoint(x: 100, y: 100, timestampMs: 900),
          targetIdAt: 'quran',
        ),
        isNull,
      );
    });
  });

  group('اليدجت والساعة', () {
    final payload = WidgetPayload(
      nextPrayerKey: 'prayerMaghrib',
      nextPrayerTime: '17:30',
      minutesRemaining: 42,
      hijriLabel: '1448-6-16',
      qiblaBearing: 136.1,
      updatedAt: DateTime.utc(2026, 11, 27),
    );

    test('حمولة اليدجت صغيرة وقابلة للتحويل', () {
      final json = payload.toJson();
      expect(json, contains('minutesRemaining'));
      expect(payload.byteLength, lessThan(512));
      expect(jsonDecode(json)['qiblaBearing'], 136);
    });

    test('حمولة الساعة محمية بالحجم', () {
      const guard = WatchPayloadGuard();
      final message = WatchMessage(
        command: WatchCommand.nextPrayer,
        titleKey: 'nextPrayer',
        value: '17:30',
        sentAt: DateTime.utc(2026, 11, 27),
      );
      expect(guard.accepts(message), isTrue);
      expect(
        guard.accepts(
          WatchMessage(
            command: WatchCommand.athkar,
            titleKey: 'navAthkar',
            value: 'x' * 1000,
            sentAt: DateTime.utc(2026, 11, 27),
          ),
        ),
        isFalse,
      );
    });
  });
}
