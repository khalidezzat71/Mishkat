import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// أول مدينة تُعرض عند التشغيل الأول؛ يمكن تغييرها من إعدادات الصلاة.
const defaultPrayerCity = PrayerCity(
  id: 1,
  nameAr: 'مكة المكرمة',
  nameEn: 'Makkah',
  country: 'SA',
  latitude: 21.4225,
  longitude: 39.8262,
  timeZone: 'Asia/Riyadh',
);

/// مدينة محلية من القائمة المدمجة — لا تُرسل إحداثياتها لأي خادم.
class PrayerCity {
  const PrayerCity({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.timeZone,
  });

  factory PrayerCity.fromJson(Map<String, dynamic> json) => PrayerCity(
    id: json['id'] as int,
    nameAr: json['name_ar'] as String,
    nameEn: json['name_en'] as String,
    country: json['country'] as String,
    latitude: (json['lat'] as num).toDouble(),
    longitude: (json['lng'] as num).toDouble(),
    timeZone: json['tz'] as String,
  );

  final int id;
  final String nameAr;
  final String nameEn;
  final String country;
  final double latitude;
  final double longitude;
  final String timeZone;

  String label(bool arabic) => arabic ? nameAr : nameEn;
}

final prayerCityCatalogProvider = FutureProvider<List<PrayerCity>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/cities.json');
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  return [
    for (final item in decoded['cities'] as List<dynamic>)
      PrayerCity.fromJson(item as Map<String, dynamic>),
  ];
});
