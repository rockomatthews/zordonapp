import SwiftUI

struct PayView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pay").font(.title).bold().foregroundStyle(Color("AccentColor"))
            Text("Create a payment to a merchant or contact.").foregroundStyle(ZTheme.Colors.textSecondary)
            // Placeholder for detailed pay flow
            Spacer()
        }
        .padding()
        .zScreenBackground()
        .navigationTitle("Pay")
    }
}


