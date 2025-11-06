import SwiftUI

struct SwapView: View {
    @State private var status: String = ""
    private let intents = IntentsService()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Swap").font(.title).bold().foregroundStyle(Color("AccentColor"))
            Text("Swap ZEC with other assets using NEAR Intents (testnet stub).")
                .foregroundStyle(ZTheme.Colors.textSecondary)
            Button("Get Example Quote") { Task { await quote() } }
                .buttonStyle(ZButtonYellowStyle())
            if !status.isEmpty { Text(status).foregroundStyle(ZTheme.Colors.textSecondary) }
            Spacer()
        }
        .padding()
        .zScreenBackground()
        .navigationTitle("Swap")
    }

    private func quote() async {
        do {
            let req = QuoteRequest(direction: .outbound, sourceChain: "zcash", sourceAsset: "ZEC", destChain: "near", destAsset: "USDC", amount: "0.5")
            let q = try await intents.fetchQuote(req)
            status = "Quote: out \(q.amountOut) slippage \(q.slippageBps)bps"
        } catch {
            status = "Failed to fetch quote"
        }
    }
}


