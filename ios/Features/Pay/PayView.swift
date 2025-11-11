import SwiftUI

struct PayView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var toChainId: String = "near"
    @State private var destination: String = ""
    @State private var amountZec: String = ""
    @State private var amountUsd: String = ""
    @State private var slippageBps: String = "100"
    @State private var quoteText: String = ""
    @State private var presentReview: Bool = false
    @State private var pendingQuoteId: String? = nil

    private let intents = IntentsService()
    private var chains: [ChainOption] { intents.availableChains() }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header balance
                VStack(spacing: 4) {
                    Text("CROSSPAY").font(.title).bold().foregroundStyle(Color("AccentColor"))
                    Text("Ƶ " + appModel.zecBalance.formatted())
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(ZTheme.Colors.text)
                }

                // Send to chain picker and address
                VStack(alignment: .leading, spacing: 8) {
                    Text("Send to").foregroundStyle(ZTheme.Colors.textSecondary)
                    HStack {
                        Picker("", selection: $toChainId) {
                            ForEach(chains, id: \.id) { c in
                                Text(c.symbol).tag(c.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .zOutlined()
                        Spacer()
                    }
                    TextField("address...", text: $destination)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.plain)
                        .zOutlined()
                }

                // Amount pair
                VStack(alignment: .leading, spacing: 8) {
                    Text("Amount").foregroundStyle(ZTheme.Colors.textSecondary)
                    HStack {
                        TextField("0.00", text: $amountZec)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                            .zOutlined()
                        Image(systemName: "arrow.left.arrow.right")
                            .foregroundStyle(ZTheme.Colors.textSecondary)
                        HStack {
                            Text("$").foregroundStyle(ZTheme.Colors.textSecondary)
                            TextField("USD", text: $amountUsd)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.plain)
                        }
                        .zOutlined()
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

                Button("Review") { Task { await getQuote() } }
                    .buttonStyle(ZButtonYellowStyle())
                if !quoteText.isEmpty { Text(quoteText).foregroundStyle(ZTheme.Colors.textSecondary) }
                Spacer(minLength: 24)
            }
            .padding()
        }
        .zScreenBackground()
        .navigationTitle("Pay")
        .sheet(isPresented: $presentReview) {
            if let q = pendingQuoteId {
                ReviewView(destination: destination,
                           amount: amountZec.isEmpty ? "0" : amountZec,
                           quoteText: quoteText,
                           feeText: nil,
                           onConfirm: {
                    await submitAndPoll(quoteId: q, destination: destination)
                })
            }
        }
    }

    @State private var lastLegs: [RouteLeg]? = nil
    private func getQuote() async {
        do {
            let selected = chains.first(where: { $0.id == toChainId }) ?? chains.first!
            let req = QuoteRequest(direction: .outbound, sourceChain: "zcash", sourceAsset: "ZEC", destChain: selected.id, destAsset: selected.symbol, amount: amountZec.isEmpty ? "0" : amountZec)
            let q = try await intents.fetchQuote(req)
            quoteText = "Quote: ~\(q.amountOut) out (slippage \(q.slippageBps) bps)"
            pendingQuoteId = q.quoteId
            lastLegs = q.legs
            presentReview = true
        } catch {
            quoteText = "Failed to fetch quote"
        }
    }

    private func submitAndPoll(quoteId: String, destination: String) async {
        do {
            let submit = try await intents.submitIntent(SubmitIntentRequest(quoteId: quoteId, destination: destination))
            let intentId = submit.intentId
            for _ in 0..<20 {
                try await Task.sleep(nanoseconds: 3_000_000_000)
                let st = try await intents.getStatus(intentId: intentId)
                await MainActor.run {
                    quoteText = "Status: \(st.state)"
                }
                if st.state.lowercased() == "completed" { break }
            }
        } catch {
            await MainActor.run { quoteText = "Submit failed" }
        }
    }
}


