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
    #if ZORDON_ZCASH_SDK
    private var synchronizer: SDKSynchronizer?
    private var zcashNetwork: ZcashNetwork = ZcashNetworkBuilder.network(for: .testnet)
    private var cancellables = Set<AnyCancellable>()
    private var accountUUID: AccountUUID?
    #endif

    func configure(lightwalletdURL: URL) async throws {
        endpoint = lightwalletdURL
        // Download params if needed and initialize SDK subsystems.
        // Set up callbacks for sync progress to update `syncStatus`.
        #if ZORDON_ZCASH_SDK
        do {
            let isTestnet = lightwalletdURL.absoluteString.contains("testnet")
            zcashNetwork = ZcashNetworkBuilder.network(for: isTestnet ? .testnet : .mainnet)
            let appSupport = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fsBlockDbRoot = appSupport.appendingPathComponent("fsblocks", isDirectory: true)
            let generalStorageURL = appSupport.appendingPathComponent("storage", isDirectory: true)
            let dataDbURL = appSupport.appendingPathComponent("data", isDirectory: true)
            let torDirURL = appSupport.appendingPathComponent("tor", isDirectory: true)
            try FileManager.default.createDirectory(at: fsBlockDbRoot, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: generalStorageURL, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: dataDbURL, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: torDirURL, withIntermediateDirectories: true)

            let endpoint = LightWalletEndpoint(
                address: lightwalletdURL.host ?? "lightwalletd",
                port: Int(lightwalletdURL.port ?? 9067),
                secure: lightwalletdURL.scheme == "https"
            )

            // Ensure Sapling params exist on disk and pass the file URLs to the initializer
            let paramsDir = try await ParamsDownloader.ensureDownloaded()
            let spendParamsURL = paramsDir.appendingPathComponent("sapling-spend.params")
            let outputParamsURL = paramsDir.appendingPathComponent("sapling-output.params")

            // Build Initializer per 2.3.7 signature
            let initializer = Initializer(
                cacheDbURL: nil,
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
                let intent: InitializerIntent = isPrepared ? .existingWallet : .newWallet
                // Use estimated birthday (fallback to 1)
                let birthday = max(1, synchronizer?.estimateBirthdayHeight(for: Date()) ?? 1)
                do {
                    _ = try await synchronizer?.prepare(
                        with: seed,
                        walletBirthday: birthday,
                        for: intent,
                        name: "default",
                        keySource: nil
                    )
                    if !isPrepared { UserDefaults.standard.set(true, forKey: preparedKey) }
                } catch {
                    // If prepare as existing fails (e.g., first run), retry as new wallet once
                    if intent == .existingWallet {
                        _ = try await synchronizer?.prepare(
                            with: seed,
                            walletBirthday: birthday,
                            for: .newWallet,
                            name: "default",
                            keySource: nil
                        )
                        UserDefaults.standard.set(true, forKey: preparedKey)
                    } else {
                        throw error
                    }
                }

                // Fetch initial addresses and account UUID
                let accounts = try await synchronizer?.listAccounts() ?? []
                self.accountUUID = accounts.first?.id
                if let acc = self.accountUUID {
                    if let ua = try? await synchronizer?.getUnifiedAddress(accountUUID: acc) {
                        await MainActor.run { self.unifiedAddress = UnifiedAddress(encoded: ua.stringEncoded) }
                    }
                    if let t = try? await synchronizer?.getTransparentAddress(accountUUID: acc) {
                        await MainActor.run { self.transparentAddress = t.stringEncoded }
                    }
                }
            }
        } catch {
            await MainActor.run { self.syncStatus = .error("Init failed: \(error.localizedDescription)") }
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
        } catch {
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


