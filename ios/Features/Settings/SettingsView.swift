import SwiftUI

struct SettingsView: View {
    @State private var lightwalletdURL: String = "https://lightwalletd.testnet.z.cash:9067"
    @State private var receiveNotifications: Bool = true
    @EnvironmentObject private var appModel: AppModel

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
                Toggle("Enable Testnet", isOn: Binding(
                    get: { appModel.env.network == .testnet },
                    set: { appModel.env.network = $0 ? .testnet : .mainnet }
                ))
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
        .onChange(of: appModel.env.network) { _ in
            Task { try? await appModel.zcash.configure(lightwalletdURL: appModel.env.lightwalletdURL); await appModel.zcash.startSync() }
        }
    }
}

#Preview { SettingsView() }


