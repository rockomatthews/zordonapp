# Zordon routing coverage — non-custodial ZEC flows (M0)

This document captures the initial analysis for non-custodial receive/pay routes that terminate or originate in Zcash shielded addresses, using NEAR Intents for orchestration. It is scoped to non-custodial execution only.

## Principles

- Prefer routes that settle directly to a Zcash Unified Address (UA) in the shielded pool.
- Avoid centralized custody; refuse routes when non-custodial execution is not available.
- Provide full fee and slippage transparency; show confirmations required.
- Reorg-safe UX: show pending, N-of-M confirmations for chains involved; wait for Zcash finality depth before surfacing as confirmed.

## Executor model (NEAR Intents)

- The mobile app requests a quote describing source chain/asset and destination chain/asset (ZEC on Zcash for receive; arbitrary chain/asset for pay).
- Executors compose DEX swaps and bridges; Zordon does not take custody and only holds ZEC keys locally.
- If an executor cannot provide a non-custodial route to ZEC shielded, the app must refuse the request and surface a clear explanation with a “notify me when supported” option.

## Coverage matrix (initial)

Legend: Supported = non-custodial route exists and can finalize to Zcash UA; Preview = expected but not yet verified on testnets; Unsupported = no viable non-custodial route at this time.

| From asset/chain | To asset/chain | Direction | Status | Notes |
|---|---|---|---|---|
| ZEC (Zcash) | ZEC (Zcash) | Receive/Pay | Supported | Native shielded transfers via lightwalletd.
| NEAR (NEAR) | ZEC (Zcash) | Receive | Preview | Requires executor leg: NEAR DEX swap to ZEC proxy -> trustless bridge leg to Zcash t-addr then shield -> UA. Refuse if t-addr exposure is required without automatic shielding.
| ETH (Ethereum) | ZEC (Zcash) | Receive | Unsupported | No broadly adopted trust-minimized bridge into Zcash shielded; monitor ecosystem.
| BTC (Bitcoin) | ZEC (Zcash) | Receive | Unsupported | Same as above; monitor for non-custodial bridges with Zcash support.
| ZEC (Zcash) | NEAR / EVM / BTC | Pay | Preview | Executor must perform shielded spend -> non-custodial swap/bridge -> L1 transfer. Refuse when a centralized swap is the only path.

Notes:
- Transparent addresses may be used by some bridges; Zordon should warn and refuse unless the leg includes automatic shielding and no third-party custody.
- The matrix should be verified on testnets and updated continuously.

## Policy

- If no non-custodial route is available, the app presents: “No trustless route available yet for this asset. Choose another asset or enable notifications.”
- Users can enable notifications for specific pairs to be informed when support is added.

## Testnet setup (preview)

- NEAR testnet account via FastAuth; funded via faucet for executor gas sponsorship testing.
- Zcash testnet lightwalletd endpoints configured; download Sapling params at first run.
- Quote simulation against Intents test endpoints; store example payloads for UI integration.

## Next steps

- Implement the QuoteEngine with refusal logic and coverage awareness.
- Verify two working any->ZEC routes on testnets before enabling Receive flow for public testers.


