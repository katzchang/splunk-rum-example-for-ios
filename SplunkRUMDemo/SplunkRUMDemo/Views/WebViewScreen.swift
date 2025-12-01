import SwiftUI
import WebKit

struct WebViewScreen: View {
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            // WebView
            ZStack {
                WebView(urlString: "https://www.wikipedia.org", isLoading: $isLoading)

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
        print("[WebView] makeUIView called")
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        context.coordinator.initialURL = urlString

        // Load URL only once in makeUIView
        if let url = URL(string: urlString) {
            print("[WebView] Loading initial URL: \(urlString)")
            let request = URLRequest(url: url)
            webView.load(request)
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Only reload if the initial URL prop changed (not for in-webview navigation)
        let previousInitialURL = context.coordinator.initialURL
        if previousInitialURL != urlString {
            print("[WebView] Initial URL changed from \(previousInitialURL ?? "nil") to \(urlString), reloading")
            context.coordinator.initialURL = urlString
            if let url = URL(string: urlString) {
                let request = URLRequest(url: url)
                webView.load(request)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        var initialURL: String?

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("[WebView] didStartProvisionalNavigation - URL: \(webView.url?.absoluteString ?? "nil")")
            parent.isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("[WebView] didFinish - URL: \(webView.url?.absoluteString ?? "nil")")
            parent.isLoading = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("[WebView] didFail - error: \(error.localizedDescription)")
            parent.isLoading = false
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("[WebView] didFailProvisionalNavigation - error: \(error.localizedDescription)")
            parent.isLoading = false
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            print("[WebView] decidePolicyFor - URL: \(navigationAction.request.url?.absoluteString ?? "nil"), type: \(navigationAction.navigationType.rawValue)")
            decisionHandler(.allow)
        }
    }
}

#Preview {
    NavigationStack {
        WebViewScreen()
    }
}
