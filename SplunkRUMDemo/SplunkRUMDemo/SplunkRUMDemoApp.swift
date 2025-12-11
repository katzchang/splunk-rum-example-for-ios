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
        guard let realm = Bundle.main.object(forInfoDictionaryKey: "SplunkRUMRealm") as? String,
              let accessToken = Bundle.main.object(forInfoDictionaryKey: "SplunkRUMAccessToken") as? String,
              !realm.isEmpty, !accessToken.isEmpty else {
            print("Splunk RUM configuration not found. Please set up Secrets.xcconfig")
            return
        }

        let endpointConfiguration = EndpointConfiguration(
            realm: realm,
            rumAccessToken: accessToken
        )

        let agentConfiguration = AgentConfiguration(
            endpoint: endpointConfiguration,
            appName: "test",
            deploymentEnvironment: "kotani"
        )
            .sessionConfiguration(SessionConfiguration(samplingRate: 0.5))

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
