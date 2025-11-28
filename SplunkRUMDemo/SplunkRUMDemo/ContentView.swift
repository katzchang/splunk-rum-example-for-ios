import SwiftUI

struct ContentView: View {
    var body: some View {
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

                Section("Settings") {
                    NavigationLink(destination: SettingsScreen()) {
                        Label("Settings & Debug", systemImage: "gear")
                    }
                }
            }
            .navigationTitle("Splunk RUM Demo")
        }
    }
}

#Preview {
    ContentView()
}
