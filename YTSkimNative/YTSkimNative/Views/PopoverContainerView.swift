import SwiftUI

struct PopoverContainerView: View {
  @ObservedObject var model: AppModel
  let dismiss: () -> Void

  var body: some View {
    Group {
      switch model.panel {
      case .result:
        ResultView(model: model, dismiss: dismiss)
      case .checklist:
        ChecklistView(model: model, dismiss: dismiss)
      case .settings:
        SettingsView(model: model, dismiss: dismiss)
      }
    }
    .frame(width: 420, height: 360)
    .padding(10)
  }
}

