// Run from packages/mishkat_core: dart run tool/build_quran_dataset.dart
import 'dart:io';

import 'package:mishkat_core/mishkat_core.dart';
import 'package:path/path.dart' as p;

void main() {
  final root = Directory(p.join(Directory.current.path, '..', '..'));
  final assets = Directory(p.join(root.path, 'assets', 'quran'));
  String read(String name) =>
      File(p.join(assets.path, name)).readAsStringSync();

  final report = const QuranIntegrityVerifier().verify(
    uthmaniXml: read('quran-uthmani-v1.1.xml'),
    metadataXml: read('quran-data-v1.0.xml'),
  );
  if (!report.isValid) {
    stderr.writeln('Refusing to build: ${report.issues.join('; ')}');
    exitCode = 1;
    return;
  }

  final dataset = const QuranDatasetBuilder().build(
    uthmaniXml: read('quran-uthmani-v1.1.xml'),
    metadataXml: read('quran-data-v1.0.xml'),
  );
  final output = File(p.join(assets.path, 'quran-dataset.json'));
  output.writeAsStringSync(dataset.toJson());
  stdout.writeln('Wrote ${dataset.ayahs.length} ayahs to ${output.path}');
}
