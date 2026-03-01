import AppKit
import SwiftUI

@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
  private let model: AppModel
  private let statusItem: NSStatusItem
  private let menu = NSMenu()
  private let popover = NSPopover()

  init(model: AppModel) {
    self.model = model
    self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    super.init()
    configureStatusItem(attempt: 0)
    configurePopover()
    configureMenu()
  }

  func showStatusItem() {
    statusItem.isVisible = true
  }

  func showPopover() {
    guard let button = statusItem.button else { return }
    if popover.isShown {
      clampPopoverToVisibleScreen(anchorButton: button)
      return
    }
    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
    clampPopoverToVisibleScreen(anchorButton: button)
    NSApp.activate(ignoringOtherApps: true)
  }

  func closePopover() {
    popover.performClose(nil)
  }

  private func clampPopoverToVisibleScreen(anchorButton: NSStatusBarButton) {
    guard
      let window = popover.contentViewController?.view.window,
      let screen = anchorButton.window?.screen ?? NSScreen.main
    else {
      return
    }

    var frame = window.frame
    let visible = screen.visibleFrame.insetBy(dx: 6, dy: 6)

    if frame.maxY > visible.maxY {
      frame.origin.y = visible.maxY - frame.height
    }
    if frame.minY < visible.minY {
      frame.origin.y = visible.minY
    }
    if frame.maxX > visible.maxX {
      frame.origin.x = visible.maxX - frame.width
    }
    if frame.minX < visible.minX {
      frame.origin.x = visible.minX
    }

    if frame != window.frame {
      window.setFrame(frame, display: true)
    }
  }

  private func configureStatusItem(attempt: Int) {
    guard let button = statusItem.button else {
      if attempt < 20 {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
          self?.configureStatusItem(attempt: attempt + 1)
        }
      }
      return
    }
    if let image = NSImage(systemSymbolName: "sparkles.rectangle.stack", accessibilityDescription: "YT Skim") {
      image.isTemplate = true
      button.image = image
      button.imagePosition = .imageOnly
      button.title = ""
    } else {
      button.image = nil
      button.title = "YT"
    }
    button.toolTip = "YT Skim"
    button.target = nil
    button.action = nil
    statusItem.length = NSStatusItem.variableLength
  }

  private func configurePopover() {
    popover.behavior = .transient
    let root = PopoverContainerView(model: model) { [weak self] in
      self?.closePopover()
    }
    popover.contentViewController = NSHostingController(rootView: root)
  }

  private func configureMenu() {
    menu.delegate = self
    statusItem.menu = menu
    rebuildMenu()
  }

  func menuWillOpen(_ menu: NSMenu) {
    rebuildMenu()
  }

  private func rebuildMenu() {
    menu.removeAllItems()

    let summarizeItem = NSMenuItem(title: "Summarize Clipboard", action: #selector(summarizeClipboard), keyEquivalent: "")
    summarizeItem.target = self
    menu.addItem(summarizeItem)

    let modeItem = NSMenuItem(title: "Mode", action: nil, keyEquivalent: "")
    let modeMenu = NSMenu()
    for mode in SummaryMode.allCases {
      let item = NSMenuItem(title: mode.displayName, action: #selector(selectMode(_:)), keyEquivalent: "")
      item.target = self
      item.representedObject = mode.rawValue
      item.state = mode == model.summaryMode ? .on : .off
      modeMenu.addItem(item)
    }
    modeItem.submenu = modeMenu
    menu.addItem(modeItem)

    let replaceItem = NSMenuItem(title: "Replace Clipboard", action: #selector(toggleReplaceClipboard), keyEquivalent: "")
    replaceItem.target = self
    replaceItem.state = model.replaceClipboard ? .on : .off
    menu.addItem(replaceItem)

    let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
    loginItem.target = self
    loginItem.state = model.launchAtLogin ? .on : .off
    menu.addItem(loginItem)

    let dockItem = NSMenuItem(title: "Show Dock Icon (Debug)", action: #selector(toggleShowDockIcon), keyEquivalent: "")
    dockItem.target = self
    dockItem.state = model.showDockIconDebug ? .on : .off
    menu.addItem(dockItem)

    let settingsItem = NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ",")
    settingsItem.target = self
    menu.addItem(settingsItem)

    let lastSummaryItem = NSMenuItem(title: "Open Last Summary", action: #selector(openLastSummary), keyEquivalent: "")
    lastSummaryItem.target = self
    menu.addItem(lastSummaryItem)

    let checksItem = NSMenuItem(title: "First-Run Check", action: #selector(openChecklist), keyEquivalent: "")
    checksItem.target = self
    menu.addItem(checksItem)

    menu.addItem(.separator())

    let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
    quitItem.target = self
    menu.addItem(quitItem)
  }

  @objc private func summarizeClipboard() {
    model.summarizeClipboard()
  }

  @objc private func selectMode(_ sender: NSMenuItem) {
    guard
      let raw = sender.representedObject as? String,
      let mode = SummaryMode(rawValue: raw)
    else {
      return
    }
    model.summaryMode = mode
    rebuildMenu()
  }

  @objc private func toggleReplaceClipboard() {
    model.replaceClipboard.toggle()
    rebuildMenu()
  }

  @objc private func toggleLaunchAtLogin() {
    model.launchAtLogin.toggle()
    rebuildMenu()
  }

  @objc private func toggleShowDockIcon() {
    model.showDockIconDebug.toggle()
    rebuildMenu()
  }

  @objc private func openSettings() {
    model.openSettings()
  }

  @objc private func openLastSummary() {
    model.openLastSummary()
  }

  @objc private func openChecklist() {
    model.openChecklist()
  }

  @objc private func quitApp() {
    NSApp.terminate(nil)
  }
}
