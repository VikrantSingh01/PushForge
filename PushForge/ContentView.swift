import SwiftUI

struct ContentView: View {
    @State private var payloadText: String = ""
    @State private var bundleIdentifier: String = ""
    @State private var showHistory = false
    @AppStorage("editorFontSize") private var editorFontSize: Double = 13

    var body: some View {
        HSplitView {
            PayloadComposerView(
                payloadText: $payloadText,
                bundleIdentifier: $bundleIdentifier,
                editorFontSize: $editorFontSize
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
            ToolbarItem(placement: .navigation) {
                HStack(spacing: 6) {
                    Image("PushForgeLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    Text("PushForge")
                        .font(.headline)
                }
            }
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
        .navigationTitle("")
    }
}
