import SwiftUI

struct SettingsView: View {
    @State private var lightwalletdURL: String = "https://lightwalletd.testnet.z.cash:9067"
    @State private var receiveNotifications: Bool = true

    var body: some View {
        Form {
            Section("Privacy & Network") {
                TextField("lightwalletd endpoint", text: $lightwalletdURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(ZTheme.Colors.text)
                    .textFieldStyle(.plain)
                    .zOutlined()
                Toggle("Route availability notifications", isOn: $receiveNotifications)
            }
            Section {
                Button("Export Logs") {}
                    .buttonStyle(ZButtonYellowStyle())
                Button("Sign Out", role: .destructive) {}
            }
        }
        .scrollContentBackground(.hidden)
        .zScreenBackground()
        .navigationTitle("Settings")
    }
}

#Preview { SettingsView() }


