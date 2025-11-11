import SwiftUI
import CryptoKit

struct RecoverAccountView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var phrase: String = ""
    @State private var requireBiometrics: Bool = true
    @State private var errorMessage: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recover Account").font(.title).bold().foregroundStyle(Color("AccentColor"))
            Text("Enter your 12-word phrase separated by spaces.")
                .foregroundStyle(ZTheme.Colors.textSecondary)

            TextEditor(text: $phrase)
                .frame(height: 140)
                .padding(8)
                .overlay(Rectangle().stroke(ZTheme.Colors.text, lineWidth: 1))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            Toggle("Require Face ID / Passcode to unlock", isOn: $requireBiometrics)
                .tint(ZTheme.Colors.primary)

            if !errorMessage.isEmpty { Text(errorMessage).foregroundStyle(.red) }

            Button("Recover") { Task { await recover() } }
                .buttonStyle(ZButtonYellowStyle())

            Spacer()
        }
        .padding()
        .zScreenBackground()
    }
}

extension RecoverAccountView {
    private func recover() async {
        do {
            let trimmed = phrase.split(separator: " ").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.joined(separator: " ")
            guard trimmed.split(separator: " ").count >= 12 else {
                await MainActor.run { errorMessage = "Please enter at least 12 words." }
                return
            }
            // Derive a 64-byte seed using SHA512 as a pragmatic stand-in for BIP39 seed.
            let seedData = Data(SHA512.hash(data: Data(trimmed.utf8)))
            try KeychainService.saveSecret(seedData, account: "primary", requireBiometrics: requireBiometrics)
            try await appModel.zcash.configure(lightwalletdURL: appModel.env.lightwalletdURL)
            await appModel.zcash.startSync()
            await MainActor.run { appModel.isSignedIn = true }
        } catch {
            await MainActor.run { errorMessage = "Recovery failed." }
        }
    }
}

#Preview { RecoverAccountView().environmentObject(AppModel()) }


