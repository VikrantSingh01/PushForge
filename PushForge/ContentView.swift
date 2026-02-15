import SwiftUI

struct ContentView: View {
    @State private var payloadText: String = ""
    @State private var bundleIdentifier: String = ""
    @State private var showHistory = false

    var body: some View {
        HSplitView {
            PayloadComposerView(
                payloadText: $payloadText,
                bundleIdentifier: $bundleIdentifier
            )
            .frame(minWidth: 400, idealWidth: 500)

            SendPanelView(
                payloadText: $payloadText,
                bundleIdentifier: $bundleIdentifier
            )
            .frame(minWidth: 300, idealWidth: 400)
        }
        .frame(minWidth: 750, minHeight: 500)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    showHistory.toggle()
                } label: {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
            }
        }
        .sheet(isPresented: $showHistory) {
            HistoryView()
                .frame(minWidth: 600, minHeight: 400)
        }
        .navigationTitle("PushForge")
    }
}
