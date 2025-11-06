import SwiftUI   // or Foundation where present
import Foundation
import Combine

public struct FastAuthSession: Codable, Sendable {
    public let accountId: String
    public let sessionKey: String
    public let expiresAt: Date
}

public protocol FastAuthProviding: AnyObject {
    var currentSession: FastAuthSession? { get }
    func signInWithEmail(_ email: String) async throws
    func confirmOTP(_ code: String) async throws -> FastAuthSession
    func signOut() async
}

/// Lightweight client placeholder for NEAR FastAuth.
final class FastAuthService: ObservableObject, FastAuthProviding {
    @Published private(set) var currentSession: FastAuthSession?

    private let baseURL = URL(string: "https://api.near.org/fastauth")!
    private let urlSession = URLSession(configuration: .ephemeral)

    func signInWithEmail(_ email: String) async throws {
        // Request OTP
        _ = email
        _ = baseURL
    }

    func confirmOTP(_ code: String) async throws -> FastAuthSession {
        _ = code
        // Simulate session creation
        let session = FastAuthSession(accountId: "user.testnet", sessionKey: "sk_abc", expiresAt: Date().addingTimeInterval(3600))
        await MainActor.run { self.currentSession = session }
        return session
    }

    func signOut() async {
        await MainActor.run { self.currentSession = nil }
    }
}


