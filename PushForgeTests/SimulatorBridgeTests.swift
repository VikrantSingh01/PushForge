import Testing
@testable import PushForge

@Suite("SimulatorBridge Tests")
struct SimulatorBridgeTests {

    @Test("ShellExecutor can run a basic command")
    func shellExecutorBasic() async throws {
        let result = try await ShellExecutor.run(
            executablePath: "/bin/echo",
            arguments: ["hello"]
        )
        #expect(result.succeeded)
        #expect(result.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "hello")
    }

    @Test("SimulatorBridge lists available simulators")
    func listSimulators() async throws {
        let bridge = SimulatorBridge()
        let simulators = try await bridge.listAvailableSimulators()
        // Should find at least one simulator on a Mac with Xcode installed
        #expect(!simulators.isEmpty)
        // Booted simulators should appear before shutdown ones
        if let firstBooted = simulators.firstIndex(where: \.isBooted),
           let firstShutdown = simulators.firstIndex(where: { !$0.isBooted }) {
            #expect(firstBooted < firstShutdown)
        }
    }
}
