import SwiftUI

struct ChecklistView: View {
  @ObservedObject var model: AppModel
  let dismiss: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text("First-Run Check")
          .font(.headline)
        Spacer()
      }

      if model.checks.isEmpty {
        ProgressView("Running checks...")
          .frame(maxWidth: .infinity, alignment: .leading)
      } else {
        ScrollView {
          VStack(alignment: .leading, spacing: 10) {
            ForEach(model.checks) { item in
              VStack(alignment: .leading, spacing: 4) {
                HStack {
                  Text(symbol(for: item.status))
                  Text(item.title)
                    .font(.subheadline.bold())
                }
                Text(item.details)
                  .font(.subheadline)
                Text("What to do: \(item.remediation)")
                  .font(.footnote)
                  .foregroundStyle(.secondary)
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(8)
              .background(Color.gray.opacity(0.1))
              .clipShape(RoundedRectangle(cornerRadius: 8))
            }
          }
        }
      }

      HStack {
        Button("Re-run checks") {
          model.openChecklist()
        }
        Spacer()
        Button("Dismiss") {
          dismiss()
        }
      }
    }
  }

  private func symbol(for status: CheckStatus) -> String {
    switch status {
    case .pass:
      return "✓"
    case .fail:
      return "✕"
    case .info:
      return "i"
    }
  }
}

