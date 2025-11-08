import SwiftUI

struct SyncBanner: View {
    let status: ZcashSyncStatus
    var body: some View {
        switch status {
        case .idle: EmptyView()
        case .syncing(let p):
            banner(text: "Syncing \(Int(p*100))%…")
        case .upToDate:
            banner(text: "Up to date")
        case .error(let msg):
            banner(text: "Sync error: \(msg)")
        }
    }

    private func banner(text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(ZTheme.Colors.text)
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(Rectangle().fill(ZTheme.Colors.surface))
            .overlay(Rectangle().stroke(ZTheme.Colors.text, lineWidth: 1))
            .clipShape(Rectangle())
    }
}


