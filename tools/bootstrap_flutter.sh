#!/usr/bin/env bash
# Generates platform folders and generated Dart sources. Run once on a Flutter machine.
set -euo pipefail
cd "$(dirname "$0")/.."
flutter create --platforms=android,ios --project-name mishkat --org com.mishkat .
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
