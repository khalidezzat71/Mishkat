package com.mishkat.mishkat

import android.content.Context
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.provideContent
import androidx.glance.layout.Column
import androidx.glance.text.Text
import org.json.JSONObject

/**
 * قالب Glance ليدجت الصلاة. يُنسخ بعد flutter create عبر tools/install_native_templates.sh.
 * يقرأ الحمولة التي يكتبها home_widget من SharedPreferences دون أي اتصال شبكي.
 */
class MishkatWidgetProvider : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val raw = prefs.getString("mishkat_payload", "{}") ?: "{}"
        val payload = runCatching { JSONObject(raw) }.getOrDefault(JSONObject())

        val nextKey = payload.optString("nextPrayerKey", "")
        val time = payload.optString("nextPrayerTime", "")
        val minutes = payload.optInt("minutesRemaining", 0)
        val hijri = payload.optString("hijriLabel", "")
        val qibla = payload.optInt("qiblaBearing", 0)

        provideContent {
            Column(modifier = GlanceModifier) {
                Text(text = "$nextKey  $time")
                Text(text = "-$minutes")
                Text(text = hijri)
                Text(text = "Qibla $qibla°")
            }
        }
    }
}

class MishkatWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = MishkatWidgetProvider()
}
