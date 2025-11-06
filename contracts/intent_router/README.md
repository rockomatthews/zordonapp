# Zordon intent-router (optional)

A minimal NEAR contract that emits an event when an intent is settled by an executor. This contract is optional; it exists to provide a canonical callback and on-chain analytics hook for the mobile app.

- Init: `new()`
- Callback: `on_intent_settled(intent_id, dest_chain, dest_asset, txid)`

Build and deploy with near-sdk-rs toolchain.

