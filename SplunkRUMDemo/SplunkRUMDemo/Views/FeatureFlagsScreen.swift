import SwiftUI

struct FeatureFlagsScreen: View {
    @ObservedObject private var flagManager = FeatureFlagManager.shared
    @State private var showingAddFlag = false
    @State private var newFlagKey = ""
    @State private var newFlagDescription = ""
    @State private var statusMessage: String?
    @State private var showingStatus = false

    var body: some View {
        List {
            Section("Active Flags") {
                ForEach(Array(flagManager.flags.values).sorted(by: { $0.key < $1.key })) { flag in
                    FlagRow(flag: flag) {
                        flagManager.toggleFlag(flag.key)
                    }
                }
                .onDelete(perform: deleteFlags)
            }

            Section("Actions") {
                Button(action: { showingAddFlag = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                        Text("Add Custom Flag")
                    }
                }

                Button(action: evaluateAllFlags) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                        Text("Evaluate All Flags")
                    }
                }

                Button(action: trackFlagContext) {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.purple)
                        Text("Send Flag Context to Splunk")
                    }
                }
            }

            Section(footer: Text("Feature flags are stored locally and changes are tracked in Splunk RUM. In production, use a dedicated feature flag service.")) {
                EmptyView()
            }
        }
        .navigationTitle("Feature Flags")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Add Flag", isPresented: $showingAddFlag) {
            TextField("Flag Key (e.g., new_feature)", text: $newFlagKey)
            TextField("Description", text: $newFlagDescription)
            Button("Cancel", role: .cancel) {
                newFlagKey = ""
                newFlagDescription = ""
            }
            Button("Add") {
                addNewFlag()
            }
        } message: {
            Text("Enter a key and description for the new flag.")
        }
        .alert("Result", isPresented: $showingStatus) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(statusMessage ?? "")
        }
    }

    private func deleteFlags(at offsets: IndexSet) {
        let sortedFlags = Array(flagManager.flags.values).sorted(by: { $0.key < $1.key })
        for index in offsets {
            flagManager.removeFlag(sortedFlags[index].key)
        }
    }

    private func addNewFlag() {
        guard !newFlagKey.isEmpty else { return }
        let key = newFlagKey.lowercased().replacingOccurrences(of: " ", with: "_")
        let description = newFlagDescription.isEmpty ? key : newFlagDescription
        flagManager.addFlag(key: key, description: description, enabled: false)
        newFlagKey = ""
        newFlagDescription = ""
        statusMessage = "Flag '\(key)' added!"
        showingStatus = true
    }

    private func evaluateAllFlags() {
        var results: [String] = []
        for flag in flagManager.flags.values {
            let result = flagManager.evaluateFlag(flag.key)
            results.append("\(flag.key): \(result ? "ON" : "OFF")")
        }
        statusMessage = "Evaluated \(results.count) flags and sent to Splunk"
        showingStatus = true
    }

    private func trackFlagContext() {
        flagManager.sendAllFlagsToSplunk()
        statusMessage = "Current flag context sent to Splunk RUM"
        showingStatus = true
    }
}

struct FlagRow: View {
    let flag: FeatureFlag
    let onToggle: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(flag.key)
                    .font(.body)
                    .fontWeight(.medium)
                Text(flag.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { flag.enabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        FeatureFlagsScreen()
    }
}
