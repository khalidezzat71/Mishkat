import 'dart:convert';

import 'notification_plan.dart';

/// تقرير تشخيص محلي — يُصدَّر من شاشة «حول التطبيق» بدون بيانات شخصية.
class DiagnosticReport {
  const DiagnosticReport({
    required this.generatedAt,
    required this.appVersion,
    required this.osVersion,
    required this.locale,
    required this.datasetValid,
    required this.ayahCount,
    required this.notificationSlots,
    required this.pendingCap,
    required this.recentErrors,
  });

  final DateTime generatedAt;
  final String appVersion;
  final String osVersion;
  final String locale;
  final bool datasetValid;
  final int ayahCount;
  final int notificationSlots;
  final int pendingCap;
  final List<String> recentErrors;

  bool get notificationBudgetOk => notificationSlots <= pendingCap;

  /// لا يحتوي على إحداثيات ولا على أسماء ولا على أي معرّف جهاز.
  String toRedactedJson() => jsonEncode({
        'generatedAt': generatedAt.toUtc().toIso8601String(),
        'appVersion': appVersion,
        'osVersion': osVersion,
        'locale': locale,
        'datasetValid': datasetValid,
        'ayahCount': ayahCount,
        'notificationSlots': notificationSlots,
        'pendingCap': pendingCap,
        'notificationBudgetOk': notificationBudgetOk,
        'recentErrors': recentErrors.take(10).toList(),
      });
}

class DiagnosticsCollector {
  const DiagnosticsCollector();

  DiagnosticReport collect({
    required String appVersion,
    required String osVersion,
    required String locale,
    required bool datasetValid,
    required int ayahCount,
    required int notificationSlots,
    required List<String> recentErrors,
    DateTime? now,
  }) {
    return DiagnosticReport(
      generatedAt: now ?? DateTime.now(),
      appVersion: appVersion,
      osVersion: osVersion,
      locale: locale,
      datasetValid: datasetValid,
      ayahCount: ayahCount,
      notificationSlots: notificationSlots,
      pendingCap: NotificationPlan.iosPendingCap,
      recentErrors: List.unmodifiable(recentErrors),
    );
  }
}
