import Foundation
import os

struct ShellResult: Sendable {
    let exitCode: Int32
    let stdout: String
    let stderr: String

    var succeeded: Bool { exitCode == 0 }
}

/// Runs shell commands off the main thread without blocking the cooperative thread pool.
enum ShellExecutor {
    private static let logger = Logger(subsystem: "com.pushforge.app", category: "ShellExecutor")

    /// Default timeout for shell commands (30 seconds).
    static let defaultTimeout: TimeInterval = 30

    static func run(
        executablePath: String = "/usr/bin/xcrun",
        arguments: [String],
        timeout: TimeInterval = defaultTimeout
    ) async throws -> ShellResult {
        logger.debug("Running: \(executablePath) \(arguments.joined(separator: " "))")

        let result: ShellResult = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: executablePath)
                process.arguments = arguments

                let stdoutPipe = Pipe()
                let stderrPipe = Pipe()
                process.standardOutput = stdoutPipe
                process.standardError = stderrPipe

                do {
                    try process.run()
                } catch {
                    logger.error("Failed to launch process: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }

                // Terminate the process if it exceeds the timeout
                let timeoutItem = DispatchWorkItem {
                    if process.isRunning {
                        logger.warning("Process timed out after \(timeout)s, terminating: \(executablePath)")
                        process.terminate()
                    }
                }
                DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: timeoutItem)

                let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

                process.waitUntilExit()
                timeoutItem.cancel()

                let result = ShellResult(
                    exitCode: process.terminationStatus,
                    stdout: String(data: stdoutData, encoding: .utf8) ?? "",
                    stderr: String(data: stderrData, encoding: .utf8) ?? ""
                )
                continuation.resume(returning: result)
            }
        }

        if result.succeeded {
            logger.debug("Process succeeded: \(executablePath)")
        } else {
            logger.warning("Process failed (exit \(result.exitCode)): \(result.stderr.prefix(200))")
        }

        return result
    }
}
