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

public protocol IntentsProviding: AnyObject {
    func fetchQuote(_ req: QuoteRequest) async throws -> QuoteResponse
    func submitIntent(_ req: SubmitIntentRequest) async throws -> SubmitIntentResponse
    func getStatus(intentId: String) async throws -> IntentStatus
}

/// Thin HTTP client placeholder for NEAR Intents quoting and submission.
final class IntentsService: IntentsProviding {
    private let baseURL = URL(string: "https://api.near.org/intents")!
    private let urlSession = URLSession(configuration: .ephemeral)

    func fetchQuote(_ req: QuoteRequest) async throws -> QuoteResponse {
        _ = req
        // Mock response until API integration is wired
        return QuoteResponse(quoteId: "q_123", amountOut: "0.99", slippageBps: 50, legs: [RouteLeg(kind: "swap", fee: "0.003"), RouteLeg(kind: "bridge", fee: "0.001")])
    }

    func submitIntent(_ req: SubmitIntentRequest) async throws -> SubmitIntentResponse {
        _ = req
        return SubmitIntentResponse(intentId: "i_123")
    }

    func getStatus(intentId: String) async throws -> IntentStatus {
        _ = intentId
        return IntentStatus(state: "pending", txids: [])
    }
}


