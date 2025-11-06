import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Zordon")
                    .font(.largeTitle).bold()
                    .foregroundStyle(ZTheme.Colors.text)

                Text("ZEC Balance")
                    .font(.subheadline)
                    .foregroundStyle(ZTheme.Colors.textSecondary)

                Text(appModel.zecBalance.formatted())
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(ZTheme.Colors.text)

                HStack(spacing: 16) {
                    NavigationLink("Receive") { ReceiveView() }
                        .buttonStyle(ZButtonYellowStyle())
                    NavigationLink("Send") { SendView() }
                        .buttonStyle(ZButtonYellowStyle())
                    NavigationLink("Activity") { ActivityView() }
                        .buttonStyle(ZButtonYellowStyle())
                    NavigationLink("Settings") { SettingsView() }
                        .buttonStyle(ZButtonYellowStyle())
                }

                Spacer()
            }
            .padding()
            .zScreenBackground()
        }
    }
}

#Preview { HomeView().environmentObject(AppModel()) }


