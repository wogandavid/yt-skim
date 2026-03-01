import AppKit
import SwiftUI

struct ResultView: View {
  @ObservedObject var model: AppModel
  let dismiss: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text(model.summary.headline)
          .font(.headline)
        Spacer()
        Text(model.summary.host)
          .foregroundStyle(.secondary)
      }

      if model.isBusy || model.summary.status == .running {
        ProgressView()
          .progressViewStyle(.linear)
      }

      ScrollView {
        Text(model.summary.body.isEmpty ? "No summary text available." : model.summary.body)
          .frame(maxWidth: .infinity, alignment: .leading)
          .textSelection(.enabled)
      }
      .frame(maxHeight: .infinity)

      if !model.summary.details.isEmpty {
        DisclosureGroup("Details") {
          ScrollView {
            Text(model.summary.details)
              .font(.footnote.monospaced())
              .frame(maxWidth: .infinity, alignment: .leading)
              .textSelection(.enabled)
          }
          .frame(minHeight: 70, maxHeight: 120)
        }
      }

      HStack {
        Button("Copy") {
          let text = model.summary.body
          guard !text.isEmpty else { return }
          NSPasteboard.general.clearContents()
          NSPasteboard.general.setString(text, forType: .string)
        }
        .disabled(model.summary.body.isEmpty)

        Spacer()

        Button("Dismiss") {
          dismiss()
        }
      }
    }
  }
}
