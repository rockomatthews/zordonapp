import SwiftUI

struct AssistantView: View {
    var body: some View {
        List {
            Section("Get started") {
                Link("FastAuth overview", destination: URL(string: "https://docs.near.org/bos/components/fastauth/overview")!)
                Link("NEAR Intents", destination: URL(string: "https://docs.near.org/build/intents")!)
                Link("Zcash iOS SDK", destination: URL(string: "https://github.com/zcash/ZcashLightClientKit")!)
            }
            Section("Project docs") {
                Link("Routing coverage", destination: URL(string: "https://example.com/docs/routing.md")!)
            }
        }
        .navigationTitle("Help")
    }
}

#Preview { AssistantView() }


