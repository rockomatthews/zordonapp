import SwiftUI
import CryptoKit

struct RecoverView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var phrase: String = ""
    @State private var error: String = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recover Account").font(.title).bold().foregroundStyle(Color("AccentColor"))
            TextEditor(text: $phrase)
                .frame(minHeight: 160)
                .overlay(Rectangle().stroke(ZTheme.Colors.text, lineWidth: 1))
                .foregroundStyle(ZTheme.Colors.text)
                .zOutlined()
            if !error.isEmpty { Text(error).foregroundStyle(.red) }
            Button("Recover") { Task { await recover() } }
                .buttonStyle(ZButtonYellowStyle())
            Spacer()
        }
        .padding()
        .zScreenBackground()
        .navigationTitle("Recover")
    }
}

extension RecoverView {
    private func recover() async {
        let trimmed = phrase.split(separator: " ").map { String($0) }.joined(separator: " ")
        guard !trimmed.isEmpty else { await MainActor.run { error = "Enter your seed phrase" }; return }
        do {
            let hash = SHA256.hash(data: Data(trimmed.utf8))
            let seedData = Data(hash)
            try KeychainService.saveSecret(seedData, account: "primary", requireBiometrics: true)
            try await appModel.zcash.configure(lightwalletdURL: appModel.env.lightwalletdURL)
            await appModel.zcash.startSync()
            await MainActor.run { appModel.isSignedIn = true }
        } catch {
            await MainActor.run { self.error = "Recovery failed" }
        }
    }
}


