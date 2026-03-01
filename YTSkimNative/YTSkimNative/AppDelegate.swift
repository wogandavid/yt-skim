import AppKit
import KeyboardShortcuts

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private let model = AppModel()
  private var statusBarController: StatusBarController?

  func applicationDidFinishLaunching(_ notification: Notification) {
    applyActivationPolicy(showDockIcon: model.showDockIconDebug)

    let controller = StatusBarController(model: model)
    controller.showStatusItem()
    statusBarController = controller

    model.onShowPopover = { [weak self] in
      self?.statusBarController?.showPopover()
    }
    model.onDockModeChanged = { [weak self] showDockIcon in
      self?.applyActivationPolicy(showDockIcon: showDockIcon)
    }

    KeyboardShortcuts.onKeyUp(for: .summarizeClipboard) { [weak self] in
      self?.model.summarizeClipboard()
    }
  }

  private func applyActivationPolicy(showDockIcon: Bool) {
    NSApp.setActivationPolicy(showDockIcon ? .regular : .accessory)
    if showDockIcon {
      NSApp.activate(ignoringOtherApps: true)
    }
  }
}
