import ActivityKit
import SwiftUI
import WidgetKit

@available(iOSApplicationExtension 16.1, *)
struct FocusLiveActivityWidgetLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: FocusSessionAttributes.self) { context in
      FocusLiveActivityContentView(context: context)
        .activityBackgroundTint(.black.opacity(0.15))
        .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          FocusLiveActivityLeadingView(context: context)
        }
        DynamicIslandExpandedRegion(.center) {
          FocusLiveActivityCenterView(context: context)
        }
        DynamicIslandExpandedRegion(.trailing) {
          FocusLiveActivityTrailingView(context: context)
        }
        DynamicIslandExpandedRegion(.bottom) {
          FocusLiveActivityBottomView(context: context)
        }
      } compactLeading: {
        Self.icon(for: context.state.mode)
          .foregroundStyle(.white)
      } compactTrailing: {
        Text(context.state.remainingSeconds.formatted(.unitsAllowed(in: [.minute, .second])))
          .font(.caption2)
          .monospacedDigit()
          .foregroundStyle(.white)
      } minimal: {
        Self.icon(for: context.state.mode)
          .foregroundStyle(.white)
      }
      .keylineTint(.white)
    }
  }

  static func icon(for mode: String) -> Image {
    switch mode {
    case "rest":
      return Image(systemName: "leaf")
    case "sleep":
      return Image(systemName: "moon.zzz")
    case "workout":
      return Image(systemName: "figure.run")
    default:
      return Image(systemName: "bolt")
    }
  }
}

@available(iOSApplicationExtension 16.1, *)
private struct FocusLiveActivityContentView: View {
  let context: ActivityViewContext<FocusSessionAttributes>

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 8) {
        modeIcon
        VStack(alignment: .leading, spacing: 2) {
          Text(titleText)
            .font(.headline)
          if let upcoming = context.state.upcomingSegment {
            Text("Up next: \(upcoming)")
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
        }
        Spacer()
      }
      ProgressView(value: context.state.progress)
        .progressViewStyle(.linear)
      Text(remainingDescription)
        .font(.title3.monospacedDigit())
        .bold()
    }
    .padding()
  }

  private var modeIcon: some View {
      FocusLiveActivityWidgetLiveActivity.icon(for: context.state.mode)
      .font(.title2)
  }

  private var titleText: String {
    if context.state.isPaused {
      return "Paused · \(context.state.segmentTitle)"
    }
    return "\(context.state.segmentTitle)"
  }

  private var remainingDescription: String {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute, .second]
    formatter.unitsStyle = .short
    return formatter.string(from: TimeInterval(context.state.remainingSeconds)) ?? ""
  }
}

@available(iOSApplicationExtension 16.1, *)
private struct FocusLiveActivityLeadingView: View {
  let context: ActivityViewContext<FocusSessionAttributes>

  var body: some View {
    FocusLiveActivityWidgetLiveActivity.icon(for: context.state.mode)
      .foregroundStyle(.white)
  }
}

@available(iOSApplicationExtension 16.1, *)
private struct FocusLiveActivityCenterView: View {
  let context: ActivityViewContext<FocusSessionAttributes>

  var body: some View {
    VStack(alignment: .leading) {
      Text(context.state.segmentTitle)
        .font(.headline)
      if let upcoming = context.state.upcomingSegment {
        Text("Next: \(upcoming)")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

@available(iOSApplicationExtension 16.1, *)
private struct FocusLiveActivityTrailingView: View {
  let context: ActivityViewContext<FocusSessionAttributes>

  var body: some View {
    Text(formattedCountdown(context.state.remainingSeconds))
    .font(.headline.monospacedDigit())
  }
}

@available(iOSApplicationExtension 16.1, *)
private struct FocusLiveActivityBottomView: View {
  let context: ActivityViewContext<FocusSessionAttributes>

  var body: some View {
    ProgressView(value: context.state.progress)
      .progressViewStyle(.linear)
  }
}

@available(iOSApplicationExtension 16.1, *)
private func formattedCountdown(_ seconds: Int) -> String {
  let formatter = DateComponentsFormatter()
  formatter.allowedUnits = [.minute, .second]
  formatter.unitsStyle = .short
  return formatter.string(from: TimeInterval(seconds)) ?? ""
}
