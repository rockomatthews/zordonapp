import SwiftUI
import UIKit

struct ReceiveView: View {
    @State private var link: String = ""
    @EnvironmentObject private var appModel: AppModel
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Receive")
                .font(.title).bold()
                .foregroundStyle(Color("AccentColor"))
            Text("Share your universal link or Zcash Unified Address to receive funds. Non‑custodial routes only.")
                .font(.footnote)
                .foregroundStyle(ZTheme.Colors.textSecondary)

            // QR for shielded UA (centered)
            HStack {
                Spacer()
                ZStack {
                    ZQRCodeView(content: appModel.zcash.unifiedAddress?.encoded ?? "", size: 220)
                    if appModel.zcash.unifiedAddress == nil {
                        ProgressView()
                    }
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text("Shielded Unified Address").foregroundStyle(ZTheme.Colors.textSecondary)
                    if appModel.zcash.unifiedAddress != nil, case .upToDate = appModel.zcash.syncStatus {
                        Text("Synced")
                            .font(.caption)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color("AccentColor"), lineWidth: 1))
                    } else {
                        ProgressView().scaleEffect(0.7)
                    }
                }
                HStack {
                    Text(appModel.zcash.unifiedAddress?.encoded ?? "Generating…")
                        .font(.callout).foregroundStyle(ZTheme.Colors.text)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                    Spacer()
                    Button("Copy") { UIPasteboard.general.string = appModel.zcash.unifiedAddress?.encoded }
                        .buttonStyle(ZButtonYellowStyle())
                        .disabled(appModel.zcash.unifiedAddress == nil)
                        .opacity(appModel.zcash.unifiedAddress == nil ? 0.6 : 1)
                }
                .zOutlined()
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Transparent Address").foregroundStyle(ZTheme.Colors.textSecondary)
                HStack {
                    Text(appModel.zcash.transparentAddress ?? "Generating…")
                        .font(.callout).foregroundStyle(ZTheme.Colors.text)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                    Spacer()
                    Button("Copy") { UIPasteboard.general.string = appModel.zcash.transparentAddress }
                        .buttonStyle(ZButtonYellowStyle())
                        .disabled(appModel.zcash.transparentAddress == nil)
                        .opacity(appModel.zcash.transparentAddress == nil ? 0.6 : 1)
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
                        .disabled(link.isEmpty)
                        .opacity(link.isEmpty ? 0.6 : 1)
                }
                .zOutlined()
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Receive")
        .task { await buildLink() }
        .onChange(of: appModel.zcash.unifiedAddress?.encoded ?? "") { _ in
            Task { await buildLink() }
        }
        .zScreenBackground()
    }
}

extension ReceiveView {
    private func buildLink() async {
        guard let ua = appModel.zcash.unifiedAddress?.encoded else {
            link = ""
            return
        }
        link = UniversalLinkBuilder.receiveLink(destinationUA: ua, amountHint: nil).absoluteString
    }
}


