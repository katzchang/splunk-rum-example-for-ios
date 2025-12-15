import Foundation
import os
import SplunkAgent

/// Configuration for log buffering behavior
struct LogBufferConfiguration {
    /// Maximum number of log entries to buffer before flushing
    var maxBufferSize: Int = 50

    /// Maximum time interval (in seconds) before flushing the buffer
    var flushInterval: TimeInterval = 5.0

    /// Whether buffering is enabled
    var enabled: Bool = true
}

/// A buffered log entry
struct BufferedLogEntry {
    let message: String
    let isError: Bool
    let timestamp: Date
}

/// Collects stdout/stderr output and forwards to Splunk RUM as custom events
/// Supports buffering to reduce network overhead
class LogCollector {
    static let shared = LogCollector()

    private var stderrPipe: [Int32] = [0, 0]
    private var savedStderr: Int32 = 0
    private var isRunning = false

    // Buffering
    private var buffer: [BufferedLogEntry] = []
    private let bufferLock = NSLock()
    private var flushTimer: Timer?
    var bufferConfiguration = LogBufferConfiguration()

    // Use os.Logger for debug output (doesn't go through stdout)
    private let logger = Logger(subsystem: "com.example.SplunkRUMDemo", category: "LogCollector")

    private init() {}

    func start() {
        guard !isRunning else { return }
        isRunning = true

        logger.info("LogCollector starting (stderr only, buffering: \(self.bufferConfiguration.enabled))...")

        // Save original stderr
        savedStderr = dup(STDERR_FILENO)

        // Create pipe for stderr
        pipe(&stderrPipe)

        // Redirect stderr to pipe (NSLog also goes to stderr)
        dup2(stderrPipe[1], STDERR_FILENO)

        // Start reading from pipe in background
        startReadLoop(pipe: stderrPipe[0], savedFd: savedStderr, isError: true)

        // Start flush timer if buffering is enabled
        if bufferConfiguration.enabled {
            startFlushTimer()
        }
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false

        // Flush remaining buffer
        flushBuffer()

        // Stop timer
        flushTimer?.invalidate()
        flushTimer = nil

        // Restore original stderr
        dup2(savedStderr, STDERR_FILENO)

        // Close pipes
        close(stderrPipe[0])
        close(stderrPipe[1])
        close(savedStderr)
    }

    // MARK: - Buffering

    private func startFlushTimer() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.flushTimer = Timer.scheduledTimer(
                withTimeInterval: self.bufferConfiguration.flushInterval,
                repeats: true
            ) { [weak self] _ in
                self?.flushBuffer()
            }
        }
    }

    /// Manually flush the buffer
    func flushBuffer() {
        bufferLock.lock()
        let entriesToSend = buffer
        buffer.removeAll()
        bufferLock.unlock()

        guard !entriesToSend.isEmpty else { return }

        logger.debug("Flushing \(entriesToSend.count) buffered log entries")

        // Send buffered logs to Splunk
        for entry in entriesToSend {
            sendToSplunkImmediate(entry: entry)
        }
    }

    /// Get current buffer count
    var bufferedCount: Int {
        bufferLock.lock()
        defer { bufferLock.unlock() }
        return buffer.count
    }

    // MARK: - Read Loop

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

                    // Process and buffer/send to Splunk
                    if let message = String(data: data, encoding: .utf8) {
                        self?.processMessage(message: message, isError: isError)
                    }
                }
            }
        }
    }

    // MARK: - Message Processing

    private func processMessage(message: String, isError: Bool) {
        let lines = message.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }

        for line in lines {
            let entry = BufferedLogEntry(message: line, isError: isError, timestamp: Date())

            if bufferConfiguration.enabled {
                addToBuffer(entry)
            } else {
                sendToSplunkImmediate(entry: entry)
            }
        }
    }

    private func addToBuffer(_ entry: BufferedLogEntry) {
        bufferLock.lock()
        buffer.append(entry)
        let shouldFlush = buffer.count >= bufferConfiguration.maxBufferSize
        bufferLock.unlock()

        if shouldFlush {
            flushBuffer()
        }
    }

    private func sendToSplunkImmediate(entry: BufferedLogEntry) {
        splunkAgent?.customTracking.trackCustomEvent(
            "Log",
            MutableAttributes(dictionary: [
                "log.message": .string(entry.message),
                "log.level": .string(entry.isError ? "error" : "info"),
                "log.source": .string("stderr"),
                "log.timestamp": .string(ISO8601DateFormatter().string(from: entry.timestamp))
            ])
        )
    }
}
