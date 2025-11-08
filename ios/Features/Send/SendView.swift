import SwiftUI

struct SendView: View {
    @State private var destination: String = ""
    @State private var amount: String = ""
    @State private var quoteText: String = ""
    @State private var slippageBps: String = "100"
    @State private var presentReview: Bool = false
    private let intents = IntentsService()
    private let engine = QuoteEngine(intents: IntentsService())
    @State private var pendingSubmit: SubmitIntentRequest? = nil
    @State private var feeText: String? = nil

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
            Section("Memo (optional)") {
                TextField("Write encrypted message here…", text: .constant(""))
                    .textFieldStyle(.plain)
                    .zOutlined()
            }
            Section {
                Button("Review & Send") { Task { await getQuoteAndSend() } }
                    .buttonStyle(ZButtonYellowStyle())
                if !quoteText.isEmpty { Text(quoteText).font(.footnote).foregroundStyle(ZTheme.Colors.textSecondary) }
            }
        }
        .scrollContentBackground(.hidden)
        .zScreenBackground()
        .navigationTitle("Send")
        .sheet(isPresented: $presentReview) {
            if let submit = pendingSubmit {
                ReviewView(destination: destination, amount: amount, quoteText: quoteText, feeText: feeText) {
                    _ = try? await intents.submitIntent(submit)
                }
            }
        }
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
            // Aggregate fees from legs if provided
            let totalFee = quote.legs.compactMap { Double($0.fee) }.reduce(0, +)
            feeText = totalFee > 0 ? String(format: "$%.4f (route est.)", totalFee) : nil
            await MainActor.run { pendingSubmit = submit; presentReview = true }
        } catch {
            quoteText = "Failed to quote or submit"
        }
    }
}

struct ReviewView: View {
    let destination: String
    let amount: String
    let quoteText: String
    let feeText: String?
    let onConfirm: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var sending = false
    @State private var result: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Review").font(.title).bold().foregroundStyle(Color("AccentColor"))
            Group {
                HStack { Text("To").bold(); Spacer(); Text(destination).multilineTextAlignment(.trailing) }
                HStack { Text("Amount").bold(); Spacer(); Text(amount) }
                HStack { Text("Route").bold(); Spacer(); Text(quoteText) }
                if let fee = feeText { HStack { Text("Fees").bold(); Spacer(); Text(fee) } }
            }
            .foregroundStyle(ZTheme.Colors.text)
            .zOutlined()

            if let res = result { Text(res).foregroundStyle(ZTheme.Colors.textSecondary) }

            Button(sending ? "Sending…" : "Confirm") {
                Task {
                    sending = true
                    await onConfirm()
                    sending = false
                    result = "Submitted. Check Activity for status."
                }
            }
            .buttonStyle(ZButtonYellowStyle())

            Spacer()
        }
        .padding()
        .zScreenBackground()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundStyle(ZTheme.Colors.primary)
            }
        }
    }
}
