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
                    NavigationStack { SelfCustodyOnboardingView() }
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
        Task { await setup() }
    }

    private func setup() async {
        do {
            try await zcash.configure(lightwalletdURL: env.lightwalletdURL)
            await zcash.startSync()
            await MainActor.run { self.zecBalance = zcash.latestBalanceZEC }
        } catch {
            // Keep silent here; UI can surface sync errors from service state.
        }
    }
}


