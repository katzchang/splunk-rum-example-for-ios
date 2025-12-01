import SwiftUI
import SplunkAgent

// Global access to Splunk RUM agent
var splunkAgent: SplunkRum?

@main
struct SplunkRUMDemoApp: App {

    init() {
        initializeSplunkRUM()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    private func initializeSplunkRUM() {
        let endpointConfiguration = EndpointConfiguration(
            realm: "YOUR_REALM_HERE",
            rumAccessToken: "YOUR_ACCESS_TOKEN_HERE"
        )

        let agentConfiguration = AgentConfiguration(
            endpoint: endpointConfiguration,
            appName: "test",
            deploymentEnvironment: "kotani"
        )

        do {
            splunkAgent = try SplunkRum.install(with: agentConfiguration)
        } catch {
            print("Unable to start the Splunk agent, error: \(error)")
        }

        // Enable automated navigation tracking
        splunkAgent?.navigation.preferences.enableAutomatedTracking = true

        // Start session replay
        splunkAgent?.sessionReplay.start()
    }
}
