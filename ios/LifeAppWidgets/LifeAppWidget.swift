import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), focus: "30m", workout: "45m", sleep: "8h")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), focus: "30m", workout: "45m", sleep: "8h")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let userDefaults = UserDefaults(suiteName: "group.com.example.lifeapp.widgets")
        let focus = userDefaults?.string(forKey: "today_focus") ?? "--"
        let workout = userDefaults?.string(forKey: "today_workout") ?? "--"
        let sleep = userDefaults?.string(forKey: "today_sleep") ?? "--"

        let entry = SimpleEntry(date: Date(), focus: focus, workout: workout, sleep: sleep)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let focus: String
    let workout: String
    let sleep: String
}

struct LifeAppWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Progress")
                .font(.headline)
                .foregroundColor(.white)

            HStack(spacing: 4) {
                StatView(label: "Focus", value: entry.focus)
                StatView(label: "Workout", value: entry.workout)
                StatView(label: "Sleep", value: entry.sleep)
            }
        }
        .padding()
        .background(Color(white: 0.1, opacity: 0.8))
    }
}

struct StatView: View {
    let label: String
    let value: String

    var body: some View {
        VStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }
}

struct LifeAppWidget: Widget {
    let kind: String = "LifeAppWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            LifeAppWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Life App Progress")
        .description("See your daily progress at a glance.")
        .supportedFamilies([.systemSmall])
    }
}
