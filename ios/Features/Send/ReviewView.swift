import SwiftUI

struct ReviewView: View {
    let destination: String
    let amount: String
    let quoteText: String
    let feeText: String?
    let legs: [RouteLeg]? = nil
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
            if let legs {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Route legs").bold().foregroundStyle(ZTheme.Colors.text)
                    ForEach(Array(legs.enumerated()), id: \.0) { _, leg in
                        HStack {
                            Text(leg.kind.capitalized)
                            Spacer()
                            Text(leg.fee)
                        }
                        .foregroundStyle(ZTheme.Colors.textSecondary)
                    }
                }
                .zOutlined()
            }

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
                Button("Close") { dismiss() }.buttonStyle(.plain).foregroundStyle(ZTheme.Colors.primary)
            }
        }
    }
}


