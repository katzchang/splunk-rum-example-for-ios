import Foundation
import SplunkAgent

/// A simple feature flag manager for demonstration purposes.
/// In production, this would typically integrate with a service like LaunchDarkly, Split, or Optimizely.
class FeatureFlagManager: ObservableObject {
    static let shared = FeatureFlagManager()

    /// Published flags for SwiftUI observation
    @Published private(set) var flags: [String: FeatureFlag] = [:]

    private let defaults = UserDefaults.standard
    private let flagsKey = "featureFlags"

    private init() {
        loadFlags()
        setupDefaultFlags()
    }

    // MARK: - Default Flags

    private func setupDefaultFlags() {
        // Set up default demo flags if not already present
        let defaultFlags: [(String, String, Bool)] = [
            ("dark_mode", "Enable Dark Mode", false),
            ("new_checkout", "New Checkout Flow", false),
            ("premium_features", "Premium Features", true),
            ("beta_ui", "Beta UI Elements", false),
            ("analytics_v2", "Analytics V2", true)
        ]

        for (key, description, defaultValue) in defaultFlags {
            if flags[key] == nil {
                flags[key] = FeatureFlag(key: key, description: description, enabled: defaultValue)
            }
        }
        saveFlags()
    }

    // MARK: - Flag Operations

    func isEnabled(_ key: String) -> Bool {
        return flags[key]?.enabled ?? false
    }

    func setFlag(_ key: String, enabled: Bool) {
        if var flag = flags[key] {
            flag.enabled = enabled
            flags[key] = flag
            saveFlags()

            // Track flag change in Splunk RUM
            trackFlagChange(key: key, enabled: enabled)
        }
    }

    func toggleFlag(_ key: String) {
        if let flag = flags[key] {
            setFlag(key, enabled: !flag.enabled)
        }
    }

    func addFlag(key: String, description: String, enabled: Bool = false) {
        flags[key] = FeatureFlag(key: key, description: description, enabled: enabled)
        saveFlags()
        trackFlagChange(key: key, enabled: enabled)
    }

    func removeFlag(_ key: String) {
        flags.removeValue(forKey: key)
        saveFlags()
    }

    // MARK: - Persistence

    private func loadFlags() {
        guard let data = defaults.data(forKey: flagsKey),
              let decoded = try? JSONDecoder().decode([String: FeatureFlag].self, from: data) else {
            return
        }
        flags = decoded
    }

    private func saveFlags() {
        guard let data = try? JSONEncoder().encode(flags) else { return }
        defaults.set(data, forKey: flagsKey)
    }

    // MARK: - Splunk RUM Integration

    private func trackFlagChange(key: String, enabled: Bool) {
        splunkAgent?.customTracking.trackCustomEvent(
            "Feature Flag Changed",
            MutableAttributes(dictionary: [
                "feature_flag.key": .string(key),
                "feature_flag.enabled": .bool(enabled),
                "feature_flag.source": .string("local")
            ])
        )
    }

    /// Evaluate a flag and track the evaluation in Splunk RUM
    func evaluateFlag(_ key: String, trackEvaluation: Bool = true) -> Bool {
        let result = isEnabled(key)

        if trackEvaluation {
            splunkAgent?.customTracking.trackCustomEvent(
                "Feature Flag Evaluated",
                MutableAttributes(dictionary: [
                    "feature_flag.key": .string(key),
                    "feature_flag.value": .bool(result),
                    "feature_flag.source": .string("local")
                ])
            )
        }

        return result
    }

    /// Get all flags summary as a custom event
    func sendAllFlagsToSplunk() {
        // Send each flag state as part of a summary event
        var flagSummary: [String] = []
        for (key, flag) in flags.sorted(by: { $0.key < $1.key }) {
            flagSummary.append("\(key)=\(flag.enabled)")
        }

        splunkAgent?.customTracking.trackCustomEvent(
            "Feature Flag Summary",
            MutableAttributes(dictionary: [
                "feature_flags.count": .int(flags.count),
                "feature_flags.summary": .string(flagSummary.joined(separator: ", "))
            ])
        )
    }
}

// MARK: - Feature Flag Model

struct FeatureFlag: Codable, Identifiable {
    let key: String
    let description: String
    var enabled: Bool

    var id: String { key }
}
