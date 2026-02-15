import Testing
@testable import PushForge

@Suite("SimulatorBridge Tests")
struct SimulatorBridgeTests {

    @Test("ShellExecutor can run a basic command")
    func shellExecutorBasic() async throws {
        let shell = ShellExecutor()
        let result = try await shell.run(
            executablePath: "/bin/echo",
            arguments: ["hello"]
        )
        #expect(result.succeeded)
        #expect(result.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "hello")
    }

    @Test("SimulatorBridge can list simulators without crashing")
    func listSimulators() async throws {
        let bridge = SimulatorBridge()
        // This should not throw — it may return an empty list if no sims are booted
        let simulators = try await bridge.listBootedSimulators()
        #expect(simulators is [BootedSimulator])
    }
}
