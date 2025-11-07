import ActivityKit

@available(iOSApplicationExtension 16.1, *)
struct FocusSessionAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var mode: String
    var segmentTitle: String
    var remainingSeconds: Int
    var totalSeconds: Int
    var isPaused: Bool
    var upcomingSegment: String?

    var progress: Double {
      guard totalSeconds > 0 else { return 0 }
      let completed = totalSeconds - max(remainingSeconds, 0)
      return Double(completed) / Double(totalSeconds)
    }
  }

  var sessionId: String
}
