import SwiftUI

struct SettingsView: View {
    @State private var receiveNotifications: Bool = true
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        Form {
            Section("Privacy") {
                Toggle("Route availability notifications", isOn: $receiveNotifications)
            }
            Section("Contacts") {
                NavigationLink("Address Book") { ContactsListView() }
                    .buttonStyle(ZButtonYellowStyle())
            }
            Section {
                Button("Export Logs") {}
                    .buttonStyle(ZButtonYellowStyle())
                NavigationLink("Export Recovery Phrase") { SeedExportView() }
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


