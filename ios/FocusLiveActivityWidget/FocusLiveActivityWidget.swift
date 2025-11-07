import SwiftUI
import WidgetKit

struct FocusWidgetEntry: TimelineEntry {
  let date: Date
  let state: FocusWidgetSharedState
}

struct FocusTimerProvider: TimelineProvider {
  func placeholder(in context: Context) -> FocusWidgetEntry {
    FocusWidgetEntry(date: Date(), state: FocusWidgetSharedState.placeholder())
  }

  func getSnapshot(in context: Context, completion: @escaping (FocusWidgetEntry) -> Void) {
    let state = FocusWidgetStorage.load() ?? FocusWidgetSharedState.placeholder()
    completion(FocusWidgetEntry(date: Date(), state: state))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<FocusWidgetEntry>) -> Void) {
    let state = FocusWidgetStorage.load() ?? FocusWidgetSharedState.placeholder()
    let entry = FocusWidgetEntry(date: Date(), state: state)
    completion(Timeline(entries: [entry], policy: .atEnd))
  }
}

struct FocusLiveActivityWidgetView: View {
  let entry: FocusWidgetEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(titleText)
        .font(.headline)
        .foregroundStyle(.primary)
      Text(subtitleText)
        .font(.footnote)
        .foregroundStyle(.secondary)
      if !remainingText.isEmpty {
        Text(remainingText)
          .font(.title2.monospacedDigit())
          .fontWeight(.semibold)
      }
      progressView
      HStack {
        Image(systemName: "play.fill")
          .font(.body)
        Text("Open Life App")
          .font(.body)
          .fontWeight(.medium)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .containerBackground(.fill.tertiary, for: .widget)
  }

  private var progressView: some View {
    if entry.state.totalSeconds <= 0 {
      return AnyView(EmptyView())
    }
    let progress = min(max(Double(entry.state.totalSeconds - entry.state.remainingSeconds) / Double(entry.state.totalSeconds), 0), 1)
    return AnyView(ProgressView(value: progress)
      .progressViewStyle(.linear))
  }

  private var titleText: String {
    if entry.state.remainingSeconds <= 0 {
      return "Ready to focus"
    }
    if entry.state.isPaused {
      return "Paused · \(entry.state.segmentTitle)"
    }
    return entry.state.segmentTitle
  }

  private var subtitleText: String {
    if entry.state.remainingSeconds <= 0 {
      return "Start your next session"
    }
    if entry.state.isPaused {
      return "Tap to resume"
    }
    if let upNext = entry.state.upNextSegment, !upNext.isEmpty {
      return "Up next: \(upNext)"
    }
    return "Stay focused"
  }

  private var remainingText: String {
    guard entry.state.remainingSeconds > 0 else {
      return ""
    }
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute, .second]
    formatter.unitsStyle = .abbreviated
    return formatter.string(from: TimeInterval(entry.state.remainingSeconds)) ?? ""
  }
}

struct FocusLiveActivityWidget: Widget {
  let kind: String = FocusWidgetStorage.widgetKind

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: FocusTimerProvider()) { entry in
      FocusLiveActivityWidgetView(entry: entry)
    }
    .configurationDisplayName("Focus Quick Launch")
    .description("Start or resume your focus routine.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
