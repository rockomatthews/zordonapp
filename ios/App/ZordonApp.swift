import SwiftUI
import Foundation
import Combine

@main
struct ZordonApp: App {
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if appModel.isSignedIn {
                    HomeView()
                } else {
                    NavigationStack { WelcomeView() }
                }
            }
            .environmentObject(appModel)
        }
    }
}

final class AppModel: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var zecBalance: Decimal = 0

    let zcash = ZcashService()
    let env = EnvironmentService()
    let pricing = PricingService()

    init() {
        Task { await setupIfHasWallet() }
    }

    private func setupIfHasWallet() async {
        do {
            // Only configure/sync automatically if a wallet already exists in Keychain.
            if let _ = try KeychainService.loadSecret(account: "primary") {
                // Do not auto-enter the app; require explicit Sign In.
                // We still prewarm pricing and env, but leave sync to Sign In.
            }
        } catch {
            // Keep silent here; UI can surface sync errors from service state.
        }
    }
}


