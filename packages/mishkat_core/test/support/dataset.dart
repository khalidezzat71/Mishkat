import 'dart:io';

import 'package:path/path.dart' as p;

/// مسار الملفات من حزمة mishkat_core إلى جذور المشروع.
Directory get projectRoot =>
    Directory(p.join(Directory.current.path, '..', '..'));

String readAsset(String name) =>
    File(p.join(projectRoot.path, 'assets', 'quran', name)).readAsStringSync();

String get uthmaniXml => readAsset('quran-uthmani-v1.1.xml');

String get metadataXml => readAsset('quran-data-v1.0.xml');
