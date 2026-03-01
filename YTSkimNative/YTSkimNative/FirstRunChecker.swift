import Foundation
import UserNotifications

final class FirstRunChecker: @unchecked Sendable {
  private let runner: ScriptRunner

  init(runner: ScriptRunner) {
    self.runner = runner
  }

  func runChecks() async -> [CheckItem] {
    var items: [CheckItem] = []

    if let scriptURL = runner.bundledScriptURL(), FileManager.default.isReadableFile(atPath: scriptURL.path), FileManager.default.isExecutableFile(atPath: scriptURL.path) {
      items.append(CheckItem(
        title: "Bundled script",
        status: .pass,
        details: "Found executable bundled yt-skim.sh at \(scriptURL.path).",
        remediation: "No action needed."
      ))
    } else {
      items.append(CheckItem(
        title: "Bundled script",
        status: .fail,
        details: "Bundled yt-skim.sh is missing or not executable in app resources.",
        remediation: "Rebuild the app and confirm Resources/yt-skim.sh is included with executable permissions."
      ))
    }

    let summarizeExists = await commandExists("summarize")
    items.append(CheckItem(
      title: "`summarize` availability",
      status: summarizeExists ? .pass : .fail,
      details: summarizeExists ? "Command `summarize` is available." : "Command `summarize` not found in PATH.",
      remediation: summarizeExists ? "No action needed." : "Install summarize and ensure PATH includes its install location."
    ))

    let codexExists = await commandExists("codex") || FileManager.default.isExecutableFile(atPath: "/Applications/Codex.app/Contents/Resources/codex")
    items.append(CheckItem(
      title: "Codex binary availability",
      status: codexExists ? .pass : .fail,
      details: codexExists ? "Found codex binary in PATH or app bundle location." : "Could not find codex binary.",
      remediation: codexExists ? "No action needed." : "Install Codex app/CLI and ensure binary is available."
    ))

    items.append(await runner.dryRunSchemaCheck())
    items.append(await notificationStatusCheck())
    return items
  }

  private func commandExists(_ command: String) async -> Bool {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/zsh")
    process.arguments = ["-lc", "command -v \(command) >/dev/null 2>&1"]
    do {
      try process.run()
      process.waitUntilExit()
      return process.terminationStatus == 0
    } catch {
      return false
    }
  }

  private func notificationStatusCheck() async -> CheckItem {
    let status = await withCheckedContinuation { continuation in
      UNUserNotificationCenter.current().getNotificationSettings { settings in
        continuation.resume(returning: settings.authorizationStatus)
      }
    }

    switch status {
    case .authorized, .provisional, .ephemeral:
      return CheckItem(
        title: "Notification permission",
        status: .info,
        details: "Notifications are enabled.",
        remediation: "No action needed."
      )
    case .denied:
      return CheckItem(
        title: "Notification permission",
        status: .info,
        details: "Notifications are denied.",
        remediation: "Optional: enable notifications in System Settings -> Notifications."
      )
    case .notDetermined:
      return CheckItem(
        title: "Notification permission",
        status: .info,
        details: "Notification permission has not been requested yet.",
        remediation: "Optional: trigger a notification path to request permission."
      )
    @unknown default:
      return CheckItem(
        title: "Notification permission",
        status: .info,
        details: "Notification authorization status is unknown.",
        remediation: "No action needed unless notifications fail."
      )
    }
  }
}
