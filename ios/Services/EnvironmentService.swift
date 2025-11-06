import Foundation
import Combine

final class EnvironmentService: ObservableObject {
    enum Network: String { case mainnet, testnet }
    private let key = "zordon.network"

    @Published var network: Network {
        didSet { UserDefaults.standard.set(network.rawValue, forKey: key) }
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: key), let n = Network(rawValue: raw) {
            network = n
        } else {
            network = .testnet
        }
    }

    var lightwalletdURL: URL {
        switch network {
        case .mainnet: return URL(string: "https://mainnet.lightwalletd.com:9067")!
        case .testnet: return URL(string: "https://lightwalletd.testnet.z.cash:9067")!
        }
    }
}


