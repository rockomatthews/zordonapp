import SwiftUI
import Combine

struct SelfCustodyOnboardingView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var seedWords: [String] = []
    @State private var requireBiometrics = true
    @State private var confirmed = false
    @State private var errorMessage: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create your wallet").font(.title).bold().foregroundStyle(Color("AccentColor"))
            Text("Write these 12 words in order and keep them private. They recover your wallet.")
                .foregroundStyle(ZTheme.Colors.textSecondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(Array(seedWords.enumerated()), id: \.0) { (index, word) in
                    HStack {
                        Text("\(index+1).").bold()
                        Text(word)
                    }
                    .padding(8)
                    .overlay(Rectangle().stroke(ZTheme.Colors.text, lineWidth: 1))
                }
            }

            Toggle("Require Face ID / Passcode to unlock", isOn: $requireBiometrics)
                .tint(ZTheme.Colors.primary)
                .foregroundStyle(ZTheme.Colors.text)

            Toggle("I have securely backed up my phrase", isOn: $confirmed)
                .tint(ZTheme.Colors.primary)
                .foregroundStyle(ZTheme.Colors.text)

            if !errorMessage.isEmpty { Text(errorMessage).foregroundStyle(.red) }

            Button("Create Wallet") { Task { await create() } }
                .buttonStyle(ZButtonYellowStyle())
                .disabled(!confirmed)

            Spacer()
        }
        .padding()
        .zScreenBackground()
        .onAppear { if seedWords.isEmpty { seedWords = Mnemonic.generate() } }
    }

    private func create() async {
        do {
            let seed = seedWords.joined(separator: " ")
            try KeychainService.saveSecret(Data(seed.utf8), account: "primary", requireBiometrics: requireBiometrics)
            await MainActor.run { appModel.isSignedIn = true }
        } catch {
            await MainActor.run { errorMessage = "Failed to save wallet" }
        }
    }
}

enum Mnemonic {
    static func generate() -> [String] {
        // Simple placeholder 12-word mnemonic (replace with BIP39 in production)
        let words = ["zebra","quantum","shadow","orchard","ledger","privacy","shield","spark","swift","near","intent","zordon","wallet","secure","yellow","blue","hash","note","block","signal","alpha","beta","gamma","delta"]
        var result: [String] = []
        for _ in 0..<12 { result.append(words.randomElement()!) }
        return result
    }
}


