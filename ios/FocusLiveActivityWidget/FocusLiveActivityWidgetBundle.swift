import WidgetKit

@main
struct FocusLiveActivityWidgetBundle: WidgetBundle {
  var body: some Widget {
    FocusLiveActivityWidget()
    if #available(iOSApplicationExtension 16.1, *) {
      FocusLiveActivityWidgetLiveActivity()
    }
  }
}
