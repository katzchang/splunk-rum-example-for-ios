import Foundation
import os
import SplunkAgent

/// Log destination options
enum LogDestination: String, CaseIterable {
    case splunkRUM = "splunk_rum"      // Send via Splunk RUM custom events
    case splunkHEC = "splunk_hec"      // Send directly to Splunk HEC (HTTP Event Collector)

    var displayName: String {
        switch self {
        case .splunkRUM: return "Splunk RUM"
        case .splunkHEC: return "Splunk Core (HEC)"
        }
    }
}

/// Collects stdout/stderr output and forwards to Splunk RUM or Splunk HEC
class LogCollector {
    static let shared = LogCollector()

    private var stderrPipe: [Int32] = [0, 0]
    private var savedStderr: Int32 = 0
    private var isRunning = false

    /// Splunk HEC configuration (loaded from Info.plist)
    private let hecURL: String?
    private let hecToken: String?

    var isHECConfigured: Bool {
        guard let url = hecURL, let token = hecToken else { return false }
        return !url.isEmpty && !token.isEmpty
    }

    // Use os.Logger for debug output (doesn't go through stdout)
    private let logger = Logger(subsystem: "com.example.SplunkRUMDemo", category: "LogCollector")

    private let urlSession: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        self.urlSession = URLSession(configuration: config)

        // Load HEC configuration from Info.plist
        self.hecURL = Bundle.main.object(forInfoDictionaryKey: "SplunkHECURL") as? String
        self.hecToken = Bundle.main.object(forInfoDictionaryKey: "SplunkHECToken") as? String
    }

    /// Get current log destination from feature flags
    var currentDestination: LogDestination {
        let useHEC = FeatureFlagManager.shared.isEnabled("log_to_splunk_hec")
        return useHEC ? .splunkHEC : .splunkRUM
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true

        logger.info("LogCollector starting (stderr only, destination: \(self.currentDestination.displayName))...")

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
        let lines = message.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }

        for line in lines {
            switch currentDestination {
            case .splunkRUM:
                sendToSplunkRUM(line: line, isError: isError)
            case .splunkHEC:
                sendToSplunkHEC(line: line, isError: isError)
            }
        }
    }

    // MARK: - Splunk RUM

    private func sendToSplunkRUM(line: String, isError: Bool) {
        splunkAgent?.customTracking.trackCustomEvent(
            "Log",
            MutableAttributes(dictionary: [
                "log.message": .string(line),
                "log.level": .string(isError ? "error" : "info"),
                "log.source": .string("stderr")
            ])
        )
    }

    // MARK: - Splunk HEC

    private func sendToSplunkHEC(line: String, isError: Bool) {
        guard let urlString = hecURL, let token = hecToken,
              !urlString.isEmpty, !token.isEmpty else {
            logger.warning("Splunk HEC not configured, falling back to RUM")
            sendToSplunkRUM(line: line, isError: isError)
            return
        }

        guard let url = URL(string: urlString) else {
            logger.error("Invalid Splunk HEC URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Splunk \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "event": line,
            "sourcetype": "ios_app",
            "source": "SplunkRUMDemo"
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            logger.error("Failed to serialize HEC payload: \(error.localizedDescription)")
            return
        }

        urlSession.dataTask(with: request) { [weak self] _, response, error in
            if let error = error {
                self?.logger.error("HEC request failed: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                self?.logger.error("HEC returned status: \(httpResponse.statusCode)")
            }
        }.resume()
    }

    /// Send a test log directly to HEC (for testing configuration)
    func sendTestLogToHEC(message: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let urlString = hecURL, let token = hecToken,
              !urlString.isEmpty, !token.isEmpty else {
            completion(.failure(NSError(domain: "LogCollector", code: 1, userInfo: [NSLocalizedDescriptionKey: "HEC not configured"])))
            return
        }

        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "LogCollector", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Splunk \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "event": message,
            "sourcetype": "ios_app",
            "source": "SplunkRUMDemo"
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            completion(.failure(error))
            return
        }

        urlSession.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        completion(.success(()))
                    } else {
                        completion(.failure(NSError(domain: "LogCollector", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"])))
                    }
                }
            }
        }.resume()
    }
}
