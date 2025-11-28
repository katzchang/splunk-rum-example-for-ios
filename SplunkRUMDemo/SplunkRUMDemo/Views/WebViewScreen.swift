import SwiftUI
import WebKit

struct WebViewScreen: View {
    @State private var selectedURL = "https://www.apple.com"
    @State private var isLoading = true

    let urls = [
        ("Apple", "https://www.apple.com"),
        ("Wikipedia", "https://www.wikipedia.org"),
        ("GitHub", "https://github.com")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // URL Selector
            Picker("Select Site", selection: $selectedURL) {
                ForEach(urls, id: \.1) { name, url in
                    Text(name).tag(url)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            // WebView
            ZStack {
                WebView(urlString: selectedURL, isLoading: $isLoading)

                if isLoading {
                    ProgressView("Loading...")
                        .padding()
                        .background(Color(.systemBackground).opacity(0.9))
                        .cornerRadius(10)
                }
            }
        }
        .navigationTitle("WebView Demo")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WebView: UIViewRepresentable {
    let urlString: String
    @Binding var isLoading: Bool

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        WebViewScreen()
    }
}
