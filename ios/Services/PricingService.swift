import Foundation
import Combine

final class PricingService: ObservableObject {
    @Published private(set) var zecToUsd: Double? = nil
    private var lastUpdate: Date? = nil
    private let url = URL(string: "https://api.coingecko.com/api/v3/simple/price?ids=zcash&vs_currencies=usd")!

    func refresh() async {
        if let last = lastUpdate, Date().timeIntervalSince(last) < 60, zecToUsd != nil { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let zcash = json["zcash"] as? [String: Any],
               let usd = zcash["usd"] as? Double {
                await MainActor.run {
                    self.zecToUsd = usd
                    self.lastUpdate = Date()
                }
            }
        } catch {
            // keep previous value
        }
    }
}


