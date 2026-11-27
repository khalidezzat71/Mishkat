import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

/// نسخة احتياطية محلية مشفّرة — لا تُرسل لأي خادم.
class BackupPayload {
  const BackupPayload({
    required this.version,
    required this.createdAt,
    required this.entries,
  });

  final int version;
  final DateTime createdAt;
  final Map<String, String> entries;

  String toCanonicalJson() => jsonEncode({
        'version': version,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'entries': Map.fromEntries(
          entries.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
        ),
      });

  String get checksum =>
      sha256.convert(utf8.encode(toCanonicalJson())).toString();
}

class EncryptedBackup {
  const EncryptedBackup({
    required this.version,
    required this.createdAt,
    required this.iv,
    required this.cipherText,
    required this.checksum,
  });

  final int version;
  final DateTime createdAt;
  final String iv;
  final String cipherText;
  final String checksum;

  String toJson() => jsonEncode({
        'format': 'mishkat-backup-v1',
        'version': version,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'iv': iv,
        'data': cipherText,
        'sha256': checksum,
      });

  factory EncryptedBackup.fromJson(String raw) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    if (decoded['format'] != 'mishkat-backup-v1') {
      throw const FormatException('unsupported backup format');
    }
    return EncryptedBackup(
      version: decoded['version'] as int,
      createdAt: DateTime.parse(decoded['createdAt'] as String),
      iv: decoded['iv'] as String,
      cipherText: decoded['data'] as String,
      checksum: decoded['sha256'] as String,
    );
  }
}

/// تشفير AES-256-CBC بمفتاح مشتق من كلمة المرور عبر SHA-256.
class BackupCodec {
  const BackupCodec();

  static const int currentVersion = 1;

  EncryptedBackup encrypt(BackupPayload payload, String passphrase) {
    if (passphrase.length < 8) {
      throw ArgumentError.value(passphrase, 'passphrase', 'at least 8 chars');
    }
    final key = enc.Key(Uint8List.fromList(
      sha256.convert(utf8.encode(passphrase)).bytes,
    ));
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(payload.toCanonicalJson(), iv: iv);
    return EncryptedBackup(
      version: currentVersion,
      createdAt: payload.createdAt,
      iv: iv.base64,
      cipherText: encrypted.base64,
      checksum: payload.checksum,
    );
  }

  BackupPayload decrypt(EncryptedBackup backup, String passphrase) {
    final key = enc.Key(Uint8List.fromList(
      sha256.convert(utf8.encode(passphrase)).bytes,
    ));
    final iv = enc.IV.fromBase64(backup.iv);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    late final String plain;
    try {
      plain = encrypter.decrypt(enc.Encrypted.fromBase64(backup.cipherText),
          iv: iv);
    } on Object {
      throw const FormatException('wrong passphrase or corrupted backup');
    }
    final decoded = jsonDecode(plain) as Map<String, dynamic>;
    final payload = BackupPayload(
      version: decoded['version'] as int,
      createdAt: DateTime.parse(decoded['createdAt'] as String),
      entries: (decoded['entries'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as String),
      ),
    );
    if (payload.checksum != backup.checksum) {
      throw const FormatException('SHA-256 checksum mismatch');
    }
    return payload;
  }
}
