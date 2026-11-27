import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mishkat/core/notifications/notification_service.dart';
import 'package:mishkat/features/prayer/domain/prayer_settings.dart';
import 'package:mishkat_core/mishkat_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/database/app_database.dart';

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
      if (index != null && index >= 0 && index < ThemeMode.values.length) {
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
    data: (p) {
      final id = p.getInt('layoutId');
      return id != null && id >= 1 && id <= 10 ? id : 1;
    },
    orElse: () => 1,
  );
});

/// المدينة المختارة. مكة هي الافتراض حتى لا تظهر شاشة فارغة عند التشغيل الأول.
final selectedCityIdProvider = StateProvider<int>((ref) {
  final prefs = ref.watch(preferencesProvider);
  return prefs.maybeWhen(data: (p) => p.getInt('cityId') ?? 1, orElse: () => 1);
});

final selectedCityProvider = Provider<PrayerCity>((ref) {
  final id = ref.watch(selectedCityIdProvider);
  final cities = ref.watch(prayerCityCatalogProvider).value ?? const [];
  for (final city in cities) {
    if (city.id == id) return city;
  }
  return defaultPrayerCity;
});

final notificationsEnabledProvider = StateProvider<bool>((ref) {
  final prefs = ref.watch(preferencesProvider);
  return prefs.maybeWhen(
    data: (p) => p.getBool('notificationsEnabled') ?? true,
    orElse: () => true,
  );
});

final calculationMethodProvider = StateProvider<SunniCalculationMethod>((ref) {
  final prefs = ref.watch(preferencesProvider);
  return prefs.maybeWhen(
    data: (p) {
      final index = p.getInt('calculationMethodIndex');
      if (index != null &&
          index >= 0 &&
          index < SunniCalculationMethod.values.length) {
        return SunniCalculationMethod.values[index];
      }
      return SunniCalculationMethod.ummAlQura;
    },
    orElse: () => SunniCalculationMethod.ummAlQura,
  );
});

final asrJurisprudenceProvider = StateProvider<AsrJurisprudence>((ref) {
  final prefs = ref.watch(preferencesProvider);
  return prefs.maybeWhen(
    data: (p) {
      final index = p.getInt('asrJurisprudenceIndex');
      if (index != null &&
          index >= 0 &&
          index < AsrJurisprudence.values.length) {
        return AsrJurisprudence.values[index];
      }
      return AsrJurisprudence.shafi;
    },
    orElse: () => AsrJurisprudence.shafi,
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

Future<void> persistThemeMode(WidgetRef ref, ThemeMode mode) async {
  final prefs = await ref.read(preferencesProvider.future);
  await prefs.setInt('themeModeIndex', mode.index);
  ref.read(themeModeProvider.notifier).state = mode;
}

Future<void> persistLayout(WidgetRef ref, int id) async {
  final prefs = await ref.read(preferencesProvider.future);
  await prefs.setInt('layoutId', id);
  ref.read(layoutIdProvider.notifier).state = id;
}

Future<void> persistCity(WidgetRef ref, int id) async {
  final prefs = await ref.read(preferencesProvider.future);
  await prefs.setInt('cityId', id);
  ref.read(selectedCityIdProvider.notifier).state = id;
}

Future<void> persistCalculationMethod(
  WidgetRef ref,
  SunniCalculationMethod method,
) async {
  final prefs = await ref.read(preferencesProvider.future);
  await prefs.setInt('calculationMethodIndex', method.index);
  ref.read(calculationMethodProvider.notifier).state = method;
}

Future<void> persistAsrJurisprudence(
  WidgetRef ref,
  AsrJurisprudence asr,
) async {
  final prefs = await ref.read(preferencesProvider.future);
  await prefs.setInt('asrJurisprudenceIndex', asr.index);
  ref.read(asrJurisprudenceProvider.notifier).state = asr;
}

Future<void> persistNotificationsEnabled(WidgetRef ref, bool enabled) async {
  final prefs = await ref.read(preferencesProvider.future);
  await prefs.setBool('notificationsEnabled', enabled);
  ref.read(notificationsEnabledProvider.notifier).state = enabled;
}

bool get isApplePlatform => Platform.isIOS || Platform.isMacOS;
