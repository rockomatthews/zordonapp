import SwiftUI

struct SwapView: View {
    @State private var fromChain: String = "POL"
    @State private var fromAmount: String = ""
    @State private var refundAddress: String = ""
    @State private var toAsset: String = "ZEC"
    @State private var slippageBps: String = "100"
    @State private var status: String = ""
    @State private var presentReview: Bool = false
    @State private var pendingQuoteId: String? = nil

    private let intents = IntentsService()
    private var chains: [String] { intents.availableChains().map { $0.symbol } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("SWAP").font(.title).bold().foregroundStyle(Color("AccentColor"))

                // From chain selector and amount
                VStack(alignment: .leading, spacing: 8) {
                    Text("From").foregroundStyle(ZTheme.Colors.textSecondary)
                    HStack {
                        Picker("Chain", selection: $fromChain) {
                            ForEach(chains, id: \.self) { sym in
                                Text(sym).tag(sym)
                            }
                        }
                        .pickerStyle(.menu)
                        .zOutlined()
                        TextField("$0.00", text: $fromAmount)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                            .zOutlined()
                    }
                }

                // Refund address
                VStack(alignment: .leading, spacing: 8) {
                    Text("Refund Address").foregroundStyle(ZTheme.Colors.textSecondary)
                    TextField("Polygon address...", text: $refundAddress)
                        .textFieldStyle(.plain)
                        .zOutlined()
                }

                // Swap arrow
                HStack { Spacer(); Image(systemName: "arrow.up.arrow.down").padding().zOutlined(); Spacer() }

                // To ZEC
                VStack(alignment: .leading, spacing: 8) {
                    Text("To").foregroundStyle(ZTheme.Colors.textSecondary)
                    HStack {
                        Text("ZEC").bold().foregroundStyle(ZTheme.Colors.text)
                        Spacer()
                        Text("0.00").foregroundStyle(ZTheme.Colors.text)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Slippage tolerance").foregroundStyle(ZTheme.Colors.textSecondary)
                    HStack {
                        TextField("100", text: $slippageBps).keyboardType(.numberPad)
                            .textFieldStyle(.plain)
                            .zOutlined()
                        Text("bps").foregroundStyle(ZTheme.Colors.textSecondary)
                    }
                }

                Button("Get Quote") { Task { await quote() } }.buttonStyle(ZButtonYellowStyle())
                if !status.isEmpty { Text(status).foregroundStyle(ZTheme.Colors.textSecondary) }
                Spacer(minLength: 24)
            }
            .padding()
        }
        .zScreenBackground()
        .navigationTitle("Swap")
        .sheet(isPresented: $presentReview) {
            if let q = pendingQuoteId, let ua = appModel.zcash.unifiedAddress?.encoded {
                ReviewView(destination: ua,
                           amount: fromAmount.isEmpty ? "0" : fromAmount,
                           quoteText: status,
                           feeText: nil,
                           onConfirm: {
                    await submitAndPoll(quoteId: q, destination: ua)
                })
            }
        }
    }

    @EnvironmentObject private var appModel: AppModel
    @State private var lastLegs: [RouteLeg]? = nil
    private func quote() async {
        do {
            let req = QuoteRequest(direction: .inbound, sourceChain: fromChain.lowercased(), sourceAsset: fromChain, destChain: "zcash", destAsset: toAsset, amount: fromAmount.isEmpty ? "0" : fromAmount)
            let q = try await intents.fetchQuote(req)
            status = "Quote: out \(q.amountOut) slippage \(q.slippageBps)bps"
            pendingQuoteId = q.quoteId
            lastLegs = q.legs
            presentReview = true
        } catch {
            status = "Failed to fetch quote"
        }
    }

    private func submitAndPoll(quoteId: String, destination: String) async {
        do {
            let submit = try await intents.submitIntent(SubmitIntentRequest(quoteId: quoteId, destination: destination))
            let intentId = submit.intentId
            // poll every 3s up to 60s
            for _ in 0..<20 {
                try await Task.sleep(nanoseconds: 3_000_000_000)
                let st = try await intents.getStatus(intentId: intentId)
                await MainActor.run {
                    status = "Status: \\(st.state)"
                }
                if st.state.lowercased() == "completed" { break }
            }
        } catch {
            await MainActor.run { status = "Submit failed" }
        }
    }
}


