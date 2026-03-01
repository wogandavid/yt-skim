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
    self.statusItem = NSStatusBar.system.statusItem(withLength: 34)
    super.init()
    configureStatusItem()
    configurePopover()
    configureMenu()
    model.onShowPopover = { [weak self] in
      self?.showPopover()
    }
  }

  func showPopover() {
    guard let button = statusItem.button else { return }
    if popover.isShown {
      return
    }
    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    NSApp.activate(ignoringOtherApps: true)
  }

  func closePopover() {
    popover.performClose(nil)
  }

  private func configureStatusItem() {
    guard let button = statusItem.button else { return }
    statusItem.isVisible = true
    button.image = nil
    button.title = "YT"
    button.toolTip = "YT Skim"
    button.action = #selector(onStatusButtonClick)
    button.target = self
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

  @objc private func onStatusButtonClick() {
    statusItem.menu = menu
    statusItem.button?.performClick(nil)
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
      item.state = (mode == model.summaryMode) ? .on : .off
      modeMenu.addItem(item)
    }
    modeItem.submenu = modeMenu
    menu.addItem(modeItem)

    let replaceClipboardItem = NSMenuItem(title: "Replace Clipboard", action: #selector(toggleReplaceClipboard), keyEquivalent: "")
    replaceClipboardItem.target = self
    replaceClipboardItem.state = model.replaceClipboard ? .on : .off
    menu.addItem(replaceClipboardItem)

    let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
    launchAtLoginItem.target = self
    launchAtLoginItem.state = model.launchAtLogin ? .on : .off
    menu.addItem(launchAtLoginItem)

    let hotkeyItem = NSMenuItem(title: "Configure Hotkey…", action: #selector(openSettings), keyEquivalent: "")
    hotkeyItem.target = self
    menu.addItem(hotkeyItem)

    let openLastItem = NSMenuItem(title: "Open Last Summary", action: #selector(openLastSummary), keyEquivalent: "")
    openLastItem.target = self
    menu.addItem(openLastItem)

    let checklistItem = NSMenuItem(title: "First-Run Check", action: #selector(openChecklist), keyEquivalent: "")
    checklistItem.target = self
    menu.addItem(checklistItem)

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

  @objc private func openLastSummary() {
    model.openLastSummary()
  }

  @objc private func openChecklist() {
    model.openChecklist()
  }

  @objc private func openSettings() {
    model.openSettings()
  }

  @objc private func quitApp() {
    NSApp.terminate(nil)
  }
}
