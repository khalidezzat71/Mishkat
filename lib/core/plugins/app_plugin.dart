import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// واجهة الإضافات المستقلة — لا تحتاج أي إضافات إلى تعديل نواة التطبيق.
abstract class AppPlugin {
  const AppPlugin();

  String get id;

  /// مفتاح نص من ARB (لا نصوص hardcoded).
  String get titleKey;

  Future<void> onRegister(PluginContext context);

  Future<void> onEnable(PluginContext context);

  Future<void> onDisable(PluginContext context);
}

class PluginContext {
  PluginContext(this.router);

  final GoRouter router;
  final Map<String, WidgetBuilder> routes = {};

  void registerRoute(String path, WidgetBuilder builder) =>
      routes[path] = builder;
}

class PluginRegistry {
  final Map<String, AppPlugin> _plugins = {};

  Iterable<AppPlugin> get plugins => _plugins.values;

  void register(AppPlugin plugin) => _plugins[plugin.id] = plugin;

  AppPlugin? get(String id) => _plugins[id];

  Future<void> enable(String id, PluginContext context) async {
    await _plugins[id]?.onEnable(context);
  }

  Future<void> disable(String id, PluginContext context) async {
    await _plugins[id]?.onDisable(context);
  }
}
