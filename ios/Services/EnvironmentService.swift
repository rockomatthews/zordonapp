import Foundation
import Combine

final class EnvironmentService: ObservableObject {
    enum Network: String { case mainnet, testnet }
    private let key = "zordon.network"

    @Published var network: Network {
        didSet { UserDefaults.standard.set(network.rawValue, forKey: key) }
    }

    init() {
        // Force mainnet regardless of any prior persisted value.
        network = .mainnet
        UserDefaults.standard.set(network.rawValue, forKey: key)
    }

    var lightwalletdURL: URL {
        switch network {
        // Use a known good public endpoint for mainnet
        case .mainnet: return URL(string: "https://mainnet.lightwalletd.com:9067")!
        // Public ECC testnet endpoint
        case .testnet: return URL(string: "https://lightwalletd.testnet.z.cash:9067")!
        }
    }

    // Fallback candidates (first is primary)
    var lightwalletdCandidates: [URL] {
        switch network {
        case .mainnet:
            return [
                URL(string: "https://mainnet.lightwalletd.com:9067")!
            ]
        case .testnet:
            return [
                URL(string: "https://lightwalletd.testnet.z.cash:9067")!
            ]
        }
    }
}


