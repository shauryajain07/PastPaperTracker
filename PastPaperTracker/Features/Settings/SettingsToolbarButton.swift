import SwiftUI

struct SettingsToolbarButton: View {
    @State private var isPresentingSettings = false

    var body: some View {
        Button {
            isPresentingSettings = true
        } label: {
            Image(systemName: "gearshape.fill")
        }
        .buttonStyle(StudyToolbarIconButtonStyle())
        .sheet(isPresented: $isPresentingSettings) {
            SettingsView()
        }
    }
}
