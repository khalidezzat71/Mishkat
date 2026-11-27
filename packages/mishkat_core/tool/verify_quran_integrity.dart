// Generates assets/quran/manifest.json after verifying the bundled Tanzil files.
// Run from packages/mishkat_core: dart run tool/verify_quran_integrity.dart
import 'dart:convert';
import 'dart:io';

import 'package:mishkat_core/mishkat_core.dart';
import 'package:path/path.dart' as p;

void main() {
  final root = Directory(p.join(Directory.current.path, '..', '..'));
  final quranDir = Directory(p.join(root.path, 'assets', 'quran'));

  String read(String name) =>
      File(p.join(quranDir.path, name)).readAsStringSync();

  final report = const QuranIntegrityVerifier().verify(
    uthmaniXml: read('quran-uthmani-v1.1.xml'),
    metadataXml: read('quran-data-v1.0.xml'),
  );

  if (!report.isValid) {
    stderr.writeln('INTEGRITY FAILED: ${report.issues.join('; ')}');
    exitCode = 1;
    return;
  }

  final manifest = File(p.join(quranDir.path, 'manifest.json'));
  manifest.writeAsStringSync('${jsonEncode(report.toJson())}\n');
  stdout.writeln('OK: ${report.ayahCount} ayahs, ${report.surahCount} surahs, '
      '${report.pageCount} pages');
  stdout.writeln('manifest written to ${manifest.path}');
}
