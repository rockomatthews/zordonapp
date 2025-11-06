import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Top row: short address and settings gear without backgrounds
                    HStack {
                        let ua = appModel.zcash.unifiedAddress?.encoded ?? "ua1…"
                        HStack(spacing: 8) {
                            Text(shortAddress(ua)).foregroundStyle(ZTheme.Colors.text).font(.subheadline)
                            Button(action: { UIPasteboard.general.string = ua }) {
                                Image(systemName: "doc.on.doc").foregroundStyle(ZTheme.Colors.primary).imageScale(.large)
                            }.buttonStyle(.plain)
                        }
                        Spacer()
                        NavigationLink { SettingsView() } label: {
                            Image(systemName: "gearshape").foregroundStyle(ZTheme.Colors.primary).imageScale(.large)
                        }.buttonStyle(.plain)
                    }
                    // Balance + pricing
                    VStack(spacing: 6) {
                        Text("ZEC Balance")
                            .font(.subheadline)
                            .foregroundStyle(Color("AccentColor"))
                        Text("Ƶ " + appModel.zecBalance.formatted())
                            .font(.system(size: 42, weight: .bold))
                            .foregroundStyle(ZTheme.Colors.text)
                        if let usd = appModel.pricing.zecToUsd {
                            let balance = (NSDecimalNumber(decimal: appModel.zecBalance) as NSDecimalNumber).doubleValue
                            let total = usd * balance
                            Text("≈ $" + String(format: "%.2f", total))
                                .font(.footnote)
                                .foregroundStyle(ZTheme.Colors.textSecondary)
                        }
                    }

                    // 2x2 grid of square buttons
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        NavigationLink { ReceiveView() } label: { IconSquare(title: "RECEIVE", imageName: "icon_receive") }
                        NavigationLink { SendView() } label: { IconSquare(title: "SEND", imageName: "icon_send") }
                        NavigationLink { PayView() } label: { IconSquare(title: "PAY", imageName: "icon_pay") }
                        NavigationLink { SwapView() } label: { IconSquare(title: "SWAP", imageName: "icon_swap") }
                    }

                    // Activity below grid on its own card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Activity")
                            .font(.headline)
                            .foregroundStyle(Color("AccentColor"))
                        ActivityView()
                            .frame(height: 260)
                            .clipShape(Rectangle())
                    }
                    .zCard()
                }
                .padding()
            }
            .zScreenBackground()
            .toolbar { }
            .task { await appModel.pricing.refresh() }
        }
    }
}

private struct IconSquare: View {
    let title: String
    let imageName: String
    var body: some View {
        Image(imageName)
            .renderingMode(.original)
            .resizable()
            .scaledToFit()
            .padding(16)
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(Rectangle().fill(ZTheme.Colors.primary))
        .overlay(Rectangle().stroke(ZTheme.Colors.text, lineWidth: 1))
    }
}

private func shortAddress(_ full: String) -> String {
    let clean = full.replacingOccurrences(of: " ", with: "")
    guard clean.count > 10 else { return clean }
    let start = clean.prefix(8)
    let end = clean.suffix(4)
    return String(start) + "…" + String(end)
}

#Preview { HomeView().environmentObject(AppModel()) }


