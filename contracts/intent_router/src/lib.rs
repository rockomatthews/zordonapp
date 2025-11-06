use near_sdk::{env, near_bindgen, AccountId, PanicOnDefault, BorshStorageKey};
use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};

#[near_bindgen]
#[derive(BorshDeserialize, BorshSerialize, PanicOnDefault)]
pub struct IntentRouter {}

#[near_bindgen]
impl IntentRouter {
    #[init]
    pub fn new() -> Self { Self {} }

    /// Called by executors after completing an intent so the app can index events.
    pub fn on_intent_settled(&self, intent_id: String, dest_chain: String, dest_asset: String, txid: String) {
        env::log_str(&format!("INTENT_SETTLED intent_id={} dest={}/{} txid={}", intent_id, dest_chain, dest_asset, txid));
    }
}


