import SwiftUI

struct SendView: View {
    @State private var destination: String = ""
    @State private var amount: String = ""
    @State private var quoteText: String = ""
    @State private var slippageBps: String = "100"
    private let intents = IntentsService()
    private let engine = QuoteEngine(intents: IntentsService())

    var body: some View {
        Form {
            Section("Destination") {
                TextField("Address or QR", text: $destination)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(ZTheme.Colors.text)
                    .textFieldStyle(.plain)
                    .zOutlined()
            }
            Section("Amount (ZEC)") {
                TextField("0.0", text: $amount)
                    .keyboardType(.decimalPad)
                    .foregroundStyle(ZTheme.Colors.text)
                    .textFieldStyle(.plain)
                    .zOutlined()
            }
            Section("Slippage (bps)") {
                TextField("100", text: $slippageBps).keyboardType(.numberPad)
                    .foregroundStyle(ZTheme.Colors.text)
                    .textFieldStyle(.plain)
                    .zOutlined()
            }
            Section {
                Button("Get Quote & Send") { Task { await getQuoteAndSend() } }
                    .buttonStyle(ZButtonYellowStyle())
                if !quoteText.isEmpty { Text(quoteText).font(.footnote).foregroundStyle(ZTheme.Colors.textSecondary) }
            }
        }
        .scrollContentBackground(.hidden)
        .zScreenBackground()
        .navigationTitle("Send")
    }
}

#Preview { SendView() }

extension SendView {
    private func getQuoteAndSend() async {
        do {
            let req = QuoteRequest(direction: .outbound, sourceChain: "zcash", sourceAsset: "ZEC", destChain: "auto", destAsset: "auto", amount: amount)
            let policy = QuoteEngine.Policy(maxSlippageBps: Int(slippageBps) ?? 100)
            let quote = try await engine.getAcceptedQuote(req, policy: policy)
            quoteText = "Quote: ~\(quote.amountOut) out (slippage \(quote.slippageBps) bps)"
            let submit = SubmitIntentRequest(quoteId: quote.quoteId, destination: destination)
            _ = try await intents.submitIntent(submit)
        } catch {
            quoteText = "Failed to quote or submit"
        }
    }
}


