import Foundation

enum ScriptRunnerError: Error {
  case missingScript
  case invalidJSON(String)
}

final class ScriptRunner: @unchecked Sendable {
  private let scriptName = "yt-skim"

  func summarize(url: URL, mode: SummaryMode) async -> ScriptResponse {
    do {
      let output = try await runScript(args: [
        "--app-mode",
        "--json",
        "--input-url", url.absoluteString,
        "--mode", mode.rawValue,
        "--keep-clipboard"
      ])
      if let response = decodeResponse(output.stdout, fallbackDetails: output.stderr, exitCode: Int(output.exitCode)) {
        return response
      }
      return ScriptResponse(
        ok: false,
        summary: nil,
        mode: nil,
        source: nil,
        errorCode: "BACKEND_FAIL",
        message: "Couldn't summarize. Maybe the video saved you some time.",
        details: output.stderr.isEmpty ? output.stdout : output.stderr,
        exitCode: Int(output.exitCode)
      )
    } catch {
      return ScriptResponse(
        ok: false,
        summary: nil,
        mode: nil,
        source: nil,
        errorCode: "BACKEND_FAIL",
        message: "Couldn't summarize. Maybe the video saved you some time.",
        details: String(describing: error),
        exitCode: 4
      )
    }
  }

  func dryRunSchemaCheck() async -> CheckItem {
    do {
      let output = try await runScript(args: [
        "--app-mode",
        "--json",
        "--input-url", "https://example.com"
      ])
      guard let response = decodeResponse(output.stdout, fallbackDetails: output.stderr, exitCode: Int(output.exitCode)) else {
        return CheckItem(
          title: "Engine JSON contract",
          status: .fail,
          details: "Script output did not parse as JSON.",
          remediation: "Ensure bundled yt-skim.sh is up to date and returns JSON in --app-mode --json."
        )
      }
      if response.ok == false && response.errorCode == "INVALID_URL" {
        return CheckItem(
          title: "Engine JSON contract",
          status: .pass,
          details: "Script returned structured JSON in dry run.",
          remediation: "No action needed."
        )
      }
      return CheckItem(
        title: "Engine JSON contract",
        status: .fail,
        details: "Unexpected dry-run response: \(response.errorCode ?? "none").",
        remediation: "Check script flags and JSON mapping in ScriptResponse."
      )
    } catch {
      return CheckItem(
        title: "Engine JSON contract",
        status: .fail,
        details: "Failed to execute script: \(error)",
        remediation: "Verify bundled script permissions and shell path."
      )
    }
  }

  func bundledScriptURL() -> URL? {
    if let direct = Bundle.main.url(forResource: scriptName, withExtension: "sh") {
      return direct
    }
    return Bundle.main.url(forResource: scriptName, withExtension: "sh", subdirectory: "Resources")
  }

  private func decodeResponse(_ stdout: String, fallbackDetails: String, exitCode: Int) -> ScriptResponse? {
    let trimmed = stdout
      .split(separator: "\n")
      .map { String($0) }
      .last(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) ?? ""
    guard !trimmed.isEmpty else { return nil }
    guard let data = trimmed.data(using: .utf8) else { return nil }

    do {
      return try JSONDecoder().decode(ScriptResponse.self, from: data)
    } catch {
      if exitCode == 0 { return nil }
      return ScriptResponse(
        ok: false,
        summary: nil,
        mode: nil,
        source: nil,
        errorCode: "BACKEND_FAIL",
        message: "Couldn't summarize. Maybe the video saved you some time.",
        details: fallbackDetails.isEmpty ? stdout : fallbackDetails,
        exitCode: exitCode
      )
    }
  }

  private func runScript(args: [String]) async throws -> (stdout: String, stderr: String, exitCode: Int32) {
    guard let scriptURL = bundledScriptURL() else {
      throw ScriptRunnerError.missingScript
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/bash")
    process.arguments = [scriptURL.path] + args

    var env = ProcessInfo.processInfo.environment
    env["PATH"] = buildRuntimePath(existingPath: env["PATH"] ?? "")
    process.environment = env

    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe

    try process.run()
    process.waitUntilExit()

    let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
    let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
    let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
    let stderr = String(data: stderrData, encoding: .utf8) ?? ""
    return (stdout, stderr, process.terminationStatus)
  }

  private func buildRuntimePath(existingPath: String) -> String {
    var entries: [String] = []
    var seen = Set<String>()

    func add(_ path: String) {
      guard !path.isEmpty, !seen.contains(path) else { return }
      seen.insert(path)
      entries.append(path)
    }

    let home = NSHomeDirectory()
    let defaults = [
      "/opt/homebrew/bin",
      "/opt/homebrew/sbin",
      "/usr/local/bin",
      "/usr/local/sbin",
      "/usr/bin",
      "/bin",
      "/usr/sbin",
      "/sbin",
      "/Applications/Codex.app/Contents/Resources",
      "\(home)/.local/bin",
      "\(home)/bin",
      "\(home)/.npm-global/bin",
      "\(home)/.volta/bin",
      "\(home)/.asdf/shims"
    ]

    defaults.forEach(add)
    nvmNodeBinPaths(home: home).forEach(add)
    existingPath.split(separator: ":").map(String.init).forEach(add)
    return entries.joined(separator: ":")
  }

  private func nvmNodeBinPaths(home: String) -> [String] {
    let root = URL(fileURLWithPath: "\(home)/.nvm/versions/node", isDirectory: true)
    guard let versions = try? FileManager.default.contentsOfDirectory(
      at: root,
      includingPropertiesForKeys: [.isDirectoryKey],
      options: [.skipsHiddenFiles]
    ) else {
      return []
    }

    return versions
      .map { $0.appendingPathComponent("bin") }
      .filter { FileManager.default.isExecutableFile(atPath: $0.path) }
      .map(\.path)
      .sorted(by: >)
  }
}
