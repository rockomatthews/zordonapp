import SwiftUI
import LocalAuthentication

struct WelcomeView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var errorMessage: String = ""
    @State private var navigatingCreate = false
    @State private var navigatingRecover = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image("icon_app")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 24))

            VStack(spacing: 12) {
                Button("Sign In") { Task { await unlock() } }
                    .buttonStyle(ZButtonYellowStyle())
                    .frame(maxWidth: .infinity)

                NavigationLink(isActive: $navigatingCreate) {
                    SelfCustodyOnboardingView()
                } label: {
                    Button("Create Account") { navigatingCreate = true }
                        .buttonStyle(ZButtonYellowStyle())
                }.buttonStyle(.plain)
                 .frame(maxWidth: .infinity)

                NavigationLink(isActive: $navigatingRecover) {
                    RecoverAccountView()
                } label: {
                    Button("Recover Account with Seed Phrase") { navigatingRecover = true }
                        .foregroundStyle(ZTheme.Colors.text)
                }.buttonStyle(.plain)
            }

            if !errorMessage.isEmpty {
                Text(errorMessage).foregroundStyle(.red)
            }
            Spacer()
            Image("title_zordon")
                .resizable()
                .scaledToFit()
                .frame(height: 28)
                .padding(.bottom, 8)
        }
        .padding()
        .navigationBarHidden(true)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .zScreenBackground()
    }
}

extension WelcomeView {
    private func unlock() async {
        do {
            guard let _ = try KeychainService.loadSecret(account: "primary") else {
                await MainActor.run { errorMessage = "No wallet found. Create or Recover first." }
                return
            }
            try await appModel.zcash.configure(lightwalletdURL: appModel.env.lightwalletdURL)
            await appModel.zcash.startSync()
            await MainActor.run { appModel.isSignedIn = true }
        } catch {
            await MainActor.run { errorMessage = "Authentication failed." }
        }
    }
}

#Preview { NavigationStack { WelcomeView() }.environmentObject(AppModel()) }

