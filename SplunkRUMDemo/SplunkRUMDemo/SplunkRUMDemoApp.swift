import SwiftUI
import SplunkAgent

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

        var agent: SplunkRum?

        do {
            agent = try SplunkRum.install(with: agentConfiguration)
        } catch {
            print("Unable to start the Splunk agent, error: \(error)")
        }

        // Enable automated navigation tracking
        agent?.navigation.preferences.enableAutomatedTracking = true

        // Start session replay
        agent?.sessionReplay.start()
    }
}
