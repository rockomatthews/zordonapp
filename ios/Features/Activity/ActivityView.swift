import SwiftUI

struct ActivityView: View {
    @EnvironmentObject private var appModel: AppModel
    var body: some View {
        List {
            Section("Recent") {
                ForEach(appModel.zcash.recentTransactions) { tx in
                    HStack {
                        Text(tx.isIncoming ? "Receive" : "Send")
                        Spacer()
                        Text("\(tx.isIncoming ? "+" : "-")\(tx.amount.description) ZEC")
                    }.foregroundStyle(ZTheme.Colors.text)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .zScreenBackground()
    }
}

#Preview { ActivityView() }


