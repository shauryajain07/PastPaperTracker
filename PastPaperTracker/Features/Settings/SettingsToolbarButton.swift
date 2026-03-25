import SwiftUI

struct SettingsToolbarButton: View {
    @State private var isPresentingSettings = false

    var body: some View {
        Button {
            isPresentingSettings = true
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 14, weight: .semibold))
                .padding(10)
                .background(.ultraThinMaterial, in: Circle())
        }
        .sheet(isPresented: $isPresentingSettings) {
            SettingsView()
        }
    }
}
