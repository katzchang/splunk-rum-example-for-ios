import SwiftUI

struct SettingsScreen: View {
    @State private var showingCrashAlert = false
    @State private var isProcessingHeavyTask = false

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

            Section("Debug Tools") {
                // Heavy task button (for Frozen Frame demo)
                Button(action: performHeavyTask) {
                    HStack {
                        Image(systemName: "tortoise.fill")
                            .foregroundColor(.orange)
                        Text("Run Heavy Task")
                        Spacer()
                        if isProcessingHeavyTask {
                            ProgressView()
                        }
                    }
                }
                .disabled(isProcessingHeavyTask)

                // Network request button
                Button(action: performNetworkRequest) {
                    HStack {
                        Image(systemName: "network")
                            .foregroundColor(.blue)
                        Text("Make Network Request")
                    }
                }

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

            Section(footer: Text("Debug tools are for demonstration purposes only. Use with caution.")) {
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
    }

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
        }
    }

    private func performNetworkRequest() {
        // Make a sample network request (will be tracked by RUM)
        guard let url = URL(string: "https://httpbin.org/get") else { return }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Network request failed: \(error)")
            } else if let httpResponse = response as? HTTPURLResponse {
                print("Network request completed with status: \(httpResponse.statusCode)")
            }
        }
        task.resume()
    }

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
