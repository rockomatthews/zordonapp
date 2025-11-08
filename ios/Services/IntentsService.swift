import Foundation

public enum IntentDirection: String, Codable, Sendable { case inbound, outbound }

public struct QuoteRequest: Codable, Sendable {
    public let direction: IntentDirection
    public let sourceChain: String
    public let sourceAsset: String
    public let destChain: String
    public let destAsset: String
    public let amount: String
}

public struct RouteLeg: Codable, Sendable { public let kind: String; public let fee: String }
public struct QuoteResponse: Codable, Sendable { public let quoteId: String; public let amountOut: String; public let slippageBps: Int; public let legs: [RouteLeg] }

public struct SubmitIntentRequest: Codable, Sendable { public let quoteId: String; public let destination: String }
public struct SubmitIntentResponse: Codable, Sendable { public let intentId: String }
public struct IntentStatus: Codable, Sendable { public let state: String; public let txids: [String] }

public struct ChainOption: Identifiable, Codable, Sendable, Equatable {
    public let id: String
    public let symbol: String
    public let name: String
    public let icon: String?
}

public protocol IntentsProviding: AnyObject {
    func fetchQuote(_ req: QuoteRequest) async throws -> QuoteResponse
    func submitIntent(_ req: SubmitIntentRequest) async throws -> SubmitIntentResponse
    func getStatus(intentId: String) async throws -> IntentStatus
    func availableChains() -> [ChainOption]
}

/// Thin HTTP client for NEAR Intents quoting and submission, configurable via AppConfig.
final class IntentsService: IntentsProviding {
    private let baseURL = AppConfig.intentsAPI
    private let urlSession = URLSession(configuration: .ephemeral)

    func availableChains() -> [ChainOption] {
        // Static stub list per provided selection modal; icons are optional placeholders.
        return [
            ChainOption(id: "eth", symbol: "ETH", name: "Ethereum", icon: "icon_chain_eth"),
            ChainOption(id: "pol", symbol: "POL", name: "Polygon", icon: "icon_chain_pol"),
            ChainOption(id: "wnear", symbol: "wNEAR", name: "Near", icon: "icon_chain_near"),
            ChainOption(id: "eth_near", symbol: "ETH", name: "Near", icon: "icon_chain_near"),
            ChainOption(id: "usdc", symbol: "USDC", name: "Near", icon: "icon_chain_near"),
            ChainOption(id: "usdt", symbol: "USDT", name: "Near", icon: "icon_chain_near"),
            ChainOption(id: "frax", symbol: "FRAX", name: "Near", icon: "icon_chain_near"),
            ChainOption(id: "aurora", symbol: "AURORA", name: "Near", icon: "icon_chain_near"),
            ChainOption(id: "wbtc", symbol: "wBTC", name: "Near", icon: "icon_chain_near")
        ]
    }

    func fetchQuote(_ req: QuoteRequest) async throws -> QuoteResponse {
        var comps = URLComponents(url: baseURL.appendingPathComponent("quote"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "direction", value: req.direction.rawValue),
            URLQueryItem(name: "source_chain", value: req.sourceChain),
            URLQueryItem(name: "source_asset", value: req.sourceAsset),
            URLQueryItem(name: "dest_chain", value: req.destChain),
            URLQueryItem(name: "dest_asset", value: req.destAsset),
            URLQueryItem(name: "amount", value: req.amount)
        ]
        let url = comps.url!
        let (data, resp) = try await urlSession.data(from: url)
        guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw NSError(domain: "intents", code: 1, userInfo: [NSLocalizedDescriptionKey: "Quote failed"])
        }
        if let decoded = try? JSONDecoder().decode(QuoteResponse.self, from: data) {
            return decoded
        }
        // Fallback: parse minimal fields if backend differs slightly
        throw NSError(domain: "intents", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unexpected quote response"])
    }

    func submitIntent(_ req: SubmitIntentRequest) async throws -> SubmitIntentResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("submit"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(req)
        let (data, resp) = try await urlSession.data(for: request)
        guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw NSError(domain: "intents", code: 3, userInfo: [NSLocalizedDescriptionKey: "Submit failed"])
        }
        guard let decoded = try? JSONDecoder().decode(SubmitIntentResponse.self, from: data) else {
            throw NSError(domain: "intents", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unexpected submit response"])
        }
        return decoded
    }

    func getStatus(intentId: String) async throws -> IntentStatus {
        let url = baseURL.appendingPathComponent("status/\(intentId)")
        let (data, resp) = try await urlSession.data(from: url)
        guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw NSError(domain: "intents", code: 5, userInfo: [NSLocalizedDescriptionKey: "Status failed"])
        }
        guard let decoded = try? JSONDecoder().decode(IntentStatus.self, from: data) else {
            throw NSError(domain: "intents", code: 6, userInfo: [NSLocalizedDescriptionKey: "Unexpected status response"])
        }
        return decoded
    }
}


