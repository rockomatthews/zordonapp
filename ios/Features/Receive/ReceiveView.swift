import SwiftUI
import UIKit

struct ReceiveView: View {
    @State private var link: String = ""
    @EnvironmentObject private var appModel: AppModel
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Receive")
                .font(.title).bold()
                .foregroundStyle(ZTheme.Colors.text)
            Text("Share your universal link or Zcash Unified Address to receive funds. Non‑custodial routes only.")
                .font(.footnote)
                .foregroundStyle(ZTheme.Colors.textSecondary)

            // QR for shielded UA
            ZQRCodeView(content: appModel.zcash.unifiedAddress?.encoded ?? "ua1…zordon", size: 220)

            VStack(alignment: .leading, spacing: 10) {
                Text("Shielded Unified Address").foregroundStyle(ZTheme.Colors.textSecondary)
                HStack {
                    Text(appModel.zcash.unifiedAddress?.encoded ?? "ua1…zordon")
                        .font(.callout).foregroundStyle(ZTheme.Colors.text)
                        .textSelection(.enabled)
                    Spacer()
                    Button("Copy") { UIPasteboard.general.string = appModel.zcash.unifiedAddress?.encoded }
                        .buttonStyle(ZButtonYellowStyle())
                }
                .zOutlined()
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Transparent Address").foregroundStyle(ZTheme.Colors.textSecondary)
                HStack {
                    Text(appModel.zcash.transparentAddress ?? "t1…zordon")
                        .font(.callout).foregroundStyle(ZTheme.Colors.text)
                        .textSelection(.enabled)
                    Spacer()
                    Button("Copy") { UIPasteboard.general.string = appModel.zcash.transparentAddress }
                        .buttonStyle(ZButtonYellowStyle())
                }
                .zOutlined()
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Universal Link").foregroundStyle(ZTheme.Colors.textSecondary)
                HStack {
                    Text(link)
                        .font(.callout).foregroundStyle(ZTheme.Colors.text)
                        .textSelection(.enabled)
                    Spacer()
                    Button("Copy") { UIPasteboard.general.string = link }
                        .buttonStyle(ZButtonYellowStyle())
                }
                .zOutlined()
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Receive")
        .task { await buildLink() }
        .zScreenBackground()
    }
}

#Preview { ReceiveView() }

extension ReceiveView {
    private func buildLink() async {
        let ua = appModel.zcash.unifiedAddress?.encoded ?? "ua1…zordon"
        link = UniversalLinkBuilder.receiveLink(destinationUA: ua, amountHint: nil).absoluteString
    }
}


