import SwiftUI

@main
struct YTSkimMenuBarApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @StateObject private var model = AppModel.shared

  var body: some Scene {
    MenuBarExtra("YT") {
      MenuBarRootView(model: model)
    }
    .menuBarExtraStyle(.menu)

    Settings {
      SettingsView(model: model, dismiss: {})
        .frame(width: 420, height: 320)
    }
  }
}
