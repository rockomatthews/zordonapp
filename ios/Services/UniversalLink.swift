import Foundation

enum UniversalLinkBuilder {
    static func receiveLink(destinationUA: String, amountHint: Decimal?) -> URL {
        var comps = URLComponents()
        comps.scheme = "https"
        comps.host = "pay.zordon.app"
        comps.path = "/intent"
        comps.queryItems = [
            URLQueryItem(name: "dest_chain", value: "zcash"),
            URLQueryItem(name: "dest_asset", value: "ZEC"),
            URLQueryItem(name: "dest_address", value: destinationUA)
        ]
        if let amt = amountHint {
            comps.queryItems?.append(URLQueryItem(name: "amount_hint", value: String(describing: amt)))
        }
        // Executors interpret source asset/chain at payment time based on payer input.
        return comps.url! 
    }
}


