import AppKit
import Foundation

@MainActor
final class AppModel: ObservableObject {
  @Published var panel: ActivePanel = .result
  @Published var summary: SummaryPresentation = SummaryPresentation(
    status: .failure,
    headline: "No summary yet",
    host: "YT Skim",
    body: "Run \"Summarize Clipboard\" from the menu or hotkey.",
    details: ""
  )
  @Published var isBusy = false
  @Published var checks: [CheckItem] = []

  @Published var summaryMode: SummaryMode {
    didSet { settings.summaryMode = summaryMode }
  }

  @Published var replaceClipboard: Bool {
    didSet { settings.replaceClipboard = replaceClipboard }
  }

  @Published var launchAtLogin: Bool {
    didSet { settings.launchAtLogin = launchAtLogin }
  }

  @Published var showDockIconDebug: Bool {
    didSet {
      settings.showDockIconDebug = showDockIconDebug
      onDockModeChanged?(showDockIconDebug)
    }
  }

  private let runner: ScriptRunner
  private let checker: FirstRunChecker
  private let settings: SettingsStore

  var onShowPopover: (() -> Void)?
  var onDockModeChanged: ((Bool) -> Void)?

  init(
    runner: ScriptRunner = ScriptRunner(),
    settings: SettingsStore = SettingsStore()
  ) {
    self.runner = runner
    self.settings = settings
    self.checker = FirstRunChecker(runner: runner)
    self.summaryMode = settings.summaryMode
    self.replaceClipboard = settings.replaceClipboard
    self.launchAtLogin = settings.launchAtLogin
    self.showDockIconDebug = settings.showDockIconDebug
  }

  func summarizeClipboard() {
    guard !isBusy else { return }
    panel = .result
    isBusy = true
    summary = SummaryPresentation(
      status: .running,
      headline: "Summarizing...",
      host: "Link",
      body: "Working on your clipboard URL.",
      details: ""
    )
    onShowPopover?()

    Task {
      defer { isBusy = false }

      guard let clipboard = NSPasteboard.general.string(forType: .string) else {
        setFailure(
          host: "Clipboard",
          message: "Couldn't summarize. Not a YouTube link.",
          details: "Clipboard does not contain text."
        )
        return
      }
      let candidate = extractFirstURL(from: clipboard) ?? clipboard
      let trimmed = sanitizeClipboard(candidate)
      guard let rawURL = URL(string: trimmed) else {
        setFailure(
          host: "Clipboard",
          message: "Couldn't summarize. Only YouTube and X links are supported.",
          details: "Clipboard content is not a valid URL: \(candidate)"
        )
        return
      }

      guard let source = detectSupportedSource(rawURL) else {
        setFailure(
          host: "Clipboard",
          message: "Couldn't summarize. Only YouTube and X links are supported.",
          details: "Supported links: YouTube videos and X post URLs. Received: \(rawURL.absoluteString)"
        )
        return
      }

      let url = normalizeURL(rawURL, source: source)
      let sourceHost = source.displayName

      let response = await runner.summarize(url: url, mode: summaryMode)
      if response.ok, let summaryText = response.summary, !summaryText.isEmpty {
        if replaceClipboard {
          NSPasteboard.general.clearContents()
          NSPasteboard.general.setString(summaryText, forType: .string)
        }
        summary = SummaryPresentation(
          status: .success,
          headline: "Summary ready",
          host: sourceHost,
          body: summaryText,
          details: ""
        )
      } else {
        let defaultMessage = "Couldn't summarize. Maybe the content saved you some time."
        let message = response.message ?? defaultMessage
        summary = SummaryPresentation(
          status: .failure,
          headline: message,
          host: sourceHost,
          body: "",
          details: response.details ?? ""
        )
      }
      onShowPopover?()
    }
  }

  func openLastSummary() {
    panel = .result
    let summaryPath = "/tmp/yt-skim-last-summary.txt"
    guard let text = try? String(contentsOfFile: summaryPath, encoding: .utf8), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      summary = SummaryPresentation(
        status: .failure,
        headline: "No recent summary found",
        host: "YT Skim",
        body: "",
        details: "No summary exists at \(summaryPath)."
      )
      onShowPopover?()
      return
    }
    summary = SummaryPresentation(
      status: .success,
      headline: "Last summary",
      host: "YT Skim",
      body: text,
      details: ""
    )
    onShowPopover?()
  }

  func openChecklist() {
    panel = .checklist
    checks = []
    onShowPopover?()
    Task {
      checks = await checker.runChecks()
      onShowPopover?()
    }
  }

  func openSettings() {
    panel = .settings
    onShowPopover?()
  }

  private func setFailure(host: String, message: String, details: String) {
    summary = SummaryPresentation(
      status: .failure,
      headline: message,
      host: host,
      body: "",
      details: details
    )
    onShowPopover?()
  }

  private func sanitizeClipboard(_ value: String) -> String {
    value
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .trimmingCharacters(in: CharacterSet(charactersIn: "<>()\"'"))
      .trimmingCharacters(in: CharacterSet(charactersIn: ",.;:!?"))
  }

  private func extractFirstURL(from value: String) -> String? {
    guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
      return nil
    }
    let range = NSRange(value.startIndex..<value.endIndex, in: value)
    guard let match = detector.firstMatch(in: value, options: [], range: range) else {
      return nil
    }
    return match.url?.absoluteString
  }

  private func normalizeURL(_ url: URL, source: SupportedSource) -> URL {
    guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      return url
    }

    let host = components.host?.lowercased() ?? ""
    switch source {
    case .youtube:
      if host == "m.youtube.com" {
        components.host = "www.youtube.com"
      }

      let path = components.path.lowercased()
      if path == "/watch", let items = components.queryItems {
        let keep = Set(["v", "t", "si"])
        components.queryItems = items.filter { keep.contains($0.name.lowercased()) }
        if components.queryItems?.isEmpty == true {
          components.queryItems = nil
        }
      } else if host == "youtu.be", let items = components.queryItems {
        let keep = Set(["t", "si"])
        components.queryItems = items.filter { keep.contains($0.name.lowercased()) }
        if components.queryItems?.isEmpty == true {
          components.queryItems = nil
        }
      }
    case .x:
      if host == "twitter.com" || host == "www.twitter.com" || host == "www.x.com" {
        components.host = "x.com"
      }

      if let items = components.queryItems {
        let trackingKeys = Set(["s", "t", "ref_src", "ref_url", "cxt", "cn", "mx"])
        components.queryItems = items.filter { item in
          let key = item.name.lowercased()
          if trackingKeys.contains(key) { return false }
          if key.hasPrefix("utm_") { return false }
          return true
        }
        if components.queryItems?.isEmpty == true {
          components.queryItems = nil
        }
      }
      components.fragment = nil
    }

    return components.url ?? url
  }

  private func detectSupportedSource(_ url: URL) -> SupportedSource? {
    guard let host = url.host?.lowercased() else { return nil }
    let path = url.path.lowercased()

    if host == "youtube.com"
      || host == "www.youtube.com"
      || host.hasSuffix(".youtube.com")
      || host == "youtu.be"
      || host.hasSuffix(".youtu.be") {
      return .youtube
    }

    if host == "x.com"
      || host == "www.x.com"
      || host == "twitter.com"
      || host == "www.twitter.com" {
      if isXStatusPath(path) {
        return .x
      }
    }

    return nil
  }

  private func isXStatusPath(_ path: String) -> Bool {
    func isNumeric(_ value: String) -> Bool {
      !value.isEmpty && value.allSatisfy(\.isNumber)
    }

    if path.hasPrefix("/i/web/status/") {
      let tail = path.replacingOccurrences(of: "/i/web/status/", with: "")
      let id = tail.split(separator: "/").first.map(String.init) ?? ""
      return isNumeric(id)
    }

    guard let range = path.range(of: "/status/") else { return false }
    let tail = path[range.upperBound...]
    let id = tail.split(separator: "/").first.map(String.init) ?? ""
    return isNumeric(id)
  }

  private enum SupportedSource {
    case youtube
    case x

    var displayName: String {
      switch self {
      case .youtube:
        return "YouTube"
      case .x:
        return "X"
      }
    }
  }
}
