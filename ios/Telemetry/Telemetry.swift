import Foundation

enum Telemetry {
    static func log(_ message: String) {
        // Replace with real analytics provider at build time; opt-in only.
        print("[Zordon] \(message)")
    }
}


