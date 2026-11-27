# ARCHITECTURE.md — مشكاة

> تحديث 2026-11-27: المرجعية السنية فقط، والمصادر المجانية أولاً مع إمكانية استبدالها
> بمصادر مدفوعة لاحقاً دون تغيير الواجهة.

## الطبقات

```
Flutter UI (features/*/presentation)
        │  Riverpod providers
        ▼
Use cases (features/*/domain)  ───────► mishkat_core (pure Dart algorithms)
        │                                   qibla / hijri / sm2 / normalize / integrity
        ▼
Repositories (features/*/data) ───────► Drift SQLite (FTS5) + AudioSource + ApiClient
```

### لماذا حزمة `mishkat_core` منفصلة؟

بيئة التطوير الحالية تعمل على `aarch64` ولا تتوفر لها حزمة Flutter SDK رسمية.
فصل المنطق الخالص في حزمة Dart مستقلة يسمح بتشغيل `dart analyze` و`dart test` فعلياً
لكل خوارزميات الصلاة والقبلة والتحفيظ وسلامة النص، ويبقيها محصّنة ضد تغيّر الإطار.

## المصادر والتدفق

| البيانات | المصدر | التخزين | ملاحظة ترخيصية |
|---|---|---|---|
| نص المصحف | Tanzil Uthmani v1.1 | `assets/quran/` حرفي + SHA-256 | CC BY 3.0، إسناد ورابط إلزاميان |
| بيانات الصفحة/الجزء/الحزب | Tanzil Metadata v1.0 | `assets/quran/` | cc-by |
| التفسير | Quran.com Content Sync | SQLite، كاش ≤ 7 أيام | لا يُضمّن في Git |
| الصوت | `AudioSource` مجرد | تنزيل بطلب المستخدم، LRU | قابل للتبديل مجاني/مدفوع |
| الخط | KFGQPC Hafs EULA | `assets/fonts/` كما هو | غير معدّل، مع إشعار الترخيص |

## قيد المرجعية

كل المحتوى الديني (تفسير، أذكار، أدعية، غريب، إحصاءات، ومخرجات AI) مقيد بالمصادر
السنية فقط. تُرفض أي إضافة لا تُثبت سندها إلى مصدر سني موثّق. طبقة `ContentPolicy`
 تتحقق من `source.sect == sunni` قبل تخزين أي محتوى ديني.

## قاعدة البيانات

رئيسية: `surahs`, `ayahs`, `ayah_fts`, `words`, `word_timings`, `reciters`,
`tafsirs`, `tafsir_texts`, `gharib_words`, `athkar`, `hifz_plans`, `hifz_units`,
`recitation_attempts`, `reading_sessions`, `hifz_logs`, `khatmahs`, `bookmarks`,
`prayer_settings`, `app_settings`, `cities`, `downloads`, `notification_schedule`,
`error_logs`, `schema_meta`.

الفهرس: عمود `text_search` مشتق محلياً من `text_uthmani` (إزالة الحركات، توحيد
آ/أ/إ/ة/ى/ؤ/ئ) ويُفهرس بـ FTS5 `unicode61`. لا يُعرض هذا العمود للمستخدم أبداً.

## جدولة الإشعارات (iOS ≤ 64)

```
42 = 6 مواقيت × 7 أيام   (أذان دقيق)
 6 = تذكير مسبق 24h
 6 = إقامة 24h
 3 = أذكار 24h
────────────────────────
57 ≤ 64  + 7 احتياط
```

إعادة البناء يومياً عبر `BGTaskScheduler` وعند فتح التطبيق. على Android:
`AlarmManager.setExactAndAllowWhileIdle` + `BOOT_COMPLETED` + WorkManager كنسخة احتياطية.

## المرحلة الثانية — واجهات الميزات المتقدمة

| الميزة | العقد في `mishkat_core` | التنفيذ في Flutter | الشرط |
|---|---|---|---|
| التفسير | `TafsirSourcePolicy`, `TafsirCache` | `TafsirRepository` | OptIn `tafsir` + عنوان وقت التشغيل |
| الصوت | `AudioSource`, `ReciterManager`, `DownloadPolicy` | `ReciterRepository` + `just_audio` | طلب المستخدم، تخزين خاص |
| الكلمات | `WordSyncProxy`, `AlignmentValidator` | `HttpWordSyncProxy` | OptIn `wordSync` + `MISHKAT_AI_PROXY_URL` |
| النظر | `GazeDwellDetector` | `GazeController` | OptIn `gaze` |
| اليدجت/الساعة | `WidgetPayload`, `WatchMessage` | `home_widget` / `MethodChannel` | OptIn `widget` / `watch` |

كل مفاتيح OptIn محفوظة في `SharedPreferences` تحت البادئة `optIn.` وكلها
`false` افتراضياً. عناوين الخوادم (`MISHKAT_TAFSIR_BASE_URL`,
`MISHKAT_AI_PROXY_URL`) تُحقن بـ `--dart-define`؛ لا توجد مفاتيح API في الهاتف.


## المرحلة الثالثة — مسارات إضافية

| المسار | العقد | التنفيذ | قيد |
|---|---|---|---|
| التسميع الصوتي | `RecitationProxy`, `RecitationPipeline` | `HttpRecitationProxy` + `RecitationScreen` | OptIn `grading` + الوكيل |
| تمييز الكلمات | `WordSyncProxy`, `WordAligner` | `wordTimingsForAyahProvider` + `WordHighlight` | OptIn `wordSync` + الوكيل |
| النظر | `GazeSource` | `MethodChannelGazeSource` + `GazeController` | OptIn `gaze` + إذن أصلي |
| اليدجت | `WidgetPayload` | قوالب Glance/WidgetKit في `native_templates/` | OptIn `widget` |
| القوالب الهيكلية | `LayoutDefinition` | `NavigationShell` يطبّق التنقل والكثافة | `layoutIdProvider` |

قوالب المنصات تُنسخ بـ `tools/install_native_templates.sh` بعد توليد مجلدات المنصات،
ولا تتضمن أي اتصال شبكي أو مفتاح. الخوارزميات تبقى في `mishkat_core` لتُختبر
على أي جهاز حتى دون Flutter.

## قابلية التوسع

- `AppPlugin` interface مع `onRegister/onEnable/onDisable` وسجل `PluginRegistry`.
- `LayoutRegistry` يعرّف 10 قوالب هيكلية (ليست مجرد ألوان).
- `BackendProxy` للذكاء الاصطناعي والتسميع: الهاتف لا يحمل أي مفتاح.
