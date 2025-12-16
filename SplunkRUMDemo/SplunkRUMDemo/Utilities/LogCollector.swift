import Foundation
import os
import SplunkAgent

/// Collects stdout/stderr output and forwards to Splunk RUM as custom events
class LogCollector {
    static let shared = LogCollector()

    private var stdoutPipe: [Int32] = [0, 0]
    private var stderrPipe: [Int32] = [0, 0]
    private var savedStdout: Int32 = 0
    private var savedStderr: Int32 = 0
    private var isRunning = false

    // Use os.Logger for debug output (doesn't go through stdout)
    private let logger = Logger(subsystem: "com.example.SplunkRUMDemo", category: "LogCollector")

    private init() {}

    func start() {
        guard !isRunning else { return }
        isRunning = true

        logger.info("LogCollector starting (stderr only)...")

        // Save original stderr
        savedStderr = dup(STDERR_FILENO)

        // Create pipe for stderr
        pipe(&stderrPipe)

        // Redirect stderr to pipe (NSLog also goes to stderr)
        dup2(stderrPipe[1], STDERR_FILENO)

        // Start reading from pipe in background
        startReadLoop(pipe: stderrPipe[0], savedFd: savedStderr, isError: true)
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false

        // Restore original stderr
        dup2(savedStderr, STDERR_FILENO)

        // Close pipes
        close(stderrPipe[0])
        close(stderrPipe[1])
        close(savedStderr)
    }

    private func startReadLoop(pipe: Int32, savedFd: Int32, isError: Bool) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let bufferSize = 2048
            var buffer = [UInt8](repeating: 0, count: bufferSize)

            while self?.isRunning == true {
                let bytesRead = read(pipe, &buffer, bufferSize)
                if bytesRead > 0 {
                    let data = Data(bytes: buffer, count: bytesRead)

                    // Write to original stdout/stderr (so Xcode console still works)
                    _ = data.withUnsafeBytes { ptr in
                        write(savedFd, ptr.baseAddress, bytesRead)
                    }

                    // Send to Splunk
                    if let message = String(data: data, encoding: .utf8) {
                        self?.sendToSplunk(message: message, isError: isError)
                    }
                }
            }
        }
    }

    private func sendToSplunk(message: String, isError: Bool) {
        // Split by newlines and send each line
        let lines = message.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }

        for line in lines {
            splunkAgent?.customTracking.trackCustomEvent(
                "Log",
                MutableAttributes(dictionary: [
                    "log.message": .string(line),
                    "log.level": .string("info"),
                    "log.source": .string("stderr")
                ])
            )
        }
    }
}
