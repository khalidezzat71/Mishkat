import 'package:home_widget/home_widget.dart';
import 'package:mishkat_core/mishkat_core.dart';

/// يرسل حمولة صغيرة إلى Glance/WidgetKit عبر home_widget.
class PrayerWidgetService {
  const PrayerWidgetService();

  static const androidProvider = 'MishkatWidgetProvider';
  static const iosProvider = 'MishkatWidget';

  Future<void> update(WidgetPayload payload) async {
    if (payload.byteLength > 512) return;
    await HomeWidget.saveWidgetData<String>(
      'mishkat_payload',
      payload.toJson(),
    );
    await HomeWidget.updateWidget(
      androidName: androidProvider,
      iOSName: iosProvider,
    );
  }
}
