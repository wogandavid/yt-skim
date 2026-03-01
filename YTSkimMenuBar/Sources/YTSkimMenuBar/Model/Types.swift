import Foundation

enum SummaryMode: String, CaseIterable {
  case short
  case standard
  case structured

  var displayName: String {
    switch self {
    case .short:
      return "Short"
    case .standard:
      return "Standard"
    case .structured:
      return "Structured"
    }
  }
}

enum ActivePanel {
  case result
  case checklist
  case settings
}

enum SummaryStatus: Equatable {
  case success
  case failure
  case running
}

struct SummaryPresentation {
  let status: SummaryStatus
  let headline: String
  let host: String
  let body: String
  let details: String
}

enum CheckStatus {
  case pass
  case fail
  case info
}

struct CheckItem: Identifiable {
  let id = UUID()
  let title: String
  let status: CheckStatus
  let details: String
  let remediation: String
}

struct ScriptResponse: Decodable {
  let ok: Bool
  let summary: String?
  let mode: String?
  let source: String?
  let errorCode: String?
  let message: String?
  let details: String?
  let exitCode: Int

  enum CodingKeys: String, CodingKey {
    case ok
    case summary
    case mode
    case source
    case errorCode = "error_code"
    case message
    case details
    case exitCode = "exit_code"
  }
}
