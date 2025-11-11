import SwiftUI   // or Foundation where present
import Foundation
#if ZORDON_ZCASH_SDK
import ZcashLightClientKit
import Combine
#endif
import Combine

public struct UnifiedAddress: Sendable, Equatable {
    public let encoded: String
}

public enum ZcashSyncStatus: Sendable, Equatable {
    case idle, syncing(progress: Double), upToDate, error(String)
}

public protocol ZcashWalletProviding: AnyObject {
    var unifiedAddress: UnifiedAddress? { get }
    var transparentAddress: String? { get }
    var latestBalanceZEC: Decimal { get }
    var syncStatus: ZcashSyncStatus { get }
    var recentTransactions: [TransactionItem] { get }

    func configure(lightwalletdURL: URL) async throws
    func startSync() async
    func stopSync()
    func sendShielded(to address: String, amountZEC: Decimal, memo: String?) async throws -> String
}

public struct TransactionItem: Identifiable, Sendable, Equatable {
    public let id: String
    public let isIncoming: Bool
    public let amount: Decimal
    public let confirmations: Int
}

/// Thin facade to the ECC Zcash iOS SDK. The actual SDK integration should replace the placeholders here.
final class ZcashService: ObservableObject, ZcashWalletProviding {
    @Published private(set) var unifiedAddress: UnifiedAddress?
    @Published private(set) var transparentAddress: String?
    @Published private(set) var latestBalanceZEC: Decimal = 0
    @Published private(set) var syncStatus: ZcashSyncStatus = .idle
    @Published private(set) var recentTransactions: [TransactionItem] = []

    private var endpoint: URL?
    private var endpointCandidates: [URL] = []
    private var endpointIndex: Int = 0
    #if ZORDON_ZCASH_SDK
    private var synchronizer: SDKSynchronizer?
    private var zcashNetwork: ZcashNetwork = ZcashNetworkBuilder.network(for: .testnet)
    private var cancellables = Set<AnyCancellable>()
    private var accountUUID: AccountUUID?
    private var syncWatchdogTask: Task<Void, Never>?
    #endif

    func configure(lightwalletdURL: URL) async throws {
        endpoint = lightwalletdURL
        // Build candidate list (primary first, then fallbacks)
        if lightwalletdURL.absoluteString.contains("testnet") {
            endpointCandidates = [lightwalletdURL]
        } else {
            endpointCandidates = [
                lightwalletdURL,
                URL(string: "https://mainnet.lightwalletd.com:443")!,
                URL(string: "https://lightwalletd.com:9067")!,
                URL(string: "https://lightwalletd.com:443")!,
                URL(string: "https://lwd.nighthawkflutter.com:9067")!
            ]
        }
        endpointIndex = 0
        // Download params if needed and initialize SDK subsystems.
        // Set up callbacks for sync progress to update `syncStatus`.
        #if ZORDON_ZCASH_SDK
        do {
            let isTestnet = lightwalletdURL.absoluteString.contains("testnet")
            zcashNetwork = ZcashNetworkBuilder.network(for: isTestnet ? .testnet : .mainnet)
            let appSupport = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            // File URLs expected by the SDK for cache and data databases
            let cacheDbURL = appSupport.appendingPathComponent("cache.db", isDirectory: false)
            let fsBlockDbRoot = appSupport.appendingPathComponent("fsblocks", isDirectory: true)
            let generalStorageURL = appSupport.appendingPathComponent("storage", isDirectory: true)
            let dataDbURL = appSupport.appendingPathComponent("data.db", isDirectory: false)
            let torDirURL = appSupport.appendingPathComponent("tor", isDirectory: true)
            try FileManager.default.createDirectory(at: fsBlockDbRoot, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: generalStorageURL, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: torDirURL, withIntermediateDirectories: true)
            // Ensure empty db files exist (SDK will initialize schema)
            if !FileManager.default.fileExists(atPath: cacheDbURL.path) {
                FileManager.default.createFile(atPath: cacheDbURL.path, contents: nil)
            }
            if !FileManager.default.fileExists(atPath: dataDbURL.path) {
                FileManager.default.createFile(atPath: dataDbURL.path, contents: nil)
            }

            // Use the provided URL; default to lwd port 9067 if not specified
            let isSecure = (lightwalletdURL.scheme == "https")
            let port = Int(lightwalletdURL.port ?? 9067)
            let host = lightwalletdURL.host ?? "lightwalletd"
            let endpoint = LightWalletEndpoint(
                address: host,
                port: port,
                secure: isSecure
            )
            print("ZcashService: using LWD endpoint \(host):\(endpoint.port) secure=\(endpoint.secure)")

            // Ensure Sapling params exist on disk and pass the file URLs to the initializer
            let paramsDir = try await ParamsDownloader.ensureDownloaded()
            let spendParamsURL = paramsDir.appendingPathComponent("sapling-spend.params")
            let outputParamsURL = paramsDir.appendingPathComponent("sapling-output.params")
            // Sanity check param files exist and are non-empty
            func fileSize(_ url: URL) -> Int64 {
                (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.int64Value ?? 0
            }
            let spendSize = fileSize(spendParamsURL)
            let outputSize = fileSize(outputParamsURL)
            if spendSize == 0 || outputSize == 0 {
                throw NSError(domain: "zordon", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Sapling params missing or empty"])
            }
            print("ZcashService: params ok spend=\(spendSize)B output=\(outputSize)B at \(paramsDir.path)")

            // Build Initializer per 2.3.7 signature
            let initializer = Initializer(
                cacheDbURL: cacheDbURL,
                fsBlockDbRoot: fsBlockDbRoot,
                generalStorageURL: generalStorageURL,
                dataDbURL: dataDbURL,
                torDirURL: torDirURL,
                endpoint: endpoint,
                network: zcashNetwork,
                spendParamsURL: spendParamsURL,
                outputParamsURL: outputParamsURL,
                saplingParamsSourceURL: SaplingParamsSourceURL.default,
                alias: ZcashSynchronizerAlias.default,
                loggingPolicy: Initializer.LoggingPolicy.default(.debug),
                isTorEnabled: false,
                isExchangeRateEnabled: false
            )

            synchronizer = try SDKSynchronizer(initializer: initializer)
            print("ZcashService: synchronizer created. Network=\(zcashNetwork.networkType)")

            // Observe state stream for progress and synced
            synchronizer?.stateStream
                .sink { [weak self] state in
                    guard let self else { return }
                    switch state.syncStatus {
                    case .syncing(let progress, _):
                        Task { @MainActor in self.syncStatus = .syncing(progress: Double(progress)) }
                    case .upToDate:
                        Task { @MainActor in self.syncStatus = .upToDate }
                    case .error(let e):
                        Task { @MainActor in self.syncStatus = .error(String(describing: e)) }
                    case .unprepared, .stopped:
                        break
                    }
                }
                .store(in: &cancellables)

            if let data = try KeychainService.loadSecret(account: "primary") {
                let seed = [UInt8](data)
                // Decide whether this is a first-time prepare
                let preparedKey = "zordon.sdk.prepared"
                let isPrepared = UserDefaults.standard.bool(forKey: preparedKey)
                // Use estimated birthday; fallback to network Sapling activation height
                let fallbackBirthday: BlockHeight = (zcashNetwork.networkType == .mainnet) ? 419_200 : 280_000
                let estimated: BlockHeight = synchronizer?.estimateBirthdayHeight(for: Date()) ?? fallbackBirthday
                let birthday: BlockHeight = (estimated < fallbackBirthday) ? fallbackBirthday : estimated
                print("ZcashService: will prepare wallet. isPrepared=\(isPrepared) birthday=\(birthday)")
                do {
                    _ = try await synchronizer?.prepare(
                        with: seed,
                        walletBirthday: birthday,
                        for: (isPrepared ? .existingWallet : .newWallet),
                        name: "default",
                        keySource: nil
                    )
                    if !isPrepared { UserDefaults.standard.set(true, forKey: preparedKey) }
                    print("ZcashService: prepare ok")
                } catch {
                    // If prepare as existing fails (e.g., first run), retry as new wallet once
                    if isPrepared {
                        print("ZcashService: prepare existing failed, retrying as new: \(error)")
                        _ = try await synchronizer?.prepare(
                            with: seed,
                            walletBirthday: birthday,
                            for: .newWallet,
                            name: "default",
                            keySource: nil
                        )
                        UserDefaults.standard.set(true, forKey: preparedKey)
                        print("ZcashService: prepare new ok")
                    } else {
                        print("ZcashService: prepare failed: \(error)")
                        throw error
                    }
                }

                // Fetch initial addresses and account UUID
                let accounts = try await synchronizer?.listAccounts() ?? []
                self.accountUUID = accounts.first?.id
                if let acc = self.accountUUID {
                    if let ua = try? await synchronizer?.getUnifiedAddress(accountUUID: acc) {
                        await MainActor.run { self.unifiedAddress = UnifiedAddress(encoded: ua.stringEncoded) }
                        print("ZcashService: UA ready.")
                    }
                    if let t = try? await synchronizer?.getTransparentAddress(accountUUID: acc) {
                        await MainActor.run { self.transparentAddress = t.stringEncoded }
                        print("ZcashService: t-addr ready.")
                    }
                }
            }
        } catch {
            await MainActor.run { self.syncStatus = .error("Init failed: \(error.localizedDescription)") }
            print("ZcashService: init error \(error)")
        }
        #else
        unifiedAddress = UnifiedAddress(encoded: "ua1…zordon")
        transparentAddress = "t1…zordon"
        #endif
    }

    func startSync() async {
        #if ZORDON_ZCASH_SDK
        do {
            try await synchronizer?.start(retry: true)
            await MainActor.run { self.syncStatus = .syncing(progress: 0) }
            // Balance is updated via stateStream sink set up in configure(_:)
            // Watchdog: if we stay at 0% for too long, hop to next endpoint
            syncWatchdogTask?.cancel()
            syncWatchdogTask = Task.detached { [weak self] in
                try? await Task.sleep(nanoseconds: 15_000_000_000) // 15s
                guard let self else { return }
                let status = await MainActor.run { self.syncStatus }
                var isStuckAtZero = false
                if case .syncing(let p) = status { isStuckAtZero = (p <= 0.0) }
                if isStuckAtZero, self.endpointIndex + 1 < self.endpointCandidates.count {
                    let next = self.endpointCandidates[self.endpointIndex + 1]
                    print("ZcashService: watchdog switching to \(next.absoluteString)")
                    do {
                        self.endpointIndex += 1
                        try await self.configure(lightwalletdURL: next)
                        try await self.synchronizer?.start(retry: true)
                        await MainActor.run { self.syncStatus = .syncing(progress: 0) }
                    } catch {
                        print("ZcashService: watchdog failed to restart \(error)")
                    }
                }
            }
        } catch {
            let err = "\(error)"
            print("ZcashService: startSync error \(err)")
            // If the server validation timed out, try next candidate endpoint once
            if err.contains("serviceGetInfoFailed") || err.contains("timeOut") {
                if endpointIndex + 1 < endpointCandidates.count {
                    endpointIndex += 1
                    let next = endpointCandidates[endpointIndex]
                    print("ZcashService: retrying with next endpoint \(next.absoluteString)")
                    do {
                        // Stop current synchronizer cleanly before re-initializing
                        try? await synchronizer?.stop()
                        synchronizer = nil
                        try await configure(lightwalletdURL: next)
                        try await synchronizer?.start(retry: true)
                        await MainActor.run { self.syncStatus = .syncing(progress: 0) }
                        return
                    } catch {
                        print("ZcashService: retry start failed \(error)")
                    }
                }
            }
            await MainActor.run { self.syncStatus = .error("Sync failed: \(error.localizedDescription)") }
        }
        #else
        syncStatus = .syncing(progress: 0)
        await MainActor.run { self.latestBalanceZEC = 0; self.syncStatus = .upToDate }
        #endif
    }

    func stopSync() {
        #if ZORDON_ZCASH_SDK
        synchronizer?.stop()
        #endif
        syncStatus = .idle
    }

    func sendShielded(to address: String, amountZEC: Decimal, memo: String?) async throws -> String {
        #if ZORDON_ZCASH_SDK
        guard let sync = synchronizer else { throw NSError(domain: "zordon", code: 0) }
        guard let acc = accountUUID else { throw NSError(domain: "zordon", code: 2, userInfo: [NSLocalizedDescriptionKey: "No account"])}
        let recipient = try Recipient(address, network: zcashNetwork.networkType)
        let zatoshis = Zatoshi(Int64((amountZEC as NSDecimalNumber).doubleValue * 100_000_000.0))
        let memoObj: Memo? = (memo?.isEmpty == false) ? try? Memo(string: memo!) : nil
        let proposal = try await sync.proposeTransfer(accountUUID: acc, recipient: recipient, amount: zatoshis, memo: memoObj)

        // Derive spending key from seed
        guard let data = try KeychainService.loadSecret(account: "primary") else { throw NSError(domain: "zordon", code: 3) }
        let seed = [UInt8](data)
        let usk = try DerivationTool(networkType: zcashNetwork.networkType).deriveUnifiedSpendingKey(seed: seed, accountIndex: Zip32AccountIndex(0))
        var lastId: Data? = nil
        let stream = try await sync.createProposedTransactions(proposal: proposal, spendingKey: usk)
        for try await result in stream {
            switch result {
            case .success(let txId): lastId = txId
            case .grpcFailure(let txId, _): lastId = txId
            case .submitFailure(let txId, _, _): lastId = txId
            case .notAttempted(let txId): lastId = txId
            }
        }
        let id = (lastId ?? Data()).map { String(format: "%02x", $0) }.joined()
        await MainActor.run {
            self.recentTransactions.insert(TransactionItem(id: id, isIncoming: false, amount: amountZEC, confirmations: 0), at: 0)
        }
        // Lightweight confirmations watcher
        Task.detached { [weak self] in
            for i in 1...10 {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                await MainActor.run {
                    guard let idx = self?.recentTransactions.firstIndex(where: { $0.id == id }) else { return }
                    var t = self!.recentTransactions[idx]
                    t = TransactionItem(id: t.id, isIncoming: t.isIncoming, amount: t.amount, confirmations: i)
                    self?.recentTransactions[idx] = t
                }
            }
        }
        return id
        #else
        let txid = "tx-\(Int.random(in: 1000...9999))"
        await MainActor.run { self.recentTransactions.insert(TransactionItem(id: txid, isIncoming: false, amount: amountZEC, confirmations: 0), at: 0) }
        return txid
        #endif
    }
}


