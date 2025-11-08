import Foundation
import Combine
import SwiftUI

struct Contact: Identifiable, Codable, Equatable {
    let id: UUID
    var address: String
    var name: String
    var chain: String
}

final class ContactStore: ObservableObject {
    @Published private(set) var contacts: [Contact] = []
    private let key = "zordon.contacts"

    init() {
        load()
    }

    func add(address: String, name: String, chain: String) {
        var list = contacts
        list.append(Contact(id: UUID(), address: address, name: name, chain: chain))
        update(list)
    }

    func delete(at offsets: IndexSet) {
        var list = contacts
        list.remove(atOffsets: offsets)
        update(list)
    }

    private func update(_ list: [Contact]) {
        contacts = list
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let list = try? JSONDecoder().decode([Contact].self, from: data) {
            contacts = list
        }
    }
}


