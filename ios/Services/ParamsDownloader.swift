import Foundation

enum ParamsDownloader {
    struct ParamFile {
        let name: String
        let url: URL
    }

    static let params: [ParamFile] = [
        .init(name: "sapling-spend.params", url: URL(string: "https://download.z.cash/downloads/sapling-spend.params")!),
        .init(name: "sapling-output.params", url: URL(string: "https://download.z.cash/downloads/sapling-output.params")!),
        .init(name: "orchard-keys.dat", url: URL(string: "https://download.z.cash/downloads/orchard-keys.dat")!),
        .init(name: "orchard-payment-keys.dat", url: URL(string: "https://download.z.cash/downloads/orchard-payment-keys.dat")!)
    ]

    static func paramsDirectory() throws -> URL {
        let dir = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("params", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func ensureDownloaded() async throws -> URL {
        let dir = try paramsDirectory()
        try await withThrowingTaskGroup(of: Void.self) { group in
            for p in params {
                group.addTask {
                    let dst = dir.appendingPathComponent(p.name)
                    if FileManager.default.fileExists(atPath: dst.path) { return }
                    let (data, _) = try await URLSession.shared.data(from: p.url)
                    try data.write(to: dst, options: .atomic)
                }
            }
            try await group.waitForAll()
        }
        return dir
    }
}


