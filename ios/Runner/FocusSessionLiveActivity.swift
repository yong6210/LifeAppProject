import ActivityKit

@available(iOS 16.1, *)
struct FocusSessionAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var mode: String
    var segmentTitle: String
    var remainingSeconds: Int
    var totalSeconds: Int
    var isPaused: Bool
    var upcomingSegment: String?
  }

  var sessionId: String
}
