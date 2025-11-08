import SwiftUI

struct ContactsListView: View {
    @StateObject private var store = ContactStore()

    var body: some View {
        VStack {
            if store.contacts.isEmpty {
                Spacer()
                Text("Your address book is empty")
                    .foregroundStyle(ZTheme.Colors.textSecondary)
                Spacer()
            } else {
                List {
                    ForEach(store.contacts) { c in
                        VStack(alignment: .leading) {
                            Text(c.name)
                                .bold()
                                .foregroundStyle(ZTheme.Colors.text)
                            Text(c.address)
                                .font(.footnote)
                                .foregroundStyle(ZTheme.Colors.textSecondary)
                        }
                    }
                    .onDelete(perform: store.delete)
                }
                .scrollContentBackground(.hidden)
            }
            NavigationLink(destination: AddContactView(store: store)) {
                Text("+  Add New Contact")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ZButtonYellowStyle())
            .padding()
        }
        .zScreenBackground()
        .navigationTitle("Address Book")
    }
}

struct AddContactView: View {
    @ObservedObject var store: ContactStore
    @Environment(\.dismiss) private var dismiss
    @State private var address: String = ""
    @State private var name: String = ""
    @State private var chain: String = "Zcash"

    var body: some View {
        Form {
            Section("Wallet Address") {
                TextField("Enter wallet address...", text: $address)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.plain)
                    .zOutlined()
            }
            Section("Contact Name") {
                TextField("Enter contact name...", text: $name)
                    .textFieldStyle(.plain)
                    .zOutlined()
            }
            Section("Select Chain") {
                Picker("Select...", selection: $chain) {
                    Text("Zcash").tag("Zcash")
                    Text("NEAR").tag("NEAR")
                    Text("Ethereum").tag("Ethereum")
                    Text("Bitcoin").tag("Bitcoin")
                }
                .pickerStyle(.menu)
            }
            Section {
                Button("Save") {
                    store.add(address: address, name: name, chain: chain)
                    dismiss()
                }
                .disabled(address.isEmpty || name.isEmpty)
                .buttonStyle(ZButtonYellowStyle())
            }
        }
        .scrollContentBackground(.hidden)
        .zScreenBackground()
        .navigationTitle("Add New Contact")
    }
}


