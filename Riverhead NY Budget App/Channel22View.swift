//
//  Channel22View.swift
//  Riverhead NY Helper
//
//  Dedicated view for Channel 22 so the embedded video
//  stays within the visible bounds.
//

import SwiftUI
import WebKit

@MainActor
struct Channel22View: View {
    var body: some View {
        Channel22WebView()
            .background(RiverheadTheme.background)
            .navigationTitle("Channel 22")
            .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - WKWebView with CSS guardrails for video

private struct Channel22WebView: UIViewRepresentable {

    func makeUIView(context: Context) -> WKWebView {
        // Configure a web view that injects a little CSS after the page loads
        let config = WKWebViewConfiguration()
        let controller = WKUserContentController()

        // CSS:
        //  - Make video/iframes responsive and never wider than the viewport
        //  - Add bottom margin so content doesn't sit under the tab bar
        let js = """
        (function() {
            var style = document.createElement('style');
            style.type = 'text/css';
            style.innerHTML = "video, iframe { max-width: 100% !important; height: auto !important; } body { margin-bottom: 120px !important; }";
            document.head.appendChild(style);
        })();
        """

        let script = WKUserScript(
            source: js,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        controller.addUserScript(script)
        config.userContentController = controller

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true

        let request = URLRequest(url: RiverheadURLs.channel22)
        webView.load(request)

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No special update behavior needed for now
    }
}
