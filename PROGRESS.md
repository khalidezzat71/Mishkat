# PROGRESS.md — سجل التنفيذ

## 2026-11-27 — بوابة الاكتشاف

- [x] عرض الخطة المعمارية (شجرة + قاعدة بيانات + حزم).
- [x] التحقق من التراخيص: Tanzil CC BY 3.0، QF شروط 2026-11-20، KFGQPC EULA، adhan MIT.
- [x] موافقة المستخدم: مجاني أولاً، قابل للاستبدال والشراء لاحقاً.
- [x] المرجعية السنية فقط — لا مصادر شيعية في أي طبقة (قيد مُختبر آلياً).

## 2026-11-27 — المرحلة الأولى: MVP ✅

### المحطة 1: Scaffold

- [x] المستندات: LICENSE, README, AGENTS, ARCHITECTURE, ROADMAP, REVIEW_CHECKLIST,
      LICENSES_AND_SOURCES, CONTRIBUTING.
- [x] تنزيل نص Tanzil Uthmani v1.1 وبياناته v1.0 مع إشعار الترخيص داخل الملف.
- [x] حزمة `mishkat_core` (Dart خالص): qibla، hijri، sm2، arabic_normalizer،
      quran_integrity + مولّد manifest.
- [x] l10n: خمسة ملفات ARB متطابقة المفاتيح + `l10n.yaml` (العربية قالب/احتياط).
- [x] هيكل Flutter: Riverpod، GoRouter، Drift/FTS5، سجل إضافات، سجل 10 قوالب واجهة.
- [x] CI وقالب البلاغ.

### المحطة 2: Core Prayer/Qibla

- [x] `adhan_dart`؛ خمس طرق سنية فقط (حُذفت الجعفرية/طهران/الجزائرية).
- [x] اختبارات مرجع adhan-js (رالي 2015، ISNA/حنفي وMWL/شافعي).
- [x] `DailyPrayers` للصلاة القادمة والعد التنازلي.
- [x] `NotificationPlan`: 42 أذان + 6 تذكير + 6 إقامة + 3 أذكار = 57 ≤ 64.
- [x] بوصلة great-circle + تحكم محاذاة بحقن البثّ؛ مزوّدات Riverpod.

### المحطة 3: Offline Quran/Search

- [x] بناء مجموعة بيانات من XML: 114 سورة / 6236 آية مع صفحة/جزء/حزب/ربع.
- [x] عمودا بحث مشتقّان (إسقاط الشدة وتوسيعها) دون لمس `text_uthmani`.
- [x] `quran-dataset.json` (3.6MB) + مستودع Drift يبني FTS5 عند أول تشغيل.
- [x] فهرس بحث في الذاكرة + اختبارات مطابقة بدون تشكيل.

### المحطة 4: Memorization Engine

- [x] SM-2 (1 → 6 → 16 يوماً، حد أدنى 1.3، إعادة تعلم عند النسيان).
- [x] خطة ختمة: صفحة/وجه/جزء (604 / 1208 / 30 وحدة) مع ورد يومي.
- [x] تقييم التسميع بمحاذاة LCS ونسبة مئوية.
- [x] توليد نص Cloze مخفي ببذرة ثابتة دون تعديل نص المصحف.
- [x] واجهة ورد اليوم مرتبطة بالخطة.

### المحطة 5: Notifications & Polish

- [x] خدمة إشعارات محلية: قنوات أندرويد/ iOS، جدولة صحيحة، معرّف ثابت.
- [x] أذكار سنية المصدر فقط في `assets/data/athkar.json` + اختبار سياسة.
- [x] شاشة المصادر والتوثيق من `assets/data/sources.json`.
- [x] نسخ احتياطي AES-256-CBC + SHA-256 وفكّه واختبار كلمة مرور خاطئة.
- [x] تقرير تشخيص محلي بدون بيانات شخصية + شاشة نسخ التقرير.
- [x] سكربت `tools/bootstrap_flutter.sh` لتوليد مجلدات المنصات.

## 2026-11-27 — المرحلة الثانية: الميزات المتقدمة ✅

### المحطة 6: Tafsir Content Sync

- [x] `TafsirSourcePolicy` يسمح بأربعة تفاسير سنية فقط (الميسّر/السعدي/ابن كثير/الجلالين).
- [x] كاش 7 أيام مع طرد الأقدم و`prune`؛ لا نص تفسير داخل Git.
- [x] `TafsirRepository` يجلب وقت التشغيل عبر dio ويخزّن في Drift، ويعمل بأمان عند انقطاع الشبكة.
- [x] لوحة تفسير اختيارية في شاشة المصحف.

### المحطة 7: إدارة القرّاء والتنزيلات

- [x] `AudioSource` + `ReciterManager`: نمط `SSSAAA`، ترتيب مجاني أولاً، رفض غير السني.
- [x] `DownloadPolicy`: تحقق SHA-256، حصة+LRU، manifest للإسناد.
- [x] `ReciterRepository`: تنزيل في مساحة documents خاصة، حذف صريح، `just_audio` للتشغيل.
- [x] شاشة القرّاء مع اختيار السورة والآية.

### المحطة 8: مزامنة الكلمات

- [x] `WordSyncProxy` كعقد، `HttpWordSyncProxy` عبر dio بلا مفاتيح (عنوان يُحقن وقت البناء).
- [x] `AlignmentValidator` يرفض التداخل/التكرار/الخروج من مدة الصوت.
- [x] مزوّد `wordTimingsProvider` مقيد بـ OptIn + إعداد الوكيل.

### المحطة 9: اليدجت والساعة والنظر

- [x] `WidgetPayload` / `WatchMessage` بحمولة صغيرة محمية بالحجم.
- [x] `home_widget` و`MethodChannel` كجسر، مع جسر نشر من شاشة الصلاة.
- [x] `GazeDwellDetector` مع اختبارات العتبة والخروج من النطاق وتغيير العنصر.
- [x] ستة مفاتيح OptIn محفوظة في SharedPreferences، كلها متوقفة افتراضياً.

### المحطة 10: الإحصائيات والنسخ الاحتياطي

- [x] شاشة إحصائيات محلية من Drift (وحدات، محاولات، متوسط دقة، صفحات).
- [x] `BackupService` يصدّر/يستعيد إعدادات ووحدات الحفظ عبر `BackupCodec`.
- [x] شاشة نسخ احتياطي مشفّرة بالكامل محلياً.
- [x] توسيع ملفات ARB الخمسة بنفس المفاتيح الجديدة (العربية قالب/احتياط).

## 2026-11-27 — المرحلة الثالثة: الاستكمال ✅

### المحطة 11: مسار التسميع الكامل

- [x] `recitation_pipeline.dart`: عقد `RecitationProxy`، تحويل الدقة إلى `Sm2Quality`.
- [x] `HttpRecitationProxy` عبر الوكيل فقط، و`RecitationScreen` تربط `record` بالمحاذاة.
- [x] حفظ محاولات التسميع في `recitation_attempts` مع الدقة والمطابقة.
- [x] 5 اختبارات جديدة للحدود والمسار الكامل.

### المحطة 12: تمييز الكلمات

- [x] `referenceFor` في `QuranRepository` يربط المعرّف العالمي بـ(سورة، آية) محلياً.
- [x] `wordTimingsForAyahProvider` و`WordHighlight` يعرضان الكلمات RTl مع تتبّع الزمن.
- [x] إصلاح خطأ نحوي ثانٍ موروث في `ensureIndexed` كان يمنع بناء الفهرس.

### المحطة 13: قوالب اليدجت الأصلية

- [x] `native_templates/android/MishkatWidgetProvider.kt` (Glance).
- [x] `native_templates/ios/MishkatWidget.swift` (WidgetKit).
- [x] `tools/install_native_templates.sh` + تعليمات التسجيل في `native_templates/README.md`.
- [x] ضبط App Group في `lib/main.dart` عبر `HomeWidget.setAppGroupId`.

### المحطة 14: مصدر النظر الأصلي

- [x] `GazeSource` كعقد مستقل + `MethodChannelGazeSource`.
- [x] `GazeController.enable` يطلب الإذن ثم يبدأ الاستماع فقط بعد الموافقة.
- [x] مفاتيح OptIn ورسائل خطأ مترجمة في ARB.

### المحطة 15: القوالب الهيكلية العشرة

- [x] `NavigationShell` يطبّق أنماط bottomBar/topTabs/floatingDock/none والكثافة.
- [x] اختبار يضمن 10 قوالب بمعرّفات فريدة ومفاتيح ترجمة موجودة.

## التحقق النهائي

- `dart analyze` في `mishkat_core`: نظيف.
- `dart test` في `mishkat_core`: **94 اختباراً ناجحاً** (18 اختباراً جديداً للمرحلة الثانية).
- `dart format --output=none --set-exit-if-changed lib test packages`: ناجح على 69 ملف Dart.
- سلامة البيانات: 114 / 6236 / 604 + SHA-256 مطابق.
- إصلاح خطأ نحوي موروث في `quran_repository.dart` (`ayahText`) أثناء هذا التحقق.

### ملاحظة بيئة التحقق

الجهاز الحالي `aarch64` بلا Flutter SDK رسمي، لذا لم يُشغَّل `flutter analyze` و
`flutter test` محلياً. وظيفة CI على `ubuntu-latest` مع Flutter 3.24.5 تنفّذهما،
وسكربت `bootstrap_flutter.sh` يولّد مجلدات المنصات هناك قبل البناء.

## المتبقي (على جهاز مزوّد بFlutter)

ترجمة قوالب Glance/WidgetKit، تتبّع نظر بالكاميرا، تشغيل `flutter analyze/test/build`،
وحلقات العائلية عند طلب صريح. انظر `ROADMAP.md`.
