import BackgroundTasks
import Flutter
import UIKit
import flutter_foreground_task
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private static let timerRefreshIdentifier = "com.ymcompany.lifeapp.timer-refresh"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    SwiftFlutterForegroundTaskPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    if #available(iOS 13.0, *) {
      registerBackgroundTasks()
      scheduleTimerRefresh()
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidEnterBackground(_ application: UIApplication) {
    super.applicationDidEnterBackground(application)
    if #available(iOS 13.0, *) {
      scheduleTimerRefresh()
    }
  }

  @available(iOS 13.0, *)
  private func registerBackgroundTasks() {
    BGTaskScheduler.shared.register(forTaskWithIdentifier: AppDelegate.timerRefreshIdentifier, using: nil) { task in
      guard let refreshTask = task as? BGAppRefreshTask else {
        task.setTaskCompleted(success: false)
        return
      }
      self.handleTimerRefresh(task: refreshTask)
    }
  }

  @available(iOS 13.0, *)
  private func scheduleTimerRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: AppDelegate.timerRefreshIdentifier)
    request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
    do {
      try BGTaskScheduler.shared.submit(request)
    } catch {
      debugPrint("Failed to schedule BG refresh: \(error)")
    }
  }

  @available(iOS 13.0, *)
  private func handleTimerRefresh(task: BGAppRefreshTask) {
    scheduleTimerRefresh()

    task.expirationHandler = {
      task.setTaskCompleted(success: false)
    }

    DispatchQueue.global(qos: .background).async {
      // For now we just mark success; timer notifications are handled in Dart via local notifications.
      task.setTaskCompleted(success: true)
    }
  }
}
