import 'package:mishkat_core/mishkat_core.dart';
import 'package:test/test.dart';

void main() {
  final payload = BackupPayload(
    version: 1,
    createdAt: DateTime.utc(2026, 11, 27, 12),
    entries: {
      'hifz_units': '[{"id":1,"interval":6}]',
      'settings': '{"locale":"ar"}',
    },
  );

  group('النسخ الاحتياطي المشفر', () {
    test('جولة تشفير/فك كاملة', () {
      final codec = const BackupCodec();
      final encrypted = codec.encrypt(payload, 'strong-passphrase');
      final restored = codec.decrypt(encrypted, 'strong-passphrase');
      expect(restored.entries, equals(payload.entries));
      expect(restored.checksum, payload.checksum);
    });

    test('كلمة مرور خاطئة تُرفض', () {
      final codec = const BackupCodec();
      final encrypted = codec.encrypt(payload, 'strong-passphrase');
      expect(
        () => codec.decrypt(encrypted, 'wrong-passphrase'),
        throwsFormatException,
      );
    });

    test('تعديل الـ checksum يُكتشف', () {
      final codec = const BackupCodec();
      final encrypted = codec.encrypt(payload, 'strong-passphrase');
      final tampered = EncryptedBackup(
        version: encrypted.version,
        createdAt: encrypted.createdAt,
        iv: encrypted.iv,
        cipherText: encrypted.cipherText,
        checksum: '0' * 64,
      );
      expect(
        () => codec.decrypt(tampered, 'strong-passphrase'),
        throwsFormatException,
      );
    });

    test('كلمة مرور قصيرة تُرفض', () {
      expect(
        () => const BackupCodec().encrypt(payload, 'short'),
        throwsArgumentError,
      );
    });

    test('صيغة JSON قابلة للتصدير والاستيراد', () {
      final codec = const BackupCodec();
      final raw = codec.encrypt(payload, 'strong-passphrase').toJson();
      final decoded = EncryptedBackup.fromJson(raw);
      expect(
        codec.decrypt(decoded, 'strong-passphrase').entries,
        payload.entries,
      );
    });

    test(' checksum حرفي مستقر', () {
      expect(payload.checksum, payload.checksum);
      expect(payload.checksum.length, 64);
    });
  });

  group('التشخيص المحلي', () {
    test('تقرير بدون بيانات شخصية', () {
      final report = const DiagnosticsCollector().collect(
        appVersion: '0.1.0+1',
        osVersion: 'Android 15',
        locale: 'ar',
        datasetValid: true,
        ayahCount: 6236,
        notificationSlots: 57,
        recentErrors: const ['timeout: tafsir'],
      );
      final json = report.toRedactedJson();
      expect(json, contains('6236'));
      expect(json, contains('57'));
      expect(json, contains('"notificationBudgetOk":true'));
      expect(json, isNot(contains('latitude')));
      expect(json, isNot(contains('deviceId')));
      expect(report.notificationBudgetOk, isTrue);
    });

    test('تجاوز السقف يُعلَّم في التقرير', () {
      final report = const DiagnosticsCollector().collect(
        appVersion: '0.1.0+1',
        osVersion: 'iOS 19',
        locale: 'en',
        datasetValid: true,
        ayahCount: 6236,
        notificationSlots: 70,
        recentErrors: const [],
      );
      expect(report.notificationBudgetOk, isFalse);
    });
  });
}
