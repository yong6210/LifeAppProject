import Foundation

struct FocusWidgetSharedState: Codable {
  let mode: String
  let segmentTitle: String
  let remainingSeconds: Int
  let totalSeconds: Int
  let isPaused: Bool
  let upNextSegment: String?

  static func placeholder() -> FocusWidgetSharedState {
    return FocusWidgetSharedState(
      mode: "focus",
      segmentTitle: "Ready to focus",
      remainingSeconds: 0,
      totalSeconds: 0,
      isPaused: false,
      upNextSegment: nil
    )
  }
}

enum FocusWidgetStorage {
  static let appGroupIdentifier = "group.com.ymcompany.lifeapp"
  static let widgetKind = "FocusLiveActivityWidget"
  private static let storageKey = "focus_widget_state_v1"

  static func save(_ state: FocusWidgetSharedState?) {
    guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
    if let state = state {
      if let data = try? JSONEncoder().encode(state) {
        defaults.set(data, forKey: storageKey)
      }
    } else {
      defaults.removeObject(forKey: storageKey)
    }
    defaults.synchronize()
  }

  static func load() -> FocusWidgetSharedState? {
    guard
      let defaults = UserDefaults(suiteName: appGroupIdentifier),
      let data = defaults.data(forKey: storageKey)
    else {
      return nil
    }
    return try? JSONDecoder().decode(FocusWidgetSharedState.self, from: data)
  }

  static func clear() {
    guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
    defaults.removeObject(forKey: storageKey)
    defaults.synchronize()
  }
}
