import SwiftUI
import WidgetKit

// قالب WidgetKit ليدجت الصلاة. يُنسخ بعد flutter create عبر tools/install_native_templates.sh.
// يقرأ الحمولة التي يكتبها home_widget من App Group، دون أي اتصال شبكي.
private let groupDefaults = UserDefaults(suiteName: "group.com.mishkat.app")

struct MishkatEntry: TimelineEntry {
    let date: Date
    let payload: [String: Any]
}

struct MishkatProvider: TimelineProvider {
    func placeholder(in context: Context) -> MishkatEntry {
        MishkatEntry(date: Date(), payload: [:])
    }

    func getSnapshot(in context: Context, completion: @escaping (MishkatEntry) -> Void) {
        completion(MishkatEntry(date: Date(), payload: readPayload()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MishkatEntry>) -> Void) {
        let entry = MishkatEntry(date: Date(), payload: readPayload())
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900))))
    }

    private func readPayload() -> [String: Any] {
        guard let raw = groupDefaults?.string(forKey: "mishkat_payload"),
              let data = raw.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return [:] }
        return json
    }
}

struct MishkatWidgetEntryView: View {
    var entry: MishkatProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(entry.payload["nextPrayerKey"] as? String ?? "") \(entry.payload["nextPrayerTime"] as? String ?? "")")
            Text("-\(entry.payload["minutesRemaining"] as? Int ?? 0)")
            Text(entry.payload["hijriLabel"] as? String ?? "")
            Text("Qibla \(entry.payload["qiblaBearing"] as? Int ?? 0)°")
        }
    }
}

@main
struct MishkatWidget: Widget {
    let kind: String = "MishkatWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MishkatProvider()) { entry in
            MishkatWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Mishkat")
        .description("Prayer times at a glance")
    }
}
