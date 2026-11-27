# CONTRIBUTING.md

## قبل البدء

اقرأ `AGENTS.md`. قواعد غير قابلة للكسر:

1. لا تعديل على نص المصحف المدمج.
2. لا نصوص واجهة hardcoded — أضف المفتاح إلى كل ملفات `lib/l10n/app_*.arb`.
3. لا مصادر شيعية، ولا مخرجات AI بلا إسناد سني موثّق.
4. أي مصدر جديد يمر عبر واجهة قابلة للتبديل ويُوثَّق في `LICENSES_AND_SOURCES.md`.

## سير العمل

```bash
cd packages/mishkat_core && dart analyze && dart test
cd ../.. && dart format lib test packages
```

أضف اختباراً مع كل تعديل منطقي. لا تُدمج تغييراً يكسر اختبارات السلامة.

## بناء إضافة جديدة (AppPlugin)

```dart
class MyPlugin implements AppPlugin {
  @override
  String get id => 'my_plugin';

  @override
  String get titleKey => 'pluginMyPluginTitle'; // من ARB

  @override
  Future<void> onRegister(PluginContext context) async {
    context.registerRoute('/my-plugin', (ctx) => const MyScreen());
  }

  @override
  Future<void> onEnable(PluginContext context) async {}

  @override
  Future<void> onDisable(PluginContext context) async {}
}
```

ثم سجّل الإضافة في `PluginRegistry` داخل `lib/app/providers.dart`.
لا تحتاج الإضافة إلى تعديل نواة التطبيق.

## إضافة مصدر صوت جديد

نفّذ `AudioSource` وأضف manifest HTTPS مع تحقق SHA-256. لا تضع مفاتيح في التطبيق.
