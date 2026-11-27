import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/database/app_database.dart';
import '../core/notifications/notification_service.dart';

final preferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

/// اللغة المحفوظة. العربية هي الاحتياط.
final localeProvider = StateProvider<Locale?>((ref) {
  final prefs = ref.watch(preferencesProvider);
  return prefs.maybeWhen(
    data: (p) {
      final language = p.getString('locale');
      return language == null ? const Locale('ar') : Locale(language);
    },
    orElse: () => const Locale('ar'),
  );
});

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  final prefs = ref.watch(preferencesProvider);
  return prefs.maybeWhen(
    data: (p) {
      final index = p.getInt('themeModeIndex');
      if (index != null && index < ThemeMode.values.length) {
        return ThemeMode.values[index];
      }
      return ThemeMode.system;
    },
    orElse: () => ThemeMode.system,
  );
});

/// معرّف القالب الهيكلي للواجهة (1..10). الافتراضي: المصحف الكلاسيكي.
final layoutIdProvider = StateProvider<int>((ref) {
  final prefs = ref.watch(preferencesProvider);
  return prefs.maybeWhen(
    data: (p) => p.getInt('layoutId') ?? 1,
    orElse: () => 1,
  );
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(FlutterLocalNotificationsPlugin());
});

Future<void> persistLocale(WidgetRef ref, Locale locale) async {
  final prefs = await ref.read(preferencesProvider.future);
  await prefs.setString('locale', locale.languageCode);
  ref.read(localeProvider.notifier).state = locale;
}

bool get isApplePlatform => Platform.isIOS || Platform.isMacOS;
