import AppKit
import KeyboardShortcuts

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private let model = AppModel.shared

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.regular)
    NSApp.activate(ignoringOtherApps: true)

    KeyboardShortcuts.onKeyUp(for: .summarizeClipboard) { [weak self] in
      self?.model.summarizeClipboard()
    }
  }
}
