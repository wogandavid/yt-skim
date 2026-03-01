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

    let codexBundlePath = "/Applications/Codex.app/Contents/Resources/codex"
    let codexInPath = await commandExists("codex")
    let codexExists = codexInPath || FileManager.default.isExecutableFile(atPath: codexBundlePath)
    items.append(CheckItem(
      title: "Codex binary availability",
      status: codexExists ? .pass : .fail,
      details: codexExists ? "Found codex binary in PATH or app bundle location." : "Could not find codex binary.",
      remediation: codexExists ? "No action needed." : "Install Codex app/CLI and ensure binary is available."
    ))

    if codexExists {
      let auth = await codexAuthStatus(codexInPath: codexInPath, codexBundlePath: codexBundlePath)
      items.append(CheckItem(
        title: "Codex login status",
        status: auth.ok ? .pass : .fail,
        details: auth.details,
        remediation: auth.ok
          ? "No action needed."
          : "Run `codex login` in Terminal, then re-run First-Run Check."
      ))
    }

    let birdExists = await commandExists("bird")
    items.append(CheckItem(
      title: "`bird` availability (optional for X)",
      status: birdExists ? .pass : .info,
      details: birdExists
        ? "Command `bird` is available. X link fetch reliability is improved."
        : "Command `bird` not found. Some X posts may fail to summarize.",
      remediation: birdExists
        ? "No action needed."
        : "Optional: install bird for better X support: https://github.com/steipete/bird"
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

  private func codexAuthStatus(codexInPath: Bool, codexBundlePath: String) async -> (ok: Bool, details: String) {
    let command: String
    if codexInPath {
      command = "codex login status 2>&1"
    } else {
      command = "\"\(codexBundlePath)\" login status 2>&1"
    }

    let result = runShell(command)
    let output = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
    let lower = output.lowercased()
    let isLoggedIn = result.status == 0 && lower.contains("logged in")

    if isLoggedIn {
      return (true, output.isEmpty ? "Logged in to Codex CLI." : output)
    }
    if output.isEmpty {
      return (false, "Unable to confirm Codex authentication state.")
    }
    return (false, output)
  }

  private func runShell(_ command: String) -> (status: Int32, output: String) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/zsh")
    process.arguments = ["-lc", command]

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe

    do {
      try process.run()
      process.waitUntilExit()
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      let text = String(data: data, encoding: .utf8) ?? ""
      return (process.terminationStatus, text)
    } catch {
      return (1, "Failed to execute command: \(command)")
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
