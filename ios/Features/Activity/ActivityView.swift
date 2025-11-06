import SwiftUI

struct ActivityView: View {
    var body: some View {
        List {
            Section("Recent") {
                Text("Shielded receive 0.5 ZEC – confirmed").foregroundStyle(ZTheme.Colors.text)
                Text("Intent: ZEC → NEAR – pending").foregroundStyle(ZTheme.Colors.text)
            }
        }
        .scrollContentBackground(.hidden)
        .zScreenBackground()
    }
}

#Preview { ActivityView() }


