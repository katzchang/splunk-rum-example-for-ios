import SwiftUI
import SplunkAgent

struct SettingsScreen: View {
    @State private var showingCrashAlert = false
    @State private var isProcessingHeavyTask = false
    @State private var statusMessage: String?
    @State private var showingStatus = false
    @State private var bufferingEnabled = LogCollector.shared.bufferConfiguration.enabled
    @State private var bufferSize = LogCollector.shared.bufferConfiguration.maxBufferSize
    @State private var flushInterval = LogCollector.shared.bufferConfiguration.flushInterval

    var body: some View {
        List {
            Section("App Information") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Build")
                    Spacer()
                    Text("1")
                        .foregroundColor(.secondary)
                }
            }

            Section("Custom Events") {
                // Button tap event
                Button(action: trackButtonTapEvent) {
                    HStack {
                        Image(systemName: "hand.tap.fill")
                            .foregroundColor(.blue)
                        Text("Track Button Tap")
                    }
                }

                // Purchase event
                Button(action: trackPurchaseEvent) {
                    HStack {
                        Image(systemName: "cart.fill")
                            .foregroundColor(.green)
                        Text("Track Purchase Event")
                    }
                }

                // User action event
                Button(action: trackUserActionEvent) {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.purple)
                        Text("Track User Action")
                    }
                }

                // Custom workflow event
                Button(action: trackWorkflowEvent) {
                    HStack {
                        Image(systemName: "arrow.triangle.branch")
                            .foregroundColor(.orange)
                        Text("Track Workflow Event")
                    }
                }
            }

            Section("Network Requests") {
                // Successful network request
                Button(action: performSuccessfulNetworkRequest) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Successful Request (200)")
                    }
                }

                // 404 Not Found
                Button(action: performNotFoundRequest) {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.orange)
                        Text("Not Found Error (404)")
                    }
                }

                // 500 Server Error
                Button(action: performServerErrorRequest) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("Server Error (500)")
                    }
                }

                // Connection Error (invalid host)
                Button(action: performConnectionError) {
                    HStack {
                        Image(systemName: "wifi.slash")
                            .foregroundColor(.red)
                        Text("Connection Error")
                    }
                }

                // Timeout Error
                Button(action: performTimeoutRequest) {
                    HStack {
                        Image(systemName: "clock.badge.xmark")
                            .foregroundColor(.orange)
                        Text("Timeout Error")
                    }
                }
            }

            Section("Application Errors") {
                // Throw an error (caught) and track it
                Button(action: triggerCaughtError) {
                    HStack {
                        Image(systemName: "exclamationmark.bubble.fill")
                            .foregroundColor(.yellow)
                        Text("Throw Caught Error")
                    }
                }

                // Array out of bounds
                Button(action: triggerArrayOutOfBounds) {
                    HStack {
                        Image(systemName: "list.number")
                            .foregroundColor(.orange)
                        Text("Array Index Out of Bounds")
                    }
                }

                // Force unwrap nil
                Button(action: triggerForceUnwrapNil) {
                    HStack {
                        Image(systemName: "exclamationmark.octagon.fill")
                            .foregroundColor(.red)
                        Text("Force Unwrap Nil")
                    }
                }
            }

            Section("Performance Issues") {
                // Heavy task button (for Frozen Frame demo)
                Button(action: performHeavyTask) {
                    HStack {
                        Image(systemName: "tortoise.fill")
                            .foregroundColor(.orange)
                        Text("Run Heavy Task (Freeze UI)")
                        Spacer()
                        if isProcessingHeavyTask {
                            ProgressView()
                        }
                    }
                }
                .disabled(isProcessingHeavyTask)

                // Memory pressure
                Button(action: triggerMemoryPressure) {
                    HStack {
                        Image(systemName: "memorychip")
                            .foregroundColor(.purple)
                        Text("Allocate Large Memory")
                    }
                }
            }

            Section("Log Collection") {
                Button(action: testNSLog) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.green)
                        Text("Test NSLog")
                    }
                }

                Button(action: testStderrLog) {
                    HStack {
                        Image(systemName: "exclamationmark.bubble.fill")
                            .foregroundColor(.red)
                        Text("Test stderr Log")
                    }
                }
            }

            Section("Log Buffering") {
                Toggle("Enable Buffering", isOn: $bufferingEnabled)
                    .onChange(of: bufferingEnabled) { newValue in
                        LogCollector.shared.bufferConfiguration.enabled = newValue
                    }

                if bufferingEnabled {
                    HStack {
                        Text("Buffer Size")
                        Spacer()
                        Picker("", selection: $bufferSize) {
                            Text("10").tag(10)
                            Text("25").tag(25)
                            Text("50").tag(50)
                            Text("100").tag(100)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }
                    .onChange(of: bufferSize) { newValue in
                        LogCollector.shared.bufferConfiguration.maxBufferSize = newValue
                    }

                    HStack {
                        Text("Flush Interval")
                        Spacer()
                        Picker("", selection: $flushInterval) {
                            Text("1s").tag(1.0)
                            Text("5s").tag(5.0)
                            Text("10s").tag(10.0)
                            Text("30s").tag(30.0)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }
                    .onChange(of: flushInterval) { newValue in
                        LogCollector.shared.bufferConfiguration.flushInterval = newValue
                    }

                    HStack {
                        Text("Buffered Logs")
                        Spacer()
                        Text("\(LogCollector.shared.bufferedCount)")
                            .foregroundColor(.secondary)
                    }

                    Button(action: flushLogBuffer) {
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(.blue)
                            Text("Flush Buffer Now")
                        }
                    }
                }
            }

            Section("Crash (Use with Caution)") {
                // Crash button
                Button(action: {
                    showingCrashAlert = true
                }) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Trigger Crash")
                            .foregroundColor(.red)
                    }
                }
            }

            Section(footer: Text("Debug tools are for demonstration purposes only. Events will be reported to Splunk RUM.")) {
                EmptyView()
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Trigger Crash?", isPresented: $showingCrashAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Crash", role: .destructive) {
                triggerCrash()
            }
        } message: {
            Text("This will force crash the app. The crash will be reported to Splunk RUM on the next app launch. Are you sure?")
        }
        .alert("Result", isPresented: $showingStatus) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(statusMessage ?? "")
        }
    }

    // MARK: - Custom Events

    private func trackButtonTapEvent() {
        splunkAgent?.customTracking.trackCustomEvent(
            "Button Tapped",
            MutableAttributes(dictionary: [
                "button_name": .string("demo_button"),
                "screen": .string("settings"),
                "timestamp": .string(ISO8601DateFormatter().string(from: Date()))
            ])
        )
        statusMessage = "Custom event 'Button Tapped' sent!"
        showingStatus = true
    }

    private func trackPurchaseEvent() {
        splunkAgent?.customTracking.trackCustomEvent(
            "Purchase Completed",
            MutableAttributes(dictionary: [
                "product_id": .string("PRD-12345"),
                "product_name": .string("Premium Subscription"),
                "amount": .double(9.99),
                "currency": .string("USD"),
                "payment_method": .string("credit_card")
            ])
        )
        statusMessage = "Custom event 'Purchase Completed' sent!"
        showingStatus = true
    }

    private func trackUserActionEvent() {
        splunkAgent?.customTracking.trackCustomEvent(
            "User Action",
            MutableAttributes(dictionary: [
                "action_type": .string("settings_viewed"),
                "user_tier": .string("free"),
                "session_duration_seconds": .int(120)
            ])
        )
        statusMessage = "Custom event 'User Action' sent!"
        showingStatus = true
    }

    private func trackWorkflowEvent() {
        splunkAgent?.customTracking.trackCustomEvent(
            "Workflow Step",
            MutableAttributes(dictionary: [
                "workflow.name": .string("Onboarding"),
                "step": .string("profile_setup"),
                "step_number": .int(2),
                "total_steps": .int(5),
                "completed": .bool(true)
            ])
        )
        statusMessage = "Custom event 'Workflow Step' sent!"
        showingStatus = true
    }

    // MARK: - Network Requests

    private func performSuccessfulNetworkRequest() {
        guard let url = URL(string: "https://httpbin.org/get") else { return }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse {
                    statusMessage = "Success! Status: \(httpResponse.statusCode)"
                    showingStatus = true
                }
            }
        }
        task.resume()
    }

    private func performNotFoundRequest() {
        guard let url = URL(string: "https://httpbin.org/status/404") else { return }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse {
                    statusMessage = "Error: \(httpResponse.statusCode) Not Found"
                    showingStatus = true
                }
            }
        }
        task.resume()
    }

    private func performServerErrorRequest() {
        guard let url = URL(string: "https://httpbin.org/status/500") else { return }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse {
                    statusMessage = "Error: \(httpResponse.statusCode) Server Error"
                    showingStatus = true
                }
            }
        }
        task.resume()
    }

    private func performConnectionError() {
        // Invalid host to trigger connection error
        guard let url = URL(string: "https://invalid-host-that-does-not-exist-12345.com/api") else { return }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    statusMessage = "Connection Error: \(error.localizedDescription)"
                    showingStatus = true
                }
            }
        }
        task.resume()
    }

    private func performTimeoutRequest() {
        guard let url = URL(string: "https://httpbin.org/delay/30") else { return }

        var request = URLRequest(url: url)
        request.timeoutInterval = 2 // 2 second timeout

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    statusMessage = "Timeout Error: \(error.localizedDescription)"
                    showingStatus = true
                }
            }
        }
        task.resume()
    }

    // MARK: - Application Errors

    private func triggerCaughtError() {
        enum DemoError: Error, LocalizedError {
            case sampleError
            var errorDescription: String? { "This is a sample application error for demo purposes" }
        }

        do {
            throw DemoError.sampleError
        } catch {
            print("Caught error: \(error)")
            // Track error with Splunk RUM
            splunkAgent?.customTracking.trackError(error)
            statusMessage = "Error caught and reported: \(error.localizedDescription)"
            showingStatus = true
        }
    }

    private func triggerArrayOutOfBounds() {
        let array = [1, 2, 3]
        // This will crash - accessing index 10 in array of 3 elements
        let _ = array[10]
    }

    private func triggerForceUnwrapNil() {
        let nilValue: String? = nil
        // This will crash - force unwrapping nil
        let _ = nilValue!
    }

    // MARK: - Performance Issues

    private func performHeavyTask() {
        isProcessingHeavyTask = true

        // Simulate heavy computation on main thread (for Frozen Frame demo)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let startTime = Date()
            var result: Double = 0

            // Heavy computation to freeze the UI
            for i in 0..<10_000_000 {
                result += Double(i).squareRoot()
            }

            let duration = Date().timeIntervalSince(startTime)
            print("Heavy task completed in \(duration) seconds, result: \(result)")

            isProcessingHeavyTask = false
            statusMessage = "Heavy task completed in \(String(format: "%.2f", duration))s"
            showingStatus = true
        }
    }

    private func triggerMemoryPressure() {
        // Allocate large memory blocks
        var largeArrays: [[Int]] = []

        for i in 0..<100 {
            let largeArray = Array(repeating: i, count: 1_000_000)
            largeArrays.append(largeArray)
        }

        statusMessage = "Allocated \(largeArrays.count) large arrays"
        showingStatus = true
    }

    // MARK: - Log Collection

    private func testNSLog() {
        NSLog("Test log message from NSLog at %@", Date() as NSDate)
        statusMessage = "NSLog sent to Splunk!"
        showingStatus = true
    }

    private func testStderrLog() {
        fputs("Test error log message from stderr at \(Date())\n", stderr)
        statusMessage = "stderr log sent to Splunk!"
        showingStatus = true
    }

    private func flushLogBuffer() {
        let count = LogCollector.shared.bufferedCount
        LogCollector.shared.flushBuffer()
        statusMessage = "Flushed \(count) buffered log entries"
        showingStatus = true
    }

    // MARK: - Crash

    private func triggerCrash() {
        // Force crash for Crash Reporting demo
        fatalError("Intentional crash for Splunk RUM demo")
    }
}

#Preview {
    NavigationStack {
        SettingsScreen()
    }
}
