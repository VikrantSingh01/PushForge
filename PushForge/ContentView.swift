import SwiftUI

struct ContentView: View {
    @State private var payloadText: String = ""
    @State private var bundleIdentifier: String = ""
    @State private var showHistory = false
    @State private var targetPlatform: TargetPlatform = .iOSSimulator
    @AppStorage("editorFontSize") private var editorFontSize: Double = 13

    var body: some View {
        HSplitView {
            PayloadComposerView(
                payloadText: $payloadText,
                bundleIdentifier: $bundleIdentifier,
                editorFontSize: $editorFontSize,
                targetPlatform: targetPlatform
            )
            .frame(minWidth: 400, idealWidth: 500)

            SendPanelView(
                payloadText: $payloadText,
                bundleIdentifier: $bundleIdentifier,
                targetPlatform: $targetPlatform
            )
            .frame(minWidth: 300, idealWidth: 400)
        }
        .frame(minWidth: 750, minHeight: 500)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                HStack(spacing: 8) {
                    Image("PushForgeLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 26, height: 26)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
                    Text("PushForge")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
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
