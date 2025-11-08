import SwiftUI
import LocalAuthentication

struct SeedExportView: View {
    @State private var seed: String? = nil
    @State private var errorMessage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recovery Phrase").font(.title).bold().foregroundStyle(Color("AccentColor"))
            if let s = seed {
                Text(s).font(.body).foregroundStyle(ZTheme.Colors.text).textSelection(.enabled).zOutlined()
                Button("Copy") { UIPasteboard.general.string = s }.buttonStyle(ZButtonYellowStyle())
            } else if let e = errorMessage {
                Text(e).foregroundStyle(.red)
            } else {
                Text("Authenticate to view your recovery phrase.").foregroundStyle(ZTheme.Colors.textSecondary)
                Button("Unlock") { Task { await unlock() } }.buttonStyle(ZButtonYellowStyle())
            }
            Spacer()
        }
        .padding()
        .zScreenBackground()
    }

    private func unlock() async {
        do {
            let ctx = LAContext()
            _ = try await ctx.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "View recovery phrase")
            if let data = try KeychainService.loadSecret(account: "primary") {
                seed = String(decoding: data, as: UTF8.self)
            } else {
                errorMessage = "No seed found."
            }
        } catch {
            errorMessage = "Authentication failed."
        }
    }
}


