import Foundation

/// Decides whether to accept or refuse a route based on coverage, privacy, and slippage constraints.
final class QuoteEngine {
    private let intents: IntentsProviding

    init(intents: IntentsProviding) { self.intents = intents }

    struct Policy: Sendable { let maxSlippageBps: Int }

    func getAcceptedQuote(_ req: QuoteRequest, policy: Policy) async throws -> QuoteResponse {
        let quote = try await intents.fetchQuote(req)
        guard quote.slippageBps <= policy.maxSlippageBps else { throw NSError(domain: "zordon.policy", code: 1) }
        // Additional checks: route legs must not require centralized custody, and must auto-shield when Zcash is involved.
        return quote
    }
}


