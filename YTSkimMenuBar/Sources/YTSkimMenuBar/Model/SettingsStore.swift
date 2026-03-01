import Foundation
import LaunchAtLogin

final class SettingsStore {
  private let defaults: UserDefaults

  private enum Key {
    static let summaryMode = "summaryMode"
    static let replaceClipboard = "replaceClipboard"
    static let launchAtLogin = "launchAtLogin"
  }

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    defaults.register(defaults: [
      Key.summaryMode: SummaryMode.standard.rawValue,
      Key.replaceClipboard: true,
      Key.launchAtLogin: false
    ])
    let launchEnabled = defaults.bool(forKey: Key.launchAtLogin)
    LaunchAtLogin.isEnabled = launchEnabled
  }

  var summaryMode: SummaryMode {
    get {
      let raw = defaults.string(forKey: Key.summaryMode) ?? SummaryMode.standard.rawValue
      return SummaryMode(rawValue: raw) ?? .standard
    }
    set {
      defaults.set(newValue.rawValue, forKey: Key.summaryMode)
    }
  }

  var replaceClipboard: Bool {
    get {
      defaults.bool(forKey: Key.replaceClipboard)
    }
    set {
      defaults.set(newValue, forKey: Key.replaceClipboard)
    }
  }

  var launchAtLogin: Bool {
    get {
      defaults.bool(forKey: Key.launchAtLogin)
    }
    set {
      defaults.set(newValue, forKey: Key.launchAtLogin)
      LaunchAtLogin.isEnabled = newValue
    }
  }
}

