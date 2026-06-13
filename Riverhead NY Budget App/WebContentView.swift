//
//  WebContentView.swift
//  Riverhead NY Budget App
//
//  Lightweight in-app web view (WKWebView) with a loading bar + error state.
//  Prefer SafariView when you want the system browser chrome & reader mode;
//  use this when you want to keep users inside your NavigationStack.
//
//  Swift 6 • iOS 17+
//

import SwiftUI
import WebKit

struct WebContentView: View {
    let url: URL
    var title: String? = nil

    @State private var isLoading = true
    @State private var progress: Double = 0
    @State private var lastError: String? = nil

    var body: some View {
        ZStack {
            WebViewRepresentable(url: url, isLoading: $isLoading, progress: $progress, lastError: $lastError)
                .ignoresSafeArea(edges: .bottom)

            if isLoading {
                VStack(spacing: 12) {
                    ProgressView(value: progress)
                        .padding(.horizontal, 20)
                    Text("Loading…")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(radius: 8)
            }

            if let lastError {
                VStack(spacing: 10) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.title2)
                    Text("Couldn’t load this page.")
                        .font(.headline)
                    Text(lastError)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                    Link("Open in Safari", destination: url)
                        .buttonStyle(.borderedProminent)
                }
                .padding(18)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding()
            }
        }
        .navigationTitle(title ?? url.host ?? "Web")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Link(destination: url) {
                    Image(systemName: "safari")
                }
                .accessibilityLabel("Open in Safari")
            }
        }
    }
}

private struct WebViewRepresentable: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var progress: Double
    @Binding var lastError: String?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        let view = WKWebView(frame: .zero, configuration: config)
        view.navigationDelegate = context.coordinator
        view.allowsBackForwardNavigationGestures = true

        view.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        view.load(URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30))
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // no-op (single URL)
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.removeObserver(coordinator, forKeyPath: #keyPath(WKWebView.estimatedProgress))
        uiView.navigationDelegate = nil
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let parent: WebViewRepresentable

        init(_ parent: WebViewRepresentable) {
            self.parent = parent
        }

        override func observeValue(
            forKeyPath keyPath: String?,
            of object: Any?,
            change: [NSKeyValueChangeKey : Any]?,
            context: UnsafeMutableRawPointer?
        ) {
            guard keyPath == "estimatedProgress", let webView = object as? WKWebView else { return }
            updateProgress(webView.estimatedProgress)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            updateState(isLoading: true, progress: 0, lastError: nil)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            updateState(isLoading: false)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            updateState(isLoading: false, lastError: error.localizedDescription)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            updateState(isLoading: false, lastError: error.localizedDescription)
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Handle target=_blank by loading in the same view
            if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        private func updateProgress(_ value: Double) {
            Task { @MainActor [parent] in
                parent.progress = value
            }
        }

        private func updateState(
            isLoading: Bool? = nil,
            progress: Double? = nil,
            lastError: String? = nil
        ) {
            Task { @MainActor [parent] in
                if let isLoading {
                    parent.isLoading = isLoading
                }
                if let progress {
                    parent.progress = progress
                }
                parent.lastError = lastError
            }
        }
    }
}
