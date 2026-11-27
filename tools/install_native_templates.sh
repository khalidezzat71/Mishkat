#!/usr/bin/env bash
# نسخ قوالب اليدجت الأصلية بعد flutter create. لا يعمل على بيئة بلا منصات.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -d android/app/src/main ] || [ ! -d ios ]; then
  echo "Run tools/bootstrap_flutter.sh first (platform folders are missing)." >&2
  exit 1
fi

android_dir="android/app/src/main/kotlin/com/mishkat/mishkat"
mkdir -p "$android_dir"
cp native_templates/android/MishkatWidgetProvider.kt "$android_dir/MishkatWidgetProvider.kt"

ios_dir="ios/MishkatWidget"
mkdir -p "$ios_dir"
cp native_templates/ios/MishkatWidget.swift "$ios_dir/MishkatWidget.swift"

echo "Copied Glance and WidgetKit templates. Review native_templates/README.md for Gradle/Xcode registration."
