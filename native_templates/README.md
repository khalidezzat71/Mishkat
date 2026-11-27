# قوالب اليدجت الأصلية

هذه قوالب غير مُترجمة محلياً؛ تُنسخ بعد تشغيل `flutter create` على جهاز مزوّد بFlutter.
البيانات تأتي من `home_widget`، والحمولة يبنيها `mishkat_core/lib/src/widget_payload.dart`
بصيغة JSON صغيرة (< 512 بايت). لا يوجد أي اتصال شبكي في اليدجت.

## أندرويد (Glance)

1. انسخ `android/MishkatWidgetProvider.kt` إلى
   `android/app/src/main/kotlin/com/mishkat/mishkat/`.
2. أضف إلى `android/app/build.gradle.kts`:

```kotlin
implementation("androidx.glance:glance-appwidget:1.1.0")
implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")
```

3. سجّل المستقبل في `AndroidManifest.xml` داخل `<application>`:

```xml
<receiver
    android:name=".MishkatWidgetReceiver"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/mishkat_widget_info" />
</receiver>
```

4. أضف `android/app/src/main/res/xml/mishkat_widget_info.xml` مع `updatePeriodMillis="900000"`.

> ملاحظة: التحديث الدقيق للصلاة يظل عبر AlarmManager في التطبيق، واليدجت يقرأ آخر حمولة.

## iOS (WidgetKit)

1. انسخ `ios/MishkatWidget.swift` إلى هدف WidgetKit جديد في مشروع Xcode.
2. فعّل App Group `group.com.mishkat.mishkat` للتطبيق واليدجت معاً.
3. اضبط `HomeWidget.saveWidgetData` لاستخدام نفس App Group عبر
   `HomeWidget.setAppGroupId('group.com.mishkat.mishkat')` في `main.dart`.

## التحقق

بعد النسخ، شغّل `flutter analyze && flutter build apk && flutter build ios`
على جهاز منصات مؤهل. القوالب نفسها لا تُترجم في بيئة `aarch64` الحالية.
