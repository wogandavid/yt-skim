import SwiftUI

struct MenuBarRootView: View {
  @ObservedObject var model: AppModel

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Button("Summarize Clipboard") {
          model.summarizeClipboard()
        }
        .disabled(model.isBusy)

        Spacer()

        Picker("Mode", selection: $model.summaryMode) {
          ForEach(SummaryMode.allCases, id: \.self) { mode in
            Text(mode.displayName).tag(mode)
          }
        }
        .labelsHidden()
        .frame(maxWidth: 160)
      }

      HStack {
        Toggle("Replace Clipboard", isOn: $model.replaceClipboard)
        Toggle("Launch at Login", isOn: $model.launchAtLogin)
      }
      .font(.subheadline)

      HStack {
        Button("Open Last Summary") {
          model.openLastSummary()
        }
        Button("First-Run Check") {
          model.openChecklist()
        }
      }

      Divider()
      PopoverContainerView(model: model, dismiss: {})
        .frame(width: 460, height: 360)
    }
    .padding(12)
    .frame(width: 480)
  }
}

