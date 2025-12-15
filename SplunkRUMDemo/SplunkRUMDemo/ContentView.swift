import SwiftUI
import SplunkAgent

struct ContentView: View {
    var body: some View {
        ZStack(alignment: .top) {
            NavigationStack {
                List {
                    Section("Demo Features") {
                        NavigationLink(destination: WebViewScreen()) {
                            Label("WebView Demo", systemImage: "globe")
                        }

                        NavigationLink(destination: CameraScreen()) {
                            Label("Camera", systemImage: "camera")
                        }

                        NavigationLink(destination: FaceIDScreen()) {
                            Label("Face ID Authentication", systemImage: "faceid")
                        }
                    }

                    Section("Configuration") {
                        NavigationLink(destination: FeatureFlagsScreen()) {
                            Label("Feature Flags", systemImage: "flag.fill")
                        }
                    }

                    Section("Settings") {
                        NavigationLink(destination: SettingsScreen()) {
                            Label("Settings & Debug", systemImage: "gear")
                        }
                    }
                }
                .navigationTitle("Splunk RUM Demo")
            }

            // Sampling status indicator
            SamplingStatusBanner()
        }
    }
}

struct SamplingStatusBanner: View {
    var body: some View {
        let isSampled = checkSamplingStatus()

        HStack(spacing: 6) {
            Circle()
                .fill(isSampled ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            Text(isSampled ? "Sampled" : "Not Sampled")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(isSampled ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
        )
        .padding(.top, 50)
    }

    private func checkSamplingStatus() -> Bool {
        guard let agent = splunkAgent else { return false }
        if case .running = agent.state.status {
            return true
        }
        return false
    }
}

#Preview {
    ContentView()
}
