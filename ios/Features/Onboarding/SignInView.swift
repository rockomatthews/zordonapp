import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var email: String = ""
    @State private var code: String = ""
    @State private var sent: Bool = false
    @State private var message: String = ""

    let fastAuth = FastAuthService()

    var body: some View {
        Form {
            if !sent {
                Section("Email") {
                    TextField("you@example.com", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(ZTheme.Colors.text)
                        .textFieldStyle(.plain)
                        .zOutlined()
                    Button("Send code") { Task { await send() } }
                        .buttonStyle(ZButtonYellowStyle())
                }
            } else {
                Section("Enter code") {
                    TextField("123456", text: $code)
                        .keyboardType(.numberPad)
                        .foregroundStyle(ZTheme.Colors.text)
                        .textFieldStyle(.plain)
                        .zOutlined()
                    Button("Confirm") { Task { await confirm() } }
                        .buttonStyle(ZButtonYellowStyle())
                }
            }
            if !message.isEmpty { Text(message).font(.footnote).foregroundStyle(ZTheme.Colors.textSecondary) }
        }
        .scrollContentBackground(.hidden)
        .zScreenBackground()
        .navigationTitle("Sign In")
    }

    private func send() async {
        do { try await fastAuth.signInWithEmail(email); await MainActor.run { sent = true; message = "Code sent" } }
        catch { await MainActor.run { message = "Failed to send code" } }
    }

    private func confirm() async {
        do {
            _ = try await fastAuth.confirmOTP(code)
            await MainActor.run {
                message = "Signed in"
                appModel.isSignedIn = true
            }
        }
        catch { await MainActor.run { message = "Invalid code" } }
    }
}

#Preview { SignInView() }


