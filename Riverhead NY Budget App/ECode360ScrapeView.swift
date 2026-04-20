import SwiftUI
import WebKit

struct ECode360ScrapeView: View {
    private let sourceURL = URL(string: "https://ecode360.com/RI0508")!

    @State private var payload = ECodePayload.empty
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var reloadID = UUID()

    var body: some View {
        List {
            Section("Source") {
                Link(destination: sourceURL) {
                    Label("Open eCode360 source page", systemImage: "link")
                }

                if isLoading {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Scraping code index...")
                            .foregroundStyle(.secondary)
                    }
                } else if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                        .font(.footnote)
                } else {
                    Label("Last refresh: \(Date.now.formatted(date: .abbreviated, time: .shortened))",
                          systemImage: "checkmark.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }

            if !payload.pageTitle.isEmpty || !payload.intro.isEmpty {
                Section(payload.pageTitle.isEmpty ? "Overview" : payload.pageTitle) {
                    if !payload.intro.isEmpty {
                        Text(payload.intro)
                            .font(.subheadline)
                    }
                }
            }

            Section("Extracted Items") {
                if payload.items.isEmpty && !isLoading {
                    Text("No extractable entries found yet. Tap Refresh or open the source page.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(payload.items) { item in
                        if let href = item.href, let url = URL(string: href) {
                            Link(destination: url) {
                                entryRow(item)
                            }
                        } else {
                            entryRow(item)
                        }
                    }
                }
            }
        }
        .navigationTitle("Town Code (eCode360)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    refresh()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
        .overlay {
            ECode360ScraperWebView(
                url: sourceURL,
                reloadID: reloadID
            ) { result in
                isLoading = false
                switch result {
                case .success(let newPayload):
                    payload = newPayload
                    errorMessage = nil
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
            .frame(width: 1, height: 1)
            .opacity(0.01)
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func entryRow(_ item: ECodeItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            if !item.snippet.isEmpty {
                Text(item.snippet)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 3)
    }

    private func refresh() {
        isLoading = true
        errorMessage = nil
        payload = .empty
        reloadID = UUID()
    }
}

private struct ECode360ScraperWebView: UIViewRepresentable {
    let url: URL
    let reloadID: UUID
    let onComplete: (Result<ECodePayload, Error>) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        webView.isHidden = true
        context.coordinator.reload(webView, url: url, token: reloadID)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.reload(uiView, url: url, token: reloadID)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let onComplete: (Result<ECodePayload, Error>) -> Void
        private var lastToken: UUID?
        private var attempts = 0
        private var hasCompleted = false

        init(onComplete: @escaping (Result<ECodePayload, Error>) -> Void) {
            self.onComplete = onComplete
        }

        func reload(_ webView: WKWebView, url: URL, token: UUID = UUID()) {
            guard lastToken != token else { return }
            lastToken = token
            attempts = 0
            hasCompleted = false
            webView.load(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 45))
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            scrape(from: webView)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            finish(.failure(error))
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            finish(.failure(error))
        }

        private func scrape(from webView: WKWebView) {
            guard !hasCompleted else { return }
            attempts += 1

            webView.evaluateJavaScript(Self.scrapeScript) { [weak self] result, error in
                guard let self else { return }
                if let error {
                    self.finish(.failure(error))
                    return
                }
                guard
                    let raw = result as? String,
                    let data = raw.data(using: .utf8),
                    let payload = try? JSONDecoder().decode(ECodePayload.self, from: data)
                else {
                    self.finish(.failure(ECodeScrapeError.badPayload))
                    return
                }

                if payload.blocked == true {
                    if self.attempts < 8 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.scrape(from: webView)
                        }
                    } else {
                        self.finish(.failure(ECodeScrapeError.blocked))
                    }
                    return
                }

                self.finish(.success(payload))
            }
        }

        private func finish(_ result: Result<ECodePayload, Error>) {
            guard !hasCompleted else { return }
            hasCompleted = true
            onComplete(result)
        }

        private static let scrapeScript = #"""
        (function() {
          function clean(value) {
            return (value || "").replace(/\s+/g, " ").trim();
          }

          const title = clean(document.querySelector("h1")?.innerText) || clean(document.title);
          const blocked =
            /just a moment/i.test(title) ||
            /enable javascript and cookies/i.test(document.body?.innerText || "");

          const host = window.location.origin;
          const inMain = document.querySelector("main, article, #content, .content, body") || document.body;

          const introNode = inMain.querySelector("p, .content p, article p");
          const intro = clean(introNode?.innerText);

          const seen = new Set();
          const items = [];

          const links = Array.from(inMain.querySelectorAll("a[href]"));
          for (const link of links) {
            const text = clean(link.innerText);
            if (!text || text.length < 3 || text.length > 180) continue;

            const href = link.getAttribute("href") || "";
            if (!href) continue;

            let absolute = "";
            try {
              absolute = new URL(href, window.location.href).toString();
            } catch (_) {
              continue;
            }

            if (!/ecode360\.com/i.test(absolute)) continue;
            const key = text + "|" + absolute;
            if (seen.has(key)) continue;
            seen.add(key);

            let snippet = "";
            const parentText = clean(link.closest("li, tr, p, div, td")?.innerText);
            if (parentText && parentText !== text) {
              snippet = parentText.replace(text, "").trim();
            }

            items.push({
              title: text,
              snippet: clean(snippet).slice(0, 220),
              href: absolute
            });
            if (items.length >= 120) break;
          }

          if (items.length === 0 && !blocked) {
            const fallback = Array.from(inMain.querySelectorAll("h2, h3, p")).slice(0, 20);
            for (const node of fallback) {
              const text = clean(node.innerText);
              if (!text || text.length < 8) continue;
              items.push({ title: text.slice(0, 120), snippet: "", href: null });
            }
          }

          return JSON.stringify({
            pageTitle: title,
            intro: intro,
            items: items,
            blocked: blocked
          });
        })();
        """#
    }
}

private enum ECodeScrapeError: LocalizedError {
    case blocked
    case badPayload

    var errorDescription: String? {
        switch self {
        case .blocked:
            return "eCode360 blocked automated loading. Try Refresh, then open source in Safari if needed."
        case .badPayload:
            return "Could not parse scraped page data."
        }
    }
}

private struct ECodePayload: Decodable {
    var pageTitle: String
    var intro: String
    var items: [ECodeItem]
    var blocked: Bool?

    static let empty = ECodePayload(pageTitle: "", intro: "", items: [], blocked: nil)
}

private struct ECodeItem: Decodable, Identifiable {
    let title: String
    let snippet: String
    let href: String?
    let id = UUID()

    private enum CodingKeys: String, CodingKey {
        case title
        case snippet
        case href
    }
}
