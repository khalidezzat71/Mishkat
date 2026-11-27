# مشكاة — الصلاة والقرآن والتحفيظ

تطبيق موبايل مفتوح المصدر يجمع مواقيت الصلاة والأذان والقبلة، والمصحف العثماني
مع البحث الفوري، ونظام تحفيظ مبني على التكرار المتباعد، وأذكاراً يومية.

**سياسة المصادر:** مجانية أولاً، قابلة للاستبدال أو الشراء لاحقاً، والمرجعية
السنية فقط (لا مصادر شيعية). التفاصيل في [`AGENTS.md`](AGENTS.md) و
[`LICENSES_AND_SOURCES.md`](LICENSES_AND_SOURCES.md).

## بناء APK للاختبار عبر GitHub Actions

لا يحتاج جهازك إلى FlutterSDK. ارفع المستودع إلى GitHub ثم:

1. افتح تبويب **Actions**.
2. اختر سير العمل **Build APK** ثم **Run workflow**.
3. بعد انتهاء التشغيل، حمّل الملف `mishkat-apk` من قسم Artifacts.
4. افتح `SHA256SUMS.txt` وتحقق من البصمة قبل التثبيت.

السير العمل يولّد مجلدات Android، ينشئ ملفات الترجمة وDrift، يفحص التنسيق والتحليل،
ثم يبني `mishkat-debug.apk` و`mishkat-release.apk`.

## التشغيل

```bash
# 1) طبقة المنطق الخالصة — تعمل دون Flutter
cd packages/mishkat_core
dart pub get
dart analyze
dart test

# 2) تطبيق Flutter (يتطلب Flutter 3.24+)
cd ../..
flutter pub get
flutter gen-l10n
flutter run
```

## البنية

```
packages/mishkat_core/   خوارزميات pure Dart: القبلة، الهجري، SM-2، التطبيع، السلامة
lib/features/*           ميزات التطبيق (prayer, quran, memorization, athkar, ...)
lib/core/                قاعدة البيانات، الشبكة، الإشعارات، الصوت، النسخ الاحتياطي
lib/l10n/                ملفات ARB: ar, en, fr, ur, id
assets/quran/            نص Tanzil v1.1 + بياناته الوصفية (حرفي وموثّق)
```

## الوثائق

- [ARCHITECTURE.md](ARCHITECTURE.md) — القرارات المعمارية.
- [ROADMAP.md](ROADMAP.md) — مراحل التسليم.
- [CONTRIBUTING.md](CONTRIBUTING.md) — المساهمة وبناء إضافة جديدة.
- [REVIEW_CHECKLIST.md](REVIEW_CHECKLIST.md) — مراجعة كل إصدار.

## حالة التقدم

انظر [`PROGRESS.md`](PROGRESS.md). المرحلة الأولى (MVP) قيد البناء.
