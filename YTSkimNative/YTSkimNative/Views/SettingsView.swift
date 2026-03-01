import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
  @ObservedObject var model: AppModel
  let dismiss: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Settings")
        .font(.headline)

      VStack(alignment: .leading, spacing: 8) {
        Text("Global Hotkey")
          .font(.subheadline.bold())
        KeyboardShortcuts.Recorder("Summarize Clipboard", name: .summarizeClipboard)
      }

      Divider()

      Toggle("Replace clipboard with summary", isOn: $model.replaceClipboard)
      Toggle("Launch at login", isOn: $model.launchAtLogin)
      Toggle("Show Dock Icon (Debug)", isOn: $model.showDockIconDebug)

      Divider()

      VStack(alignment: .leading, spacing: 6) {
        Text("Default Summary Mode")
          .font(.subheadline.bold())
        Picker("Mode", selection: $model.summaryMode) {
          ForEach(SummaryMode.allCases, id: \.self) { mode in
            Text(mode.displayName).tag(mode)
          }
        }
        .pickerStyle(.segmented)
      }

      Spacer()

      HStack {
        Spacer()
        Button("Dismiss") {
          dismiss()
        }
      }
    }
  }
}
